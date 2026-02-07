```typescript
/**
 * Единый модуль управления версиями
 * Читает номер версии из package.json, обеспечивая единообразие версий во всем проекте
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Получает текущий номер версии проекта
 * @returns Строка с номером версии
 */
export function getVersion(): string {
  try {
    // Попытка чтения package.json из нескольких возможных путей
    const possiblePaths = [
      path.join(__dirname, '../package.json'),      // Относительный путь от каталога src
      path.join(__dirname, '../../package.json'),   // Относительный путь от каталога dist
      path.join(process.cwd(), 'package.json'),     // Текущий рабочий каталог
    ];

    for (const pkgPath of possiblePaths) {
      if (fs.existsSync(pkgPath)) {
        const packageJson = JSON.parse(fs.readFileSync(pkgPath, 'utf-8'));
        return packageJson.version || '0.0.0';
      }
    }

    // Если package.json не найден, возвращает версию по умолчанию
    return '0.4.2';
  } catch (error) {
    // В случае ошибки возвращает версию по умолчанию
    return '0.4.2';
  }
}

/**
 * Получает строку с информацией о версии
 * @returns Форматированная информация о версии
 */
export function getVersionInfo(): string {
  return `Версия: ${getVersion()} | Архитектура на базе Spec Kit | Улучшенная система отслеживания`;
}

/**
 * Получает краткую информацию о версии
 * @returns Краткая информация о версии
 */
export function getShortVersionInfo(): string {
  return `v${getVersion()}`;
}

// Экспорт константы версии (для обратной совместимости)
export const VERSION = getVersion();
```