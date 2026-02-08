/**
 * Дешифратор
 * Отвечает за расшифровку зашифрованных Prompt, полученных от сервера, в памяти.
 * Принцип безопасности: результат расшифровки находится только в памяти, никогда не сохраняется.
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
   * Расшифровывает зашифрованный Prompt.
   * @param {Object} encryptedData - Объект, содержащий зашифрованные данные.
   * @param {string} encryptedData.encrypted - Зашифрованные данные в hex-кодировке.
   * @param {string} encryptedData.iv - IV в hex-кодировке.
   * @param {string} encryptedData.authTag - Тег аутентификации в hex-кодировке.
   * @param {string} sessionKey - Ключ сессии в формате hex.
   * @returns {string} Расшифрованный Prompt (только в памяти).
   */
  async decrypt(encryptedData, sessionKey) {
    let decrypted = null;

    try {
      // Проверка входных данных
      if (!encryptedData || !encryptedData.encrypted || !encryptedData.iv || !encryptedData.authTag) {
        throw new Error('Неполные зашифрованные данные');
      }

      // Преобразование из hex в Buffer
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

      // Выполнение расшифровки
      let decrypted = decipher.update(encrypted, null, 'utf8');
      decrypted += decipher.final('utf8');

      // Проверка результата расшифровки
      if (!this.isValidPrompt(decrypted)) {
        throw new Error('Недопустимый результат расшифровки');
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
        throw new Error('Ошибка расшифровки: неверный ключ или поврежденные данные');
      } else if (error.message.includes('auth tag')) {
        throw new Error('Ошибка расшифровки: ошибка проверки целостности данных');
      } else {
        throw new Error(`Ошибка расшифровки: ${error.message}`);
      }
    }
  }


  /**
   * Проверяет, является ли расшифрованный Prompt действительным.
   * Базовая проверка, чтобы убедиться, что это не случайный набор символов.
   */
  isValidPrompt(prompt) {
    if (!prompt || typeof prompt !== 'string') {
      return false;
    }

    // Проверка на наличие основных признаков Prompt
    // Эти признаки должны быть общими для всех Prompt
    const hasValidStructure =
      prompt.length > 10 && // Минимум определенной длины
      prompt.includes('{{') && // Содержит заполнители параметров
      /[\u4e00-\u9fa5]/.test(prompt); // Содержит китайские символы

    return hasValidStructure;
  }

  /**
   * Безопасная очистка конфиденциальных данных.
   * Освобождает ссылки на память как можно быстрее.
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
        // Для объектов выполняем рекурсивную очистку
        Object.keys(data).forEach(key => {
          this.secureClear(data[key]);
          delete data[key];
        });
        data = null;
      }
    } catch (e) {
      // Игнорируем ошибки очистки
    }
  }

  /**
   * Проверяет формат ключа сессии.
   */
  isValidSessionKey(sessionKey) {
    if (!sessionKey || typeof sessionKey !== 'string') {
      return false;
    }

    // Ключ сессии должен быть строкой разумной длины
    return sessionKey.length >= 32 && sessionKey.length <= 256;
  }


  /**
   * Оценивает размер данных после расшифровки.
   * Используется для управления памятью.
   */
  estimateDecryptedSize(encryptedData) {
    // Base64 кодирование увеличивает размер примерно на 33%
    // Шифрование AES может включать заполнение
    const base64Size = encryptedData.length;
    const estimatedSize = Math.floor(base64Size * 0.75);
    return estimatedSize;
  }

  /**
   * Проверяет, можно ли безопасно выполнить расшифровку.
   * Убеждается, что достаточно памяти.
   */
  canSafelyDecrypt(encryptedData) {
    const estimatedSize = this.estimateDecryptedSize(encryptedData);
    const memoryUsage = process.memoryUsage();
    const availableMemory = 500 * 1024 * 1024; // Предполагаем лимит в 500 МБ

    return (memoryUsage.heapUsed + estimatedSize) < availableMemory;
  }
}

// Экспорт синглтона
export const decryptor = new Decryptor();