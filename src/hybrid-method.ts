```typescript
/**
 * Поддержка гибридных методов
 * Позволяет комбинировать различные методы написания
 */

interface HybridConfig {
  primary: {
    method: string;
    scope: 'main-plot';
  };
  secondary?: {
    method: string;
    scope: 'sub-plot' | 'character-arc' | 'chapter-structure';
  };
  micro?: {
    method: string;
    scope: 'scene' | 'chapter';
  };
}

interface HybridStructure {
  config: HybridConfig;
  mapping: StructureMapping;
  guidelines: string[];
  examples: string[];
}

interface StructureMapping {
  mainPlot: PlotStructure;
  subPlots?: PlotStructure[];
  characterArcs?: CharacterArcStructure[];
  chapterTemplates?: ChapterTemplate[];
}

interface PlotStructure {
  method: string;
  elements: StructureElement[];
}

interface StructureElement {
  name: string;
  chapters: number[];
  description: string;
}

interface CharacterArcStructure {
  character: string;
  method: string;
  arc: StructureElement[];
}

interface ChapterTemplate {
  chapterRange?: number[];
  method: string;
  template: string;
}

export class HybridMethodManager {
  /**
   * Предопределенные допустимые гибридные комбинации
   */
  private validCombinations = [
    {
      name: 'Эпическая фэнтези-комбинация',
      primary: 'hero-journey',
      secondary: 'story-circle',
      description: 'Основная сюжетная линия по Пути Героя, побочные сюжетные линии персонажей по Кругу Истории',
      suitable: ['Фэнтези', 'Эпос', 'Серийные романы']
    },
    {
      name: 'Саспенс-триллер комбинация',
      primary: 'seven-point',
      secondary: 'three-act',
      description: 'Общая структура по семи точкам, организация глав по трем актам',
      suitable: ['Саспенс', 'Триллер', 'Детектив']
    },
    {
      name: 'Многолинейная повествовательная комбинация',
      primary: 'three-act',
      secondary: 'story-circle',
      micro: 'pixar-formula',
      description: 'Основная линия по трем актам, побочные линии по Кругу Истории, сцены по Формуле Пиксар',
      suitable: ['Ансамбль', 'Многолинейность', 'Современная литература']
    },
    {
      name: 'Комбинация истории взросления',
      primary: 'story-circle',
      secondary: 'hero-journey',
      description: 'Общая циклическая структура, ключевые главы по Пути Героя',
      suitable: ['Взросление', 'Молодежь', 'Серия']
    }
  ];

  /**
   * Создание гибридной структуры
   */
  createHybridStructure(config: HybridConfig, storyDetails: any): HybridStructure {
    // Проверка валидности комбинации
    this.validateCombination(config);

    // Создание основной сюжетной структуры
    const mainPlot = this.createMainPlot(config.primary.method, storyDetails);

    // Создание вторичной структуры
    const mapping: StructureMapping = {
      mainPlot
    };

    if (config.secondary) {
      if (config.secondary.scope === 'sub-plot') {
        mapping.subPlots = this.createSubPlots(config.secondary.method, storyDetails);
      } else if (config.secondary.scope === 'character-arc') {
        mapping.characterArcs = this.createCharacterArcs(config.secondary.method, storyDetails);
      }
    }

    if (config.micro) {
      mapping.chapterTemplates = this.createChapterTemplates(config.micro.method, storyDetails);
    }

    // Генерация руководящих принципов
    const guidelines = this.generateGuidelines(config);

    // Генерация примеров
    const examples = this.generateExamples(config);

    return {
      config,
      mapping,
      guidelines,
      examples
    };
  }

  /**
   * Проверка валидности комбинации
   */
  private validateCombination(config: HybridConfig): void {
    const incompatible = [
      ['pixar-formula', 'hero-journey'], // Несоответствие сложности
      ['pixar-formula', 'seven-point']   // Несоответствие сложности
    ];

    if (config.primary && config.secondary) {
      const pair = [config.primary.method, config.secondary.method].sort();
      incompatible.forEach(([a, b]) => {
        if (pair[0] === a && pair[1] === b) {
          throw new Error(`Нежелательная комбинация: ${a} и ${b} имеют слишком большую разницу в сложности`);
        }
      });
    }
  }

  /**
   * Создание основной сюжетной структуры
   */
  private createMainPlot(method: string, storyDetails: any): PlotStructure {
    const structures: Record<string, StructureElement[]> = {
      'three-act': [
        { name: 'Акт I: Завязка', chapters: [1, 25], description: 'Представление мира и конфликта' },
        { name: 'Акт II: Развитие', chapters: [26, 75], description: 'Эскалация и развитие конфликта' },
        { name: 'Акт III: Развязка', chapters: [76, 100], description: 'Кульминация и финал' }
      ],
      'hero-journey': [
        { name: 'Обычный мир', chapters: [1, 8], description: 'Повседневная жизнь героя' },
        { name: 'Зов к приключениям', chapters: [9, 16], description: 'Нарушение спокойствия' },
        // ... другие этапы
      ],
      'seven-point': [
        { name: 'Крючок', chapters: [1, 3], description: 'Захват читателя' },
        { name: 'PP1', chapters: [25], description: 'Первый поворотный пункт' },
        // ... другие точки
      ]
    };

    return {
      method,
      elements: structures[method] || []
    };
  }

  /**
   * Создание структуры побочных сюжетов
   */
  private createSubPlots(method: string, storyDetails: any): PlotStructure[] {
    // Создание структуры для каждой побочной линии
    const subPlots: PlotStructure[] = [];

    if (storyDetails.subPlots) {
      storyDetails.subPlots.forEach((subplot: any) => {
        subPlots.push({
          method,
          elements: this.adaptStructureToSubplot(method, subplot)
        });
      });
    }

    return subPlots;
  }

  /**
   * Создание структуры арок персонажей
   */
  private createCharacterArcs(method: string, storyDetails: any): CharacterArcStructure[] {
    const arcs: CharacterArcStructure[] = [];

    if (storyDetails.characters) {
      storyDetails.characters.forEach((character: any) => {
        if (character.hasArc) {
          arcs.push({
            character: character.name,
            method,
            arc: this.createCharacterArcElements(method, character)
          });
        }
      });
    }

    return arcs;
  }

  /**
   * Создание шаблонов глав
   */
  private createChapterTemplates(method: string, storyDetails: any): ChapterTemplate[] {
    if (method === 'pixar-formula') {
      return [
        {
          method: 'pixar-formula',
          template: `
## Структура главы (Формула Пиксар)
1. Начальное состояние: [Ситуация в начале главы]
2. Повседневность/Ожидания: [Что делает персонаж / чего хочет]
3. Событие, меняющее ситуацию: [Что нарушает спокойствие]
4. Следствие 1: [Прямое последствие]
5. Следствие 2: [Цепная реакция]
6. Итог: [Состояние в конце главы]
          `
        }
      ];
    }

    return [];
  }

  /**
   * Адаптация структуры для побочного сюжета
   */
  private adaptStructureToSubplot(method: string, subplot: any): StructureElement[] {
    // Упрощение основной структуры для побочных сюжетов
    if (method === 'story-circle') {
      return [
        { name: 'Зона комфорта', chapters: subplot.startChapter, description: 'Начало побочного сюжета' },
        { name: 'Потребность', chapters: subplot.startChapter + 2, description: 'Возникновение потребности' },
        { name: 'Поиск', chapters: subplot.middleChapters, description: 'Поиск решения' },
        { name: 'Находка', chapters: subplot.endChapter - 2, description: 'Получение ответа' },
        { name: 'Перемены', chapters: subplot.endChapter, description: 'Разрешение побочного сюжета' }
      ];
    }

    return [];
  }

  /**
   * Создание элементов арки персонажа
   */
  private createCharacterArcElements(method: string, character: any): StructureElement[] {
    if (method === 'story-circle') {
      return [
        { name: 'Исходное состояние', chapters: [1, 10], description: `Начало пути ${character.name}` },
        { name: 'Возникновение потребности', chapters: [11, 20], description: 'Осознание недостатка' },
        { name: 'Попытки измениться', chapters: [21, 60], description: 'Попытки и неудачи' },
        { name: 'Достижение роста', chapters: [61, 80], description: 'Истинные перемены' },
        { name: 'Новое Я', chapters: [81, 100], description: 'Завершение трансформации' }
      ];
    }

    return [];
  }

  /**
   * Генерация руководящих принципов
   */
  private generateGuidelines(config: HybridConfig): string[] {
    const guidelines: string[] = [];

    guidelines.push(`Основной сюжет использует структуру ${this.getMethodName(config.primary.method)}`);

    if (config.secondary) {
      if (config.secondary.scope === 'sub-plot') {
        guidelines.push(`Побочные сюжеты используют структуру ${this.getMethodName(config.secondary.method)}`);
        guidelines.push('Побочные сюжеты не должны затмевать основной, сохраняйте связь с основной линией');
      } else if (config.secondary.scope === 'character-arc') {
        guidelines.push(`Развитие персонажей отслеживается по структуре ${this.getMethodName(config.secondary.method)}`);
        guidelines.push('Убедитесь, что арки персонажей развиваются синхронно с основным сюжетом');
      }
    }

    if (config.micro) {
      guidelines.push(`Отдельные ${config.micro.scope} могут быть организованы по ${this.getMethodName(config.micro.method)}`);
      guidelines.push('Микроструктура должна служить макроструктуре');
    }

    guidelines.push('Сохраняйте общую согласованность и связность');
    guidelines.push('Избегайте структурных конфликтов и повторений');

    return guidelines;
  }

  /**
   * Генерация примеров
   */
  private generateExamples(config: HybridConfig): string[] {
    const examples: string[] = [];

    if (config.primary.method === 'hero-journey' && config.secondary?.method === 'story-circle') {
      examples.push(`
Пример: "Фэнтезийное приключение"
- Основной сюжет (Путь Героя): Главный герой превращается из обычного юноши в героя, спасающего мир
- Побочный сюжет А (Круг Истории): Цикл поиска наставником преемника
- Побочный сюжет Б (Круг Истории): Цикл падения злодея от добра ко злу
      `);
    }

    if (config.primary.method === 'seven-point' && config.micro?.method === 'pixar-formula') {
      examples.push(`
Пример: "Городской саспенс"
- Общая структура (Семь точек): Саспенс развивается через 7 ключевых точек
- Структура глав (Формула Пиксар): Каждая глава строится по принципу "Следствие... Следствие... В итоге..."
      `);
    }

    return examples;
  }

  /**
   * Рекомендация гибридных схем
   */
  recommendHybrid(genre: string, length: number, complexity: string): HybridConfig | null {
    // Рекомендация гибридных схем на основе характеристик
    if (genre === 'Фэнтези' && length > 200000 && complexity === 'Сложный') {
      return {
        primary: { method: 'hero-journey', scope: 'main-plot' },
        secondary: { method: 'story-circle', scope: 'character-arc' }
      };
    }

    if (genre === 'Саспенс' && complexity === 'Средний') {
      return {
        primary: { method: 'seven-point', scope: 'main-plot' },
        micro: { method: 'three-act', scope: 'chapter' }
      };
    }

    if (genre === 'Ансамбль' || genre === 'Многолинейность') {
      return {
        primary: { method: 'three-act', scope: 'main-plot' },
        secondary: { method: 'story-circle', scope: 'sub-plot' }
      };
    }

    return null;
  }

  /**
   * Генерация документации по гибридному методу
   */
  generateHybridDocument(structure: HybridStructure): string {
    let doc = `# Документация по гибридному методу\n\n`;

    doc += `## Конфигурация метода\n`;
    doc += `- **Основной метод**：${this.getMethodName(structure.config.primary.method)} (${structure.config.primary.scope})\n`;

    if (structure.config.secondary) {
      doc += `- **Вторичный метод**：${this.getMethodName(structure.config.secondary.method)} (${structure.config.secondary.scope})\n`;
    }

    if (structure.config.micro) {
      doc += `- **Микро-метод**：${this.getMethodName(structure.config.micro.method)} (${structure.config.micro.scope})\n`;
    }

    doc += `\n## Карта структуры\n\n`;
    doc += `### Основной сюжет\n`;
    structure.mapping.mainPlot.elements.forEach(element => {
      doc += `- **${element.name}**：Главы ${element.chapters[0]}-${element.chapters[1]} - ${element.description}\n`;
    });

    if (structure.mapping.subPlots) {
      doc += `\n### Побочные сюжеты\n`;
      structure.mapping.subPlots.forEach((subplot, index) => {
        doc += `#### Побочный сюжет ${index + 1}\n`;
        subplot.elements.forEach(element => {
          doc += `- ${element.name}：${element.description}\n`;
        });
      });
    }

    if (structure.mapping.characterArcs) {
      doc += `\n### Арки персонажей\n`;
      structure.mapping.characterArcs.forEach(arc => {
        doc += `#### ${arc.character}\n`;
        arc.arc.forEach(element => {
          doc += `- ${element.name}：Главы ${element.chapters[0]}-${element.chapters[1]}\n`;
        });
      });
    }

    if (structure.mapping.chapterTemplates && structure.mapping.chapterTemplates.length > 0) {
      doc += `\n### Шаблоны глав\n`;
      structure.mapping.chapterTemplates.forEach(template => {
        doc += `#### Метод: ${this.getMethodName(template.method)}\n`;
        doc += `\`\`\`markdown\n${template.template.trim()}\n\`\`\`\n`;
      });
    }

    doc += `\n## Руководящие принципы\n`;
    structure.guidelines.forEach(guideline => {
      doc += `- ${guideline}\n`;
    });

    doc += `\n## Примеры\n`;
    structure.examples.forEach(example => {
      doc += `${example}\n`;
    });

    return doc;
  }

  /**
   * Получение названия метода
   */
  private getMethodName(method: string): string {
    const methodNames: Record<string, string> = {
      'three-act': 'Трехактная структура',
      'hero-journey': 'Путь Героя',
      'seven-point': 'Структура по семи точкам',
      'story-circle': 'Круг Истории',
      'pixar-formula': 'Формула Пиксар'
    };
    return methodNames[method] || method;
  }
}
```
```typescript
      });
    }

    doc += `\n## Руководство по использованию\n`;
    structure.guidelines.forEach(guideline => {
      doc += `- ${guideline}\n`;
    });

    if (structure.examples.length > 0) {
      doc += `\n## Примеры\n`;
      structure.examples.forEach(example => {
        doc += example + '\n';
      });
    }

    return doc;
  }

  /**
   * Получить китайское название метода
   */
  private getMethodName(method: string): string {
    const names: Record<string, string> = {
      'three-act': 'Структура из трёх актов',
      'hero-journey': 'Путешествие героя',
      'story-circle': 'Круг историй',
      'seven-point': 'Структура из семи пунктов',
      'pixar-formula': 'Формула Пиксар'
    };
    return names[method] || method;
  }
}
```