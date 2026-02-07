/**
 * Шаблонный движок
 * Отвечает за заполнение пользовательскими параметрами шаблонов Prompt
 * Поддерживает замену переменных, условный рендеринг и циклы и т. д.
 */

export class TemplateEngine {
  constructor() {
    // Поддерживаемый синтаксис шаблонов
    this.syntax = {
      variable: /\{\{([^}]+)\}\}/g,           // {{переменная}}
      condition: /\{\{#if\s+([^}]+)\}\}([\s\S]*?)\{\{\/if\}\}/g,  // {{#if условие}}...{{/if}}
      unless: /\{\{#unless\s+([^}]+)\}\}([\s\S]*?)\{\{\/unless\}\}/g,  // {{#unless условие}}...{{/unless}}
      each: /\{\{#each\s+([^}]+)\}\}([\s\S]*?)\{\{\/each\}\}/g,   // {{#each элементы}}...{{/each}}
      with: /\{\{#with\s+([^}]+)\}\}([\s\S]*?)\{\{\/with\}\}/g,   // {{#with объект}}...{{/with}}
    };
  }

  /**
   * Заполнение шаблона
   * @param {string} template - Шаблон Prompt
   * @param {object} parameters - Пользовательские параметры
   * @returns {string} Заполненный Prompt
   */
  fill(template, parameters) {
    if (!template || typeof template !== 'string') {
      throw new Error('Недействительный шаблон');
    }

    if (!parameters || typeof parameters !== 'object') {
      throw new Error('Недействительные параметры');
    }

    let result = template;

    try {
      // 1. Обработка условных блоков
      result = this.processConditions(result, parameters);

      // 2. Обработка циклических блоков
      result = this.processLoops(result, parameters);

      // 3. Обработка блоков with
      result = this.processWithBlocks(result, parameters);

      // 4. Обработка замены переменных (помещается в конце)
      result = this.processVariables(result, parameters);

      // 5. Очистка неиспользуемых заполнителей
      result = this.cleanupTemplate(result);

      return result;
    } catch (error) {
      throw new Error(`Ошибка заполнения шаблона: ${error.message}`);
    }
  }

  /**
   * Обработка замены переменных
   */
  processVariables(template, parameters) {
    return template.replace(this.syntax.variable, (match, path) => {
      const trimmedPath = path.trim();

      // Поддержка доступа к вложенным свойствам (например, user.name)
      const value = this.getValueByPath(parameters, trimmedPath);

      // Обработка значений разных типов
      if (value === undefined || value === null) {
        return ''; // Неопределенная переменная заменяется пустой строкой
      }

      if (typeof value === 'object') {
        // Объекты преобразуются в JSON-строку
        return JSON.stringify(value, null, 2);
      }

      // Другие типы преобразуются в строку
      return String(value);
    });
  }

  /**
   * Обработка условного рендеринга
   */
  processConditions(template, parameters) {
    // Обработка {{#if условие}}
    template = template.replace(this.syntax.condition, (match, condition, content) => {
      const trimmedCondition = condition.trim();
      const conditionValue = this.evaluateCondition(trimmedCondition, parameters);

      return conditionValue ? content : '';
    });

    // Обработка {{#unless условие}}
    template = template.replace(this.syntax.unless, (match, condition, content) => {
      const trimmedCondition = condition.trim();
      const conditionValue = this.evaluateCondition(trimmedCondition, parameters);

      return !conditionValue ? content : '';
    });

    return template;
  }

  /**
   * Обработка циклов
   */
  processLoops(template, parameters) {
    return template.replace(this.syntax.each, (match, arrayPath, content) => {
      const trimmedPath = arrayPath.trim();
      const array = this.getValueByPath(parameters, trimmedPath);

      if (!Array.isArray(array)) {
        return ''; // Возвращается пустая строка, если это не массив
      }

      // Рендеринг контента для каждого элемента
      return array.map((item, index) => {
        // Создание контекста цикла
        const loopContext = {
          ...parameters,
          '@item': item,
          '@index': index,
          '@first': index === 0,
          '@last': index === array.length - 1
        };

        // Замена переменных внутри контента цикла
        return content.replace(this.syntax.variable, (m, path) => {
          const p = path.trim();

          // Специальные переменные
          if (p.startsWith('@')) {
            return loopContext[p] !== undefined ? String(loopContext[p]) : '';
          }

          // Поддержка ключевого слова this
          if (p === 'this' || p === '.') {
            return String(item);
          }

          // Обычный доступ к свойствам
          return this.getValueByPath(loopContext, p);
        });
      }).join('');
    });
  }

  /**
   * Обработка блока with
   */
  processWithBlocks(template, parameters) {
    return template.replace(this.syntax.with, (match, objectPath, content) => {
      const trimmedPath = objectPath.trim();
      const object = this.getValueByPath(parameters, trimmedPath);

      if (!object || typeof object !== 'object') {
        return ''; // Возвращается пустая строка, если это не объект
      }

      // Создание нового контекста
      const withContext = {
        ...parameters,
        ...object
      };

      // Заполнение переменных внутри блока with
      return this.processVariables(content, withContext);
    });
  }

  /**
   * Оценка условного выражения
   */
  evaluateCondition(condition, parameters) {
    // Поддерживаемые операторы
    const operators = {
      '==': (a, b) => a == b,
      '===': (a, b) => a === b,
      '!=': (a, b) => a != b,
      '!==': (a, b) => a !== b,
      '>': (a, b) => a > b,
      '>=': (a, b) => a >= b,
      '<': (a, b) => a < b,
      '<=': (a, b) => a <= b,
      '&&': (a, b) => a && b,
      '||': (a, b) => a || b
    };

    // Простое условие (только имя переменной)
    if (!condition.match(/[=!<>&|]/)) {
      const value = this.getValueByPath(parameters, condition);
      return this.isTruthy(value);
    }

    // Сложное условие (включает операторы)
    // Здесь упрощенная обработка, в реальности может потребоваться более сложный парсинг выражений
    for (const [op, fn] of Object.entries(operators)) {
      if (condition.includes(op)) {
        const parts = condition.split(op).map(p => p.trim());
        if (parts.length === 2) {
          const left = this.getValueByPath(parameters, parts[0]) || parts[0];
          const right = this.getValueByPath(parameters, parts[1]) || parts[1];
          return fn(left, right);
        }
      }
    }

    // По умолчанию возвращается false
    return false;
  }

  /**
   * Проверка истинности значения
   */
  isTruthy(value) {
    if (value === undefined || value === null) {
      return false;
    }

    if (typeof value === 'boolean') {
      return value;
    }

    if (typeof value === 'number') {
      return value !== 0;
    }

    if (typeof value === 'string') {
      return value.length > 0;
    }

    if (Array.isArray(value)) {
      return value.length > 0;
    }

    if (typeof value === 'object') {
      return Object.keys(value).length > 0;
    }

    return !!value;
  }

  /**
   * Получение значения по пути
   * Поддерживает доступ к вложенным свойствам, например 'user.profile.name'
   */
  getValueByPath(object, path) {
    if (!object || !path) {
      return undefined;
    }

    // Обработка литералов
    if (path.startsWith('"') && path.endsWith('"')) {
      return path.slice(1, -1);
    }

    if (path.startsWith("'") && path.endsWith("'")) {
      return path.slice(1, -1);
    }

    // Числовые литералы
    if (/^\d+$/.test(path)) {
      return parseInt(path, 10);
    }

    // Булевы литералы
    if (path === 'true') return true;
    if (path === 'false') return false;

    // Путь к свойству
    const parts = path.split('.');
    let current = object;

    for (const part of parts) {
      if (current === undefined || current === null) {
        return undefined;
      }

      // Поддержка индексов массива
      const arrayMatch = part.match(/^(\w+)\[(\d+)\]$/);
      if (arrayMatch) {
        current = current[arrayMatch[1]];
        if (Array.isArray(current)) {
          current = current[parseInt(arrayMatch[2], 10)];
        } else {
          return undefined;
        }
      } else {
        current = current[part];
      }
    }

    return current;
  }

  /**
   * Очистка неиспользуемых тегов шаблона
   */
  cleanupTemplate(template) {
    // Удаление несовпавших заполнителей переменных
    template = template.replace(/\{\{[^}]*\}\}/g, '');

    // Удаление лишних пустых строк
    template = template.replace(/\n\s*\n\s*\n/g, '\n\n');

    // Удаление конечных пробелов
    template = template.trimEnd();

    return template;
  }

  /**
   * Проверка синтаксиса шаблона
   * Проверка шаблона на наличие синтаксических ошибок перед заполнением
   */
  validateTemplate(template) {
    const errors = [];

    // Проверка незакрытых тегов
    const openTags = template.match(/\{\{#(if|unless|each|with)[^}]*\}\}/g) || [];
    const closeTags = template.match(/\{\{\/(if|unless|each|with)\}\}/g) || [];

    if (openTags.length !== closeTags.length) {
      errors.push('Шаблон содержит незакрытые теги');
    }

    // Проверка формата переменных
    const variables = template.match(this.syntax.variable) || [];
    for (const variable of variables) {
      if (variable.includes('{{{{')) {
        errors.push(`Недействительный формат переменной: ${variable}`);
      }
    }

    return errors.length === 0 ? null : errors;
  }

  /**
   * Предварительная обработка параметров
   * Добавление некоторых полезных встроенных переменных
   */
  preprocessParameters(parameters) {
    return {
      ...parameters,
      '@date': new Date().toISOString().split('T')[0],
      '@time': new Date().toTimeString().split(' ')[0],
      '@timestamp': Date.now(),
      '@random': Math.random().toString(36).substr(2, 9)
    };
  }
}

// Экспорт одиночного экземпляра
export const templateEngine = new TemplateEngine();