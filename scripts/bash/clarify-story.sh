```bash
#!/bin/bash

# Скрипт для уточнения плана истории
# Используется для команды /clarify, сканирует и возвращает текущий путь к истории

set -e

# Подключение общих функций
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Разбор аргументов
JSON_MODE=false
PATHS_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_MODE=true
            shift
            ;;
        --paths-only)
            PATHS_ONLY=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Получение корневого каталога проекта
PROJECT_ROOT=$(get_project_root)
cd "$PROJECT_ROOT"

# Поиск текущего каталога истории
STORIES_DIR="stories"
if [ ! -d "$STORIES_DIR" ]; then
    if [ "$JSON_MODE" = true ]; then
        echo '{"error": "No stories directory found"}'
    else
        echo "Ошибка: Директория stories не найдена. Пожалуйста, сначала запустите /story для создания плана истории."
    fi
    exit 1
fi

# Получение последней истории (пока предполагается одна история, может быть расширено)
STORY_DIR=$(find "$STORIES_DIR" -maxdepth 1 -type d ! -name "stories" | sort -r | head -n 1)

if [ -z "$STORY_DIR" ]; then
    if [ "$JSON_MODE" = true ]; then
        echo '{"error": "No story found"}'
    else
        echo "Ошибка: История не найдена. Пожалуйста, сначала запустите /story для создания плана истории."
    fi
    exit 1
fi

# Извлечение имени истории из каталога
STORY_NAME=$(basename "$STORY_DIR")

# Поиск файла истории (новый формат specification.md)
STORY_FILE="$STORY_DIR/specification.md"
if [ ! -f "$STORY_FILE" ]; then
    if [ "$JSON_MODE" = true ]; then
        echo '{"error": "Story file not found (specification.md required)"}'
    else
        echo "Ошибка: Файл истории specification.md не найден."
    fi
    exit 1
fi

# Проверка наличия записей об уточнении
CLARIFICATION_EXISTS=false
if grep -q "## 澄清记录" "$STORY_FILE" 2>/dev/null; then
    CLARIFICATION_EXISTS=true
fi

# Подсчет существующих сессий уточнения
CLARIFICATION_COUNT=0
if [ "$CLARIFICATION_EXISTS" = true ]; then
    CLARIFICATION_COUNT=$(grep -c "### 澄清会话" "$STORY_FILE" 2>/dev/null || echo "0")
fi

# Вывод в формате JSON, если запрошено
if [ "$JSON_MODE" = true ]; then
    if [ "$PATHS_ONLY" = true ]; then
        # Минимальный вывод для шаблона команды
        cat <<EOF
{
    "STORY_PATH": "$STORY_FILE",
    "STORY_NAME": "$STORY_NAME",
    "STORY_DIR": "$STORY_DIR"
}
EOF
    else
        # Полный вывод для анализа
        cat <<EOF
{
    "STORY_PATH": "$STORY_FILE",
    "STORY_NAME": "$STORY_NAME",
    "STORY_DIR": "$STORY_DIR",
    "CLARIFICATION_EXISTS": $CLARIFICATION_EXISTS,
    "CLARIFICATION_COUNT": $CLARIFICATION_COUNT,
    "PROJECT_ROOT": "$PROJECT_ROOT"
}
EOF
    fi
else
    echo "Найдена история: $STORY_NAME"
    echo "Путь к файлу: $STORY_FILE"
    if [ "$CLARIFICATION_EXISTS" = true ]; then
        echo "Проведено сессий уточнения: $CLARIFICATION_COUNT"
    else
        echo "Уточнение еще не проводилось"
    fi
fi
```