```sh
#!/usr/bin/env bash
# Написание главы

set -e

# Загрузка общих функций
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

# Получение текущей директории истории
STORY_DIR=$(get_current_story)

if [ -z "$STORY_DIR" ]; then
    echo "Ошибка: Проект истории не найден" >&2
    exit 1
fi

# Проверка предварительных условий
if [ ! -f "$STORY_DIR/outline.md" ]; then
    echo "Ошибка: План главы не найден, используйте команду /outline" >&2
    exit 1
fi

# Определение главы для написания (можно передать как параметр или автоматически найти следующую)
CHAPTER_NUM="${1:-}"

# Парсинг информации о томе из outline.md
parse_volume_info() {
    local outline_file="$1"
    local chapter_num="$2"

    # Попытка парсинга информации о томе из outline.md
    # Пример формата: ### Том 1: Вступление ученого
    # - **Диапазон глав**: Главы 1-60

    local volume_num=1
    while IFS= read -r line; do
        if [[ "$line" =~ ^###[[:space:]]+第.*卷 ]]; then
            # Найден заголовок тома, продолжаем поиск диапазона глав
            local next_line
            while IFS= read -r next_line; do
                if [[ "$next_line" =~ 章节范围.*第([0-9]+)-([0-9]+)章 ]]; then
                    local start_ch="${BASH_REMATCH[1]}"
                    local end_ch="${BASH_REMATCH[2]}"
                    if [ "$chapter_num" -ge "$start_ch" ] && [ "$chapter_num" -le "$end_ch" ]; then
                        echo "volume-${volume_num}"
                        return 0
                    fi
                    volume_num=$((volume_num + 1))
                    break
                elif [[ "$next_line" =~ ^### ]]; then
                    # Встречен следующий заголовок тома, выходим
                    break
                fi
            done
        fi
    done < "$outline_file"

    # Если не удалось распарсить из outline.md, используем правило по умолчанию
    # Один том на 60 глав
    local volume=$((($chapter_num - 1) / 60 + 1))
    echo "volume-${volume}"
}

# Определение тома, к которому относится глава
determine_volume() {
    local chapter=$1
    local outline_file="$STORY_DIR/outline.md"

    if [ -f "$outline_file" ]; then
        # Попытка парсинга
        parse_volume_info "$outline_file" "$chapter"
    else
        # Правило по умолчанию: один том на 60 глав
        local volume=$((($chapter - 1) / 60 + 1))
        echo "volume-${volume}"
    fi
}

if [ -z "$CHAPTER_NUM" ]; then
    # Автоматический поиск следующей ненаписанной главы
    CHAPTER_NUM=1
    found=false
    # Получение общего количества глав из outline.md, если не найдено, по умолчанию ищем до 500 глав
    MAX_CHAPTERS=500
    if [ -f "$STORY_DIR/outline.md" ]; then
        # Попытка парсинга общего количества глав из outline.md
        # Формат: - **Общее количество глав**: 240 глав
        TOTAL_CHAPTERS=$(grep -E "总章节数.*[0-9]+章" "$STORY_DIR/outline.md" | grep -o "[0-9]+" | head -1)
        if [ -n "$TOTAL_CHAPTERS" ]; then
            MAX_CHAPTERS=$TOTAL_CHAPTERS
        fi
    fi

    while [ "$CHAPTER_NUM" -le "$MAX_CHAPTERS" ] && [ "$found" = false ]; do
        VOLUME=$(determine_volume "$CHAPTER_NUM")
        CHAPTER_FMT=$(printf "%03d" "$CHAPTER_NUM")
        if [ ! -f "$STORY_DIR/chapters/$VOLUME/chapter-${CHAPTER_FMT}.md" ]; then
            found=true
        else
            CHAPTER_NUM=$((CHAPTER_NUM + 1))
        fi
    done
fi

# Форматирование номера главы и определение соответствующего тома
CHAPTER_NUM_FMT=$(printf "%03d" "$CHAPTER_NUM")
VOLUME_DIR=$(determine_volume "$CHAPTER_NUM")
CHAPTER_FILE="$STORY_DIR/chapters/$VOLUME_DIR/chapter-${CHAPTER_NUM_FMT}.md"

# Создание файла главы (включая каталог тома)
mkdir -p "$(dirname "$CHAPTER_FILE")"
touch "$CHAPTER_FILE"

# Обновление прогресса
PROGRESS_FILE="$STORY_DIR/progress.json"
if [ -f "$PROGRESS_FILE" ]; then
    # Здесь должно быть обновление JSON, упрощенная обработка
    echo "Создан файл главы: $CHAPTER_FILE" >&2
fi

# Вывод результата
echo "CHAPTER_FILE: $CHAPTER_FILE"
echo "CHAPTER_NUM: $CHAPTER_NUM"
echo "VOLUME: $VOLUME_DIR"
echo "STATUS: ready"
```