```bash
#!/usr/bin/env bash
# Настройка структуры глав

set -e

# Загрузка общих функций
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

# Получение текущей директории истории
STORY_DIR=$(get_current_story)

if [ -z "$STORY_DIR" ]; then
    echo "Ошибка: Проект истории не найден. Пожалуйста, сначала создайте историю с помощью команды /story" >&2
    exit 1
fi

# Создание файла структуры глав
OUTLINE_FILE="$STORY_DIR/outline.md"
PROJECT_ROOT=$(get_project_root)
TEMPLATE="$PROJECT_ROOT/.specify/templates/outline-template.md"

ensure_file "$OUTLINE_FILE" "$TEMPLATE"

# Создание структуры директорий для глав
mkdir -p "$STORY_DIR/chapters/volume-1"

# Вывод результата
echo "OUTLINE_FILE: $OUTLINE_FILE"
echo "STORY_DIR: $STORY_DIR"
echo "STATUS: ready"
```