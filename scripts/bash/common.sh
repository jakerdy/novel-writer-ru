#!/usr/bin/env bash
# Общие функции

# Получить корневой каталог проекта
get_project_root() {
    if [ -f ".specify/config.json" ]; then
        pwd
    else
        # Искать вверх по дереву каталог, содержащий .specify
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

    # Найти самый новый каталог истории
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
        # Если истории нет, вернуть имя по умолчанию
        echo "story-$(date +%Y%m%d)"
    fi
}

# Создать каталог с номером
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

# Вывести JSON (для взаимодействия с AI-ассистентом)
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

# Точный подсчет китайских слов
# Исключить Markdown-разметку, пробелы, переносы строк, считать только фактическое содержание
count_chinese_words() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "0"
        return
    fi

    # Удалить Markdown-разметку и форматирующие символы, затем посчитать символы
    # 1. Удалить блоки кода
    # 2. Удалить маркеры заголовков (#)
    # 3. Удалить маркеры выделения (* и _)
    # 4. Удалить маркеры ссылок ([ ] ( ))
    # 5. Удалить маркеры цитат (>)
    # 6. Удалить маркеры списков (- *)
    # 7. Удалить пробелы, переносы строк, табуляцию
    # 8. Посчитать оставшиеся символы
    local word_count=$(cat "$file" | \
        sed '/^```/,/^```/d' | \
        sed 's/^#\+[[:space:]]*//' | \
        sed 's/\*\*//g' | \
        sed 's/__//g' | \
        sed 's/\*//g' | \
        sed 's/_//g' | \
        sed 's/\[//g' | \
        sed 's/\]//g' | \
        sed 's/(http[^)]*)//g' | \
        sed 's/^>[[:space:]]*//' | \
        sed 's/^[[:space:]]*[-*][[:space:]]*//' | \
        sed 's/^[[:space:]]*[0-9]\+\.[[:space:]]*//' | \
        tr -d '[:space:]' | \
        tr -d '[:punct:]' | \
        grep -o . | \
        wc -l | \
        tr -d ' ')

    echo "$word_count"
}

# Отобразить информацию о количестве слов в удобном формате
# Параметры: путь к файлу, минимальное количество слов (опционально), максимальное количество слов (опционально)
show_word_count_info() {
    local file="$1"
    local min_words="${2:-0}"
    local max_words="${3:-999999}"
    local actual_words=$(count_chinese_words "$file")

    echo "Количество слов: $actual_words"

    if [ "$min_words" -gt 0 ]; then
        if [ "$actual_words" -lt "$min_words" ]; then
            echo "⚠️ Не достигнуто минимальное количество слов (минимум: ${min_words})"
        elif [ "$actual_words" -gt "$max_words" ]; then
            echo "⚠️ Превышен лимит максимального количества слов (максимум: ${max_words})"
        else
            echo "✅ Соответствует требованиям по количеству слов (${min_words}-${max_words})"
        fi
    fi
}