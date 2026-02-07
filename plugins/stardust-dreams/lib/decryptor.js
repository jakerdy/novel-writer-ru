```javascript
/**
 * Дешифратор
 * Отвечает за дешифровку зашифрованных Prompt, полученных с сервера, в памяти
 * Принцип безопасности: результат дешифровки находится только в памяти, никогда не сохраняется
 */

import crypto from 'crypto';

export class Decryptor {
  constructor() {
    // Конфигурация алгоритма
    this.algorithm = 'aes-256-gcm';
    this.saltLength = 32;
    this.ivLength = 16;
    this.tagLength = 16;
  }

  /**
   * Дешифрует зашифрованный Prompt
   * @param {Object} encryptedData - Объект, содержащий зашифрованные данные
   * @param {string} encryptedData.encrypted - Зашифрованные данные в hex-кодировке
   * @param {string} encryptedData.iv - IV в hex-кодировке
   * @param {string} encryptedData.authTag - Тег аутентификации в hex-кодировке
   * @param {string} sessionKey - Ключ сессии в hex-формате
   * @returns {string} Дешифрованный Prompt (только в памяти)
   */
  async decrypt(encryptedData, sessionKey) {
    let decrypted = null;

    try {
      // Проверка ввода
      if (!encryptedData || !encryptedData.encrypted || !encryptedData.iv || !encryptedData.authTag) {
        throw new Error('Неполные зашифрованные данные');
      }

      // Преобразование из hex-формата в Buffer
      const iv = Buffer.from(encryptedData.iv, 'hex');
      const authTag = Buffer.from(encryptedData.authTag, 'hex');
      const encrypted = Buffer.from(encryptedData.encrypted, 'hex');
      const key = Buffer.from(sessionKey, 'hex');

      // Проверка целостности данных
      if (iv.length !== this.ivLength) {
        throw new Error('Недопустимая длина IV');
      }

      if (authTag.length !== this.tagLength) {
        throw new Error('Недопустимая длина тега аутентификации');
      }

      if (key.length !== 32) {
        throw new Error('Недопустимая длина ключа');
      }

      // Создание дешифратора
      const decipher = crypto.createDecipheriv(this.algorithm, key, iv);
      decipher.setAuthTag(authTag);

      // Выполнение дешифровки
      let decrypted = decipher.update(encrypted, null, 'utf8');
      decrypted += decipher.final('utf8');

      // Проверка результата дешифровки
      if (!this.isValidPrompt(decrypted)) {
        throw new Error('Недопустимый результат дешифровки');
      }

      // Немедленный возврат, без сохранения
      return decrypted;

    } catch (error) {
      // Очистка возможных конфиденциальных данных
      if (decrypted) {
        this.secureClear(decrypted);
      }

      // Предоставление полезной информации в зависимости от типа ошибки
      if (error.message.includes('bad decrypt')) {
        throw new Error('Ошибка дешифровки: неверный ключ или поврежденные данные');
      } else if (error.message.includes('auth tag')) {
        throw new Error('Ошибка дешифровки: проверка целостности данных не удалась');
      } else {
        throw new Error(`Ошибка дешифровки: ${error.message}`);
      }
    }
  }


  /**
   * Проверяет, является ли дешифрованный Prompt действительным
   * Базовая проверка, чтобы убедиться, что это не мусор
   */
  isValidPrompt(prompt) {
    if (!prompt || typeof prompt !== 'string') {
      return false;
    }

    // Проверка наличия основных признаков Prompt
    // Эти признаки должны быть общей частью всех Prompt
    const hasValidStructure =
      prompt.length > 10 && // Минимум определенной длины
      prompt.includes('{{') && // Содержит плейсхолдеры параметров
      /[\u4e00-\u9fa5]/.test(prompt); // Содержит китайские символы

    return hasValidStructure;
  }

  /**
   * Безопасно очищает конфиденциальные данные
   * Освобождает ссылки на память как можно быстрее
   */
  secureClear(data) {
    if (!data) return;

    try {
      if (typeof data === 'string') {
        // Для строк невозможно реально перезаписать, но можно освободить ссылку
        data = null;
      } else if (Buffer.isBuffer(data)) {
        // Для Buffer можно заполнить нулями
        data.fill(0);
        data = null;
      } else if (typeof data === 'object') {
        // Для объектов выполняет рекурсивную очистку
        Object.keys(data).forEach(key => {
          this.secureClear(data[key]);
          delete data[key];
        });
        data = null;
      }
    } catch (e) {
      // Игнорировать ошибки очистки
    }
  }

  /**
   * Проверяет формат ключа сессии
   */
  isValidSessionKey(sessionKey) {
    if (!sessionKey || typeof sessionKey !== 'string') {
      return false;
    }

    // Ключ сессии должен быть строкой разумной длины
    return sessionKey.length >= 32 && sessionKey.length <= 256;
  }


  /**
   * Оценивает размер после дешифровки
   * Используется для управления памятью
   */
  estimateDecryptedSize(encryptedData) {
    // Base64 кодирование увеличивает размер примерно на 33%
    // Шифрование AES может включать заполнение
    const base64Size = encryptedData.length;
    const estimatedSize = Math.floor(base64Size * 0.75);
    return estimatedSize;
  }

  /**
   * Проверяет, можно ли безопасно дешифровать
   * Убеждается, что достаточно памяти
   */
  canSafelyDecrypt(encryptedData) {
    const estimatedSize = this.estimateDecryptedSize(encryptedData);
    const memoryUsage = process.memoryUsage();
    const availableMemory = 500 * 1024 * 1024; // Предполагаемый верхний предел в 500 МБ

    return (memoryUsage.heapUsed + estimatedSize) < availableMemory;
  }
}

// Экспорт одиночного экземпляра
export const decryptor = new Decryptor();
```