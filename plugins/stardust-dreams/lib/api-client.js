/**
 * Клиент API Stardust Dreams
 * Отвечает за взаимодействие с API сервера для получения зашифрованных Prompt и данных сессии
 */

import fetch from 'node-fetch';

const API_BASE = process.env.STARDUST_API_URL || 'https://api.stardust-dreams.com';

export class StardustAPIClient {
  constructor() {
    this.baseUrl = API_BASE;
    this.apiKey = process.env.STARDUST_API_KEY || null;
  }

  /**
   * Установка API Key
   */
  setApiKey(apiKey) {
    this.apiKey = apiKey;
  }

  /**
   * Получение информации о сессии
   * @param {string} sessionId - ID сессии
   * @returns {Object} Данные сессии
   */
  async getSession(sessionId) {
    const response = await this.request('/api/trpc/form.getSession', {
      method: 'POST',
      body: {
        json: { sessionId }
      }
    });

    if (!response?.result?.data?.success) {
      throw new Error(`Сессия ${sessionId} не существует или устарела`);
    }

    return response.result.data.data;
  }

  /**
   * Получение зашифрованного Prompt (основная функция)
   * @param {string} sessionId - ID сессии
   * @returns {Object} Объект, содержащий зашифрованный Prompt и ключ для его расшифровки
   */
  async getEncryptedPrompt(sessionId) {
    const response = await this.request('/api/trpc/form.getPrompt', {
      method: 'POST',
      body: {
        json: {
          sessionId,
          apiKey: this.apiKey
        }
      }
    });

    if (!response?.result?.data?.success) {
      throw new Error(`Не удалось получить зашифрованный Prompt для сессии ${sessionId}`);
    }

    const data = response.result.data.data;

    // Возврат зашифрованных данных в стандартном формате
    return {
      sessionId: data.sessionId,
      formId: data.formId,
      formName: data.formName,
      parameters: data.parameters,
      encryptedPrompt: data.encryptedPrompt,
      iv: data.iv,
      authTag: data.authTag,
      sessionKey: data.sessionKey,
      expiresAt: data.expiresAt
    };
  }


  /**
   * Отправка запроса к API
   */
  async request(endpoint, options = {}) {
    const url = endpoint.startsWith('http') ? endpoint : `${this.baseUrl}${endpoint}`;

    const headers = {
      'Content-Type': 'application/json'
    };

    const fetchOptions = {
      method: options.method || 'GET',
      headers
    };

    if (options.body) {
      fetchOptions.body = JSON.stringify(options.body);
    }

    try {
      const response = await fetch(url, fetchOptions);
      const data = await response.json();

      // Обработка ограничения скорости запросов
      if (response.status === 429) {
        const retryAfter = response.headers.get('Retry-After');
        throw new Error(`Слишком частые запросы, попробуйте снова через ${retryAfter || '60'} секунд`);
      }

      return data;
    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error(`Сетевой запрос не удался: ${error}`);
    }
  }
}

// Экспорт синглтона
export const apiClient = new StardustAPIClient();