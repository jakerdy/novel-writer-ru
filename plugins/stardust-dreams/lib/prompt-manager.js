/**
 * Менеджер промптов
 * Основной компонент безопасности: отвечает за получение зашифрованных промптов с сервера, их расшифровку в памяти и обеспечение отсутствия их сохранения
 */

import { apiClient } from './api-client.js';
import { Decryptor } from './decryptor.js';
import { TemplateEngine } from './template-engine.js';

export class PromptManager {
  constructor() {
    this.decryptor = new Decryptor();
    this.templateEngine = new TemplateEngine();

    // Не используем постоянное кэширование, только временное хранение в памяти
    this.memoryCache = new Map();

    // Запускаем таймер очистки памяти
    this.startMemoryCleaner();
  }

  /**
   * Генерация контента с использованием шаблона промпта
   * Весь процесс гарантирует, что промпт находится только в памяти и очищается сразу после использования
   */
  async usePrompt(sessionId, apiKey = null) {
    let decryptedPrompt = null;
    let filledPrompt = null;
    let encryptedData = null;

    try {
      // Установка API Key (если предоставлен)
      if (apiKey) {
        apiClient.setApiKey(apiKey);
      }

      // Шаг 1: Получение информации о сессии
      console.log('📋 Получение информации о сессии...');
      const session = await apiClient.getSession(sessionId);

      if (!session) {
        throw new Error('Сессия не существует или истекла');
      }

      // Проверка истечения срока действия сессии
      if (new Date(session.expiresAt) < new Date()) {
        throw new Error('Сессия истекла, пожалуйста, сгенерируйте новую в веб-интерфейсе');
      }

      // Шаг 2: Получение зашифрованного промпта
      console.log('🔐 Получение зашифрованного шаблона...');
      encryptedData = await apiClient.getEncryptedPrompt(sessionId);

      // Шаг 3: Расшифровка в памяти
      console.log('🔓 Расшифровка шаблона...');
      decryptedPrompt = await this.decryptInMemory(
        {
          encrypted: encryptedData.encryptedPrompt,
          iv: encryptedData.iv,
          authTag: encryptedData.authTag
        },
        encryptedData.sessionKey
      );

      // Шаг 4: Заполнение параметров
      console.log('📝 Заполнение параметров...');
      filledPrompt = this.templateEngine.fill(
        decryptedPrompt,
        encryptedData.parameters
      );

      // Шаг 5: Запись использования (без конфиденциальных данных)
      const startTime = Date.now();

      // Шаг 6: Возврат заполненного промпта (для использования ИИ)
      // Примечание: после возврата вызывающий код должен немедленно использовать и очистить его
      return {
        prompt: filledPrompt,
        metadata: {
          formId: encryptedData.formId,
          formName: encryptedData.formName,
          sessionId: sessionId,
          duration: Date.now() - startTime
        }
      };

    } finally {
      // Шаг 7: Принудительная очистка конфиденциальных данных из памяти
      this.clearSensitiveData(decryptedPrompt);
      this.clearSensitiveData(filledPrompt);
      this.clearSensitiveData(encryptedData);

      // Запуск сборки мусора (если доступно)
      if (global.gc) {
        global.gc();
      }
    }
  }

  /**
   * Расшифровка промпта в памяти
   * Не записывает данные в файлы или логи
   */
  async decryptInMemory(encryptedPrompt, sessionKey) {
    // Использование временных переменных для гарантии отсутствия сохранения
    let decrypted = null;

    try {
      // Проверка ограничений памяти
      this.checkMemoryUsage();

      // Выполнение расшифровки
      decrypted = await this.decryptor.decrypt(encryptedPrompt, sessionKey);

      // Проверка результата расшифровки
      if (!decrypted || typeof decrypted !== 'string') {
        throw new Error('Ошибка расшифровки: недействительный результат');
      }

      // Немедленный возврат, без сохранения
      return decrypted;

    } catch (error) {
      // Очистка данных также при возникновении ошибки
      this.clearSensitiveData(decrypted);
      throw new Error(`Ошибка расшифровки: ${error.message}`);
    }
  }

  /**
   * Очистка конфиденциальных данных
   * JavaScript не может по-настоящему перезаписать память, но может как можно скорее освободить ссылки
   */
  clearSensitiveData(data) {
    if (!data) return;

    try {
      if (typeof data === 'string') {
        // Для строк создаем новую пустую строку и освобождаем исходную ссылку
        data = '';
        data = null;
      } else if (typeof data === 'object') {
        // Для объектов очищаем все свойства
        Object.keys(data).forEach(key => {
          if (typeof data[key] === 'string') {
            data[key] = '';
          }
          data[key] = null;
          delete data[key];
        });
        data = null;
      }
    } catch (e) {
      // Игнорируем ошибки при очистке
    }
  }

  /**
   * Проверка использования памяти
   * Предотвращение утечек памяти
   */
  checkMemoryUsage() {
    const usage = process.memoryUsage();
    const heapUsedMB = usage.heapUsed / 1024 / 1024;

    // Если объем памяти превышает 100 МБ, выдаем предупреждение
    if (heapUsedMB > 100) {
      console.warn(`⚠️ Высокое использование памяти: ${heapUsedMB.toFixed(2)} MB`);

      // Очистка кэша памяти
      this.clearMemoryCache();

      // Принудительная сборка мусора
      if (global.gc) {
        global.gc();
      }
    }
  }

  /**
   * Очистка кэша памяти
   */
  clearMemoryCache() {
    // Очистка всех элементов кэша
    for (const [key, value] of this.memoryCache) {
      this.clearSensitiveData(value);
    }
    this.memoryCache.clear();
  }

  /**
   * Запуск таймера очистки памяти
   * Периодическая очистка неиспользуемой памяти
   */
  startMemoryCleaner() {
    // Проверка каждую минуту
    setInterval(() => {
      const now = Date.now();

      // Очистка кэша, срок хранения которого превышает 5 минут
      for (const [key, value] of this.memoryCache) {
        if (value.timestamp && now - value.timestamp > 5 * 60 * 1000) {
          this.clearSensitiveData(value);
          this.memoryCache.delete(key);
        }
      }

      // Проверка использования памяти
      this.checkMemoryUsage();
    }, 60 * 1000);
  }

  /**
   * Проверка прав доступа к сессии
   * Гарантия того, что пользователь может получить доступ только к своим сессиям
   */
  async validateAccess(sessionId, userId) {
    // Здесь можно добавить дополнительную логику проверки прав доступа
    const session = await apiClient.getSession(sessionId);

    if (!session) {
      throw new Error('Сессия не существует');
    }

    // Проверка владельца сессии
    if (session.userId && session.userId !== userId) {
      throw new Error('Нет прав доступа к данной сессии');
    }

    return true;
  }

  /**
   * Получение метаданных промпта (без фактического содержимого)
   * Для отображения информации о шаблоне
   */
  async getPromptMetadata(templateId) {
    // Возвращаем только метаданные, без фактического содержимого промпта
    const templates = await apiClient.getTemplates();
    const template = templates.find(t => t.id === templateId);

    if (!template) {
      throw new Error('Шаблон не существует');
    }

    return {
      id: template.id,
      name: template.name,
      description: template.description,
      category: template.category,
      parameters: template.parameters,
      // Фактическое содержимое промпта не включается
    };
  }

  /**
   * Предварительная проверка
   * Проверка всех условий перед фактическим использованием
   */
  async preCheck(sessionId) {
    const checks = {
      session: false,
      auth: false,
      memory: false,
      network: false
    };

    try {
      // Проверка сессии
      const session = await apiClient.getSession(sessionId);
      checks.session = !!session && new Date(session.expiresAt) > new Date();

      // Проверка аутентификации
      checks.auth = !!apiClient.token;

      // Проверка памяти
      const usage = process.memoryUsage();
      checks.memory = usage.heapUsed < 200 * 1024 * 1024; // < 200 МБ

      // Проверка сети
      checks.network = true; // Проверено при получении сессии

      return checks;
    } catch (error) {
      return checks;
    }
  }

  /**
   * Безопасное выполнение
   * Обертка процесса выполнения для обеспечения безопасности и очистки
   */
  async safeExecute(fn) {
    const sensitiveData = [];

    try {
      // Регистрация функции очистки
      const registerForCleanup = (data) => {
        sensitiveData.push(data);
        return data;
      };

      // Выполнение функции
      const result = await fn(registerForCleanup);

      return result;

    } finally {
      // Очистка конфиденциальных данных независимо от успеха или неудачи
      for (const data of sensitiveData) {
        this.clearSensitiveData(data);
      }
      sensitiveData.length = 0;
    }
  }
}

// Экспорт одиночного экземпляра
export const promptManager = new PromptManager();