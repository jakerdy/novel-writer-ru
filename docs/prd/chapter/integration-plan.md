# План интеграции сервера Dreams

## Информация о документе

- **Версия**: v1.0.0
- **Дата создания**: 2025-10-14
- **Автор**: Команда Novel Writer
- **Статус**: На этапе планирования

## Оглавление

1. [Предпосылки](#1-предпосылки)
2. [Цели интеграции](#2-цели-интеграции)
3. [Текущее состояние системы Dreams](#3-текущее-состояние-системы-dreams)
4. [Проектирование архитектуры интеграции](#4-проектирование-архитектуры-интеграции)
5. [Дизайн веб-интерфейса](#5-дизайн-веб-интерфейса)
6. [Дизайн API](#6-дизайн-api)
7. [Механизм синхронизации сессий](#7-механизм-синхронизации-сессий)
8. [Поэтапный план реализации](#8-поэтапный-план-реализации)
9. [Технические проблемы и решения](#9-технические-проблемы-и-решения)
10. [Критерии успеха](#10-критерии-успеха)

---

## 1. Предпосылки

### 1.1 Текущая ситуация

**novel-writer-cn CLI**:
- ✅ Полная система, управляемая спецификациями (specification.md, constitution.md)
- ✅ Система отслеживания персонажей, сцен и сюжета
- ✅ Процесс написания с использованием Slash Command (/write)
- 🚧 Система конфигурации глав (добавлено в этом цикле)
- ❌ Веб-интерфейс визуализации

**Сервер Dreams**:
- ✅ Платформа полного стека Next.js 14
- ✅ Система форм YAML
- ✅ Механизм управления сессиями
- ✅ Безопасные API tRPC
- ✅ Управление произведениями, преобразование форматов, рынок инструментов
- ❌ Управление конфигурацией глав

### 1.2 Ценность интеграции

| Функция | Только CLI | Интеграция с Dreams | Повышение ценности |
|---------|------------|---------------------|--------------------|
| Создание конфигурации | Интерактивное взаимодействие с командной строкой/ручное написание YAML | Визуальное заполнение через веб-формы | ⭐⭐⭐⭐⭐ |
| Просмотр пресетов | `novel preset list` | Визуальные карточки + предварительный просмотр | ⭐⭐⭐⭐ |
| Управление конфигурацией | Локальная файловая система | Облачное хранилище + контроль версий | ⭐⭐⭐⭐ |
| Командная работа | Обмен через Git | Облачная синхронизация в реальном времени | ⭐⭐⭐ |
| Доступ с мобильных устройств | Не поддерживается | Адаптивный веб-интерфейс | ⭐⭐⭐ |

---

## 2. Цели интеграции

### 2.1 Краткосрочные цели (v1.0)

1. **Веб-формы конфигурации**: Предоставить интерфейс для визуального создания конфигурации глав.
2. **Рынок пресетов**: Отображать и искать шаблоны пресетов.
3. **Синхронизация сессий**: Синхронизировать конфигурацию из веб-интерфейса в локальную среду CLI.
4. **Базовые CRUD операции**: Создание, чтение, обновление, удаление конфигураций глав.

### 2.2 Долгосрочные цели (v2.0+)

1. **Облачное хранилище**: Резервное копирование конфигурационных файлов в облаке, синхронизация между устройствами.
2. **Контроль версий**: История версий и откаты для конфигурационных файлов.
3. **Командная работа**: Совместное использование конфигураций несколькими пользователями, процессы комментирования и утверждения.
4. **Интеллектуальные рекомендации**: Рекомендации подходящих пресетов и конфигураций в зависимости от типа произведения.
5. **Рынок шаблонов конфигурации**: Пользователи могут делиться и продавать собственные шаблоны конфигурации.

---

## 3. Текущее состояние системы Dreams

### 3.1 Система форм YAML

Dreams уже имеет полноценную инфраструктуру форм YAML:

```yaml
# Пример forms/intro.yaml
fields:
  - id: genre
    type: select
    label: Тип произведения
    options:
      - {value: xuanhuan, label: Фэнтези}
      - {value: dushi, label: Городское}
    required: true

  - id: protagonist_name
    type: text
    label: Имя главного героя
    required: true

  - id: special_requirements
    type: textarea
    label: Особые требования
    rows: 5
```

**Существующие возможности**:
- ✅ Различные типы полей (text, textarea, select, radio, checkbox)
- ✅ Валидация форм
- ✅ Хранение сессий
- ✅ Интерфейс для интеграции с CLI

### 3.2 Механизм интеграции с CLI

Процесс интеграции Dreams с CLI:

```
Заполнение веб-формы → Хранение сессии → CLI загружает → AI выполняет локальный запрос
     ↓
  (session-id)
```

Существующие команды CLI:
```bash
novel intro --session {session-id}   # Загрузить данные из Dreams
novel write --session {session-id}    # Использовать конфигурацию Dreams для написания
```

### 3.3 Архитектура базы данных

Dreams использует Prisma + MySQL:

```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  books     Book[]
  sessions  Session[]
}

model Book {
  id          String    @id @default(cuid())
  title       String
  userId      String
  user        User      @relation(...)
  chapters    Chapter[]
}

model Session {
  id          String   @id @default(cuid())
  userId      String
  data        Json
  createdAt   DateTime
}
```

---

## 4. Проектирование архитектуры интеграции

### 4.1 Общая архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                     Dreams Web UI                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Формы конфиг. глав │  │ Рынок пресетов │  │ Управление конфиг. │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ tRPC API (типобезопасный)
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Dreams Backend (Next.js API)                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Сервис конфиг. │  │ Сервис       │  │ Сервис       │      │
│  │ глав         │  │ управления   │  │ сессий       │      │
│  └──────────────┘  │ пресетами    │  └──────────────┘      │
│                    └──────────────┘                          │
│                    ┌──────────────┐                          │
│                    │   База данных │ (MySQL + Prisma)         │
│                    └──────────────┘                          │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ ID сессии / API ключ
                              ▼
┌─────────────────────────────────────────────────────────────┐
│               novel-writer-cn CLI                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Команды конфиг.│  │ write.md     │  │ Локальное     │      │
│  │ глав         │  │ (slash cmd) │  │ хранилище YAML│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Поток данных

#### 4.2.1 Процесс создания конфигурации через Web

```
1. Пользователь заполняет форму конфигурации главы в Dreams Web
   ↓
2. Фронтенд отправляет запрос в tRPC API: chapterConfig.create()
   ↓
3. Бэкенд проверяет данные и сохраняет их в базе данных
   ↓
4. Создается сессия, session-id возвращается фронтенду
   ↓
5. Фронтенд отображает подсказку для CLI:
   novel chapter-config pull --session {session-id}
   ↓
6. Пользователь выполняет команду в CLI, загружая конфигурацию в локальную среду
   ↓
7. Локально сохраняется как .novel/chapters/chapter-X-config.yaml
   ↓
8. Пользователь выполняет команду /write, которая автоматически загружает локальный конфигурационный файл
```

#### 4.2.2 Процесс отправки конфигурации из CLI (двусторонняя синхронизация)

```
1. Пользователь создает конфигурацию в CLI:
   novel chapter-config create 5 --interactive
   ↓
2. Локально сохраняется файл chapter-5-config.yaml
   ↓
3. Пользователь выполняет команду отправки:
   novel chapter-config push 5
   ↓
4. CLI считывает локальный YAML и вызывает API Dreams
   ↓
5. Dreams сохраняет данные в базе данных, связывая их с произведением пользователя
   ↓
6. Возвращается config-id, CLI обновляет локальные метаданные
```

### 4.3 Стратегия хранения

| Место хранения | Тип данных | Назначение | Способ синхронизации |
|-----------------|------------|------------|----------------------|
| Локальные файлы CLI | chapter-X-config.yaml | Прямое чтение при написании | Основное хранилище |
| База данных Dreams | Записи ChapterConfig | Облачное резервное копирование, меж-устройственная синхронизация | pull/push |
| Сессия Dreams | Временные данные конфигурации | Передача данных Web → CLI | session-id |
| Метаданные CLI | .novel/meta/sync.json | Запись состояния синхронизации | Локальное управление |

**Пример метаданных синхронизации**:
```json
{
  "chapters": {
    "5": {
      "local_path": ".novel/chapters/chapter-5-config.yaml",
      "remote_id": "cuid_abc123",
      "last_synced": "2025-10-14T10:30:00Z",
      "hash": "sha256_hash_value"
    }
  },
  "last_pull": "2025-10-14T08:00:00Z"
}
```

---

## 5. Дизайн веб-интерфейса

### 5.1 Структура страницы

#### 5.1.1 Страница создания конфигурации главы

**Маршрут**: `/app/(dashboard)/books/[bookId]/chapters/[chapterId]/config`

**Макет**:
```
┌────────────────────────────────────────────────────────────┐
│ 【Назад】 Конфигурация главы 5 - Первое появление     【Сохранить】  │
├────────────────────────────────────────────────────────────┤
│                                                              │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│ │ Основная инф.│  │ Персонажи    │  │ Стиль сюжета │      │
│ └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│ ╔════════════════ Основная информация ════════════════╗               │
│ ║ Номер главы: [  5  ]  Название главы: [Первое появление  ]  ║               │
│ ║                                           ║               │
│ ║ Использовать пресет: [Выбрать пресет ▼]  или  [С нуля]   ║               │
│ ╚══════════════════════════════════════════════════════╝               │
│                                                              │
│ ╔════════════════ Появляющиеся персонажи ════════════════╗               │
│ ║ [+ Добавить персонажа]                              ║               │
│ ║                                           ║               │
│ ║ ┌─ Персонаж 1: Ли Чен (Главный герой)─────────────┐    ║               │
│ ║ │ Уровень участия: ● Высокий  ○ Средний  ○ Низкий │    ║               │
│ ║ │ Изменения состояния:                         │    ║               │
│ ║ │ • Получил ранение (легкое)                    │    ║               │
│ ║ │ • Уровень силы повышен                        │    ║               │
│ ║ └───────────────────────────────────────────────────┘    ║               │
│ ╚══════════════════════════════════════════════════════╝               │
│                                                              │
│ ╔════════════════ Настройки сцены ════════════════╗               │
│ ║ Место: [Заброшенный завод ▼]  Время: [Полночь]     ║               │
│ ║ Погода: [Сильный дождь ▼]                         ║               │
│ ║ Атмосфера: [Напряженная ▼]                         ║               │
│ ╚═══════════════════════════════════════════╝               │
│                                                              │
│ ╔════════════════ Тип сюжета ════════════════╗               │
│ ║ Тип: [Конфронтация ▼]                       ║               │
│ ║                                           ║               │
│ ║ Краткое содержание сюжета:                  ║               │
│ ║ ┌───────────────────────────────────┐    ║               │
│ ║ │ Главный герой впервые сталкивается... │    ║               │
│ ║ └───────────────────────────────────┘    ║               │
│ ║                                           ║               │
│ ║ Ключевые сюжетные точки:                    ║               │
│ ║ • Внезапное нападение злодея               ║               │
│ ║ • Напряжённая драка                         ║               │
│ ║ [+ Добавить сюжетную точку]                 ║               │
│ ╚═══════════════════════════════════════════╝               │
│                                                              │
│ ╔════════════════ Стиль письма ════════════════╗               │
│ ║ Темп: ● Быстрый  ○ Средний  ○ Медленный       ║               │
│ ║ Длина предложений: ● Короткие  ○ Средние  ○ Длинные ║               │
│ ║ Акцент: ☑ Действие  ☐ Диалог  ☐ Психология  ☐ Окружение ║               │
│ ║ Тон: [Серьёзный ▼]                          ║               │
│ ╚═══════════════════════════════════════════╝               │
│                                                              │
│ ╔════════════════ Требования к объёму ════════════════╗               │
│ ║ Целевой объём: [ 3500 ]                       ║               │
│ ║ Минимальный объём: [ 3000 ]  Максимальный объём: [ 4000 ] ║               │
│ ╚═══════════════════════════════════════════╝               │
│                                                              │
│ ╔════════════════ Особые требования ════════════════╗               │
│ ║ ┌───────────────────────────────────┐    ║               │
│ ║ │ Требования к написанию экшн-сцен:   │    ║               │
│ ║ │ - Преимущественно короткие предложения │    ║               │
│ ║ │ - Длина предложения 15-25 символов   │    ║               │
│ ║ │ ...                                │    ║               │
│ ║ └───────────────────────────────────┘    ║               │
│ ╚═══════════════════════════════════════════╝               │
│                                                              │
│          ┌────────┐  ┌────────┐  ┌────────┐               │
│          │ Сохранить черновик │  │ Предпросмотр │  │ Сгенерировать CLI│               │
│          └────────┘  └────────┘  └────────┘               │
└────────────────────────────────────────────────────────────┘
```

#### 5.1.2 Страница магазина пресетов

**Маршрут**: `/app/(dashboard)/presets`

**Макет**:
```
┌────────────────────────────────────────────────────────────┐
│ Магазин пресетов шаблонов                     [Поиск]  [Фильтр▼]    │
├────────────────────────────────────────────────────────────┤
│                                                              │
│ Категории: [Все] [Экшн] [Диалоги] [Эмоции] [Саспенс] [...] │
│                                                              │
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│ │ Сцена экшена │  │ Сцена диалогов │  │ Сцена признаний │         │
│ │             │  │             │  │             │         │
│ │ Подходит для описания драк, погонь │ Подходит для переговоров, │ Подходит для признаний, │
│ │ и других высокоинтенсивных сцен │ споров и других сцен, │ примирений и других │
│ │             │  │ основанных на диалогах │ эмоциональных сцен │
│ │             │  │             │  │             │         │
│ │ ⭐4.8 · 1.2k │  │ ⭐4.7 · 890 │  │ ⭐4.9 · 2.1k │         │
│ │ [Использовать пресет] │  │ [Использовать пресет] │  │ [Использовать пресет] │         │
│ └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                              │
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│ │ Сцена нагнетания саспенса │  │ Сцена развития отношений │  │ Сцена демонстрации способностей │         │
│ │ ...          │  │ ...          │  │ ...          │         │
│ └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                              │
└────────────────────────────────────────────────────────────┘
```

При нажатии на карточку пресета отображается всплывающее окно с деталями:
```
┌────────────────────────────────────────────────────────────┐
│ Сцена экшена                                      [Закрыть×] │
├────────────────────────────────────────────────────────────┤
│ Версия: v1.0.0                                              │
│ Автор: Novel Writer Official                               │
│ Категория: Сценарный пресет                                 │
│                                                              │
│ 📝 Описание:                                                 │
│ Подходит для описания драк, погонь и других высокоинтенсивных │
│ сцен, быстрый темп, короткие предложения, плотное действие. │
│                                                              │
│ ⚙️ Настройки по умолчанию:                                   │
│ • Темп: Быстрый                                             │
│ • Длина предложений: Короткие                               │
│ • Акцент: Действие                                          │
│ • Целевой объём: 3000 слов                                  │
│                                                              │
│ 📚 Рекомендуемые сцены:                                     │
│ • Конфронтация                                              │
│ • Финальная битва                                           │
│ • Сцены погони                                              │
│                                                              │
│ 🎭 Совместимые жанры:                                       │
│ Фэнтези · Уся · Городское фэнтези · Научная фантастика/Меха │
│                                                              │
│ 💡 Советы по использованию:                                 │
│ • Подходит для кульминации главы, не следует использовать слишком часто │
│ • Рекомендуется использовать с короткими главами (2000-3500 слов) │
│ • Требует предыстории и заключительной части                 │
│                                                              │
│          ┌────────────┐  ┌────────────┐                    │
│          │ Использовать этот пресет │  │ Посмотреть пример │                    │
│          └────────────┘  └────────────┘                    │
└────────────────────────────────────────────────────────────┘
```

#### 5.1.3 Страница управления конфигурациями

**Маршрут**: `/app/(dashboard)/books/[bookId]/configs`

**Макет**:
```
┌────────────────────────────────────────────────────────────┐
│ Управление конфигурациями глав - «Перерождение городского мастера боевых искусств»            [Новая конфигурация+] │
├────────────────────────────────────────────────────────────┤
│ Фильтр: [Все] [Завершено] [Черновик] [Не синхронизировано]        Сортировка: [Номер главы▼]│
│                                                              │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ Глава 5: Первый показ мастерства                          [Редактировать] [Удалить] │   │
│ │ Тип: Демонстрация способностей | Объем: 3000 | Статус: ✓ Синхронизировано │   │
│ │ Создано: 2025-10-14 | Последнее изменение: 2025-10-14 10:30 │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ Глава 8: Первая схватка                          [Редактировать] [Удалить] │   │
│ │ Тип: Конфронтация | Объем: 3500 | Статус: ⚠ Не синхронизировано │   │
│ │ Создано: 2025-10-14 | Последнее изменение: 2025-10-14 15:30 │   │
│ │ [Синхронизировать с CLI]                                  │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ Глава 15: Взаимопонимание                      [Править] [Удалить] │   │
│ │ Тип: Развитие отношений  |  Объем: 2500  |  Статус: 📝 Черновик      │   │
│ │ Создано: 2025-10-14  |  Последнее изменение: 2025-10-14 16:00       │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
└────────────────────────────────────────────────────────────┘
```

### 5.2 Сопоставление YAML-форм

Система YAML-форм Dreams позволяет напрямую сопоставлять конфигурации глав:

```yaml
# forms/chapter-config.yaml
form_id: chapter-config
title: Конфигурация главы
version: 1.0.0

fields:
  # Основная информация
  - id: chapter
    type: number
    label: Номер главы
    required: true
    min: 1

  - id: title
    type: text
    label: Название главы
    required: true

  - id: preset_id
    type: select
    label: Использовать пресет (необязательно)
    options_source: api  # Динамическая загрузка списка пресетов из API
    endpoint: /api/presets/list

  # Раздел персонажей
  - id: characters
    type: array
    label: Появляющиеся персонажи
    min_items: 1
    item_schema:
      - id: character_id
        type: select
        label: Выбрать персонажа
        options_source: api
        endpoint: /api/characters/list?bookId={bookId}

      - id: focus
        type: radio
        label: Роль в сюжете
        options:
          - {value: high, label: Главная}
          - {value: medium, label: Второстепенная}
          - {value: low, label: Эпизодическая}
        default: medium

      - id: state_changes
        type: array
        label: Изменения состояния
        item_type: text

  # Раздел сцены
  - id: scene.location_id
    type: select
    label: Место действия
    options_source: api
    endpoint: /api/locations/list?bookId={bookId}

  - id: scene.time
    type: text
    label: Время действия
    placeholder: Например: 10 утра, полночь, рассвет

  - id: scene.weather
    type: text
    label: Погода
    placeholder: Например: ясно, сильный дождь, пасмурно

  - id: scene.atmosphere
    type: select
    label: Атмосфера
    options:
      - {value: tense, label: Напряженная}
      - {value: relaxed, label: Расслабленная}
      - {value: sad, label: Грустная}
      - {value: exciting, label: Волнующая}
      - {value: mysterious, label: Таинственная}

  # Раздел сюжета
  - id: plot.type
    type: select
    label: Тип сюжета
    required: true
    options:
      - {value: ability_showcase, label: Демонстрация способностей}
      - {value: relationship_dev, label: Развитие отношений}
      - {value: conflict_combat, label: Конфликт/Поединок}
      - {value: mystery_suspense, label: Загадка/Напряжение}
      - {value: plot_twist, label: Поворот сюжета}
      - {value: climax, label: Кульминация/Противостояние}

  - id: plot.summary
    type: textarea
    label: Краткое содержание сюжета
    required: true
    rows: 3
    placeholder: Опишите основной сюжет главы в одном-двух предложениях

  - id: plot.key_points
    type: array
    label: Ключевые моменты сюжета
    item_type: text
    min_items: 1

  # Стиль письма
  - id: style.pace
    type: radio
    label: Темп повествования
    options:
      - {value: fast, label: Быстрый}
      - {value: medium, label: Средний}
      - {value: slow, label: Медленный}
    default: medium

  - id: style.sentence_length
    type: radio
    label: Длина предложений
    options:
      - {value: short, label: Короткие}
      - {value: medium, label: Средние}
      - {value: long, label: Длинные}
    default: medium

  - id: style.focus
    type: checkbox
    label: Акцент в описании (множественный выбор)
    options:
      - {value: action, label: Действие}
      - {value: dialogue, label: Диалог}
      - {value: psychology, label: Психология}
      - {value: environment, label: Окружение}
    min_selections: 1

  - id: style.tone
    type: select
    label: Тон повествования
    options:
      - {value: light, label: Легкий}
      - {value: serious, label: Серьезный}
      - {value: dark, label: Мрачный}
      - {value: humorous, label: Юмористический}

  # Требования к объему
  - id: wordcount.target
    type: number
    label: Целевой объем
    required: true
    min: 1000
    max: 10000
    default: 3000

  - id: wordcount.min
    type: number
    label: Минимальный объем
    required: true
    min: 500

  - id: wordcount.max
    type: number
    label: Максимальный объем
    required: true
    max: 15000

  # Особые требования
  - id: special_requirements
    type: textarea
    label: Особые указания по написанию
    rows: 8
    placeholder: Подробные инструкции и замечания по написанию

validation:
  # Пользовательские правила валидации
  - rule: wordcount.min < wordcount.target < wordcount.max
    message: Целевой объем должен быть между минимальным и максимальным
```

### 5.3 Повторное использование UI-компонентов

Существующие компоненты shadcn/ui в Dreams могут быть использованы напрямую:

- `<Form>` / `<FormField>` - Базовые компоненты формы
- `<Input>` / `<Textarea>` - Поля ввода
- `<Select>` - Выпадающий список
- `<RadioGroup>` - Группа переключателей
- `<Checkbox>` - Флажок
- `<Button>` - Кнопка
- `<Card>` - Контейнер карточки
- `<Dialog>` - Диалоговое окно
- `<Tabs>` - Вкладки

**Новые компоненты**:
- `<ArrayFieldEditor>` - Редактор полей массива (для списков персонажей, ключевых моментов сюжета)
- `<PresetSelector>` - Селектор пресетов (с функцией предварительного просмотра)
- `<ConfigPreview>` - Компонент предварительного просмотра конфигурации (отображение в формате YAML)

---

## 6. API-дизайн

### 6.1 tRPC Router: chapterConfigRouter

```typescript
// server/api/routers/chapterConfig.ts

import { z } from 'zod';
import { router, protectedProcedure } from '../trpc';

// Zod Schema (соответствует JSON Schema)
const ChapterConfigSchema = z.object({
  chapter: z.number().int().min(1),
  title: z.string().min(1),
  characters: z.array(z.object({
    id: z.string(),
    name: z.string(),
    focus: z.enum(['high', 'medium', 'low']),
    state_changes: z.array(z.string()).optional(),
  })).optional(),
  scene: z.object({
    location_id: z.string().optional(),
    location_name: z.string().optional(),
    time: z.string().optional(),
    weather: z.string().optional(),
    atmosphere: z.enum([
      'tense', 'relaxed', 'sad', 'exciting',
      'mysterious', 'romantic'
    ]).optional(),
  }).optional(),
  plot: z.object({
    type: z.enum([
      'ability_showcase', 'relationship_dev', 'conflict_combat',
      'mystery_suspense', 'plot_twist', 'climax', 'transition'
    ]),
    summary: z.string(),
    key_points: z.array(z.string()),
    plotlines: z.array(z.string()).optional(),
    foreshadowing: z.array(z.object({
      id: z.string(),
      content: z.string(),
    })).optional(),
  }),
  style: z.object({
    pace: z.enum(['fast', 'medium', 'slow']),
    sentence_length: z.enum(['short', 'medium', 'long']),
    focus: z.array(z.enum([
      'action', 'dialogue', 'psychology', 'environment'
    ])),
    tone: z.enum(['light', 'serious', 'dark', 'humorous']),
  }).optional(),
  wordcount: z.object({
    target: z.number().int().min(1000).max(10000),
    min: z.number().int().min(500),
    max: z.number().int().max(15000),
  }),
  special_requirements: z.string().optional(),
  preset_used: z.string().optional(),
});

export const chapterConfigRouter = router({
  // Создание конфигурации
  create: protectedProcedure
    .input(z.object({
      bookId: z.string(),
      config: ChapterConfigSchema,
    }))
    .mutation(async ({ ctx, input }) => {
      const { bookId, config } = input;
      const userId = ctx.session.user.id;

      // 1. Проверка принадлежности книги
      const book = await ctx.db.book.findUnique({
        where: { id: bookId },
      });

      if (!book || book.userId !== userId) {
        throw new Error('Книга не найдена или доступ запрещен');
      }

      // 2. Проверка на конфликт номеров глав
      const existing = await ctx.db.chapterConfig.findUnique({
        where: {
          bookId_chapter: {
            bookId,
            chapter: config.chapter,
          },
        },
      });

      if (existing) {
        throw new Error(`Конфигурация для главы ${config.chapter} уже существует`);
      }

      // 3. Создание записи конфигурации
      const chapterConfig = await ctx.db.chapterConfig.create({
        data: {
          bookId,
          chapter: config.chapter,
          title: config.title,
          configData: config, // Полная конфигурация сохраняется в JSON-поле
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      });

      // 4. Создание сессии (для получения через CLI)
      const session = await ctx.db.session.create({
        data: {
          userId,
          type: 'chapter-config',
          data: {
            configId: chapterConfig.id,
            bookId,
            chapter: config.chapter,
            config,
          },
          expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 часа
        },
      });

      return {
        configId: chapterConfig.id,
        sessionId: session.id,
        cliCommand: `novel chapter-config pull --session ${session.id}`,
      };
    }),

  // Получение списка конфигураций
  list: protectedProcedure
    .input(z.object({
      bookId: z.string(),
    }))
    .query(async ({ ctx, input }) => {
      const { bookId } = input;
      const userId = ctx.session.user.id;

      // Проверка прав доступа
      const book = await ctx.db.book.findUnique({
        where: { id: bookId },
      });

      if (!book || book.userId !== userId) {
        throw new Error('Доступ запрещен');
      }

      // Получение списка конфигураций
      const configs = await ctx.db.chapterConfig.findMany({
        where: { bookId },
        orderBy: { chapter: 'asc' },
        select: {
          id: true,
          chapter: true,
          title: true,
          configData: true,
          createdAt: true,
          updatedAt: true,
          syncStatus: true,
        },
      });

      return configs.map(config => ({
        id: config.id,
        chapter: config.chapter,
        title: config.title,
        plotType: (config.configData as any).plot?.type,
        wordcount: (config.configData as any).wordcount?.target,
        syncStatus: config.syncStatus,
        createdAt: config.createdAt,
        updatedAt: config.updatedAt,
      }));
    }),

  // Получение одной конфигурации
  get: protectedProcedure
    .input(z.object({
      configId: z.string(),
    }))
    .query(async ({ ctx, input }) => {
      const { configId } = input;
      const userId = ctx.session.user.id;

      const config = await ctx.db.chapterConfig.findUnique({
        where: { id: configId },
        include: { book: true },
      });

      if (!config || config.book.userId !== userId) {
        throw new Error('Конфигурация не найдена или доступ запрещен');
      }

      return {
        id: config.id,
        bookId: config.bookId,
        chapter: config.chapter,
        title: config.title,
        config: config.configData,
        createdAt: config.createdAt,
        updatedAt: config.updatedAt,
      };
    }),

  // Обновление конфигурации
  update: protectedProcedure
    .input(z.object({
      configId: z.string(),
      config: ChapterConfigSchema.partial(),
    }))
    .mutation(async ({ ctx, input }) => {
      const { configId, config } = input;
      const userId = ctx.session.user.id;

      // Проверка прав доступа
      const existing = await ctx.db.chapterConfig.findUnique({
        where: { id: configId },
        include: { book: true },
      });

      if (!existing || existing.book.userId !== userId) {
        throw new Error('Доступ запрещен');
      }

      // Слияние конфигураций
      const mergedConfig = {
        ...(existing.configData as any),
        ...config,
      };

      // Обновление записи
      const updated = await ctx.db.chapterConfig.update({
        where: { id: configId },
        data: {
          configData: mergedConfig,
          updatedAt: new Date(),
          syncStatus: 'pending', // Отметка о необходимости синхронизации
        },
      });

      return {
        configId: updated.id,
        config: updated.configData,
      };
    }),

  // Удаление конфигурации
  delete: protectedProcedure
    .input(z.object({
      configId: z.string(),
    }))
    .mutation(async ({ ctx, input }) => {
      const { configId } = input;
      const userId = ctx.session.user.id;

      // Проверка прав доступа
      const existing = await ctx.db.chapterConfig.findUnique({
        where: { id: configId },
        include: { book: true },
      });

      if (!existing || existing.book.userId !== userId) {
        throw new Error('Unauthorized');
      }

      // Удаление записи
      await ctx.db.chapterConfig.delete({
        where: { id: configId },
      });

      return { success: true };
    }),

  // Получение конфигурации из сессии (вызов CLI)
  pullFromSession: protectedProcedure
    .input(z.object({
      sessionId: z.string(),
    }))
    .query(async ({ ctx, input }) => {
      const { sessionId } = input;
      const userId = ctx.session.user.id;

      // Получение сессии
      const session = await ctx.db.session.findUnique({
        where: { id: sessionId },
      });

      if (!session || session.userId !== userId) {
        throw new Error('Session not found or unauthorized');
      }

      if (session.expiresAt < new Date()) {
        throw new Error('Session expired');
      }

      // Возврат данных конфигурации
      const sessionData = session.data as any;
      return {
        bookId: sessionData.bookId,
        chapter: sessionData.chapter,
        config: sessionData.config,
      };
    }),

  // Отправка конфигурации в облако (вызов CLI)
  push: protectedProcedure
    .input(z.object({
      bookId: z.string(),
      chapter: z.number(),
      config: ChapterConfigSchema,
      localHash: z.string(), // Хеш локального файла
    }))
    .mutation(async ({ ctx, input }) => {
      const { bookId, chapter, config, localHash } = input;
      const userId = ctx.session.user.id;

      // Проверка прав доступа
      const book = await ctx.db.book.findUnique({
        where: { id: bookId },
      });

      if (!book || book.userId !== userId) {
        throw new Error('Unauthorized');
      }

      // Upsert конфигурации
      const chapterConfig = await ctx.db.chapterConfig.upsert({
        where: {
          bookId_chapter: { bookId, chapter },
        },
        create: {
          bookId,
          chapter,
          title: config.title,
          configData: config,
          localHash,
          syncStatus: 'synced',
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        update: {
          configData: config,
          localHash,
          syncStatus: 'synced',
          updatedAt: new Date(),
        },
      });

      return {
        configId: chapterConfig.id,
        remoteHash: localHash,
        syncStatus: 'synced',
      };
    }),

  // Проверка статуса синхронизации (вызов CLI)
  checkSyncStatus: protectedProcedure
    .input(z.object({
      bookId: z.string(),
      chapters: z.array(z.object({
        chapter: z.number(),
        localHash: z.string(),
      })),
    }))
    .query(async ({ ctx, input }) => {
      const { bookId, chapters } = input;
      const userId = ctx.session.user.id;

      // Проверка прав доступа
      const book = await ctx.db.book.findUnique({
        where: { id: bookId },
      });

      if (!book || book.userId !== userId) {
        throw new Error('Unauthorized');
      }

      // Пакетный запрос удаленных конфигураций
      const remoteConfigs = await ctx.db.chapterConfig.findMany({
        where: {
          bookId,
          chapter: { in: chapters.map(c => c.chapter) },
        },
        select: {
          chapter: true,
          localHash: true,
          updatedAt: true,
        },
      });

      // Сравнение хешей
      const syncStatuses = chapters.map(local => {
        const remote = remoteConfigs.find(r => r.chapter === local.chapter);

        if (!remote) {
          return {
            chapter: local.chapter,
            status: 'not_synced',
            needsPush: true,
          };
        }

        if (remote.localHash !== local.localHash) {
          return {
            chapter: local.chapter,
            status: 'conflict',
            needsResolve: true,
            remoteUpdatedAt: remote.updatedAt,
          };
        }

        return {
          chapter: local.chapter,
          status: 'synced',
        };
      });

      return { syncStatuses };
    }),
});
```

### 6.2 Маршрутизатор пресетов

```typescript
// server/api/routers/preset.ts

export const presetRouter = router({
  // Получение списка пресетов
  list: protectedProcedure
    .input(z.object({
      category: z.enum(['scene', 'style', 'genre']).optional(),
      search: z.string().optional(),
    }))
    .query(async ({ ctx, input }) => {
      const { category, search } = input;

      const presets = await ctx.db.preset.findMany({
        where: {
          ...(category && { category }),
          ...(search && {
            OR: [
              { name: { contains: search } },
              { description: { contains: search } },
            ],
          }),
        },
        orderBy: [
          { featured: 'desc' },
          { rating: 'desc' },
          { usageCount: 'desc' },
        ],
      });

      return presets;
    }),

  // Получение деталей пресета
  get: protectedProcedure
    .input(z.object({
      presetId: z.string(),
    }))
    .query(async ({ ctx, input }) => {
      const preset = await ctx.db.preset.findUnique({
        where: { id: input.presetId },
        include: {
          author: {
            select: {
              name: true,
              avatar: true,
            },
          },
        },
      });

      if (!preset) {
        throw new Error('Preset not found');
      }

      return preset;
    }),

  // Применение пресета к конфигурации
  applyToConfig: protectedProcedure
    .input(z.object({
      presetId: z.string(),
      baseConfig: ChapterConfigSchema.partial(),
    }))
    .mutation(async ({ ctx, input }) => {
      const { presetId, baseConfig } = input;

      // Получение пресета
      const preset = await ctx.db.preset.findUnique({
        where: { id: presetId },
      });

      if (!preset) {
        throw new Error('Preset not found');
      }

      // Слияние значений по умолчанию пресета
      const presetData = preset.configData as any;
      const mergedConfig = {
        ...baseConfig,
        style: {
          ...presetData.defaults?.style,
          ...baseConfig.style,
        },
        wordcount: {
          ...presetData.defaults?.wordcount,
          ...baseConfig.wordcount,
        },
        special_requirements: presetData.defaults?.special_requirements || '',
        preset_used: presetId,
      };

      // Увеличение счетчика использований
      await ctx.db.preset.update({
        where: { id: presetId },
        data: {
          usageCount: { increment: 1 },
        },
      });

      return { config: mergedConfig };
    }),
});
```

### 6.3 Обновление схемы базы данных

```prisma
// prisma/schema.prisma

model ChapterConfig {
  id          String   @id @default(cuid())
  bookId      String
  chapter     Int
  title       String
  configData  Json     // Полная JSON-конфигурация главы
  localHash   String?  // Хеш локального файла
  syncStatus  String   @default("not_synced") // synced, pending, conflict

  book        Book     @relation(fields: [bookId], references: [id], onDelete: Cascade)

  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  @@unique([bookId, chapter])
  @@index([bookId])
  @@map("chapter_configs")
}

model Preset {
  id              String   @id @default(cuid())
  presetId        String   @unique // Например, "action-intense"
  name            String
  description     String
  category        String   // scene, style, genre
  configData      Json     // Данные конфигурации пресета

  authorId        String
  author          User     @relation(fields: [authorId], references: [id])

  featured        Boolean  @default(false)
  rating          Float    @default(0)
  ratingCount     Int      @default(0)
  usageCount      Int      @default(0)

  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  @@index([category])
  @@index([featured, rating])
  @@map("presets")
}

model Session {
  id          String   @id @default(cuid())
  userId      String
  type        String   // intro, chapter-config, etc.
  data        Json
  expiresAt   DateTime

  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  createdAt   DateTime @default(now())

  @@index([userId])
  @@index([expiresAt])
  @@map("sessions")
}

// Расширение существующей модели Book
model Book {
  // ... существующие поля
  chapterConfigs  ChapterConfig[]
}
```

---

## 7. Механизм синхронизации сессий

### 7.1 Процесс синхронизации

#### Вариант A: Односторонняя синхронизация на основе сессий (v1.0 MVP)

**Сценарий использования**: Создание в Web → Использование в CLI

```
┌──────────────┐
│  Dreams Web  │
│  Создание конфи│
└───────┬──────┘
        │
        │ 1. POST /api/chapterConfig/create
        ▼
┌──────────────┐
│   Backend    │
│ Хранение +   │
│ создание     │
│  сессии      │
└───────┬──────┘
        │
        │ 2. Возврат session-id
        ▼
┌──────────────┐
│  Копирование  │
│  пользователем│
│  команды CLI  │
└───────┬──────┘
        │
        │ 3. novel chapter-config pull --session {id}
        ▼
┌──────────────┐
│   CLI        │
│ GET /api/    │
│ pullFromSession
└───────┬──────┘
        │
        │ 4. Загрузка данных конфигурации
        ▼
┌──────────────┐
│ Локальное     │
│ сохранение   │
│  YAML файла   │
└──────────────┘
```

**Преимущества**:
- Просто и надежно
- Не требует сложной логики синхронизации
- Сессии имеют время истечения, автоматическая очистка

**Недостатки**:
- Односторонняя синхронизация, не поддерживает CLI → Web
- Требуется ручное копирование команды

#### Вариант B: Двусторонняя синхронизация на основе хешей (v2.0+)

**Сценарий использования**: Двусторонняя синхронизация CLI ↔ Web

```
┌──────────────┐              ┌──────────────┐
│   Локальный  │              │  Dreams Web  │
│     CLI      │              │              │
│ chapter-5-   │◀────┐        │              │
│ config.yaml  │     │        │              │
│              │     │        │              │
│ hash: abc123 │     │        │              │
└──────┬───────┘     │        └──────┬───────┘
       │             │               │
       │ 1. novel    │               │ 5. Просмотр в Web
       │ chapter-    │               │ /configs
       │ config      │               │
       │ sync        │               │
       │             │               ▼
       │             │        ┌──────────────┐
       │             │        │   Backend    │
       │             │        │              │
       │             │        │ Удаленная БД:│
       │             └────────│ hash: xyz789 │
       │                      │              │
       │ 2. checkSyncStatus   │              │
       ├─────────────────────▶│              │
       │                      │              │
       │ 3. Возврат статуса   │              │
       │    conflict!         │              │
       │◀─────────────────────┤              │
       │                      │              │
       │ 4. Выбор пользователя:│              │
       │    - pull（拉取远程）│              │
       │    - merge（合并）   │              │
       │                      │              │
       │ novel chapter-config │              │
       │ push 5 --force       │              │
       ├─────────────────────▶│              │
       │                      │ обновление hash │
       │                      │ hash: abc123 │
       │◀─────────────────────┤              │
       │  синхронизация успешна│              │
       │                      └──────────────┘
```

**Расчет хэша**:
```typescript
import crypto from 'crypto';

function calculateConfigHash(config: ChapterConfig): string {
  // Исключаем поля метаданных (created_at, updated_at и т.д.)
  const stableConfig = {
    chapter: config.chapter,
    title: config.title,
    characters: config.characters,
    scene: config.scene,
    plot: config.plot,
    style: config.style,
    wordcount: config.wordcount,
    special_requirements: config.special_requirements,
  };

  // Сортируем ключи для обеспечения единообразия
  const canonical = JSON.stringify(stableConfig, Object.keys(stableConfig).sort());

  // Вычисляем хэш SHA-256
  return crypto.createHash('sha256').update(canonical).digest('hex');
}
```

**Стратегия разрешения конфликтов**:

1. **Автоматическое разрешение**: Приоритет временной метки
   ```bash
   novel chapter-config sync --auto
   # Автоматически выбирается последняя версия
   ```

2. **Ручное разрешение**: Трехстороннее сравнение
   ```bash
   novel chapter-config sync 5
   # Показать детали конфликта:
   # Local:  modified 2025-10-14 15:30
   # Remote: modified 2025-10-14 16:00
   #
   # Выберите действие:
   #   1. Использовать локальную версию (перезаписать удаленную)
   #   2. Использовать удаленную версию (перезаписать локальную)
   #   3. Ручное слияние (открыть редактор)
   ```

3. **Стратегия слияния**: Слияние на уровне полей
   ```typescript
   // Поля без конфликтов сливаются автоматически
   // Поля с конфликтами запрашивают выбор пользователя
   function mergeConfigs(
     local: ChapterConfig,
     remote: ChapterConfig,
     base: ChapterConfig
   ): ChapterConfig {
     const merged = { ...base };

     for (const key of Object.keys(local)) {
       if (JSON.stringify(local[key]) === JSON.stringify(base[key])) {
         // Локальное не изменено, использовать удаленное
         merged[key] = remote[key];
       } else if (JSON.stringify(remote[key]) === JSON.stringify(base[key])) {
         // Удаленное не изменено, использовать локальное
         merged[key] = local[key];
       } else {
         // Изменено обеими сторонами, записать конфликт
         conflicts.push(key);
       }
     }

     return merged;
   }
   ```

### 7.2 Проектирование команды синхронизации

```bash
# Загрузка (Web → CLI)
novel chapter-config pull --session {session-id}
novel chapter-config pull 5 --remote  # Загрузить конфигурацию главы 5 из облака

# Отправка (CLI → Web)
novel chapter-config push 5
novel chapter-config push 5 --force   # Принудительно перезаписать удаленную конфигурацию

# Синхронизация (двусторонняя интеллектуальная синхронизация)
novel chapter-config sync              # Синхронизировать все конфигурации
novel chapter-config sync 5            # Синхронизировать главу 5
novel chapter-config sync --auto       # Автоматически разрешать конфликты

# Проверка статуса синхронизации
novel chapter-config status
# Пример вывода:
# Chapter 5: ✓ Synced (last synced: 2025-10-14 10:30)
# Chapter 8: ⚠ Conflict (local: 15:30, remote: 16:00)
# Chapter 15: ↑ Not synced (local changes, need push)
```

### 7.3 Реализация CLI

```typescript
// src/commands/chapter-config.ts

import { Command } from 'commander';
import { ChapterConfigManager } from '../lib/chapter-config';
import { DreamsClient } from '../lib/dreams-client';

export function registerChapterConfigCommands(program: Command) {
  const chapterConfig = program
    .command('chapter-config')
    .description('Управление конфигурацией глав');

  // команда pull
  chapterConfig
    .command('pull')
    .description('Загрузить конфигурацию из Dreams')
    .option('--session <id>', 'ID сессии')
    .option('--remote', 'Загрузить из облака')
    .argument('[chapter]', 'Номер главы')
    .action(async (chapter, options) => {
      const manager = new ChapterConfigManager();
      const client = new DreamsClient();

      if (options.session) {
        // Режим сессии
        const data = await client.pullFromSession(options.session);
        const config = data.config;

        await manager.saveConfig(config);
        console.log(`✓ Конфигурация сохранена в .novel/chapters/chapter-${config.chapter}-config.yaml`);
      } else if (options.remote && chapter) {
        // Режим удаленной загрузки
        const bookId = await manager.getCurrentBookId();
        const config = await client.getConfig(bookId, parseInt(chapter));

        await manager.saveConfig(config);
        console.log(`✓ Конфигурация главы ${chapter} загружена из облака`);
      } else {
        console.error('Ошибка: необходимо указать опцию --session или --remote');
        process.exit(1);
      }
    });

  // команда push
  chapterConfig
    .command('push <chapter>')
    .description('Отправить конфигурацию в Dreams')
    .option('--force', 'Принудительно перезаписать удаленную конфигурацию')
    .action(async (chapter, options) => {
      const manager = new ChapterConfigManager();
      const client = new DreamsClient();

      const chapterNum = parseInt(chapter);
      const config = await manager.loadConfig(chapterNum);

      if (!config) {
        console.error(`Ошибка: конфигурация главы ${chapter} не существует`);
        process.exit(1);
      }

      const bookId = await manager.getCurrentBookId();
      const localHash = manager.calculateHash(config);

      try {
        const result = await client.pushConfig(bookId, chapterNum, config, localHash, options.force);

        // Обновить локальные метаданные
        await manager.updateSyncMetadata(chapterNum, {
          remote_id: result.configId,
          remote_hash: result.remoteHash,
          last_synced: new Date().toISOString(),
        });

        console.log(`✓ Конфигурация главы ${chapter} отправлена в облако`);
      } catch (error) {
        if (error.message.includes('conflict')) {
          console.error('⚠ Обнаружен конфликт, удаленная конфигурация была изменена');
          console.error('Используйте --force для принудительного перезаписывания или сначала выполните pull для загрузки удаленной конфигурации');
        } else {
          throw error;
        }
      }
    });

  // команда sync
  chapterConfig
    .command('sync [chapter]')
    .description('Двусторонняя синхронизация конфигурации')
    .option('--auto', 'Автоматически разрешать конфликты')
    .action(async (chapter, options) => {
      const manager = new ChapterConfigManager();
      const client = new DreamsClient();

      const bookId = await manager.getCurrentBookId();

      // Получить список локальных конфигураций
      const localConfigs = await manager.listConfigs();

      // Проверить статус синхронизации
      const statusResult = await client.checkSyncStatus(
        bookId,
        localConfigs.map(c => ({
          chapter: c.chapter,
          localHash: manager.calculateHash(c.config),
        }))
      );

      for (const status of statusResult.syncStatuses) {
        if (chapter && status.chapter !== parseInt(chapter)) {
          continue;
        }

        if (status.status === 'synced') {
          console.log(`Глава ${status.chapter}: ✓ Синхронизировано`);
        } else if (status.status === 'not_synced') {
          // Требуется отправка
          console.log(`Глава ${status.chapter}: ↑ Отправка в облако...`);
          await client.pushConfig(bookId, status.chapter, ...);
        } else if (status.status === 'conflict') {
          // Обработка конфликтов
          if (options.auto) {
            // Автоматический выбор последней версии
            if (status.remoteUpdatedAt > localUpdatedAt) {
              console.log(`Глава ${status.chapter}: ↓ Загрузка удаленной конфигурации (обновлено удаленно)...`);
              await client.getConfig(bookId, status.chapter);
            } else {
              console.log(`Глава ${status.chapter}: ↑ Отправка локальной конфигурации (обновлено локально)...`);
              await client.pushConfig(bookId, status.chapter, ..., true);
            }
          } else {
            console.log(`Глава ${status.chapter}: ⚠ Обнаружен конфликт`);
            console.log(`  Время локального изменения: ${localUpdatedAt}`);
            console.log(`  Время удаленного изменения: ${status.remoteUpdatedAt}`);

            const answer = await inquirer.prompt([{
              type: 'list',
              name: 'action',
              message: 'Выберите действие:',
              choices: [
                { name: '1. Использовать локальную версию (перезаписать удаленную)', value: 'push' },
                { name: '2. Использовать удаленную версию (перезаписать локальную)', value: 'pull' },
                { name: '3. Пропустить эту главу', value: 'skip' },
              ],
            }]);

            if (answer.action === 'push') {
              await client.pushConfig(bookId, status.chapter, ..., true);
            } else if (answer.action === 'pull') {
              await client.getConfig(bookId, status.chapter);
            }
          }
        }
      }

      console.log('\n✓ Синхронизация завершена');
    });

  // команда status
  chapterConfig
    .command('status')
    .description('Проверить статус синхронизации')
    .action(async () => {
      const manager = new ChapterConfigManager();
      const client = new DreamsClient();

      const bookId = await manager.getCurrentBookId();
      const localConfigs = await manager.listConfigs();

      const statusResult = await client.checkSyncStatus(bookId, localConfigs.map(...));

      console.log('\nСтатус синхронизации конфигурации глав:\n');

      for (const status of statusResult.syncStatuses) {
        const icon = status.status === 'synced' ? '✓' :
                     status.status === 'not_synced' ? '↑' :
                     '⚠';

        const statusText = status.status === 'synced' ? 'Синхронизировано' :
                          status.status === 'not_synced' ? 'Требуется отправка' :
                          'Конфликт';

        console.log(`  Глава ${status.chapter}: ${icon} ${statusText}`);

        if (status.status === 'conflict') {
          console.log(`    Время удаленного изменения: ${status.remoteUpdatedAt}`);
        }
      }

      console.log('');
    });
}
```

---

## 8. План поэтапной реализации

### Этап 1: Инфраструктура (2 недели)

**Цель**: Завершить базовую инфраструктуру Dreams и одностороннюю синхронизацию

**Задачи**:
1. Проектирование и миграция схемы базы данных
   - Создать таблицу `ChapterConfig`
   - Создать таблицу `Preset`
   - Расширить таблицу `Session`

2. Разработка API tRPC
   - `chapterConfigRouter`: create, list, get, update, delete, pullFromSession
   - `presetRouter`: list, get

3. Разработка команд CLI
   - `novel chapter-config pull --session`
   - Сохранение локальных YAML-файлов

4. Тестирование
   - Модульные тесты API
   - Интеграционные тесты CLI

**Результаты**:
- ✅ Файлы миграции базы данных
- ✅ Реализация tRPC Router
- ✅ Команда CLI pull
- ✅ Тестовые случаи

---

### Этап 2: Разработка Web UI (3 недели)

**Цель**: Завершить интерфейс создания конфигурации в Dreams

**Задачи**:
1. Расширение системы YAML-форм
   - Создать `forms/chapter-config.yaml`
   - Поддержка полей массивов (списки персонажей, сюжетных поворотов)
   - Поддержка динамических опций (загрузка персонажей, локаций из API)

2. Разработка страниц
   - Страница создания конфигурации главы (`/books/[id]/chapters/[chapter]/config`)
   - Страница списка конфигураций (`/books/[id]/configs`)
   - Страница результатов сессии (отображение команд CLI)

3. Разработка компонентов
   - `<ArrayFieldEditor>` - Редактор полей массивов
   - `<ConfigPreview>` - Компонент предварительного просмотра YAML
   - `<CharacterSelector>` - Селектор персонажей (с поиском)

4. Тестирование
   - Модульные тесты фронтенда
   - E2E тесты

**Результаты**:
- ✅ Конфигурация YAML-форм
- ✅ Страница создания конфигурации
- ✅ Страница списка конфигураций
- ✅ Библиотека UI-компонентов
- ✅ E2E тесты

---

### Этап 3: Система пресетов (2 недели)

**Цель**: Завершить функции рынка пресетов и применения пресетов

**Задачи**:
1. Подготовка данных пресетов
   - Создание официальных пресетов (10 шт.)
   - Метаданные пресетов (категории, теги, примеры)
   - Скрипты заполнения базы данных (Seed)

2. Страница рынка пресетов
   - Страница списка пресетов (`/presets`)
   - Модальное окно деталей пресета
   - Функции поиска и фильтрации

3. Логика применения пресетов
   - API для применения пресетов: `applyToConfig`
   - Интеграция селектора пресетов на фронтенде
   - Предустановленные статистические данные использования

4. Поддержка предустановленных настроек CLI
   - `novel preset list`
   - `novel preset get <id>`
   - `novel chapter-config create --preset <id>`

**Результаты**:
- ✅ 10 официальных предустановок
- ✅ Страница рынка предустановок
- ✅ API применения предустановок
- ✅ Команды CLI для предустановок

---

### Фаза 4: Двусторонняя синхронизация (3 недели)

**Цель**: Завершить отправку из CLI в Web и разрешение конфликтов

**Задачи**:
1. Расчет хеша и управление метаданными
   - Реализовать `calculateConfigHash()`
   - Локальный файл метаданных `.novel/meta/sync.json`
   - Отслеживание состояния синхронизации

2. Разработка API отправки
   - `chapterConfig.push`
   - `chapterConfig.checkSyncStatus`
   - Логика обнаружения конфликтов

3. Команды синхронизации CLI
   - `novel chapter-config push`
   - `novel chapter-config sync`
   - `novel chapter-config status`

4. UI разрешения конфликтов
   - Интерактивное разрешение конфликтов в CLI
   - Страница сравнения конфликтов в Web (опционально)

5. Тестирование
   - Тестирование сценариев синхронизации
   - Тестирование обработки конфликтов

**Результаты**:
- ✅ Модуль расчета хеша
- ✅ API отправки
- ✅ Команды синхронизации CLI
- ✅ Механизм разрешения конфликтов
- ✅ Тестовые случаи

---

### Фаза 5: Оптимизация и улучшения (2 недели)

**Цель**: Оптимизация производительности, улучшение пользовательского опыта

**Задачи**:
1. Оптимизация производительности
   - Оптимизация времени ответа API
   - Оптимизация загрузки фронтенда (разделение кода)
   - Оптимизация запросов к базе данных (индексы)

2. Пользовательский опыт
   - Автоматическое сохранение формы (черновик)
   - Улучшение подсказок валидации формы
   - Обработка состояния загрузки и ошибок
   - Обратная связь об успешном выполнении операции

3. Документация и учебные пособия
   - Документация по интеграции Dreams
   - Видеоуроки (процесс создания конфигурации)
   - Документация по командам CLI

4. Мониторинг и логирование
   - Мониторинг вызовов API
   - Отслеживание ошибок (Sentry)
   - Оповещения о сбоях синхронизации

**Результаты**:
- ✅ Отчет об оптимизации производительности
- ✅ Список улучшений UX
- ✅ Пользовательская документация
- ✅ Панель мониторинга

---

## 9. Технические проблемы и решения

### 9.1 Проблема 1: Производительность больших форм

**Проблема**: Форма конфигурации главы имеет много полей (20+), а поля массивов могут содержать несколько элементов, что может привести к замедлению рендеринга и взаимодействия.

**Решение**:
1. **Поэтапная загрузка формы**: Использование вкладок или аккордеонов для разделения отображения, рендеринг только видимой части.
2. **Виртуальная прокрутка**: Для полей массивов (список персонажей) используется виртуальная прокрутка для оптимизации длинных списков.
3. **Подавление ввода**: Для ввода текста используется функция debounce для уменьшения повторных рендерингов.
4. **Оптимизация React.memo**: Использование `memo` для дочерних компонентов для предотвращения ненужных повторных рендерингов.

```typescript
// Использование React.memo для оптимизации компонента элемента массива
const CharacterItem = React.memo(({ character, onChange }) => {
  return (
    <div>
      <Select value={character.id} onChange={...} />
      <RadioGroup value={character.focus} onChange={...} />
      {/* ... */}
    </div>
  );
});
```

### 9.2 Проблема 2: Преобразование формата между YAML и JSON

**Проблема**: Бэкенд Dreams использует JSON для хранения данных, а CLI — формат YAML, требуется без потерь преобразование.

**Решение**:
1. **Стандартизированное преобразование**: Использование библиотеки `js-yaml` для обеспечения согласованности двустороннего преобразования.
2. **Сохранение комментариев**: YAML поддерживает комментарии, JSON — нет, требуется специальная обработка.

```typescript
import yaml from 'js-yaml';
import { preserveComments } from '../utils/yaml-comments';

export function yamlToJson(yamlString: string): ChapterConfig {
  return yaml.load(yamlString) as ChapterConfig;
}

export function jsonToYaml(config: ChapterConfig, includeComments = true): string {
  let yamlString = yaml.dump(config, {
    indent: 2,
    lineWidth: 80,
    noRefs: true,
  });

  if (includeComments) {
    yamlString = preserveComments(yamlString);
  }

  return yamlString;
}

// Функция сохранения комментариев
function preserveComments(yamlString: string): string {
  // Добавление комментариев после ключевых полей
  return yamlString
    .replace(/^chapter:/m, 'chapter: # Номер главы')
    .replace(/^title:/m, 'title: # Заголовок главы')
    .replace(/^characters:/m, 'characters: # Участвующие персонажи')
    // ...
}
```

### 9.3 Проблема 3: Обработка конфликтов при синхронизации между устройствами

**Проблема**: Пользователи могут одновременно редактировать данные на нескольких устройствах, что может привести к конфликтам.

**Решение**:
1. **Оптимистическая блокировка**: Использование временной метки `updatedAt` и номера версии.
2. **Трехстороннее слияние**: Запись базовой версии и выполнение трехстороннего сравнения.
3. **Маркировка конфликтов на уровне полей**: Отметка только действительно конфликтующих полей, автоматическое слияние неконфликтующих полей.

```typescript
interface SyncMetadata {
  chapter: number;
  local_hash: string;
  remote_hash: string;
  base_hash: string;  // Хеш с момента последней синхронизации (для трехстороннего слияния)
  last_synced: string;
}

async function sync(chapter: number) {
  const local = await manager.loadConfig(chapter);
  const remote = await client.getConfig(bookId, chapter);
  const meta = await manager.getSyncMetadata(chapter);

  const localHash = calculateHash(local);
  const remoteHash = calculateHash(remote);

  if (localHash === remoteHash) {
    return { status: 'synced' };
  }

  if (localHash === meta.base_hash) {
    // Локальные изменения отсутствуют, удаленные есть → загрузить удаленные
    await manager.saveConfig(remote);
    return { status: 'pulled' };
  }

  if (remoteHash === meta.base_hash) {
    // Удаленные изменения отсутствуют, локальные есть → отправить локальные
    await client.pushConfig(bookId, chapter, local, localHash);
    return { status: 'pushed' };
  }

  // Изменения есть с обеих сторон → конфликт
  return { status: 'conflict', local, remote };
}
```

### 9.4 Проблема 4: Загрузка данных для динамических опций формы

**Проблема**: Опции, такие как персонажи и места, должны динамически загружаться из базы знаний произведения и могут иметь задержки.

**Решение**:
1. **Предварительная загрузка**: Параллельное получение всех данных опций при загрузке страницы.
2. **Кэширование**: Использование React Query для кэширования данных опций.
3. **Скелетный экран**: Отображение скелетного экрана во время загрузки данных для улучшения воспринимаемой производительности.

```typescript
// Использование React Query для предварительной загрузки всех опций
function ChapterConfigForm({ bookId }) {
  const { data: characters } = useQuery({
    queryKey: ['characters', bookId],
    queryFn: () => api.characters.list({ bookId }),
    staleTime: 5 * 60 * 1000, // Кэш на 5 минут
  });

  const { data: locations } = useQuery({
    queryKey: ['locations', bookId],
    queryFn: () => api.locations.list({ bookId }),
    staleTime: 5 * 60 * 1000,
  });

  if (!characters || !locations) {
    return <FormSkeleton />;
  }

  return <Form characters={characters} locations={locations} />;
}
```

### 9.5 Проблема 5: Масштабируемость системы предустановок

**Проблема**: Количество предустановок может расти, как ими управлять и расширять?

**Решение**:
1. **Категоризация предустановок**: По сценарию, стилю, жанру.
2. **Система тегов**: Поддержка нескольких тегов для удобного поиска.
3. **Управление версиями**: Предустановки поддерживают версии, пользователи могут выбирать версию.
4. **Пользовательские предустановки**: Разрешить пользователям создавать и делиться предустановками.

```prisma
model Preset {
  // ...
  category    String     // scene, style, genre
  tags        String[]   // Массив тегов
  version     String     @default("1.0.0")
  isOfficial  Boolean    @default(false)
  isPublic    Boolean    @default(false)

  // Поддержка форков и наследования
  parentId    String?
  parent      Preset?    @relation("PresetFork", fields: [parentId], references: [id])
  forks       Preset[]   @relation("PresetFork")
}
```

---

## 10. Критерии успеха

### 10.1 Показатели полноты функционала

- [ ] Успешная отправка формы на Web > 95%
- [ ] Успешная синхронизация сессии > 98%
- [ ] Корректность формата YAML конфигурационного файла 100%
- [ ] Успешное применение предустановки > 99%

### 10.2 Показатели производительности

- [ ] Время загрузки страницы создания конфигурации < 2с
- [ ] Время ответа на отправку формы < 500мс
- [ ] Время выполнения команды `pull` CLI < 3с
- [ ] Время выполнения команды `sync` CLI < 5с (одна глава)

### 10.3 Показатели пользовательского опыта

- [ ] Время завершения создания конфигурации < 5 минут (первое использование)
- [ ] Время завершения создания конфигурации < 2 минуты (с использованием предустановки)
- [ ] Оценка удовлетворенности пользователей > 4.5/5
- [ ] Использование функции > 40% (доля пользователей, создающих конфигурацию)

### 10.4 Показатели стабильности

- [ ] Частота ошибок API < 0.5%
- [ ] Частота сбоев команд CLI < 1%
- [ ] Частота конфликтов синхронизации < 5%
- [ ] События потери данных = 0

---

## Приложение A: Справочные материалы

### A.1 Связанные документы

- [PRD системы конфигурации глав](./chapter-config-system.md)
- [Технические спецификации](./tech-spec.md)
- [Архитектура системы форм YAML Dreams](../../../other/dreams/docs/form-system-architecture.md)
- [Архитектура CLI novel-writer-cn](../../../README.md)

### A.2 Документация по технологическому стеку

- [Документация Next.js 14](https://nextjs.org/docs)
- [Документация tRPC](https://trpc.io/docs)
- [Документация Prisma](https://www.prisma.io/docs)
- [Компоненты shadcn/ui](https://ui.shadcn.com/)
- [React Hook Form](https://react-hook-form.com/)
- [Библиотека js-yaml](https://github.com/nodeca/js-yaml)

---

## Журнал изменений

- **v1.0.0** (2025-10-14): Начальная версия, полный план интеграции Dreams