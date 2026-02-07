```javascript
/**
 * Безопасное хранилище
 * Отвечает за безопасное хранение учетных данных (зашифрованное сохранение)
 * Примечание: хранит только учетные данные, не Prompt
 */

import crypto from 'crypto';
import fs from 'fs-extra';
import path from 'path';
import os from 'os';

export class SecureStorage {
  constructor() {
    // Путь к хранилищу
    this.storageDir = path.join(os.homedir(), '.novel', 'stardust');
    this.authFile = path.join(this.storageDir, 'auth.enc');
    this.configFile = path.join(this.storageDir, 'config.json');

    // Конфигурация шифрования
    this.algorithm = 'aes-256-gcm';

    // Убедиться, что каталог хранилища существует
    this.ensureStorageDir();
  }

  /**
   * Убедиться, что каталог хранилища существует
   */
  async ensureStorageDir() {
    try {
      await fs.ensureDir(this.storageDir);
      // Установить права доступа к каталогу (только чтение и запись для пользователя)
      await fs.chmod(this.storageDir, 0o700);
    } catch (error) {
      console.error('Не удалось создать каталог хранилища:', error.message);
    }
  }

  /**
   * Сохранить учетные данные
   */
  async saveAuth(authData) {
    try {
      // Зашифровать учетные данные
      const encrypted = await this.encrypt(JSON.stringify(authData));

      // Сохранить в файл
      await fs.writeFile(this.authFile, encrypted, 'utf8');

      // Установить права доступа к файлу (только чтение и запись для пользователя)
      await fs.chmod(this.authFile, 0o600);

      return true;
    } catch (error) {
      console.error('Не удалось сохранить учетные данные:', error.message);
      return false;
    }
  }

  /**
   * Получить учетные данные
   */
  async getAuth() {
    try {
      // Проверить существование файла
      if (!await fs.pathExists(this.authFile)) {
        return null;
      }

      // Прочитать зашифрованные данные
      const encrypted = await fs.readFile(this.authFile, 'utf8');

      // Расшифровать
      const decrypted = await this.decrypt(encrypted);

      // Распарсить JSON
      const authData = JSON.parse(decrypted);

      // Проверить на истечение срока действия
      if (authData.expiresAt && Date.now() > authData.expiresAt) {
        // Токен истек, но refreshToken сохранен
        return {
          ...authData,
          token: null,
          expired: true
        };
      }

      return authData;
    } catch (error) {
      console.error('Не удалось прочитать учетные данные:', error.message);
      return null;
    }
  }

  /**
   * Обновить учетные данные
   */
  async updateAuth(updates) {
    try {
      const current = await this.getAuth() || {};
      const updated = { ...current, ...updates };
      return await this.saveAuth(updated);
    } catch (error) {
      console.error('Не удалось обновить учетные данные:', error.message);
      return false;
    }
  }

  /**
   * Очистить учетные данные
   */
  async clearAuth() {
    try {
      if (await fs.pathExists(this.authFile)) {
        // Сначала перезаписать содержимое файла случайными данными
        const randomData = crypto.randomBytes(1024);
        await fs.writeFile(this.authFile, randomData);

        // Затем удалить файл
        await fs.remove(this.authFile);
      }
      return true;
    } catch (error) {
      console.error('Не удалось очистить учетные данные:', error.message);
      return false;
    }
  }

  /**
   * Сохранить конфигурацию (неконфиденциальная информация)
   */
  async saveConfig(config) {
    try {
      await fs.writeJson(this.configFile, config, { spaces: 2 });
      return true;
    } catch (error) {
      console.error('Не удалось сохранить конфигурацию:', error.message);
      return false;
    }
  }

  /**
   * Получить конфигурацию
   */
  async getConfig() {
    try {
      if (!await fs.pathExists(this.configFile)) {
        return {};
      }
      return await fs.readJson(this.configFile);
    } catch (error) {
      console.error('Не удалось прочитать конфигурацию:', error.message);
      return {};
    }
  }

  /**
   * Зашифровать данные
   */
  async encrypt(data) {
    // Получить ключ устройства
    const key = this.getDeviceKey();

    // Сгенерировать случайный IV
    const iv = crypto.randomBytes(16);

    // Создать шифратор
    const cipher = crypto.createCipheriv(this.algorithm, key, iv);

    // Зашифровать данные
    let encrypted = cipher.update(data, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    // Получить тег аутентификации
    const authTag = cipher.getAuthTag();

    // Скомбинировать результат: iv:authTag:encrypted
    return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`;
  }

  /**
   * Расшифровать данные
   */
  async decrypt(encryptedData) {
    // Получить ключ устройства
    const key = this.getDeviceKey();

    // Распарсить зашифрованные данные
    const parts = encryptedData.split(':');
    if (parts.length !== 3) {
      throw new Error('Неверный формат зашифрованных данных');
    }

    const iv = Buffer.from(parts[0], 'hex');
    const authTag = Buffer.from(parts[1], 'hex');
    const encrypted = parts[2];

    // Создать дешифратор
    const decipher = crypto.createDecipheriv(this.algorithm, key, iv);
    decipher.setAuthTag(authTag);

    // Расшифровать данные
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
  }

  /**
   * Получить ключ устройства
   * Сгенерировать уникальный ключ на основе информации об устройстве
   */
  getDeviceKey() {
    // Собрать характеристики устройства
    const deviceInfo = [
      os.hostname(),           // Имя хоста
      os.userInfo().username,   // Имя пользователя
      os.platform(),           // Операционная система
      os.arch(),              // Архитектура
      'stardust-dreams-2024'  // Фиксированная соль
    ].join(':');

    // Сгенерировать 256-битный ключ
    return crypto.createHash('sha256').update(deviceInfo).digest();
  }

  /**
   * Проверить состояние хранилища
   */
  async checkHealth() {
    const health = {
      storageDir: false,
      authFile: false,
      configFile: false,
      permissions: false
    };

    try {
      // Проверить каталог
      health.storageDir = await fs.pathExists(this.storageDir);

      // Проверить файлы
      health.authFile = await fs.pathExists(this.authFile);
      health.configFile = await fs.pathExists(this.configFile);

      // Проверить права доступа
      if (health.storageDir) {
        const stats = await fs.stat(this.storageDir);
        health.permissions = (stats.mode & 0o777) === 0o700;
      }

      return health;
    } catch (error) {
      return health;
    }
  }

  /**
   * Экспортировать учетные данные (для отладки)
   * Примечание: экспортируются зашифрованные данные
   */
  async exportAuth() {
    try {
      if (!await fs.pathExists(this.authFile)) {
        return null;
      }

      const encrypted = await fs.readFile(this.authFile, 'utf8');
      const timestamp = new Date().toISOString();

      return {
        encrypted,
        timestamp,
        device: os.hostname()
      };
    } catch (error) {
      return null;
    }
  }

  /**
   * Импортировать учетные данные
   * Примечание: расшифровка возможна только на том же устройстве
   */
  async importAuth(exportedData) {
    try {
      if (!exportedData || !exportedData.encrypted) {
        throw new Error('Неверные данные для импорта');
      }

      // Проверить возможность расшифровки (тестовая расшифровка)
      await this.decrypt(exportedData.encrypted);

      // Сохранить в файл
      await fs.writeFile(this.authFile, exportedData.encrypted, 'utf8');
      await fs.chmod(this.authFile, 0o600);

      return true;
    } catch (error) {
      console.error('Не удалось импортировать учетные данные:', error.message);
      return false;
    }
  }

  /**
   * Очистить устаревшие данные
   */
  async cleanup() {
    try {
      // Очистить устаревшие учетные данные
      const auth = await this.getAuth();
      if (auth && auth.expired) {
        await this.clearAuth();
      }

      // Очистить временные файлы
      const tempFiles = await fs.readdir(this.storageDir);
      for (const file of tempFiles) {
        if (file.endsWith('.tmp')) {
          await fs.remove(path.join(this.storageDir, file));
        }
      }

      return true;
    } catch (error) {
      return false;
    }
  }
}

// Экспортировать одиночный экземпляр
export const secureStorage = new SecureStorage();
```