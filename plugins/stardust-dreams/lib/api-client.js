```javascript
/**
 * Клиент API Stardust Dreams
 * Отвечает за взаимодействие с API сервера для получения зашифрованных Prompt и данных сеанса
 */

import fetch from 'node-fetch';

const API_BASE = process.env.STARDUST_API_URL || 'https://api.stardust-dreams.com';

export class StardustAPIClient {
  constructor() {
    this.baseUrl = API_BASE;
    this.apiKey = process.env.STARDUST_API_KEY || null;
  }

  /**
   * Установить API Key
   */
  setApiKey(apiKey) {
    this.apiKey = apiKey;
  }

  /**
   * Получить информацию о сеансе
   * @param {string} sessionId - ID сеанса
   * @returns {Object} Данные сеанса
   */
  async getSession(sessionId) {
    const response = await this.request('/api/trpc/form.getSession', {
      method: 'POST',
      body: {
        json: { sessionId }
      }
    });

    if (!response?.result?.data?.success) {
      throw new Error(`Сеанс ${sessionId} не существует или истек`);
    }

    return response.result.data.data;
  }

  /**
   * Получить зашифрованный Prompt (основная функция)
   * @param {string} sessionId - ID сеанса
   * @returns {Object} Объект, содержащий зашифрованный Prompt и ключ для расшифровки
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
      throw new Error(`Не удалось получить зашифрованный Prompt для сеанса ${sessionId}`);
    }

    const data = response.result.data.data;

    // Возвращаем зашифрованные данные в стандартном формате
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
   * Отправить запрос к API
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
        throw new Error(`Слишком частые запросы, повторите попытку через ${retryAfter || '60'} секунд`);
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
```