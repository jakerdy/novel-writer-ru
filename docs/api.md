# Документация API Novel Writer

## Обзор

Novel Writer предоставляет полный набор API для создания романов с помощью ИИ. API поддерживает множество поставщиков ИИ-моделей, включая OpenAI, Claude, Gemini, а также отечественные Tongyi Qianwen, Wenxin Yiyan и другие.

## Аутентификация

### Настройка API Key

```bash
# Настройка переменной окружения
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export GEMINI_API_KEY="..."
export QWEN_API_KEY="..."
```

### Файл конфигурации

```json
{
  "providers": {
    "openai": {
      "api_key": "sk-...",
      "base_url": "https://api.openai.com/v1"
    },
    "claude": {
      "api_key": "sk-ant-...",
      "base_url": "https://api.anthropic.com"
    }
  }
}
```

## Команды CLI

### 1. style - Определение стиля

Определяет общий стиль и тон романа.

```bash
novel style <project-name> [options]
```

**Параметры:**
- `project-name`: Название проекта
- `--genre`: Жанр романа (fantasy/scifi/romance/mystery/horror)
- `--tone`: Тон повествования (serious/humorous/dark/light/neutral)
- `--ai`: Поставщик ИИ (openai/claude/gemini/qwen)
- `--model`: Конкретная модель (gpt-4/claude-3/gemini-pro)

**Пример:**
```bash
novel style my-fantasy-novel --genre fantasy --tone serious --ai claude
```

**Вывод:**
```yaml
# specs/001-my-fantasy-novel/constitution.yaml
genre: fantasy
tone: serious
narrative_voice: third-person omniscient
themes:
  - hero's journey
  - good vs evil
  - redemption
atmosphere: epic and mystical
language_style: formal with archaic elements
```

### 2. story - Синопсис истории

Генерирует основной синопсис истории и ключевые сюжетные точки.

```bash
novel story <project-name> [options]
```

**Параметры:**
- `--plot`: Тип сюжета (adventure/mystery/romance/thriller)
- `--conflict`: Тип конфликта (person-vs-person/person-vs-nature/person-vs-self)
- `--setting`: Место действия истории
- `--era`: Эпоха действия

**Пример:**
```bash
novel story my-fantasy-novel --plot adventure --conflict person-vs-evil --setting "magical kingdom" --era medieval
```

**Вывод:**
```markdown
# specs/001-my-fantasy-novel/specify.md

## Синопсис в одном предложении
Обычный деревенский юноша случайно обретает древнюю магию и отправляется в приключение, чтобы спасти королевство.

## Основной конфликт
Главный герой должен найти баланс между владением могущественной силой и сохранением чистоты своей души.

## Сюжетная линия
1. Завязка: Деревня подвергается таинственному нападению
2. Развитие: Обнаружение магического дара
3. Поворот: Предательство наставника
4. Кульминация: Финальная битва
5. Развязка: Новый баланс
```

### 3. outline - Структура глав

Генерирует подробную структуру глав.

```bash
novel outline <project-name> [options]
```

**Параметры:**
- `--chapters`: Количество глав (по умолчанию 20)
- `--words-per-chapter`: Количество слов в главе (по умолчанию 3000)
- `--structure`: Тип структуры (linear/parallel/circular)
- `--pov`: Точка зрения (first/third-limited/third-omniscient)

**Пример:**
```bash
novel outline my-fantasy-novel --chapters 25 --words-per-chapter 4000 --pov third-limited
```

**Вывод:**
```markdown
# specs/001-my-fantasy-novel/plan.md

## Глава 1: Спокойное утро
- Сцена: Повседневная жизнь в маленькой деревне
- Персонажи: Представление главного героя и его семьи
- Событие: Таинственное предзнаменование
- Количество слов: 4000

## Глава 2: Незваные гости
- Сцена: Деревенская площадь
- Персонажи: Введение таинственного путника
- Событие: Первое пробуждение магии
- Количество слов: 4000

[...]
```

### 4. characters - Описание персонажей

Создает подробное описание персонажей.

```bash
novel characters <project-name> [options]
```

**Параметры:**
- `--main`: Количество главных персонажей
- `--supporting`: Количество второстепенных персонажей
- `--depth`: Глубина проработки (basic/detailed/comprehensive)

**Пример:**
```bash
novel characters my-fantasy-novel --main 3 --supporting 5 --depth detailed
```

**Вывод:**
```yaml
# specs/001-my-fantasy-novel/characters.yaml
main_characters:
  - name: Эйден, Сын Рассвета
    age: 17
    appearance:
      height: Средний рост
      hair: Каштановые кудрявые волосы
      eyes: Темно-синие, светятся при пробуждении магии
    personality:
      traits: [храбрый, добрый, импульсивный]
      fears: [потеря семьи, потеря контроля над силой]
      motivations: [защитить деревню, найти правду]
    background:
      family: Крестьянская семья, родители живы
      education: Деревенская школа
      skills: [начальные навыки владения мечом, магический дар]
    arc: От наивного юноши к ответственному герою
```

### 5. write - Написание главы

Генерирует конкретное содержание главы.

```bash
novel write <project-name> <chapter> [options]
```

**Параметры:**
- `chapter`: Идентификатор главы (chapter-1, chapter-2...)
- `--style-check`: Проверить соответствие стилю
- `--continue`: Продолжить с последнего места остановки
- `--words`: Целевое количество слов

**Пример:**
```bash
novel write my-fantasy-novel chapter-1 --words 4000 --style-check
```

**Вывод:**
```markdown
# Глава 1: Спокойное утро

Утренний туман окутывал деревню Эйр, словно легкая вуаль, нежно покрывающая эту тихую долину. Эйден стоял у двери своего дома и глубоко вдыхал воздух, пахнущий травой. Сегодня должен был быть обычный день, он собирался помочь отцу собирать последнюю партию пшеницы в поле.

Однако необычный красный отблеск на горизонте вызвал у него чувство беспокойства...

[Продолжение на 4000 слов]
```

## Python API

### Базовое использование

```python
from novel_writer import NovelWriter

# Инициализация
writer = NovelWriter(
    ai_provider="claude",
    api_key="sk-ant-..."
)

# Создание проекта
project = writer.create_project(
    name="my-novel",
    genre="fantasy",
    language="zh-CN"
)

# Определение стиля
style = writer.define_style(
    project=project,
    tone="epic",
    themes=["heroism", "sacrifice"]
)

# Создание истории
story = writer.create_story(
    project=project,
    plot_type="hero_journey",
    setting="medieval_fantasy"
)

# Генерация структуры
outline = writer.generate_outline(
    project=project,
    chapters=20,
    words_per_chapter=3000
)

# Написание главы
chapter = writer.write_chapter(
    project=project,
    chapter_number=1,
    outline=outline,
    style=style
)
```

### Расширенные функции

```python
# Пакетная генерация
chapters = writer.batch_write(
    project=project,
    chapter_range=(1, 5),
    parallel=True
)

# Проверка стиля
consistency = writer.check_consistency(
    chapters=chapters,
    style=style
)

# Предложения по доработке
revisions = writer.suggest_revisions(
    chapter=chapter,
    focus=["dialogue", "pacing"]
)

# Экспорт
writer.export(
    project=project,
    format="markdown",  # or "docx", "epub"
    output_path="./output"
)
```

## REST API

### Базовые конечные точки

```http
POST /api/v1/projects
Content-Type: application/json
Authorization: Bearer {api_key}

{
  "name": "my-novel",
  "genre": "fantasy",
  "language": "zh-CN"
}
```

### Генерация стиля

```http
POST /api/v1/projects/{project_id}/constitution
Content-Type: application/json

{
  "tone": "epic",
  "themes": ["heroism", "sacrifice"],
  "narrative_voice": "third_person"
}
```

### Написание главы

```http
POST /api/v1/projects/{project_id}/tasks
Content-Type: application/json

{
  "chapter_number": 1,
  "target_words": 3000,
  "continue_from": null
}
```

### WebSocket потоковая генерация

```javascript
const ws = new WebSocket('wss://api.novel-writer.com/v1/stream');

ws.send(JSON.stringify({
  action: 'write',
  project_id: 'my-novel',
  chapter: 1,
  streaming: true
}));

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Generated text:', data.text);
};
```

## Обработка ошибок

### Коды ошибок

| Код | Описание | Рекомендации по устранению |
|------|------|----------|
| 400 | Ошибка параметра | Проверьте параметры запроса |
| 401 | Ошибка аутентификации | Проверьте API Key |
| 403 | Недостаточно прав | Проверьте права доступа к аккаунту |
| 404 | Ресурс не найден | Проверьте ID проекта |
| 429 | Ограничение скорости запросов | Подождите и повторите попытку |
| 500 | Ошибка сервера | Свяжитесь с поддержкой |

### Формат ответа об ошибке

```json
{
  "error": {
    "code": "invalid_parameter",
    "message": "Количество глав должно быть от 1 до 100",
    "field": "chapters",
    "request_id": "req_123456"
  }
}
```

## Ограничения скорости запросов

| План | Запросов/минуту | Параллельные запросы | Символов/месяц |
|------|-----------|--------|---------|
| Бесплатный | 10 | 1 | 100,000 |
| Базовый | 60 | 3 | 1,000,000 |
| Профессиональный | 300 | 10 | 10,000,000 |
| Корпоративный | Индивидуально | Индивидуально | Без ограничений |

## Webhook

### Настройка Webhook

```json
{
  "url": "https://your-server.com/webhook",
  "events": ["chapter.completed", "project.finished"],
  "secret": "webhook_secret_key"
}
```

### Типы событий

- `project.created` - Проект создан
- `style.defined` - Стиль определен
- `outline.generated` - Структура сгенерирована
- `chapter.started` - Начало написания главы
- `chapter.completed` - Глава завершена
- `project.finished` - Проект завершен

### Полезная нагрузка события

```json
{
  "event": "chapter.completed",
  "timestamp": "2024-01-01T10:00:00Z",
  "data": {
    "project_id": "my-novel",
    "chapter": 1,
    "word_count": 3000,
    "generation_time": 45.2
  }
}
```

## SDK

### JavaScript/TypeScript

```bash
npm install @novel-writer/sdk
```

```typescript
import { NovelWriter } from '@novel-writer/sdk';

const writer = new NovelWriter({
  apiKey: process.env.NOVEL_WRITER_API_KEY,
  provider: 'claude'
});

async function createNovel() {
  const project = await writer.createProject({
    name: 'my-novel',
    genre: 'fantasy'
  });

  const chapter = await writer.writeChapter(project.id, 1);
  console.log(chapter.content);
}
```

### Python

```bash
pip install novel-writer-sdk
```

```python
from novel_writer_sdk import NovelWriter

writer = NovelWriter(
    api_key=os.getenv('NOVEL_WRITER_API_KEY'),
    provider='claude'
)

project = writer.create_project(
    name='my-novel',
    genre='fantasy'
)

chapter = writer.write_chapter(project.id, 1)
print(chapter.content)
```

## Лучшие практики

### 1. Поэтапная генерация

Не генерируйте весь роман за один раз, а выполняйте следующие шаги последовательно:

1. Определение стиля
2. Синопсис истории
3. Описание персонажей
4. Структура глав
5. Поглавное написание

### 2. Использование кэширования

Используйте ID проекта и номер главы для кэширования:

```python
cache_key = f"{project_id}:chapter:{chapter_num}"
if cached := cache.get(cache_key):
    return cached
```

### 3. Повторные попытки при ошибках

Реализуйте повторные попытки с экспоненциальной задержкой:

```python
import time

def retry_with_backoff(func, max_retries=3):
    for i in range(max_retries):
        try:
            return func()
        except RateLimitError:
            time.sleep(2 ** i)
    raise Exception("Max retries exceeded")
```

### 4. Пакетная обработка

Обрабатывайте несколько глав пакетами для повышения эффективности:

```python
chapters = writer.batch_write(
    chapter_range=(1, 10),
    parallel=True,
    max_workers=3
)
```

## Связанные ресурсы

- [API Playground](https://playground.novel-writer.com)
- [Документация SDK](https://sdk-docs.novel-writer.com)
- [Примеры проектов](https://github.com/novel-writer/examples)
- [Форум сообщества](https://community.novel-writer.com)
- [Страница статуса](https://status.novel-writer.com)

---

📚 **Примечание**: Документация по этому API постоянно обновляется. Последнюю версию можно найти в [онлайн-документации](https://docs.novel-writer.com/api).