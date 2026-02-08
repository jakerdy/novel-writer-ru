#!/usr/bin/env bash
# Управление и проверка временной шкалы истории

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

# Пути к файлам
TIMELINE="$STORY_DIR/spec/tracking/timeline.json"
PROGRESS="$STORY_DIR/progress.json"

# Параметры команды
COMMAND="${1:-show}"
PARAM2="${2:-}"

# Инициализация файла временной шкалы
init_timeline() {
    if [ ! -f "$TIMELINE" ]; then
        echo "⚠️  Файл временной шкалы не найден, создается..." >&2
        mkdir -p "$STORY_DIR/spec/tracking"

        if [ -f "$SCRIPT_DIR/../../templates/tracking/timeline.json" ]; then
            cp "$SCRIPT_DIR/../../templates/tracking/timeline.json" "$TIMELINE"
            echo "✅ Файл временной шкалы создан"
        else
            echo "Ошибка: Не удалось найти файл шаблона" >&2
            exit 1
        fi
    fi
}

# Отображение временной шкалы
show_timeline() {
    echo "📅 Временная шкала истории"
    echo "━━━━━━━━━━━━━━━━━━━━"

    if [ -f "$TIMELINE" ]; then
        # Текущее время
        CURRENT_TIME=$(jq -r '.storyTime.current // "Не установлено"' "$TIMELINE")
        echo "⏰ Текущее время: $CURRENT_TIME"
        echo ""

        # Расчет временного интервала
        START_TIME=$(jq -r '.storyTime.start // ""' "$TIMELINE")
        if [ -n "$START_TIME" ]; then
            echo "📍 Начальное время: $START_TIME"

            # Расчет количества пройденных событий
            EVENT_COUNT=$(jq '.events | length' "$TIMELINE")
            echo "📊 Записано событий: ${EVENT_COUNT} шт."
        fi

        echo ""
        echo "📖 Важные события:"
        echo "───────────────"

        # Отображение последних событий
        jq -r '.events | sort_by(.chapter) | reverse | .[0:5][] |
            "Глава " + (.chapter | tostring) + " | " + .date + " | " + .event' \
            "$TIMELINE" 2>/dev/null || echo "  Событий пока нет"

        # Отображение параллельных событий
        PARALLEL_COUNT=$(jq '.parallelEvents.timepoints | length' "$TIMELINE" 2>/dev/null || echo "0")
        if [ "$PARALLEL_COUNT" != "0" ] && [ "$PARALLEL_COUNT" != "null" ]; then
            echo ""
            echo "🔄 Параллельные события:"
            jq -r '.parallelEvents.timepoints | to_entries[] |
                .key + ": " + (.value | join(", "))' "$TIMELINE" 2>/dev/null || true
        fi
    else
        echo "Файл временной шкалы не найден"
    fi
}

# Добавление временной точки
add_event() {
    local chapter="${2:-}"
    local date="${3:-}"
    local event="${4:-}"

    if [ -z "$chapter" ] || [ -z "$date" ] || [ -z "$event" ]; then
        echo "Использование: $0 add <номер главы> <время> <описание события>" >&2
        echo "Пример: $0 add 5 'Весна 30-го года Ваньли' 'Главный герой прибывает в столицу'" >&2
        exit 1
    fi

    if [ ! -f "$TIMELINE" ]; then
        init_timeline
    fi

    # Добавление нового события
    TEMP_FILE=$(mktemp)
    jq --arg ch "$chapter" \
       --arg dt "$date" \
       --arg ev "$event" \
       '.events += [{
           chapter: ($ch | tonumber),
           date: $dt,
           event: $ev,
           duration: "",
           participants: []
       }] |
       .events |= sort_by(.chapter) |
       .lastUpdated = now | strftime("%Y-%m-%dT%H:%M:%S")' \
       "$TIMELINE" > "$TEMP_FILE"

    mv "$TEMP_FILE" "$TIMELINE"
    echo "✅ Событие добавлено: Глава ${chapter} - $date - $event"
}

# Проверка непрерывности временной шкалы
check_continuity() {
    echo "🔍 Проверка непрерывности временной шкалы"
    echo "━━━━━━━━━━━━━━━━━━━━"

    if [ ! -f "$TIMELINE" ]; then
        echo "Ошибка: Файл временной шкалы не существует" >&2
        exit 1
    fi

    # Проверка порядка событий
    echo "Проверка порядка глав..."

    # Получение всех номеров глав и проверка их возрастания
    CHAPTERS=$(jq -r '.events | sort_by(.chapter) | .[].chapter' "$TIMELINE")

    prev_chapter=0
    issues=0

    for chapter in $CHAPTERS; do
        if [ "$chapter" -le "$prev_chapter" ]; then
            echo "⚠️  Нарушение порядка глав: Глава ${chapter} появилась после главы ${prev_chapter}"
            ((issues++))
        fi
        prev_chapter=$chapter
    done

    # Проверка временных интервалов
    echo ""
    echo "Проверка временных интервалов..."

    # Здесь можно добавить более сложную логику проверки времени
    # Например, проверку разумности времени в пути

    if [ "$issues" -eq 0 ]; then
        echo ""
        echo "✅ Проверка временной шкалы пройдена, логических проблем не обнаружено"
    else
        echo ""
        echo "⚠️  Обнаружено ${issues} потенциальных проблем, пожалуйста, проверьте"
    fi

    # Запись результатов проверки
    if [ -f "$TIMELINE" ]; then
        TEMP_FILE=$(mktemp)
        jq --arg date "$(date -Iseconds)" \
           --arg issues "$issues" \
           '.lastChecked = $date |
            .anomalies.lastCheckIssues = ($issues | tonumber)' \
           "$TIMELINE" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$TIMELINE"
    fi
}

# Синхронизация параллельных событий
sync_parallel() {
    local timepoint="${2:-}"
    local events="${3:-}"

    if [ -z "$timepoint" ] || [ -z "$events" ]; then
        echo "Использование: $0 sync <временная точка> <список событий>" >&2
        echo "Пример: $0 sync 'Весна 30-го года Ваньли' 'Начало войны, Прибытие посольства'" >&2
        exit 1
    fi

    if [ ! -f "$TIMELINE" ]; then
        init_timeline
    fi

    # Преобразование списка событий в JSON-массив
    IFS=',' read -ra EVENT_ARRAY <<< "$events"
    JSON_ARRAY=$(printf '"%s",' "${EVENT_ARRAY[@]}" | sed 's/,$//')
    JSON_ARRAY="[${JSON_ARRAY}]"

    # Обновление параллельных событий
    TEMP_FILE=$(mktemp)
    jq --arg tp "$timepoint" \
       --argjson events "$JSON_ARRAY" \
       '.parallelEvents.timepoints[$tp] = $events |
        .lastUpdated = now | strftime("%Y-%m-%dT%H:%M:%S")' \
       "$TIMELINE" > "$TEMP_FILE"

    mv "$TEMP_FILE" "$TIMELINE"
    echo "✅ Параллельные события синхронизированы: $timepoint"
}

# Основная функция
main() {
    init_timeline

    case "$COMMAND" in
        show)
            show_timeline
            ;;
        add)
            add_event "$@"
            ;;
        check)
            check_continuity
            ;;
        sync)
            sync_parallel "$@"
            ;;
        *)
            echo "Использование: $0 [show|add|check|sync] [параметры...]" >&2
            echo "Команды:" >&2
            echo "  show  - Показать временную шкалу" >&2
            echo "  add   - Добавить временную точку" >&2
            echo "  check - Проверить непрерывность" >&2
            echo "  sync  - Синхронизировать параллельные события" >&2
            exit 1
            ;;
    esac
}

# Выполнение основной функции
main "$@"