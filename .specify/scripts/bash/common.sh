```bash
#!/usr/bin/env bash
# Общая библиотека функций

# Получить корневой каталог проекта
get_project_root() {
    if [ -f ".specify/config.json" ]; then
        pwd
    else
        # Искать вверх по иерархии каталог, содержащий .specify
        current=$(pwd)
        while [ "$current" != "/" ]; do
            if [ -f "$current/.specify/config.json" ]; then
                echo "$current"
                return 0
            fi
            current=$(dirname "$current")
        done
        echo "Ошибка: Корневой каталог проекта романа не найден" >&2
        exit 1
    fi
}

# Получить текущий каталог истории
get_current_story() {
    PROJECT_ROOT=$(get_project_root)
    STORIES_DIR="$PROJECT_ROOT/stories"

    # Найти самый последний каталог истории
    if [ -d "$STORIES_DIR" ]; then
        latest=$(ls -t "$STORIES_DIR" 2>/dev/null | head -1)
        if [ -n "$latest" ]; then
            echo "$STORIES_DIR/$latest"
        fi
    fi
}

# Получить имя активной истории (возвращает только имя, а не путь)
get_active_story() {
    story_dir=$(get_current_story)
    if [ -n "$story_dir" ]; then
        basename "$story_dir"
    else
        # Если историй нет, вернуть имя по умолчанию
        echo "story-$(date +%Y%m%d)"
    fi
}

# Создать каталог с нумерацией
create_numbered_dir() {
    base_dir="$1"
    prefix="$2"

    mkdir -p "$base_dir"

    # Найти максимальный номер
    highest=0
    for dir in "$base_dir"/*; do
        [ -d "$dir" ] || continue
        dirname=$(basename "$dir")
        number=$(echo "$dirname" | grep -o '^[0-9]\+' || echo "0")
        number=$((10#$number))
        if [ "$number" -gt "$highest" ]; then
            highest=$number
        fi
    done

    # Вернуть следующий номер
    next=$((highest + 1))
    printf "%03d" "$next"
}

# Вывести JSON (для связи с AI-ассистентом)
output_json() {
    echo "$1"
}

# Убедиться, что файл существует
ensure_file() {
    file="$1"
    template="$2"

    if [ ! -f "$file" ]; then
        if [ -f "$template" ]; then
            cp "$template" "$file"
        else
            touch "$file"
        fi
    fi
}
```