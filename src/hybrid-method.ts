/**
 * Поддержка гибридных методов
 * Позволяет комбинировать несколько методов письма
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
   * Предопределенные допустимые комбинации
   */
  private validCombinations = [
    {
      name: 'Эпическая фэнтези-комбинация',
      primary: 'hero-journey',
      secondary: 'story-circle',
      description: 'Основной сюжет — Путь Героя, второстепенные сюжеты персонажей — Круг Истории',
      suitable: ['Фэнтези', 'Эпическая', 'Серийные романы']
    },
    {
      name: 'Саспенс-триллер-комбинация',
      primary: 'seven-point',
      secondary: 'three-act',
      description: 'Общая структура — Семиточечная, организация глав — Трехактная',
      suitable: ['Саспенс', 'Триллер', 'Детектив']
    },
    {
      name: 'Многолинейная повествовательная комбинация',
      primary: 'three-act',
      secondary: 'story-circle',
      micro: 'pixar-formula',
      description: 'Основной сюжет — Трехактная, второстепенные сюжеты — Круг Истории, сцены — Формула Пиксар',
      suitable: ['Ансамбль', 'Многолинейный', 'Современная литература']
    },
    {
      name: 'Комбинация истории взросления',
      primary: 'story-circle',
      secondary: 'hero-journey',
      description: 'Общая циклическая структура, ключевые главы — Путь Героя',
      suitable: ['Взросление', 'Подростковый', 'Серийный']
    }
  ];

  /**
   * Создание гибридной структуры
   */
  createHybridStructure(config: HybridConfig, storyDetails: any): HybridStructure {
    // Проверка валидности комбинации
    this.validateCombination(config);

    // Создание основной структуры сюжета
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
          throw new Error(`Не рекомендуемая комбинация: ${a} и ${b} слишком сильно различаются по сложности`);
        }
      });
    }
  }

  /**
   * Создание основной структуры сюжета
   */
  private createMainPlot(method: string, storyDetails: any): PlotStructure {
    const structures: Record<string, StructureElement[]> = {
      'three-act': [
        { name: 'Акт 1: Экспозиция', chapters: [1, 25], description: 'Представление мира и конфликта' },
        { name: 'Акт 2: Развитие', chapters: [26, 75], description: 'Эскалация и развитие конфликта' },
        { name: 'Акт 3: Развязка', chapters: [76, 100], description: 'Кульминация и финал' }
      ],
      'hero-journey': [
        { name: 'Обычный мир', chapters: [1, 8], description: 'Повседневность героя' },
        { name: 'Зов к приключениям', chapters: [9, 16], description: 'Нарушение спокойствия' },
        // ... другие этапы
      ],
      'seven-point': [
        { name: 'Крючок', chapters: [1, 3], description: 'Привлечение читателя' },
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
   * Создание структуры второстепенных сюжетов
   */
  private createSubPlots(method: string, storyDetails: any): PlotStructure[] {
    // Создание структуры для каждого второстепенного сюжета
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
6. Результат: [Состояние в конце главы]
          `
        }
      ];
    }

    return [];
  }

  /**
   * Адаптация структуры для второстепенного сюжета
   */
  private adaptStructureToSubplot(method: string, subplot: any): StructureElement[] {
    // Упрощение основной структуры для второстепенного сюжета
    if (method === 'story-circle') {
      return [
        { name: 'Зона комфорта', chapters: subplot.startChapter, description: 'Начало второстепенного сюжета' },
        { name: 'Потребность', chapters: subplot.startChapter + 2, description: 'Возникновение потребности' },
        { name: 'Поиск', chapters: subplot.middleChapters, description: 'Поиск решения' },
        { name: 'Находка', chapters: subplot.endChapter - 2, description: 'Получение ответа' },
        { name: 'Изменение', chapters: subplot.endChapter, description: 'Развязка второстепенного сюжета' }
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
        { name: 'Начальное состояние', chapters: [1, 10], description: `Начало пути ${character.name}` },
        { name: 'Возникновение потребности', chapters: [11, 20], description: 'Осознание недостатка' },
        { name: 'Попытки изменения', chapters: [21, 60], description: 'Попытки и неудачи' },
        { name: 'Достижение роста', chapters: [61, 80], description: 'Истинное изменение' },
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
        guidelines.push(`Второстепенные сюжеты используют структуру ${this.getMethodName(config.secondary.method)}`);
        guidelines.push('Второстепенные сюжеты не должны затмевать основной, сохраняйте связь с главным сюжетом');
      } else if (config.secondary.scope === 'character-arc') {
        guidelines.push(`Развитие персонажей отслеживается с помощью ${this.getMethodName(config.secondary.method)}`);
        guidelines.push('Убедитесь, что арки персонажей развиваются синхронно с основным сюжетом');
      }
    }

    if (config.micro) {
      guidelines.push(`Отдельные ${config.micro.scope} могут быть организованы с помощью ${this.getMethodName(config.micro.method)}`);
      guidelines.push('Микроструктура должна служить макроструктуре');
    }

    guidelines.push('Поддерживайте общую согласованность и связность');
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
Пример: "Эпическое приключение"
- Основной сюжет (Путь Героя): Главный герой превращается из обычного юноши в героя, спасающего мир
- Второстепенный сюжет А (Круг Истории): Цикл поиска наставником преемника
- Второстепенный сюжет Б (Круг Истории): Цикл падения злодея от добра ко злу
      `);
    }

    if (config.primary.method === 'seven-point' && config.micro?.method === 'pixar-formula') {
      examples.push(`
Пример: "Городской саспенс"
- Общая структура (Семиточечная): Саспенс развивается через 7 ключевых точек
- Структура глав (Формула Пиксар): Каждая глава продвигается через "Следствие... Следствие... В итоге..."
      `);
    }

    return examples;
  }

  /**
   * Рекомендация гибридных методов
   */
  recommendHybrid(genre: string, length: number, complexity: string): HybridConfig | null {
    // Рекомендация гибридных методов на основе характеристик
    if (genre === 'Фэнтези' && length > 200000 && complexity === 'Сложная') {
      return {
        primary: { method: 'hero-journey', scope: 'main-plot' },
        secondary: { method: 'story-circle', scope: 'character-arc' }
      };
    }

    if (genre === 'Саспенс' && complexity === 'Средняя') {
      return {
        primary: { method: 'seven-point', scope: 'main-plot' },
        micro: { method: 'three-act', scope: 'chapter' }
      };
    }

    if (genre === 'Ансамбль' || genre === 'Многолинейный') {
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
      doc += `- **Микро метод**：${this.getMethodName(structure.config.micro.method)} (${structure.config.micro.scope})\n`;
    }

    doc += `\n## Структурное отображение\n\n`;
    doc += `### Основной сюжет\n`;
    structure.mapping.mainPlot.elements.forEach(element => {
      doc += `- **${element.name}**：Главы ${element.chapters[0]}-${element.chapters[1]} - ${element.description}\n`;
    });

    if (structure.mapping.subPlots) {
      doc += `\n### Второстепенные сюжеты\n`;
      structure.mapping.subPlots.forEach((subplot, index) => {
        doc += `#### Второстепенный сюжет ${index + 1}\n`;
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