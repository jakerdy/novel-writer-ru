#!/usr/bin/env bash
# Создание задач

set -e

# Загрузка общих функций
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

# Получение текущего каталога истории
STORY_DIR=$(get_current_story)

if [ -z "$STORY_DIR" ]; then
    echo "Ошибка: Проект истории не найден" >&2
    exit 1
fi

# Проверка предварительных условий
if [ ! -f "$STORY_DIR/specification.md" ]; then
    echo "Ошибка: Файл спецификации истории не найден, пожалуйста, сначала используйте команду /specify" >&2
    exit 1
fi

if [ ! -f "$STORY_DIR/outline.md" ]; then
    echo "Ошибка: Файл плана глав не найден, пожалуйста, сначала используйте команду /outline" >&2
    exit 1
fi

# Получение текущей даты
CURRENT_DATE=$(date '+%Y-%m-%d')
CURRENT_DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# Создание файла задач с предварительно заполненной основной информацией
TASKS_FILE="$STORY_DIR/tasks.md"
cat > "$TASKS_FILE" << EOF
# Список задач по написанию

## Обзор задач
- **Дата создания**: ${CURRENT_DATE}
- **Последнее обновление**: ${CURRENT_DATE}
- **Статус задач**: Ожидается генерация

---
EOF

# Создание файла отслеживания прогресса
PROGRESS_FILE="$STORY_DIR/progress.json"
if [ ! -f "$PROGRESS_FILE" ]; then
    cat > "$PROGRESS_FILE" << EOF
{
  "created_at": "${CURRENT_DATETIME}",
  "updated_at": "${CURRENT_DATETIME}",
  "total_chapters": 0,
  "completed": 0,
  "in_progress": 0,
  "word_count": 0
}
EOF
fi

# Вывод результата
echo "TASKS_FILE: $TASKS_FILE"
echo "PROGRESS_FILE: $PROGRESS_FILE"
echo "CURRENT_DATE: $CURRENT_DATE"
echo "STATUS: ready"