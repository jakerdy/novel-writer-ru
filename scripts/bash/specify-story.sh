```bash
#!/bin/bash

# Скрипт определения спецификаций истории
# Используется для команды /specify

set -e

# Подключение общих функций
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Парсинг аргументов
JSON_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_MODE=true
            shift
            ;;
        *)
            STORY_NAME="$1"
            shift
            ;;
    esac
done

# Получение корневого каталога проекта
PROJECT_ROOT=$(get_project_root)
cd "$PROJECT_ROOT"

# Определение имени и пути к истории
if [ -z "$STORY_NAME" ]; then
    # Поиск последней истории
    STORIES_DIR="stories"
    if [ -d "$STORIES_DIR" ] && [ "$(ls -A $STORIES_DIR 2>/dev/null)" ]; then
        STORY_DIR=$(find "$STORIES_DIR" -maxdepth 1 -type d ! -name "stories" | sort -r | head -n 1)
        if [ -n "$STORY_DIR" ]; then
            STORY_NAME=$(basename "$STORY_DIR")
        fi
    fi

    # Если всё ещё нет, генерация имени по умолчанию
    if [ -z "$STORY_NAME" ]; then
        STORY_NAME="story-$(date +%Y%m%d)"
    fi
fi

# Установка путей
STORY_DIR="stories/$STORY_NAME"
SPEC_FILE="$STORY_DIR/specification.md"

# Создание каталога
mkdir -p "$STORY_DIR"

# Проверка состояния файла
SPEC_EXISTS=false
STATUS="new"

if [ -f "$SPEC_FILE" ]; then
    SPEC_EXISTS=true
    STATUS="exists"
fi

# Вывод в формате JSON
if [ "$JSON_MODE" = true ]; then
    cat <<EOF
{
    "STORY_NAME": "$STORY_NAME",
    "STORY_DIR": "$STORY_DIR",
    "SPEC_PATH": "$SPEC_FILE",
    "STATUS": "$STATUS",
    "PROJECT_ROOT": "$PROJECT_ROOT"
}
EOF
else
    echo "Инициализация спецификации истории"
    echo "=================================="
    echo "Имя истории: $STORY_NAME"
    echo "Путь к спецификации: $SPEC_FILE"

    if [ "$SPEC_EXISTS" = true ]; then
        echo "Статус: Файл спецификации существует, подготовка к обновлению"
    else
        echo "Статус: Подготовка к созданию новой спецификации"
    fi

    # Проверка конституции
    if [ -f "memory/constitution.md" ]; then
        echo ""
        echo "✅ Обнаружена конституция творчества, спецификация будет соответствовать принципам конституции"
    fi
fi
```