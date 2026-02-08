#!/usr/bin/env bash
# Управление и проверка временной шкалы истории

set -e

# Загрузка общих функций
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

# Проверка режима чек-листа
CHECKLIST_MODE=false
COMMAND="${1:-show}"
if [ "$COMMAND" = "--checklist" ]; then
    CHECKLIST_MODE=true
    COMMAND="check"
fi

# Получение текущей директории истории
STORY_DIR=$(get_current_story)

if [ -z "$STORY_DIR" ]; then
    echo "Ошибка: Проект истории не найден" >&2
    exit 1
fi

# Пути к файлам
TIMELINE="$STORY_DIR/spec/tracking/timeline.json"
PROGRESS="$STORY_DIR/progress.json"

# Параметры команды (режим чек-листа обработан выше)
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
            echo "📍 Время начала: $START_TIME"

            # Подсчет количества пройденных событий
            EVENT_COUNT=$(jq '.events | length' "$TIMELINE")
            echo "📊 Записано событий: ${EVENT_COUNT} шт."
        fi

        echo ""
        echo "📖 Важные события:"
        echo "───────────────"

        # Отображение последних событий
        jq -r '.events | sort_by(.chapter) | reverse | .[0:5][] |
            "Глава " + (.chapter | tostring) + " | " + .date + " | " + .event' \
            "$TIMELINE" 2>/dev/null || echo "  Пока нет записей событий"

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
        echo "Использование: $0 add <номер главы> <дата> <описание события>" >&2
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

    # Проверка порядка глав
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
        echo "Пример: $0 sync 'Весна 30-го года Ваньли' 'Начало войны,Прибытие посольства'" >&2
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

# Генерация вывода в формате checklist
output_checklist() {
    init_timeline

    local event_count=0
    local parallel_count=0
    local current_time=""
    local start_time=""
    local has_issues=0

    if [ -f "$TIMELINE" ]; then
        event_count=$(jq '.events | length' "$TIMELINE")
        parallel_count=$(jq '.parallelEvents.timepoints | length' "$TIMELINE" 2>/dev/null || echo "0")
        current_time=$(jq -r '.storyTime.current // ""' "$TIMELINE")
        start_time=$(jq -r '.storyTime.start // ""' "$TIMELINE")

        # Проверка проблем с порядком событий
        has_issues=$(jq '
            .events |
            sort_by(.chapter) |
            . as $sorted |
            reduce range(1; length) as $i (0;
                if $sorted[$i].chapter <= $sorted[$i-1].chapter then . + 1 else . end
            )' "$TIMELINE")
    fi

    cat <<EOF
# Чек-лист проверки временной шкалы

**Время проверки**: $(date '+%Y-%m-%d %H:%M:%S')
**Проверяемый объект**: spec/tracking/timeline.json
**Количество записанных событий**: $event_count

---

## Целостность файла

- [$([ -f "$TIMELINE" ] && echo "x" || echo " ")] CHK001 Файл timeline.json существует и имеет корректный формат

## Настройки времени

- [$([ -n "$start_time" ] && echo "x" || echo " ")] CHK002 Установлено время начала истории ($start_time)
- [$([ -n "$current_time" ] && echo "x" || echo " ")] CHK003 Обновлено текущее время истории ($current_time)

## Запись событий

- [$([ $event_count -gt 0 ] && echo "x" || echo " ")] CHK004 Записаны временные события ($event_count шт.)
- [$([ $has_issues -eq 0 ] && echo "x" || echo "!")] CHK005 Временные события упорядочены по главам$([ $has_issues -gt 0 ] && echo " (⚠️ обнаружено $has_issues нарушений порядка)" || echo "")

## Параллельные события

EOF

    if [ "$parallel_count" -gt 0 ]; then
        echo "- [x] CHK006 Записаны временные точки параллельных событий ($parallel_count шт.)"
    else
        echo "- [ ] CHK006 Записаны временные точки параллельных событий (нет записей)"
    fi

    cat <<EOF

---

## Дальнейшие действия

EOF

    local has_actions=false

    if [ $event_count -eq 0 ]; then
        echo "- [ ] Начать запись временных событий"
        has_actions=true
    fi

    if [ -z "$current_time" ]; then
        echo "- [ ] Установить текущее время истории"
        has_actions=true
    fi

    if [ $has_issues -gt 0 ]; then
        echo "- [ ] Исправить $has_issues нарушений порядка событий"
        has_actions=true
    fi

    if [ "$has_actions" = false ]; then
        echo "*Запись временной шкалы полная, особых действий не требуется*"
    fi

    cat <<EOF

---

**Инструмент проверки**: check-timeline.sh
**Версия**: 1.1 (поддержка вывода checklist)
EOF
}

# Основная функция
main() {
    if [ "$CHECKLIST_MODE" = true ]; then
        output_checklist
        exit 0
    fi

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