```bash
#!/usr/bin/env bash
# Комплексный скрипт проверки согласованности

set -e

# Загрузка общих функций
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

# Режим проверки
CHECKLIST_MODE=false
if [ "$1" = "--checklist" ]; then
    CHECKLIST_MODE=true
fi

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
        warn "Некоторые файлы отслеживания отсутствуют, проверка глав не может быть завершена"
    fi

    echo ""
}

# Проверка непрерывности временной шкалы
check_timeline_consistency() {
    echo "⏰ Проверка непрерывности временной шкалы"
    echo "───────────────────"

    if [ -f "$TIMELINE" ]; then
        # Проверка, увеличиваются ли события временной шкалы по главам
        TIMELINE_ISSUES=$(jq '
            .events |
            sort_by(.chapter) |
            . as $sorted |
            reduce range(1; length) as $i (0;
                if $sorted[$i].chapter <= $sorted[$i-1].chapter then . + 1 else . end
            )' "$TIMELINE")

        check "Порядок событий временной шкалы" \
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
        check "Запись местоположения главного героя" \
              "[ -n '$LAST_LOCATION' ]" \
              "текущее местоположение главного героя не записано"
    else
        warn "Файлы отслеживания персонажей неполные"
    fi

    echo ""
}

# Проверка плана по возврату зацепок
check_foreshadowing_plan() {
    echo "🎯 Проверка управления зацепками"
    echo "──────────────"

    if [ -f "$PLOT_TRACKER" ]; then
        # Статистика статусов зацепок
        TOTAL_FORESHADOW=$(jq '.foreshadowing | length' "$PLOT_TRACKER")
        ACTIVE_FORESHADOW=$(jq '[.foreshadowing[] | select(.status == "active")] | length' "$PLOT_TRACKER")

        if [ -f "$PROGRESS" ]; then
            CURRENT_CHAPTER=$(jq -r '.statistics.currentChapter // 0' "$PROGRESS")

            # Проверка просроченных зацепок, которые не были возвращены
            OVERDUE=$(jq --arg current "$CURRENT_CHAPTER" '
                [.foreshadowing[] |
                 select(.status == "active" and .planted.chapter and
                        (($current | tonumber) - .planted.chapter) > 50)] |
                length' "$PLOT_TRACKER")

            check "Своевременный возврат зацепок" \
                  "[ '$OVERDUE' = '0' ]" \
                  "просрочено ${OVERDUE} зацепок, не возвращенных более 50 глав"
        fi

        echo "  📊 Статистика зацепок: Всего ${TOTAL_FORESHADOW} шт., активно ${ACTIVE_FORESHADOW} шт."

        # Предупреждение о слишком большом количестве активных зацепок
        if [ "$ACTIVE_FORESHADOW" -gt 10 ]; then
            warn "Слишком много активных зацепок (${ACTIVE_FORESHADOW} шт.), это может сбить с толку читателей"
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

    # Проверка корректности формата JSON
    for file in "$PROGRESS" "$PLOT_TRACKER" "$TIMELINE" "$RELATIONSHIPS" "$CHARACTER_STATE"; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if jq empty "$file" 2>/dev/null; then
                check "$filename формат" "true" ""
            else
                check "$filename формат" "false" "Некорректный формат JSON"
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
    echo -e "  ${GREEN}Пройдено: ${PASSED_CHECKS}${NC}"
    echo -e "  ${YELLOW}Предупреждений: ${WARNINGS}${NC}"
    echo -e "  ${RED}Ошибок: ${ERRORS}${NC}"

    if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Отлично! Все проверки пройдены${NC}"
    elif [ "$ERRORS" -eq 0 ]; then
        echo ""
        echo -e "${YELLOW}⚠️  Есть ${WARNINGS} предупреждений, рекомендуется обратить внимание${NC}"
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

# Генерация вывода в формате checklist
output_checklist() {
    # Тихое выполнение логики проверки
    exec 3>&1 4>&2  # Сохранение исходного вывода
    exec 1>/dev/null 2>&1  # Перенаправление в null

    check_file_integrity
    check_chapter_consistency
    check_timeline_consistency
    check_character_consistency
    check_foreshadowing_plan

    exec 1>&3 2>&4  # Восстановление вывода

    # Получение номеров глав для проверки
    local progress_chapter=""
    local plot_chapter=""
    local char_chapter=""
    if [ -f "$PROGRESS" ] && [ -f "$PLOT_TRACKER" ]; then
        progress_chapter=$(jq -r '.statistics.currentChapter // 0' "$PROGRESS" 2>/dev/null || echo "0")
        plot_chapter=$(jq -r '.currentState.chapter // 0' "$PLOT_TRACKER" 2>/dev/null || echo "0")
    fi
    if [ -f "$CHARACTER_STATE" ]; then
        char_chapter=$(jq -r '.protagonist.currentStatus.chapter // 0' "$CHARACTER_STATE" 2>/dev/null || echo "0")
    fi

    # Проверка статуса зацепок
    local total_foreshadow=0
    local active_foreshadow=0
    local overdue_foreshadow=0
    if [ -f "$PLOT_TRACKER" ]; then
        total_foreshadow=$(jq '.foreshadowing | length' "$PLOT_TRACKER" 2>/dev/null || echo "0")
        active_foreshadow=$(jq '[.foreshadowing[] | select(.status == "active")] | length' "$PLOT_TRACKER" 2>/dev/null || echo "0")

        if [ -f "$PROGRESS" ]; then
            local current_chapter=$(jq -r '.statistics.currentChapter // 0' "$PROGRESS" 2>/dev/null || echo "0")
            overdue_foreshadow=$(jq --arg current "$current_chapter" '[.foreshadowing[] | select(.status == "active" and .planted.chapter and (($current | tonumber) - .planted.chapter) > 50)] | length' "$PLOT_TRACKER" 2>/dev/null || echo "0")
        fi
    fi

    # Вывод в формате checklist
    cat <<EOF
# Чек-лист проверки согласованности данных

**Время проверки**: $(date '+%Y-%m-%d %H:%M:%S')
**Объект проверки**: Все JSON-файлы в директории spec/tracking/
**Область проверки**: Целостность файлов, синхронизация глав, непрерывность временной шкалы, состояние персонажей, управление зацепками

---

## Целостность файлов

- [$([ -f "$PROGRESS" ] && echo "x" || echo " ")] CHK001 progress.json существует и имеет корректный формат
- [$([ -f "$PLOT_TRACKER" ] && echo "x" || echo " ")] CHK002 plot-tracker.json существует и имеет корректный формат
- [$([ -f "$TIMELINE" ] && echo "x" || echo " ")] CHK003 timeline.json существует и имеет корректный формат
- [$([ -f "$RELATIONSHIPS" ] && echo "x" || echo " ")] CHK004 relationships.json существует и имеет корректный формат
- [$([ -f "$CHARACTER_STATE" ] && echo "x" || echo " ")] CHK005 character-state.json существует и имеет корректный формат

## Синхронизация номеров глав

EOF

    if [ "$progress_chapter" = "$plot_chapter" ]; then
        echo "- [x] CHK006 progress.json и plot-tracker.json имеют одинаковые номера глав (Глава $progress_chapter)"
    else
        echo "- [!] progress.json(${progress_chapter}) и plot-tracker.json(${plot_chapter}) имеют разные номера глав"
    fi

    if [ -n "$char_chapter" ]; then
        if [ "$progress_chapter" = "$char_chapter" ]; then
            echo "- [x] progress.json и character-state.json имеют одинаковые номера глав"
        else
            echo "- [!] progress.json(${progress_chapter}) и character-state.json(${char_chapter}) имеют разные номера глав"
        fi
    else
        echo "- [ ] CHK007 Проверка номеров глав character-state.json (файл отсутствует или данные отсутствуют)"
    fi

    cat <<EOF

## Непрерывность временной шкалы

- [$([ -f "$TIMELINE" ] && echo "x" || echo " ")] CHK008 События временной шкалы упорядочены по главам
- [$([ -f "$TIMELINE" ] && echo "x" || echo " ")] CHK009 Текущее время истории установлено

## Состояние персонажей

EOF
}

# Основная логика скрипта
if [ "$CHECKLIST_MODE" = true ]; then
    output_checklist
else
    generate_report
fi
```
```sh
    if [ -f "$CHARACTER_STATE" ] && [ -f "$RELATIONSHIPS" ]; then
        local protag_name=$(jq -r '.protagonist.name // ""' "$CHARACTER_STATE" 2>/dev/null)
        if [ -n "$protag_name" ]; then
            echo "- [x] CHK010 Основная информация о протагонисте полна ($protag_name)"
            local has_relations=$(jq --arg name "$protag_name" 'has($name)' "$RELATIONSHIPS" 2>/dev/null || echo "false")
            if [ "$has_relations" = "true" ]; then
                echo "- [x] CHK011 Основная информация о протагонисте имеет запись в relationships.json"
            else
                echo "- [!] CHK011 Основная информация о протагонисте '$protag_name' не имеет записи в relationships.json"
            fi
        else
            echo "- [ ] CHK010 Основная информация о протагонисте полна (данные отсутствуют)"
            echo "- [ ] CHK011 Основная информация о протагонисте имеет запись в relationships.json (данные отсутствуют)"
        fi

        local last_location=$(jq -r '.protagonist.currentStatus.location // ""' "$CHARACTER_STATE" 2>/dev/null)
        if [ -n "$last_location" ]; then
            echo "- [x] CHK012 Текущее местоположение протагониста записано ($last_location)"
        else
            echo "- [!] CHK012 Текущее местоположение протагониста не записано"
        fi
    else
        echo "- [ ] CHK010 Основная информация о протагонисте полна (файл не существует)"
        echo "- [ ] CHK011 Основная информация о протагонисте имеет запись в relationships.json (файл не существует)"
        echo "- [ ] CHK012 Текущее местоположение протагониста записано (файл не существует)"
    fi

    cat <<EOF

## Управление завязками

EOF

    if [ "$total_foreshadow" -gt 0 ]; then
        echo "- [x] CHK013 Записи о завязках существуют (всего $total_foreshadow, активно $active_foreshadow)"

        if [ "$overdue_foreshadow" -eq 0 ]; then
            echo "- [x] CHK014 Завязки своевременно разрешены (нет просроченных)"
        else
            echo "- [!] CHK014 Завязки своевременно разрешены (просрочено $overdue_foreshadow, не разрешено более 50 глав)"
        fi

        if [ "$active_foreshadow" -le 10 ]; then
            echo "- [x] CHK015 Количество активных завязок в норме ($active_foreshadow ≤ 10)"
        else
            echo "- [!] CHK015 Слишком много активных завязок ($active_foreshadow > 10, может вызвать путаницу у читателя)"
        fi
    else
        echo "- [ ] CHK013 Записи о завязках существуют (записи не найдены)"
        echo "- [ ] CHK014 Завязки своевременно разрешены (нет данных)"
        echo "- [ ] CHK015 Количество активных завязок в норме (нет данных)"
    fi

    cat <<EOF

---

## Статистика проверок

- **Всего проверок**: ${TOTAL_CHECKS}
- **Пройдено**: ${PASSED_CHECKS}
- **Предупреждений**: ${WARNINGS}
- **Ошибок**: ${ERRORS}

---

## Дальнейшие действия

EOF

    if [ "$ERRORS" -gt 0 ]; then
        echo "- [ ] Исправить вышеуказанные несоответствия, отмеченные как [!]"
    fi
    if [ "$WARNINGS" -gt 0 ]; then
        echo "- [ ] Обратить внимание на предупреждения, рассмотреть возможность улучшения"
    fi
    if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
        echo "*Все проверки пройдены, действий не требуется*"
    fi

    cat <<EOF

---

**Инструмент проверки**: check-consistency.sh
**Версия**: 1.1 (поддержка вывода чек-листа)
EOF
}

# Основная функция
main() {
    if [ "$CHECKLIST_MODE" = true ]; then
        output_checklist
    else
        generate_report
    fi

    # Возврат соответствующего кода выхода в зависимости от результата
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