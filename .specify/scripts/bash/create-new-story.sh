```bash
#!/usr/bin/env bash
# Создание нового проекта истории

set -e

# Загрузка общих функций
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

# Парсинг аргументов
JSON_MODE=false
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h) echo "Использование: $0 [--json] <описание истории>"; exit 0 ;;
        *) ARGS+=("$arg") ;;
    esac
done

STORY_DESCRIPTION="${ARGS[*]}"
if [ -z "$STORY_DESCRIPTION" ]; then
    echo "Использование: $0 [--json] <описание истории>" >&2
    exit 1
fi

# Получение корневого каталога проекта
PROJECT_ROOT=$(get_project_root)
STORIES_DIR="$PROJECT_ROOT/stories"

# Создание каталога истории с нумерацией
STORY_NUM=$(create_numbered_dir "$STORIES_DIR" "story")

# Генерация имени каталога истории (по аналогии с spec-kit)
STORY_NAME=$(echo "$STORY_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | \
    sed 's/^-//' | sed 's/-$//')

# Извлечение первых 3 значимых слов
if [ -n "$STORY_NAME" ]; then
    WORDS=$(echo "$STORY_NAME" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//')
    STORY_NAME="$WORDS"
fi

# Если после обработки имя пустое (например, описание только на китайском), использовать имя по умолчанию
if [ -z "$STORY_NAME" ]; then
    STORY_NAME="story"
fi

STORY_DIR_NAME="${STORY_NUM}-${STORY_NAME}"
STORY_DIR="$STORIES_DIR/$STORY_DIR_NAME"

# Создание структуры каталогов истории
mkdir -p "$STORY_DIR"
mkdir -p "$STORY_DIR/chapters"
mkdir -p "$STORY_DIR/characters"
mkdir -p "$STORY_DIR/world"
mkdir -p "$STORY_DIR/notes"

# Копирование шаблонных файлов
TEMPLATE="$PROJECT_ROOT/.specify/templates/story-template.md"
STORY_FILE="$STORY_DIR/story.md"
ensure_file "$STORY_FILE" "$TEMPLATE"

# Вывод результата
if $JSON_MODE; then
    printf '{"STORY_NAME":"%s","STORY_FILE":"%s","STORY_NUM":"%s","STORY_DIR":"%s"}\n' \
        "$STORY_DIR_NAME" "$STORY_FILE" "$STORY_NUM" "$STORY_DIR"
else
    echo "STORY_NAME: $STORY_DIR_NAME"
    echo "STORY_FILE: $STORY_FILE"
    echo "STORY_NUM: $STORY_NUM"
    echo "STORY_DIR: $STORY_DIR"
fi
```