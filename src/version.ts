/**
 * Единый модуль управления версиями
 * Читает номер версии из package.json, обеспечивая единообразие версий всего проекта
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Получить номер текущей версии проекта
 * @returns Строка с номером версии
 */
export function getVersion(): string {
  try {
    // Попытка прочитать package.json из нескольких возможных путей
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

    // Если package.json не найден, вернуть версию по умолчанию
    return '0.4.2';
  } catch (error) {
    // При возникновении ошибки вернуть версию по умолчанию
    return '0.4.2';
  }
}

/**
 * Получить строку с информацией о версии
 * @returns Отформатированная информация о версии
 */
export function getVersionInfo(): string {
  return `Версия: ${getVersion()} | На базе архитектуры Spec Kit | Улучшенная система отслеживания`;
}

/**
 * Получить краткую информацию о версии
 * @returns Краткая информация о версии
 */
export function getShortVersionInfo(): string {
  return `v${getVersion()}`;
}

// Экспорт константы версии (для обратной совместимости)
export const VERSION = getVersion();