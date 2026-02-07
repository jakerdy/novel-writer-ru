```bash
#!/usr/bin/env bash
# Комплексный скрипт проверки согласованности

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
PROGRESS="$STORY_DIR/progress.json"
PLOT_TRACKER="$STORY_DIR/spec/tracking/plot-tracker.json"
TIMELINE="$STORY_DIR/spec/tracking/timeline.json"
RELATIONSHIPS="$STORY_DIR/spec/tracking/relationships.json"
CHARACTER_STATE="$STORY_DIR/spec/tracking/character-state.json"

# Коды цветов ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные для статистики
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNINGS=0
ERRORS=0

# Функция проверки
check() {
    local name="$1"
    local condition="$2"
    local error_msg="$3"

    ((TOTAL_CHECKS++))

    if eval "$condition"; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASSED_CHECKS++))
    else
        echo -e "${RED}✗${NC} $name: $error_msg"
        ((ERRORS++))
    fi
}

warn() {
    local msg="$1"
    echo -e "${YELLOW}⚠${NC} Предупреждение: $msg"
    ((WARNINGS++))
}

# Проверка согласованности номеров глав
check_chapter_consistency() {
    echo "📖 Проверка согласованности номеров глав"
    echo "───────────────────"

    if [ -f "$PROGRESS" ] && [ -f "$PLOT_TRACKER" ]; then
        PROGRESS_CHAPTER=$(jq -r '.statistics.currentChapter // 0' "$PROGRESS")
        PLOT_CHAPTER=$(jq -r '.currentState.chapter // 0' "$PLOT_TRACKER")

        check "Синхронизация номеров глав" \
              "[ '$PROGRESS_CHAPTER' = '$PLOT_CHAPTER' ]" \
              "progress.json(${PROGRESS_CHAPTER}) != plot-tracker.json(${PLOT_CHAPTER})"

        if [ -f "$CHARACTER_STATE" ]; then
            CHAR_CHAPTER=$(jq -r '.protagonist.currentStatus.chapter // 0' "$CHARACTER_STATE")
            check "Синхронизация глав состояния персонажа" \
                  "[ '$PROGRESS_CHAPTER' = '$CHAR_CHAPTER' ]" \
                  "несоответствие с character-state.json(${CHAR_CHAPTER})"
        fi
    else
        warn "Некоторые файлы отслеживания отсутствуют, невозможно завершить проверку глав"
    fi

    echo ""
}

# Проверка непрерывности временной шкалы
check_timeline_consistency() {
    echo "⏰ Проверка непрерывности временной шкалы"
    echo "───────────────────"

    if [ -f "$TIMELINE" ]; then
        # Проверка, увеличиваются ли временные события по главам
        TIMELINE_ISSUES=$(jq '
            .events |
            sort_by(.chapter) |
            . as $sorted |
            reduce range(1; length) as $i (0;
                if $sorted[$i].chapter <= $sorted[$i-1].chapter then . + 1 else . end
            )' "$TIMELINE")

        check "Порядок временных событий" \
              "[ '$TIMELINE_ISSUES' = '0' ]" \
              "обнаружено ${TIMELINE_ISSUES} неупорядоченных событий"

        # Проверка обновления текущего времени
        CURRENT_TIME=$(jq -r '.storyTime.current // ""' "$TIMELINE")
        check "Настройка текущего времени" \
              "[ -n '$CURRENT_TIME' ]" \
              "текущее время истории не установлено"
    else
        warn "Файл временной шкалы отсутствует"
    fi

    echo ""
}

# Проверка разумности состояния персонажа
check_character_consistency() {
    echo "👥 Проверка разумности состояния персонажа"
    echo "─────────────────────"

    if [ -f "$CHARACTER_STATE" ] && [ -f "$RELATIONSHIPS" ]; then
        # Проверка наличия главного героя в обоих файлах
        PROTAG_NAME=$(jq -r '.protagonist.name // ""' "$CHARACTER_STATE")

        if [ -n "$PROTAG_NAME" ]; then
            HAS_RELATIONS=$(jq --arg name "$PROTAG_NAME" \
                'has($name)' "$RELATIONSHIPS" 2>/dev/null || echo "false")

            check "Запись отношений главного героя" \
                  "[ '$HAS_RELATIONS' = 'true' ]" \
                  "главный герой '$PROTAG_NAME' не записан в relationships.json"
        fi

        # Проверка логики местоположения персонажа
        LAST_LOCATION=$(jq -r '.protagonist.currentStatus.location // ""' "$CHARACTER_STATE")
        check "Запись текущего местоположения главного героя" \
              "[ -n '$LAST_LOCATION' ]" \
              "текущее местоположение главного героя не записано"
    else
        warn "Файлы отслеживания персонажей неполные"
    fi

    echo ""
}

# Проверка плана по использованию затравки (foreshadowing)
check_foreshadowing_plan() {
    echo "🎯 Проверка управления затравкой"
    echo "──────────────"

    if [ -f "$PLOT_TRACKER" ]; then
        # Статистика статусов затравки
        TOTAL_FORESHADOW=$(jq '.foreshadowing | length' "$PLOT_TRACKER")
        ACTIVE_FORESHADOW=$(jq '[.foreshadowing[] | select(.status == "active")] | length' "$PLOT_TRACKER")

        if [ -f "$PROGRESS" ]; then
            CURRENT_CHAPTER=$(jq -r '.statistics.currentChapter // 0' "$PROGRESS")

            # Проверка просроченных, неиспользованных затравк
            OVERDUE=$(jq --arg current "$CURRENT_CHAPTER" '
                [.foreshadowing[] |
                 select(.status == "active" and .planted.chapter and
                        (($current | tonumber) - .planted.chapter) > 50)] |
                length' "$PLOT_TRACKER")

            check "Своевременное использование затравки" \
                  "[ '$OVERDUE' = '0' ]" \
                  "просрочено ${OVERDUE} затравки, не использованных более 50 глав"
        fi

        echo "  📊 Статистика затравки: всего ${TOTAL_FORESHADOW} шт., активных ${ACTIVE_FORESHADOW} шт."

        # Предупреждение о слишком большом количестве активных затравк
        if [ "$ACTIVE_FORESHADOW" -gt 10 ]; then
            warn "Слишком много активных затравк (${ACTIVE_FORESHADOW} шт.), что может вызвать путаницу у читателя"
        fi
    else
        warn "Файл отслеживания сюжета отсутствует"
    fi

    echo ""
}

# Проверка целостности файлов
check_file_integrity() {
    echo "📁 Проверка целостности файлов"
    echo "────────────────"

    check "progress.json" "[ -f '$PROGRESS' ]" "Файл отсутствует"
    check "plot-tracker.json" "[ -f '$PLOT_TRACKER' ]" "Файл отсутствует"
    check "timeline.json" "[ -f '$TIMELINE' ]" "Файл отсутствует"
    check "relationships.json" "[ -f '$RELATIONSHIPS' ]" "Файл отсутствует"
    check "character-state.json" "[ -f '$CHARACTER_STATE' ]" "Файл отсутствует"

    # Проверка валидности формата JSON
    for file in "$PROGRESS" "$PLOT_TRACKER" "$TIMELINE" "$RELATIONSHIPS" "$CHARACTER_STATE"; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if jq empty "$file" 2>/dev/null; then
                check "$filename формат" "true" ""
            else
                check "$filename формат" "false" "Невалидный формат JSON"
            fi
        fi
    done

    echo ""
}

# Генерация отчета
generate_report() {
    echo "═══════════════════════════════════════"
    echo "📊 Комплексный отчет о проверке согласованности"
    echo "═══════════════════════════════════════"
    echo ""

    check_file_integrity
    check_chapter_consistency
    check_timeline_consistency
    check_character_consistency
    check_foreshadowing_plan

    echo "═══════════════════════════════════════"
    echo "📈 Сводка результатов проверки"
    echo "───────────────────"
    echo "  Всего проверок: ${TOTAL_CHECKS}"
    echo -e "  ${GREEN}Успешно: ${PASSED_CHECKS}${NC}"
    echo -e "  ${YELLOW}Предупреждений: ${WARNINGS}${NC}"
    echo -e "  ${RED}Ошибок: ${ERRORS}${NC}"

    if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Отлично! Все пункты проверки пройдены${NC}"
    elif [ "$ERRORS" -eq 0 ]; then
        echo ""
        echo -e "${YELLOW}⚠️  Обнаружено ${WARNINGS} предупреждений, рекомендуется обратить внимание${NC}"
    else
        echo ""
        echo -e "${RED}❌ Обнаружено ${ERRORS} ошибок, требуется исправление${NC}"
    fi

    echo "═══════════════════════════════════════"
    echo ""
    echo "Время проверки: $(date '+%Y-%m-%d %H:%M:%S')"

    # Запись результатов проверки
    if [ -f "$STORY_DIR/spec/tracking" ]; then
        echo "{
            \"timestamp\": \"$(date -Iseconds)\",
            \"total\": $TOTAL_CHECKS,
            \"passed\": $PASSED_CHECKS,
            \"warnings\": $WARNINGS,
            \"errors\": $ERRORS
        }" > "$STORY_DIR/spec/tracking/.last-check.json"
    fi
}

# Основная функция
main() {
    generate_report

    # Возврат соответствующего кода выхода в зависимости от результатов
    if [ "$ERRORS" -gt 0 ]; then
        exit 1
    elif [ "$WARNINGS" -gt 0 ]; then
        exit 0  # Предупреждения не считаются ошибкой
    else
        exit 0
    fi
}

# Выполнение основной функции
main
```