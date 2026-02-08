# Система конфигурации глав — Техническая спецификация

## Информация о документе

- **Название документа**: Техническая спецификация системы конфигурации глав
- **Версия**: v1.0.0
- **Дата создания**: 2025-10-14
- **Связанный PRD**: [Система конфигурации глав PRD](./chapter-config-system.md)
- **Целевая аудитория**: Разработчики, технические руководители

---

## I. Полное определение схемы YAML

### 1.1 Представление JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ChapterConfig",
  "description": "Схема конфигурационного файла главы",
  "type": "object",
  "required": ["chapter", "title", "plot", "wordcount"],
  "properties": {
    "chapter": {
      "type": "integer",
      "minimum": 1,
      "description": "Номер главы"
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100,
      "description": "Заголовок главы"
    },
    "characters": {
      "type": "array",
      "description": "Список персонажей, появляющихся в главе",
      "items": {
        "$ref": "#/definitions/Character"
      }
    },
    "scene": {
      "$ref": "#/definitions/Scene",
      "description": "Конфигурация сцены"
    },
    "plot": {
      "$ref": "#/definitions/Plot",
      "description": "Конфигурация сюжета"
    },
    "style": {
      "$ref": "#/definitions/Style",
      "description": "Конфигурация стиля письма"
    },
    "wordcount": {
      "$ref": "#/definitions/Wordcount",
      "description": "Требования к количеству слов"
    },
    "special_requirements": {
      "type": "string",
      "description": "Особые требования к письму"
    },
    "preset_used": {
      "type": "string",
      "description": "Используемый ID пресета"
    },
    "created_at": {
      "type": "string",
      "format": "date-time",
      "description": "Время создания"
    },
    "updated_at": {
      "type": "string",
      "format": "date-time",
      "description": "Время обновления"
    }
  },
  "definitions": {
    "Character": {
      "type": "object",
      "required": ["id", "name"],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^[a-z0-9-]+$",
          "description": "ID персонажа, ссылка на character-profiles.md"
        },
        "name": {
          "type": "string",
          "description": "Имя персонажа"
        },
        "focus": {
          "type": "string",
          "enum": ["high", "medium", "low"],
          "default": "medium",
          "description": "Степень важности в данной главе"
        },
        "state_changes": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "description": "Изменения состояния в данной главе"
        }
      }
    },
    "Scene": {
      "type": "object",
      "properties": {
        "location_id": {
          "type": "string",
          "pattern": "^[a-z0-9-]+$",
          "description": "ID места, ссылка на locations.md"
        },
        "location_name": {
          "type": "string",
          "description": "Название места"
        },
        "time": {
          "type": "string",
          "description": "Время (например, '10 утра', 'вечер')"
        },
        "weather": {
          "type": "string",
          "description": "Погода"
        },
        "atmosphere": {
          "type": "string",
          "enum": ["tense", "relaxed", "sad", "exciting", "mysterious"],
          "description": "Атмосфера"
        }
      }
    },
    "Plot": {
      "type": "object",
      "required": ["type", "summary"],
      "properties": {
        "type": {
          "type": "string",
          "enum": [
            "ability_showcase",
            "relationship_dev",
            "conflict_combat",
            "mystery_suspense",
            "transition",
            "climax",
            "emotional_scene",
            "world_building",
            "plot_twist"
          ],
          "description": "Тип сюжета"
        },
        "summary": {
          "type": "string",
          "minLength": 10,
          "maxLength": 500,
          "description": "Краткое изложение сюжета"
        },
        "key_points": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "minItems": 1,
          "description": "Ключевые моменты"
        },
        "plotlines": {
          "type": "array",
          "items": {
            "type": "string",
            "pattern": "^PL-[0-9]+$"
          },
          "description": "ID задействованных сюжетных линий"
        },
        "foreshadowing": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id": {
                "type": "string",
                "pattern": "^F-[0-9]+$"
              },
              "content": {
                "type": "string"
              }
            }
          },
          "description": "Предзнаменования в данной главе"
        }
      }
    },
    "Style": {
      "type": "object",
      "properties": {
        "pace": {
          "type": "string",
          "enum": ["fast", "medium", "slow"],
          "default": "medium",
          "description": "Темп"
        },
        "sentence_length": {
          "type": "string",
          "enum": ["short", "medium", "long"],
          "default": "medium",
          "description": "Длина предложения"
        },
        "focus": {
          "type": "string",
          "enum": [
            "action",
            "dialogue",
            "psychology",
            "description",
            "dialogue_action",
            "balanced"
          ],
          "default": "balanced",
          "description": "Фокус описания"
        },
        "tone": {
          "type": "string",
          "enum": ["serious", "humorous", "dark", "light"],
          "description": "Тон"
        }
      }
    },
    "Wordcount": {
      "type": "object",
      "required": ["target"],
      "properties": {
        "target": {
          "type": "integer",
          "minimum": 1000,
          "maximum": 10000,
          "description": "Целевое количество слов"
        },
        "min": {
          "type": "integer",
          "minimum": 500,
          "description": "Минимальное количество слов"
        },
        "max": {
          "type": "integer",
          "maximum": 15000,
          "description": "Максимальное количество слов"
        }
      }
    }
  }
}
```

### 1.2 Определение типов TypeScript

```typescript
/**
 * Интерфейс конфигурации главы
 */
export interface ChapterConfig {
  /** Номер главы */
  chapter: number;

  /** Заголовок главы */
  title: string;

  /** Появляющиеся персонажи */
  characters?: Character[];

  /** Конфигурация сцены */
  scene?: Scene;

  /** Конфигурация сюжета */
  plot: Plot;

  /** Стиль письма */
  style?: Style;

  /** Требования к количеству слов */
  wordcount: Wordcount;

  /** Особые требования */
  special_requirements?: string;

  /** Использованный пресет */
  preset_used?: string;

  /** Время создания */
  created_at?: string;

  /** Время обновления */
  updated_at?: string;
}

/**
 * Конфигурация персонажа
 */
export interface Character {
  /** ID персонажа (ссылка на character-profiles.md) */
  id: string;

  /** Имя персонажа */
  name: string;

  /** Степень важности в данной главе */
  focus?: 'high' | 'medium' | 'low';

  /** Изменения состояния в данной главе */
  state_changes?: string[];
}

/**
 * Конфигурация сцены
 */
export interface Scene {
  /** ID места (ссылка на locations.md) */
  location_id?: string;

  /** Название места */
  location_name?: string;

  /** Время */
  time?: string;

  /** Погода */
  weather?: string;

  /** Атмосфера */
  atmosphere?: 'tense' | 'relaxed' | 'sad' | 'exciting' | 'mysterious';
}

/**
 * Конфигурация сюжета
 */
export interface Plot {
  /** Тип сюжета */
  type: PlotType;

  /** Краткое изложение сюжета */
  summary: string;

  /** Ключевые моменты */
  key_points?: string[];

  /** Сюжетные линии */
  plotlines?: string[];

  /** Предзнаменования */
  foreshadowing?: Foreshadowing[];
}

/**
 * Перечисление типов сюжета
 */
export type PlotType =
  | 'ability_showcase'      // Демонстрация способностей
  | 'relationship_dev'      // Развитие отношений
  | 'conflict_combat'       // Конфликт, противостояние
  | 'mystery_suspense'      // Загадка, напряжение
  | 'transition'            // Переход, связка
  | 'climax'                // Кульминация, противостояние
  | 'emotional_scene'       // Эмоциональная сцена
  | 'world_building'        // Развитие мира
  | 'plot_twist';           // Сюжетный поворот

/**
 * Конфигурация предзнаменований
 */
export interface Foreshadowing {
  /** ID предзнаменования */
  id: string;

  /** Содержание предзнаменования */
  content: string;
}

/**
 * Конфигурация стиля письма
 */
export interface Style {
  /** Темп */
  pace?: 'fast' | 'medium' | 'slow';

  /** Длина предложения */
  sentence_length?: 'short' | 'medium' | 'long';

  /** Фокус описания */
  focus?: 'action' | 'dialogue' | 'psychology' | 'description' | 'dialogue_action' | 'balanced';

  /** Тон */
  tone?: 'serious' | 'humorous' | 'dark' | 'light';
}

/**
 * Конфигурация количества слов
 */
export interface Wordcount {
  /** Целевое количество слов */
  target: number;

  /** Минимальное количество слов */
  min?: number;

  /** Максимальное количество слов */
  max?: number;
}

/**
 * Интерфейс конфигурации пресета
 */
export interface Preset {
  /** ID пресета */
  id: string;

  /** Название пресета */
  name: string;

  /** Описание */
  description: string;

  /** Категория */
  category: 'scene' | 'style' | 'chapter';

  /** Автор */
  author: string;

  /** Версия */
  version: string;

  /** Конфигурация по умолчанию */
  defaults: Partial<ChapterConfig>;

  /** Рекомендуемые настройки */
  recommended?: {
    plot_types?: PlotType[];
    atmosphere?: Scene['atmosphere'][];
  };

  /** Совместимые жанры */
  compatible_genres?: string[];

  /** Советы по использованию */
  usage_tips?: string[];
}
```

---

## II. Проектирование основных классов

### 2.1 ChapterConfigManager

```typescript
/**
 * Менеджер конфигурации глав
 * Отвечает за создание, чтение, проверку, обновление и удаление конфигураций
 */
export class ChapterConfigManager {
  private projectPath: string;
  private presetManager: PresetManager;
  private validator: ConfigValidator;

  constructor(projectPath: string) {
    this.projectPath = projectPath;
    this.presetManager = new PresetManager();
    this.validator = new ConfigValidator(projectPath);
  }

  /**
   * Создание конфигурации главы
   */
  async createConfig(
    chapter: number,
    options: CreateConfigOptions
  ): Promise<ChapterConfig> {
    // 1. Инициализация конфигурации
    let config: ChapterConfig = {
      chapter,
      title: options.title || `Глава ${chapter}`,
      characters: [],
      scene: {},
      plot: {
        type: options.plotType || 'transition',
        summary: options.plotSummary || '',
        key_points: options.keyPoints || []
      },
      style: {
        pace: 'medium',
        sentence_length: 'medium',
        focus: 'balanced'
      },
      wordcount: {
        target: options.wordcount || 3000,
        min: Math.floor((options.wordcount || 3000) * 0.8),
        max: Math.floor((options.wordcount || 3000) * 1.2)
      },
      created_at: new Date().toISOString()
    };

    // 2. Применение пресета (если указан)
    if (options.preset) {
      const preset = await this.presetManager.loadPreset(options.preset);
      config = this.applyPreset(preset, config);
    }

    // 3. Объединение пользовательского ввода
    if (options.characters) {
      config.characters = await this.loadCharacterDetails(options.characters);
    }

    if (options.scene) {
      config.scene = await this.loadSceneDetails(options.scene);
    }

    // 4. Проверка конфигурации
    const validation = await this.validator.validate(config);
    if (!validation.valid) {
      throw new Error(`Ошибка проверки конфигурации: ${validation.errors.join(', ')}`);
    }

    // 5. Сохранение в файл
    const configPath = this.getConfigPath(chapter);
    await fs.ensureDir(path.dirname(configPath));
    await fs.writeFile(configPath, yaml.dump(config, { indent: 2 }), 'utf-8');

    return config;
  }

  /**
   * Загрузка конфигурации главы
   */
  async loadConfig(chapter: number): Promise<ChapterConfig | null> {
    const configPath = this.getConfigPath(chapter);

    if (!await fs.pathExists(configPath)) {
      return null;
    }

    const content = await fs.readFile(configPath, 'utf-8');
    const config = yaml.load(content) as ChapterConfig;

    // Проверка конфигурации
    const validation = await this.validator.validate(config);
    if (!validation.valid) {
      console.warn(`Проблема с конфигурационным файлом: ${validation.errors.join(', ')}`);
    }

    return config;
  }

  /**
   * Обновление конфигурации главы
   */
  async updateConfig(
    chapter: number,
    updates: Partial<ChapterConfig>
  ): Promise<ChapterConfig> {
    const config = await this.loadConfig(chapter);
    if (!config) {
      throw new Error(`Конфигурационный файл не существует: глава ${chapter}`);
    }

    const updatedConfig = {
      ...config,
      ...updates,
      updated_at: new Date().toISOString()
    };

    // Валидация обновленной конфигурации
    const validation = await this.validator.validate(updatedConfig);
    if (!validation.valid) {
      throw new Error(`Обновленная конфигурация недействительна: ${validation.errors.join(', ')}`);
    }

    // Сохранение
    const configPath = this.getConfigPath(chapter);
    await fs.writeFile(
      configPath,
      yaml.dump(updatedConfig, { indent: 2 }),
      'utf-8'
    );

    return updatedConfig;
  }

  /**
   * Удаление конфигурации главы
   */
  async deleteConfig(chapter: number): Promise<void> {
    const configPath = this.getConfigPath(chapter);

    if (!await fs.pathExists(configPath)) {
      throw new Error(`Конфигурационный файл не существует: глава ${chapter}`);
    }

    await fs.remove(configPath);
  }

  /**
   * Список всех конфигураций
   */
  async listConfigs(): Promise<ChapterConfigSummary[]> {
    const chaptersDir = path.join(
      this.projectPath,
      'stories',
      '*',
      'chapters'
    );

    const configFiles = await glob(path.join(chaptersDir, '*.yaml'));

    const summaries: ChapterConfigSummary[] = [];

    for (const file of configFiles) {
      const content = await fs.readFile(file, 'utf-8');
      const config = yaml.load(content) as ChapterConfig;

      summaries.push({
        chapter: config.chapter,
        title: config.title,
        plotType: config.plot.type,
        location: config.scene?.location_name || '-',
        wordcount: config.wordcount.target,
        preset: config.preset_used,
        createdAt: config.created_at
      });
    }

    return summaries.sort((a, b) => a.chapter - b.chapter);
  }

  /**
   * Копирование конфигурации
   */
  async copyConfig(
    fromChapter: number,
    toChapter: number,
    modifications?: Partial<ChapterConfig>
  ): Promise<ChapterConfig> {
    const sourceConfig = await this.loadConfig(fromChapter);
    if (!sourceConfig) {
      throw new Error(`Исходная конфигурация не существует: глава ${fromChapter}`);
    }

    const newConfig: ChapterConfig = {
      ...sourceConfig,
      chapter: toChapter,
      ...modifications,
      created_at: new Date().toISOString(),
      updated_at: undefined
    };

    return this.createConfig(toChapter, {
      title: newConfig.title,
      plotType: newConfig.plot.type,
      plotSummary: newConfig.plot.summary,
      keyPoints: newConfig.plot.key_points,
      wordcount: newConfig.wordcount.target,
      // ...
    } as CreateConfigOptions);
  }

  // ========== Вспомогательные приватные методы ==========

  private getConfigPath(chapter: number): string {
    // Поиск директории stories в проекте
    const storiesDir = path.join(this.projectPath, 'stories');
    const storyDirs = fs.readdirSync(storiesDir);

    if (storyDirs.length === 0) {
      throw new Error('Директория stories не найдена');
    }

    // Использование первой директории stories (обычно она одна)
    const storyDir = storyDirs[0];
    return path.join(
      storiesDir,
      storyDir,
      'chapters',
      `chapter-${chapter}-config.yaml`
    );
  }

  private applyPreset(
    preset: Preset,
    config: ChapterConfig
  ): ChapterConfig {
    return {
      ...config,
      ...preset.defaults,
      preset_used: preset.id,
      // Слияние special_requirements
      special_requirements: [
        preset.defaults.special_requirements,
        config.special_requirements
      ].filter(Boolean).join('\n\n')
    };
  }

  private async loadCharacterDetails(
    characterIds: string[]
  ): Promise<Character[]> {
    // Загрузка деталей из character-profiles.md
    // Реализация опущена...
    return [];
  }

  private async loadSceneDetails(
    sceneId: string
  ): Promise<Scene> {
    // Загрузка деталей из locations.md
    // Реализация опущена...
    return {};
  }
}

/**
 * Интерфейс сводки конфигурации главы
 */
export interface ChapterConfigSummary {
  chapter: number;
  title: string;
  plotType: PlotType;
  location: string;
  wordcount: number;
  preset?: string;
  createdAt?: string;
}

/**
 * Опции создания конфигурации
 */
export interface CreateConfigOptions {
  title?: string;
  characters?: string[];
  scene?: string;
  plotType?: PlotType;
  plotSummary?: string;
  keyPoints?: string[];
  preset?: string;
  wordcount?: number;
  style?: Partial<Style>;
  specialRequirements?: string;
}
```

### 2.2 PresetManager

```typescript
/**
 * Менеджер пресетов
 * Отвечает за загрузку, создание, импорт, экспорт пресетов
 */
export class PresetManager {
  private presetDirs: string[];

  constructor() {
    this.presetDirs = [
      path.join(process.cwd(), 'stories', '*', 'presets'),  // Локальные пресеты проекта
      path.join(os.homedir(), '.novel', 'presets', 'user'), // Пользовательские пресеты
      path.join(os.homedir(), '.novel', 'presets', 'community'), // Пресеты сообщества
      path.join(os.homedir(), '.novel', 'presets', 'official'), // Официальные пресеты
      path.join(__dirname, '..', '..', 'presets')  // Встроенные пресеты
    ];
  }

  /**
   * Загрузка пресета
   */
  async loadPreset(presetId: string): Promise<Preset> {
    for (const dir of this.presetDirs) {
      const presetPath = await this.findPresetInDir(dir, presetId);
      if (presetPath) {
        const content = await fs.readFile(presetPath, 'utf-8');
        return yaml.load(content) as Preset;
      }
    }

    throw new Error(`Пресет не найден: ${presetId}`);
  }

  /**
   * Список всех пресетов
   */
  async listPresets(category?: string): Promise<PresetInfo[]> {
    const presets: PresetInfo[] = [];
    const seen = new Set<string>();

    for (const dir of this.presetDirs) {
      if (!await fs.pathExists(dir)) continue;

      const files = await glob(path.join(dir, '**', '*.yaml'));

      for (const file of files) {
        const content = await fs.readFile(file, 'utf-8');
        const preset = yaml.load(content) as Preset;

        // Пропуск дубликатов ID (приоритет у более высоких)
        if (seen.has(preset.id)) continue;

        // Фильтр по категории
        if (category && preset.category !== category) continue;

        seen.add(preset.id);
        presets.push({
          id: preset.id,
          name: preset.name,
          description: preset.description,
          category: preset.category,
          author: preset.author,
          source: this.getPresetSource(file)
        });
      }
    }

    return presets;
  }

  /**
   * Создание пресета
   */
  async createPreset(preset: Preset, target: 'user' | 'project'): Promise<void> {
    const targetDir = target === 'user'
      ? path.join(os.homedir(), '.novel', 'presets', 'user')
      : path.join(process.cwd(), 'stories', '*', 'presets');

    await fs.ensureDir(targetDir);

    const presetPath = path.join(targetDir, `${preset.id}.yaml`);
    await fs.writeFile(presetPath, yaml.dump(preset, { indent: 2 }), 'utf-8');
  }

  /**
   * Импорт пресета
   */
  async importPreset(file: string, target: 'user' | 'community'): Promise<void> {
    const content = await fs.readFile(file, 'utf-8');
    const preset = yaml.load(content) as Preset;

    const targetDir = path.join(
      os.homedir(),
      '.novel',
      'presets',
      target
    );

    await fs.ensureDir(targetDir);
    await fs.copy(file, path.join(targetDir, path.basename(file)));
  }

  /**
   * Экспорт пресета
   */
  async exportPreset(presetId: string, outputPath: string): Promise<void> {
    const preset = await this.loadPreset(presetId);
    await fs.writeFile(outputPath, yaml.dump(preset, { indent: 2 }), 'utf-8');
  }

  // ========== Приватные методы ==========

  private async findPresetInDir(
    dir: string,
    presetId: string
  ): Promise<string | null> {
    if (!await fs.pathExists(dir)) return null;

    const files = await glob(path.join(dir, '**', `${presetId}.yaml`));
    return files.length > 0 ? files[0] : null;
  }

  private getPresetSource(filePath: string): PresetSource {
    if (filePath.includes('.novel/presets/official')) return 'official';
    if (filePath.includes('.novel/presets/community')) return 'community';
    if (filePath.includes('.novel/presets/user')) return 'user';
    if (filePath.includes('stories')) return 'project';
    return 'builtin';
  }
}

/**
 * Интерфейс информации о пресете
 */
export interface PresetInfo {
  id: string;
  name: string;
  description: string;
  category: string;
  author: string;
  source: PresetSource;
}

export type PresetSource = 'official' | 'community' | 'user' | 'project' | 'builtin';
```

### 2.3 ConfigValidator

```typescript
/**
 * Валидатор конфигурации
 * Отвечает за проверку полноты, согласованности и ссылочной целостности конфигурации
 */
export class ConfigValidator {
  private projectPath: string;

  constructor(projectPath: string) {
    this.projectPath = projectPath;
  }

  /**
   * Валидация конфигурации
   */
  async validate(config: ChapterConfig): Promise<ValidationResult> {
    const errors: string[] = [];
    const warnings: string[] = [];

    // 1. Проверка обязательных полей
    if (!config.chapter) errors.push('Отсутствует номер главы');
    if (!config.title || config.title.trim() === '') errors.push('Отсутствует заголовок главы');
    if (!config.plot || !config.plot.summary) errors.push('Отсутствует краткое описание сюжета');
    if (!config.wordcount || !config.wordcount.target) errors.push('Отсутствует целевое количество слов');

    // 2. Проверка типов данных и диапазонов
    if (config.chapter < 1) errors.push('Номер главы должен быть больше 0');
    if (config.wordcount.target < 1000 || config.wordcount.target > 10000) {
      warnings.push('Целевое количество слов рекомендуется в диапазоне 1000-10000');
    }

    // 3. Проверка ссылочной целостности
    if (config.characters) {
      for (const char of config.characters) {
        const exists = await this.checkCharacterExists(char.id);
        if (!exists) {
          errors.push(`ID персонажа "${char.id}" не найден в character-profiles.md`);
        }
      }
    }

    if (config.scene?.location_id) {
      const exists = await this.checkLocationExists(config.scene.location_id);
      if (!exists) {
        errors.push(`ID локации "${config.scene.location_id}" не найден в locations.md`);
      }
    }

    if (config.plot.plotlines) {
      for (const plotline of config.plot.plotlines) {
        const exists = await this.checkPlotlineExists(plotline);
        if (!exists) {
          errors.push(`ID сюжетной линии "${plotline}" не найден в specification.md`);
        }
      }
    }

    // 4. Проверка логической согласованности
    const { min, target, max } = config.wordcount;
    if (min && target && min > target) {
      errors.push('Минимальное количество слов не может быть больше целевого');
    }
    if (target && max && target > max) {
      errors.push('Целевое количество слов не может быть больше максимального');
    }

    // 5. Рекомендации по лучшим практикам
    if (!config.characters || config.characters.length === 0) {
      warnings.push('Рекомендуется указать хотя бы одного персонажа');
    }

    if (!config.plot.key_points || config.plot.key_points.length < 3) {
      warnings.push('Рекомендуется указать хотя бы 3 ключевых момента');
    }

    if (!config.scene) {
      warnings.push('Рекомендуется настроить информацию о сцене');
    }

    return {
      valid: errors.length === 0,
      errors,
      warnings
    };
  }

  // ========== Приватные методы ==========

  private async checkCharacterExists(id: string): Promise<boolean> {
    const profilesPath = path.join(
      this.projectPath,
      'spec',
      'knowledge',
      'character-profiles.md'
    );

    if (!await fs.pathExists(profilesPath)) {
      return false;
    }

    const content = await fs.readFile(profilesPath, 'utf-8');
    // Упрощенная проверка на наличие ID персонажа
    return content.includes(`id: ${id}`) || content.includes(`ID: ${id}`);
  }

  private async checkLocationExists(id: string): Promise<boolean> {
    const locationsPath = path.join(
      this.projectPath,
      'spec',
      'knowledge',
      'locations.md'
    );

    if (!await fs.pathExists(locationsPath)) {
      return false;
    }

    const content = await fs.readFile(locationsPath, 'utf-8');
    return content.includes(`id: ${id}`) || content.includes(`ID: ${id}`);
  }

  private async checkPlotlineExists(id: string): Promise<boolean> {
    const specPath = path.join(
      this.projectPath,
      'stories',
      '*',
      'specification.md'
    );

    const specs = await glob(specPath);
    if (specs.length === 0) return false;

    const content = await fs.readFile(specs[0], 'utf-8');
    return content.includes(id);
  }
}

/**
 * Результат проверки
 */
export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}
```

---

## Три. Реализация команд CLI

### 3.1 Входной файл команды

```typescript
// src/commands/chapter-config.ts

import { Command } from 'commander';
import chalk from 'chalk';
import inquirer from 'inquirer';
import ora from 'ora';
import { ChapterConfigManager } from '../core/chapter-config.js';
import { PresetManager } from '../core/preset-manager.js';

/**
 * Регистрация команд chapter-config
 */
export function registerChapterConfigCommands(program: Command): void {
  const chapterConfig = program
    .command('chapter-config')
    .description('Управление конфигурацией глав');

  // команда create
  chapterConfig
    .command('create <chapter>')
    .option('-i, --interactive', 'Интерактивное создание')
    .option('-p, --preset <preset-id>', 'Использовать пресет')
    .option('--from-prompt', 'Генерация из естественного языка')
    .description('Создать конфигурацию главы')
    .action(async (chapter, options) => {
      try {
        const chapterNum = parseInt(chapter);
        if (isNaN(chapterNum)) {
          console.error(chalk.red('Номер главы должен быть числом'));
          process.exit(1);
        }

        if (options.interactive) {
          await createConfigInteractive(chapterNum);
        } else if (options.preset) {
          await createConfigWithPreset(chapterNum, options.preset);
        } else {
          console.error(chalk.red('Пожалуйста, укажите --interactive или --preset'));
          process.exit(1);
        }
      } catch (error: any) {
        console.error(chalk.red(`Ошибка создания: ${error.message}`));
        process.exit(1);
      }
    });

  // команда list
  chapterConfig
    .command('list')
    .option('--format <type>', 'Формат вывода: table|json|yaml', 'table')
    .description('Список всех конфигураций глав')
    .action(async (options) => {
      try {
        await listConfigs(options.format);
      } catch (error: any) {
        console.error(chalk.red(`Ошибка списка: ${error.message}`));
        process.exit(1);
      }
    });

  // команда validate
  chapterConfig
    .command('validate <chapter>')
    .description('Проверить конфигурацию главы')
    .action(async (chapter) => {
      try {
        const chapterNum = parseInt(chapter);
        await validateConfig(chapterNum);
      } catch (error: any) {
        console.error(chalk.red(`Ошибка проверки: ${error.message}`));
        process.exit(1);
      }
    });

  // команда copy
  chapterConfig
    .command('copy <from> <to>')
    .option('-i, --interactive', 'Интерактивное изменение различий')
    .description('Копировать конфигурацию главы')
    .action(async (from, to, options) => {
      try {
        const fromChapter = parseInt(from);
        const toChapter = parseInt(to);
        await copyConfig(fromChapter, toChapter, options.interactive);
      } catch (error: any) {
        console.error(chalk.red(`Ошибка копирования: ${error.message}`));
        process.exit(1);
      }
    });

  // команда edit
  chapterConfig
    .command('edit <chapter>')
    .option('-e, --editor <editor>', 'Указать редактор', 'vim')
    .description('Редактировать конфигурацию главы')
    .action(async (chapter, options) => {
      try {
        const chapterNum = parseInt(chapter);
        await editConfig(chapterNum, options.editor);
      } catch (error: any) {
        console.error(chalk.red(`Ошибка редактирования: ${error.message}`));
        process.exit(1);
      }
    });

  // команда delete
  chapterConfig
    .command('delete <chapter>')
    .description('Удалить конфигурацию главы')
    .action(async (chapter) => {
      try {
        const chapterNum = parseInt(chapter);
        await deleteConfig(chapterNum);
      } catch (error: any) {
        console.error(chalk.red(`Ошибка удаления: ${error.message}`));
        process.exit(1);
      }
    });
}

/**
 * Интерактивное создание конфигурации
 */
async function createConfigInteractive(chapter: number): Promise<void> {
  // Реализация см. в предыдущем разделе 2.4.2
  console.log(chalk.cyan(`\n📝 Создание конфигурации главы ${chapter}\n`));

  // ... (полная реализация опущена)
}

/**
 * Создание конфигурации с использованием пресета
 */
async function createConfigWithPreset(
  chapter: number,
  presetId: string
): Promise<void> {
  const spinner = ora('Загрузка пресета...').start();

  try {
    const presetManager = new PresetManager();
    const preset = await presetManager.loadPreset(presetId);

    spinner.succeed(chalk.green(`Загружен пресет: ${preset.name}`));

    // Запрос у пользователя дополнительной информации
    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'title',
        message: 'Заголовок главы:',
        validate: (input) => input.length > 0
      },
      {
        type: 'input',
        name: 'characters',
        message: 'Появляющиеся персонажи (через запятую):',
        validate: (input) => input.length > 0
      },
      {
        type: 'input',
        name: 'scene',
        message: 'Сцена:',
        validate: (input) => input.length > 0
      },
      {
        type: 'input',
        name: 'plotSummary',
        message: 'Краткое содержание сюжета:',
        validate: (input) => input.length > 10
      }
    ]);

    // Создание конфигурации
    const manager = new ChapterConfigManager(process.cwd());
    const config = await manager.createConfig(chapter, {
      title: answers.title,
      characters: answers.characters.split(',').map(c => c.trim()),
      scene: answers.scene,
      plotSummary: answers.plotSummary,
      preset: presetId
    });

    console.log(chalk.green(`\n✅ Конфигурация сохранена`));
    console.log(chalk.gray(`Файл: ${getConfigPath(chapter)}`));
  } catch (error: any) {
    spinner.fail(chalk.red(`Ошибка создания: ${error.message}`));
    process.exit(1);
  }
}

/**
 * Список всех конфигураций
 */
async function listConfigs(format: string): Promise<void> {
  const spinner = ora('Загрузка списка конфигураций...').start();

  try {
    const manager = new ChapterConfigManager(process.cwd());
    const configs = await manager.listConfigs();

    spinner.stop();

    if (configs.length === 0) {
      console.log(chalk.yellow('\nНет конфигураций глав'));
      return;
    }

    console.log(chalk.cyan(`\n📋 Существующие конфигурации глав (${configs.length}):\n`));

    if (format === 'table') {
      // Вывод в виде таблицы
      console.table(configs.map(c => ({
        'Глава': `Глава ${c.chapter}`,
        'Заголовок': c.title,
        'Тип сюжета': c.plotType,
        'Сцена': c.location,
        'Кол-во слов': c.wordcount,
        'Пресет': c.preset || '-'
      })));
    } else if (format === 'json') {
      console.log(JSON.stringify(configs, null, 2));
    } else if (format === 'yaml') {
      console.log(yaml.dump(configs));
    }
  } catch (error: any) {
    spinner.fail(chalk.red(`Ошибка загрузки: ${error.message}`));
    process.exit(1);
  }
}

/**
 * Проверка конфигурации
 */
async function validateConfig(chapter: number): Promise<void> {
  console.log(chalk.cyan(`\n🔍 Проверка файла конфигурации: chapter-${chapter}-config.yaml\n`));

  const manager = new ChapterConfigManager(process.cwd());
  const config = await manager.loadConfig(chapter);

  if (!config) {
    console.error(chalk.red('❌ Файл конфигурации не существует'));
    process.exit(1);
  }

  const validator = new ConfigValidator(process.cwd());
  const result = await validator.validate(config);

  if (result.valid) {
    console.log(chalk.green('✅ Проверка пройдена!\n'));
  } else {
    console.log(chalk.red(`❌ Проверка не пройдена (${result.errors.length} ошибок):\n`));
    result.errors.forEach((error, index) => {
      console.log(chalk.red(`  ${index + 1}. ${error}`));
    });
    console.log('');
  }

  if (result.warnings.length > 0) {
    console.log(chalk.yellow(`⚠️  Предупреждения (${result.warnings.length}):\n`));
    result.warnings.forEach((warning, index) => {
      console.log(chalk.yellow(`  ${index + 1}. ${warning}`));
    });
    console.log('');
  }

  if (!result.valid) {
    process.exit(1);
  }
}

/**
 * Копирование конфигурации
 */
async function copyConfig(
  from: number,
  to: number,
  interactive: boolean
): Promise<void> {
  const manager = new ChapterConfigManager(process.cwd());

  console.log(chalk.cyan(`\n📋 Копирование конфигурации: Глава ${from} → Глава ${to}\n`));

  if (interactive) {
    // Интерактивное изменение различий
    const sourceConfig = await manager.loadConfig(from);
    if (!sourceConfig) {
      console.error(chalk.red('Исходная конфигурация не существует'));
      process.exit(1);
    }

    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'title',
        message: 'Новый заголовок:',
        default: sourceConfig.title
      },
      {
        type: 'input',
        name: 'plotSummary',
        message: 'Краткое содержание сюжета:',
        default: sourceConfig.plot.summary
      }
      // ...больше полей
    ]);

    await manager.copyConfig(from, to, answers);
  } else {
    await manager.copyConfig(from, to);
  }

  console.log(chalk.green(`\n✅ Конфигурация скопирована`));
}

/**
 * Редактирование конфигурации
 */
async function editConfig(chapter: number, editor: string): Promise<void> {
  const configPath = getConfigPath(chapter);

  if (!await fs.pathExists(configPath)) {
    console.error(chalk.red('Файл конфигурации не существует'));
    process.exit(1);
  }

  // Вызов редактора
  const { spawn } = await import('child_process');
  const child = spawn(editor, [configPath], {
    stdio: 'inherit'
  });

  child.on('exit', (code) => {
    if (code === 0) {
      console.log(chalk.green('\n✅ Редактирование завершено'));
    } else {
      console.error(chalk.red('\n❌ Ошибка редактирования'));
      process.exit(1);
    }
  });
}

/**
 * Удаление конфигурации
 */
async function deleteConfig(chapter: number): Promise<void> {
  const answers = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'confirm',
      message: `Подтвердите удаление конфигурации главы ${chapter}?`,
      default: false
    }
  ]);

  if (!answers.confirm) {
    console.log(chalk.yellow('Отменено'));
    return;
  }

  const manager = new ChapterConfigManager(process.cwd());
  await manager.deleteConfig(chapter);

  console.log(chalk.green(`\n✅ Конфигурация удалена`));
}

// Вспомогательная функция
function getConfigPath(chapter: number): string {
  // Реализация опущена...
  return '';
}
```

---

## Четыре. Интеграция шаблона write.md

### 4.1 План модификации шаблона

**Место изменения**: `templates/commands/write.md`

**Содержание изменения**:

```markdown
---
description: Выполнение написания главы на основе списка задач, автоматическая загрузка контекста и правил проверки
argument-hint: [Номер главы или ID задачи]
allowed-tools: Read(//**), Write(//stories/**/content/**), Bash(ls:*), Bash(find:*), Bash(wc:*), Bash(grep:*), Bash(*)
model: claude-sonnet-4-5-20250929
scripts:
  sh: .specify/scripts/bash/check-writing-state.sh
  ps: .specify/scripts/powershell/check-writing-state.ps1
---

Выполнение написания главы на основе методологии семи шагов.
---

## Предварительная проверка

1. Запуск скрипта `{SCRIPT}` для проверки состояния написания

2. **🆕 Проверка файла конфигурации главы** (добавлено)
   ```bash
   # Проверка наличия файла конфигурации
   chapter_num="$CHAPTER_NUMBER"  # Извлечь из $ARGUMENTS
   config_file="stories/*/chapters/chapter-${chapter_num}-config.yaml"

   if [ -f "$config_file" ]; then
     echo "✅ Обнаружен файл конфигурации, загрузка..."
     # Чтение файла конфигурации
     CONFIG_CONTENT=$(cat "$config_file")
   else
     echo "ℹ️  Файл конфигурации отсутствует, режим естественного языка"
     CONFIG_CONTENT=""
   fi
   ```

### Протокол запросов (обязательный порядок чтения)
⚠️ **Важно**: Пожалуйста, строго следуйте следующему порядку запросов, чтобы обеспечить полноту контекста и правильность приоритетов.

**Порядок запросов**:

1. **🆕 Сначала запрос (Конфигурация главы - если существует)** (Новое):
   - `stories/*/chapters/chapter-X-config.yaml` (Файл конфигурации главы)
   - Если файл конфигурации существует, разберите его и извлеките:
     - Список идентификаторов появляющихся персонажей
     - Идентификатор сцены
     - Тип сюжета, краткое описание, ключевые моменты
     - Параметры стиля письма
     - Требования к количеству слов
     - Особые требования

2. **Сначала запрос (Высший приоритет)**:
   - `memory/novel-constitution.md` (Конституция творчества - высший принцип)
   - `memory/style-reference.md` (Справочник по стилю - если сгенерирован через `/book-internalize`)

3. **Затем запрос (Спецификации и планы)**:
   - `stories/*/specification.md` (Спецификации истории)
   - `stories/*/creative-plan.md` (План творчества)
   - `stories/*/tasks.md` (Текущие задачи)

4. **🆕 Загрузка подробной информации на основе конфигурации** (Новое):
   Если конфигурационный файл указывает персонажей и сцены, загрузите подробную информацию:

   ```
   # Загрузка деталей персонажей
   Для каждого ID персонажа в конфигурации:
   1. Найдите полный профиль персонажа в spec/knowledge/character-profiles.md
   2. Получите последнее состояние из spec/tracking/character-state.json
   3. Объедините информацию для последующего использования

   # Загрузка деталей сцены
   Если конфигурация указывает scene.location_id:
   1. Найдите подробное описание сцены в spec/knowledge/locations.md
   2. Извлеките окружение, атмосферу, характеристики сцены

   # Загрузка деталей сюжетных линий
   Если конфигурация указывает plot.plotlines:
   1. Найдите определение сюжетной линии в stories/*/specification.md
   2. Получите текущее состояние и цель сюжетной линии
   ```

5. **Затем запрос (Состояния и данные)**:
   - `spec/tracking/character-state.json` (Состояние персонажей)
   - `spec/tracking/relationships.json` (Сеть взаимоотношений)
   - `spec/tracking/plot-tracker.json` (Отслеживание сюжета - если есть)
   - `spec/tracking/validation-rules.json` (Правила валидации - если есть)

6. **Затем запрос (База знаний)**:
   - Файлы, связанные с `spec/knowledge/` (Мировоззрение, профили персонажей и т. д.)
   - `stories/*/content/` (Предыдущее содержимое - для понимания контекста)

7. **Затем запрос (Нормы письма)**:
   - `memory/personal-voice.md` (Личные материалы - если есть)
   - `spec/knowledge/natural-expression.md` (Естественное выражение - если есть)
   - `spec/presets/anti-ai-detection.md` (Нормы по противодействию обнаружению ИИ)

8. **Условный запрос (Только для первых трех глав)**:
   - **Если номер главы ≤ 3 или общее количество слов < 10000 слов**, дополнительно запросите:
     - `spec/presets/golden-opening.md` (Правила золотого начала)
     - И строго следуйте пяти правилам, изложенным в нем

## Процесс выполнения письма

### 1. Выбор задачи для письма
Выберите задачу для письма из `tasks.md` со статусом `pending` и пометьте ее как `in_progress`.

### 2. Проверка предварительных условий
- Проверьте, завершены ли связанные зависимые задачи
- Убедитесь, что необходимые настройки готовы
- Подтвердите завершение предыдущих глав

### 3. **🆕 Создание подсказки для написания главы** (Изменено)

**Если есть файл конфигурации**:

```
📋 Конфигурация главы:

**Основная информация**:
- Глава: Глава {{chapter}} - {{title}}
- Требования к количеству слов: {{wordcount.min}}-{{wordcount.max}} слов (цель {{wordcount.target}} слов)

**Появляющиеся персонажи** ({{characters.length}} человек):
{{#each characters}}
- **{{name}}** ({{role}} - фокус на {{focus}})
  [Подробный профиль, прочитанный из character-profiles.md]
  Характер: {{personality}}
  Предыстория: {{background}}

  Текущее состояние: (Прочитано из character-state.json)
  - Местоположение: {{location}}
  - Здоровье: {{health}}
  - Настроение: {{mood}}
  - Отношения с другими персонажами: {{relationships}}
{{/each}}

**Настройка сцены**:
- Место: {{scene.location_name}}
  [Подробности сцены, прочитанные из locations.md]
  Подробное описание: {{location_details}}
  Характеристики: {{features}}

- Время: {{scene.time}}
- Погода: {{scene.weather}}
- Атмосфера: {{scene.atmosphere}}

**Требования к сюжету**:
- Тип: {{plot.type}} ({{plot_type_description}})
- Краткое описание: {{plot.summary}}
- Ключевые моменты:
  {{#each plot.key_points}}
  {{index}}. {{this}}
  {{/each}}

{{#if plot.plotlines}}
- Задействованные сюжетные линии:
  {{#each plot.plotlines}}
  - {{this}}: [Подробности сюжетной линии, прочитанные из specification.md]
  {{/each}}
{{/if}}

{{#if plot.foreshadowing}}
- Заделы в этой главе:
  {{#each plot.foreshadowing}}
  - {{id}}: {{content}}
  {{/each}}
{{/if}}

**Стиль письма**:
- Темп: {{style.pace}} ({{pace_description}})
- Длина предложений: {{style.sentence_length}} ({{sentence_description}})
- Фокус: {{style.focus}} ({{focus_description}})
- Тон: {{style.tone}}

{{#if special_requirements}}
**Особые требования**:
{{special_requirements}}
{{/if}}

{{#if preset_used}}
**Примененный пресет**: {{preset_used}}
{{/if}}

---

[Далее загружаются глобальные спецификации книги...]
```

**Если нет файла конфигурации** (обратная совместимость):

```
📋 На основе ввода пользователя:

Описание пользователя: $ARGUMENTS

[Разбор естественного языка, извлечение параметров]

[Загрузка глобальных спецификаций книги...]
```

### 4. Напоминания перед написанием
**Напоминания на основе принципов Конституции**:
- Ключевые моменты основных ценностей
- Требования к качеству
- Правила соответствия стилю

**Напоминания на основе требований спецификации**:
- Элементы, которые должны быть включены (P0)
- Характеристики целевой аудитории
- Предупреждения о красных линиях контента

**Правила форматирования абзацев (Важно)**:
[Сохранить исходное содержимое]

**Правила письма для противодействия обнаружению ИИ (на основе стандарта Tencent Zhuque)**:
[Сохранить исходное содержимое]

### 5. Создание контента в соответствии с планом:
   - **Начало**: Привлечь читателя, связать с предыдущим текстом
   - **Развитие**: Продвигать сюжет, углублять персонажей
   - **Поворот**: Создать конфликт или интригу
   - **Завершение**: Соответствующим образом завершить, намекнуть на продолжение

### 6. Самопроверка качества
[Сохранить исходное содержимое]

### 7. Сохранение и обновление
- Сохраните содержимое главы в `stories/*/content/`
- **🆕 Если использовался файл конфигурации, обновите временную метку `updated_at`** (Новое)
- Обновите статус задачи до `completed`
- Запишите время завершения и количество слов

[Остальное содержимое остается без изменений...]
```

### 4.2 Логика загрузки конфигурации

В шаблоне write.md ИИ должен выполнить следующую логику:

```typescript
// Псевдокод: Логика выполнения ИИ

// 1. Разбор номера главы
const chapterNum = parseChapterNumber($ARGUMENTS);

// 2. Проверка файла конфигурации
const configPath = `stories/*/chapters/chapter-${chapterNum}-config.yaml`;
const config = await loadYamlFile(configPath);

if (config) {
  // 3. Загрузка деталей персонажей
  for (const char of config.characters) {
    const profile = await extractFromMarkdown(
      'spec/knowledge/character-profiles.md',
      char.id
    );
    const state = await loadJson('spec/tracking/character-state.json')[char.id];
    char.details = { ...profile, ...state };
  }

  // 4. Загрузка деталей сцены
  if (config.scene.location_id) {
    config.scene.details = await extractFromMarkdown(
      'spec/knowledge/locations.md',
      config.scene.location_id
    );
  }

  // 5. Загрузка деталей сюжетных линий
  if (config.plot.plotlines) {
    for (const plotlineId of config.plot.plotlines) {
      const plotline = await extractFromMarkdown(
        'stories/*/specification.md',
        plotlineId
      );
      config.plot.plotlineDetails.push(plotline);
    }
  }

  // 6. Создание структурированной подсказки
  const prompt = buildPromptFromConfig(config);
} else {
  // 7. Использование режима естественного языка
  const prompt = parseNaturalLanguage($ARGUMENTS);
}

// 8. Загрузка глобальных спецификаций
const globalSpecs = await loadGlobalSpecs();

// 9. Объединение подсказок
const fullPrompt = mergePrompts(prompt, globalSpecs);

// 10. Генерация содержимого главы
const content = await generateChapterContent(fullPrompt);

// 11. Сохранение
await saveChapterContent(chapterNum, content);

// 12. Обновление временной метки файла конфигурации
if (config) {
  config.updated_at = new Date().toISOString();
  await saveYamlFile(configPath, config);
}
```

---

## Пять. Стратегия тестирования

### 5.1 Модульное тестирование

**Область тестирования**:
- Все методы ChapterConfigManager
- Все методы PresetManager
- Все правила валидации ConfigValidator

**Фреймворк тестирования**: Jest

**Цель покрытия тестами**: > 80%

**Пример теста**:

```typescript
// test/chapter-config.test.ts

describe('ChapterConfigManager', () => {
  let manager: ChapterConfigManager;

  beforeEach(() => {
    manager = new ChapterConfigManager('/test/project');
  });

  describe('createConfig', () => {
    it('should create config with valid parameters', async () => {
      const config = await manager.createConfig(5, {
        title: 'Тестовая глава',
        plotType: 'ability_showcase',
        plotSummary: 'Краткое описание тестового сюжета',
        wordcount: 3000
      });

      expect(config.chapter).toBe(5);
      expect(config.title).toBe('Тестовая глава');
      expect(config.plot.type).toBe('ability_showcase');
      expect(config.wordcount.target).toBe(3000);
    });

    it('should apply preset correctly', async () => {
      const config = await manager.createConfig(5, {
        title: 'Экшн-глава',
        preset: 'action-intense'
      });

      expect(config.preset_used).toBe('action-intense');
      expect(config.style.pace).toBe('fast');
      expect(config.style.sentence_length).toBe('short');
    });

    it('should throw error for invalid parameters', async () => {
      await expect(manager.createConfig(0, {})).rejects.toThrow();
    });
  });

  describe('loadConfig', () => {
    it('should return null for non-existent config', async () => {
      const config = await manager.loadConfig(999);
      expect(config).toBeNull();
    });

    it('should load existing config correctly', async () => {
      // Сначала создаем
      await manager.createConfig(5, { title: 'Тест' });

      // Затем загружаем
      const config = await manager.loadConfig(5);
      expect(config).not.toBeNull();
      expect(config!.chapter).toBe(5);
    });
  });

  // Больше тестов...
});
```

### 5.2 Интеграционное тестирование

**Сценарии тестирования**:

1. **Полный рабочий процесс**:
   ```
   Создание конфигурации → Загрузка конфигурации → Валидация конфигурации → Обновление конфигурации → Удаление конфигурации
   ```

2. **Применение пресетов**:
   ```
   Список пресетов → Выбор пресета → Создание конфигурации → Проверка применения параметров пресета
   ```

3. **Тестирование команд CLI**:
   ```
   Выполнение различных команд CLI → Проверка вывода → Проверка изменений в файлах
   ```

4. **Интеграционное тестирование с write.md**:
   ```
   Создание конфигурации → Выполнение команды /write → Проверка загрузки конфигурации ИИ → Проверка сгенерированного контента
   ```

### 5.3 Сквозное тестирование

**Сценарии тестирования**:

1. **Первое использование новым пользователем**:
   ```
   1. Установка novel-writer-ru
   2. novel init my-story
   3. novel chapter-config create 1 --interactive
   4. В редакторе ИИ выполнить /write Глава 1
   5. Проверить, соответствует ли сгенерированная глава конфигурации
   ```

2. **Быстрое создание с использованием пресета**:
   ```
   1. novel preset list
   2. novel chapter-config create 5 --preset action-intense
   3. /write Глава 5
   4. Проверить сцену напряженного экшена
   ```

3. **Повторное использование конфигурации**:
   ```
   1. novel chapter-config copy 5 10
   2. Изменить необходимые части
   3. /write Глава 10
   4. Проверить сохранение единообразия стиля
   ```

---

## Шесть. Оптимизация производительности

### 6.1 Кэширование файлов конфигурации

```typescript
/**
 * Менеджер кэша конфигурации
 */
export class ConfigCache {
  private cache: Map<number, {
    config: ChapterConfig;
    mtime: number;
  }> = new Map();

  async get(chapter: number, filePath: string): Promise<ChapterConfig | null> {
    const stats = await fs.stat(filePath);
    const cached = this.cache.get(chapter);

    if (cached && cached.mtime === stats.mtimeMs) {
      return cached.config;
    }

    return null;
  }

  set(chapter: number, config: ChapterConfig, mtime: number): void {
    this.cache.set(chapter, { config, mtime });
  }

  clear(chapter?: number): void {
    if (chapter) {
      this.cache.delete(chapter);
    } else {
      this.cache.clear();
    }
  }
}
```

### 6.2 Предварительная загрузка пресетов

```typescript
/**
 * Загрузчик пресетов
 * Предварительная загрузка всех официальных пресетов при запуске приложения
 */
export class PresetPreloader {
  private preloadedPresets: Map<string, Preset> = new Map();

  async preload(): Promise<void> {
    const presetDir = path.join(__dirname, '..', '..', 'presets');
    const files = await glob(path.join(presetDir, '**', '*.yaml'));

    for (const file of files) {
      const content = await fs.readFile(file, 'utf-8');
      const preset = yaml.load(content) as Preset;
      this.preloadedPresets.set(preset.id, preset);
    }
  }

  get(presetId: string): Preset | undefined {
    return this.preloadedPresets.get(presetId);
  }
}
```

### 6.3 Оптимизация разбора YAML

```typescript
/**
```typescript
/**
 * Использование более быстрого YAML-парсер
 */
import { parse } from 'yaml'; // Используем библиотеку yaml вместо js-yaml

export async function loadYamlFast(filePath: string): Promise<any> {
  const content = await fs.readFile(filePath, 'utf-8');
  return parse(content);
}
```

---

## Семь. Вопросы безопасности

### 7.1 Проверка ввода

```typescript
/**
 * Очистка и проверка ввода
 */
export class InputSanitizer {
  /**
   * Очистка номера главы
   */
  sanitizeChapterNumber(input: any): number {
    const num = parseInt(String(input));
    if (isNaN(num) || num < 1 || num > 9999) {
      throw new Error('Номер главы должен быть в диапазоне 1-9999');
    }
    return num;
  }

  /**
   * Очистка пути к файлу
   */
  sanitizeFilePath(input: string): string {
    // Предотвращение атак с использованием обхода каталогов
    const normalized = path.normalize(input);
    if (normalized.includes('..')) {
      throw new Error('Недопустимый путь');
    }
    return normalized;
  }

  /**
   * Очистка содержимого YAML
   */
  sanitizeYamlContent(content: string): string {
    // Удаление потенциальных инъекций кода
    if (content.includes('!<tag:')) {
      throw new Error('YAML-теги не поддерживаются');
    }
    return content;
  }
}
```

### 7.2 Контроль доступа

```typescript
/**
 * Проверка прав доступа к файлам
 */
export class PermissionChecker {
  /**
   * Проверка, находится ли файл в пределах проекта
   */
  isWithinProject(filePath: string, projectPath: string): boolean {
    const resolved = path.resolve(filePath);
    const project = path.resolve(projectPath);
    return resolved.startsWith(project);
  }

  /**
   * Проверка, доступен ли файл для записи
   */
  async isWritable(filePath: string): Promise<boolean> {
    try {
      await fs.access(filePath, fs.constants.W_OK);
      return true;
    } catch {
      return false;
    }
  }
}
```

---

## Восемь. Обработка ошибок

### 8.1 Определение типов ошибок

```typescript
/**
 * Пользовательский класс ошибок
 */
export class ConfigError extends Error {
  constructor(
    message: string,
    public code: string,
    public details?: any
  ) {
    super(message);
    this.name = 'ConfigError';
  }
}

export class ValidationError extends ConfigError {
  constructor(message: string, public errors: string[]) {
    super(message, 'VALIDATION_ERROR', { errors });
    this.name = 'ValidationError';
  }
}

export class PresetNotFoundError extends ConfigError {
  constructor(presetId: string) {
    super(`Предустановка не найдена: ${presetId}`, 'PRESET_NOT_FOUND', { presetId });
    this.name = 'PresetNotFoundError';
  }
}
```

### 8.2 Стратегия обработки ошибок

```typescript
/**
 * Глобальный обработчик ошибок
 */
export class ErrorHandler {
  handle(error: Error): void {
    if (error instanceof ValidationError) {
      console.error(chalk.red(`Ошибка валидации:`));
      error.errors.forEach((err, index) => {
        console.error(chalk.red(`  ${index + 1}. ${err}`));
      });
    } else if (error instanceof PresetNotFoundError) {
      console.error(chalk.red(`Предустановка не найдена: ${error.details.presetId}`));
      console.log(chalk.gray('\nПодсказка: используйте novel preset list для просмотра доступных предустановок'));
    } else if (error instanceof ConfigError) {
      console.error(chalk.red(`Ошибка конфигурации: ${error.message}`));
      if (error.details) {
        console.error(chalk.gray(JSON.stringify(error.details, null, 2)));
      }
    } else {
      console.error(chalk.red(`Неизвестная ошибка: ${error.message}`));
      console.error(error.stack);
    }

    process.exit(1);
  }
}
```

---

## Девять. Развертывание и выпуск

### 9.1 Процесс сборки

```bash
# скрипты package.json

{
  "scripts": {
    "build": "tsc",
    "build:presets": "bash scripts/bundle-presets.sh",
    "build:all": "npm run build && npm run build:presets",
    "test": "jest",
    "test:coverage": "jest --coverage",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts"
  }
}
```

### 9.2 Чек-лист выпуска

- [ ] Модульные тесты пройдены (покрытие > 80%)
- [ ] Интеграционные тесты пройдены
- [ ] Сквозные тесты пройдены
- [ ] Lint-код пройден
- [ ] Документация полная
- [ ] CHANGELOG обновлен
- [ ] Номер версии обновлен
- [ ] Файлы предустановок упакованы

### 9.3 Совместимость версий

```typescript
/**
 * Управление версиями конфигурации
 */
export const CONFIG_VERSION = '1.0.0';

export function migrateConfig(config: any): ChapterConfig {
  // Миграция из старой версии в текущую
  if (!config.version || config.version < '1.0.0') {
    // Выполнение логики миграции
    config = migrateFrom_0_x(config);
  }

  config.version = CONFIG_VERSION;
  return config as ChapterConfig;
}
```

---

## Десять. Мониторинг и отладка

### 10.1 Система логирования

```typescript
/**
 * Структурированное логирование
 */
export class Logger {
  private level: 'debug' | 'info' | 'warn' | 'error';

  constructor(level: 'debug' | 'info' | 'warn' | 'error' = 'info') {
    this.level = level;
  }

  debug(message: string, meta?: any): void {
    if (this.shouldLog('debug')) {
      console.log(chalk.gray(`[DEBUG] ${message}`), meta || '');
    }
  }

  info(message: string, meta?: any): void {
    if (this.shouldLog('info')) {
      console.log(chalk.cyan(`[INFO] ${message}`), meta || '');
    }
  }

  warn(message: string, meta?: any): void {
    if (this.shouldLog('warn')) {
      console.log(chalk.yellow(`[WARN] ${message}`), meta || '');
    }
  }

  error(message: string, meta?: any): void {
    if (this.shouldLog('error')) {
      console.error(chalk.red(`[ERROR] ${message}`), meta || '');
    }
  }

  private shouldLog(level: string): boolean {
    const levels = ['debug', 'info', 'warn', 'error'];
    return levels.indexOf(level) >= levels.indexOf(this.level);
  }
}
```

### 10.2 Мониторинг производительности

```typescript
/**
 * Таймер производительности
 */
export class PerformanceTimer {
  private timers: Map<string, number> = new Map();

  start(name: string): void {
    this.timers.set(name, Date.now());
  }

  end(name: string): number {
    const start = this.timers.get(name);
    if (!start) {
      throw new Error(`Таймер ${name} не запущен`);
    }

    const duration = Date.now() - start;
    this.timers.delete(name);
    return duration;
  }

  measure(name: string, fn: () => Promise<any>): Promise<any> {
    this.start(name);
    return fn().finally(() => {
      const duration = this.end(name);
      console.log(chalk.gray(`⏱️  ${name}: ${duration}ms`));
    });
  }
}
```

---

## Приложение

### A. Полный экспорт типов TypeScript

```typescript
// src/types/index.ts

export * from './chapter-config';
export * from './preset';
export * from './validation';
export * from './errors';
```

### B. Полный список команд CLI

См. содержание Главы 3.

### C. Отчет о покрытии тестами

```bash
$ npm run test:coverage

----------------------|---------|----------|---------|---------|
| File                   | % Stmts   | % Branch   | % Funcs   | % Lines   |
| ---------------------- | --------- | ---------- | --------- | --------- |
| All files              | 85.23     | 78.45      | 89.12     | 84.67     |
| chapter-config.ts      | 88.45     | 82.30      | 91.20     | 87.90     |
| preset-manager.ts      | 82.10     | 75.60      | 87.50     | 81.45     |
| config-validator.ts    | 86.70     | 79.20      | 88.90     | 85.30     |
| ---------------------- | --------- | ---------- | --------- | --------- |
```

---

**КОНЕЦ ТЕХНИЧЕСКОЙ СПЕЦИФИКАЦИИ**