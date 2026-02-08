#!/usr/bin/env bash
# Проверка согласованности и связности развития сюжета

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
PLOT_TRACKER="$STORY_DIR/spec/tracking/plot-tracker.json"
OUTLINE="$STORY_DIR/outline.md"
PROGRESS="$STORY_DIR/progress.json"

# Проверка необходимых файлов
check_required_files() {
    local missing=false

    if [ ! -f "$PLOT_TRACKER" ]; then
        echo "⚠️  Файл отслеживания сюжета не найден, создаем..." >&2
        mkdir -p "$STORY_DIR/spec/tracking"
        # Копирование шаблона
        if [ -f "$SCRIPT_DIR/../../templates/tracking/plot-tracker.json" ]; then
            cp "$SCRIPT_DIR/../../templates/tracking/plot-tracker.json" "$PLOT_TRACKER"
        else
            echo "Ошибка: Невозможно найти файл шаблона" >&2
            exit 1
        fi
    fi

    if [ ! -f "$OUTLINE" ]; then
        echo "Ошибка: Файл плана глав (outline.md) не найден" >&2
        echo "Пожалуйста, сначала создайте план с помощью команды /outline" >&2
        exit 1
    fi
}

# Чтение текущего прогресса
get_current_progress() {
    if [ -f "$PROGRESS" ]; then
        CURRENT_CHAPTER=$(jq -r '.statistics.currentChapter // 1' "$PROGRESS")
        CURRENT_VOLUME=$(jq -r '.statistics.currentVolume // 1' "$PROGRESS")
    else
        CURRENT_CHAPTER=$(jq -r '.currentState.chapter // 1' "$PLOT_TRACKER")
        CURRENT_VOLUME=$(jq -r '.currentState.volume // 1' "$PLOT_TRACKER")
    fi
}

# Анализ согласованности сюжета
analyze_plot_alignment() {
    echo "📊 Отчет о проверке развития сюжета"
    echo "━━━━━━━━━━━━━━━━━━━━"

    # Текущий прогресс
    echo "📍 Текущий прогресс: Глава ${CURRENT_CHAPTER} (Том ${CURRENT_VOLUME})"

    # Чтение данных отслеживания сюжета
    if [ -f "$PLOT_TRACKER" ]; then
        MAIN_PLOT=$(jq -r '.plotlines.main.currentNode // "Не задано"' "$PLOT_TRACKER")
        PLOT_STATUS=$(jq -r '.plotlines.main.status // "unknown"' "$PLOT_TRACKER")
        echo "📖 Прогресс основной линии: $MAIN_PLOT [$PLOT_STATUS]"

        # Завершенные узлы
        COMPLETED_COUNT=$(jq '.plotlines.main.completedNodes | length' "$PLOT_TRACKER")
        echo ""
        echo "✅ Завершенные узлы: ${COMPLETED_COUNT} шт."
        jq -r '.plotlines.main.completedNodes[]? | "  • " + .' "$PLOT_TRACKER" 2>/dev/null || true

        # Предстоящие узлы
        UPCOMING_COUNT=$(jq '.plotlines.main.upcomingNodes | length' "$PLOT_TRACKER")
        if [ "$UPCOMING_COUNT" -gt 0 ]; then
            echo ""
            echo "→ Предстоящие узлы:"
            jq -r '.plotlines.main.upcomingNodes[0:3][]? | "  • " + .' "$PLOT_TRACKER" 2>/dev/null || true
        fi
    fi
}

# Проверка состояния заделов
check_foreshadowing() {
    echo ""
    echo "🎯 Отслеживание заделов"
    echo "───────────"

    if [ -f "$PLOT_TRACKER" ]; then
        # Статистика заделов
        TOTAL_FORESHADOW=$(jq '.foreshadowing | length' "$PLOT_TRACKER")
        ACTIVE_FORESHADOW=$(jq '[.foreshadowing[] | select(.status == "active")] | length' "$PLOT_TRACKER")
        RESOLVED_FORESHADOW=$(jq '[.foreshadowing[] | select(.status == "resolved")] | length' "$PLOT_TRACKER")

        echo "Статистика: всего ${TOTAL_FORESHADOW} шт., активно ${ACTIVE_FORESHADOW} шт., разрешено ${RESOLVED_FORESHADOW} шт."

        # Перечисление активных заделов
        if [ "$ACTIVE_FORESHADOW" -gt 0 ]; then
            echo ""
            echo "⚠️ Активные заделы:"
            jq -r '.foreshadowing[] | select(.status == "active") |
                "  • " + .content + "（Заложено в главе " + (.planted.chapter | tostring) + "）"' \
                "$PLOT_TRACKER" 2>/dev/null || true
        fi

        # Проверка просроченных заделов (более 30 глав не обработано)
        OVERDUE=$(jq --arg current "$CURRENT_CHAPTER" '
            [.foreshadowing[] |
             select(.status == "active" and .planted.chapter and
                    (($current | tonumber) - .planted.chapter) > 30)] |
            length' "$PLOT_TRACKER")

        if [ "$OVERDUE" -gt 0 ]; then
            echo ""
            echo "⚠️ Предупреждение: ${OVERDUE} заделов не обработано более 30 глав"
        fi
    fi
}

# Проверка развития конфликтов
check_conflicts() {
    echo ""
    echo "⚔️ Отслеживание конфликтов"
    echo "───────────"

    if [ -f "$PLOT_TRACKER" ]; then
        ACTIVE_CONFLICTS=$(jq '.conflicts.active | length' "$PLOT_TRACKER")

        if [ "$ACTIVE_CONFLICTS" -gt 0 ]; then
            echo "Текущие активные конфликты: ${ACTIVE_CONFLICTS} шт."
            jq -r '.conflicts.active[] |
                "  • " + .name + " [" + .intensity + "]"' \
                "$PLOT_TRACKER" 2>/dev/null || true
        else
            echo "Активных конфликтов нет"
        fi
    fi
}

# Генерация предложений
generate_suggestions() {
    echo ""
    echo "💡 Предложения"
    echo "───────"

    # Предложения на основе текущей главы
    if [ "$CURRENT_CHAPTER" -lt 10 ]; then
        echo "• Первые 10 глав — ключевые, убедитесь, что есть достаточно крючков для читателя"
    elif [ "$CURRENT_CHAPTER" -lt 30 ]; then
        echo "• Приближается первый мини-кульминационный момент, проверьте, достаточно ли напряжены конфликты"
    elif [ "$((CURRENT_CHAPTER % 60))" -gt 50 ]; then
        echo "• Приближается конец тома, подготовьте кульминацию и завязку для продолжения"
    fi

    # Предложения на основе состояния заделов
    if [ "$ACTIVE_FORESHADOW" -gt 5 ]; then
        echo "• Активно много заделов, рассмотрите возможность разрешения некоторых из них в ближайших главах"
    fi

    # Предложения на основе состояния конфликтов
    if [ "$ACTIVE_CONFLICTS" -eq 0 ] && [ "$CURRENT_CHAPTER" -gt 5 ]; then
        echo "• В настоящее время нет активных конфликтов, рассмотрите возможность введения новых точек напряжения"
    fi
}

# Генерация вывода в формате checklist
output_checklist() {
    # Проверка необходимых файлов (тихо)
    check_required_files > /dev/null 2>&1 || true

    # Получение текущего прогресса
    get_current_progress

    # Сбор данных
    local main_plot="Не задано"
    local plot_status="unknown"
    local completed_count=0
    local upcoming_count=0
    local total_foreshadow=0
    local active_foreshadow=0
    local resolved_foreshadow=0
    local overdue_foreshadow=0
    local active_conflicts=0

    if [ -f "$PLOT_TRACKER" ]; then
        main_plot=$(jq -r '.plotlines.main.currentNode // "Не задано"' "$PLOT_TRACKER")
        plot_status=$(jq -r '.plotlines.main.status // "unknown"' "$PLOT_TRACKER")
        completed_count=$(jq '.plotlines.main.completedNodes | length' "$PLOT_TRACKER")
        upcoming_count=$(jq '.plotlines.main.upcomingNodes | length' "$PLOT_TRACKER")

        total_foreshadow=$(jq '.foreshadowing | length' "$PLOT_TRACKER")
        active_foreshadow=$(jq '[.foreshadowing[] | select(.status == "active")] | length' "$PLOT_TRACKER")
        resolved_foreshadow=$(jq '[.foreshadowing[] | select(.status == "resolved")] | length' "$PLOT_TRACKER")

        overdue_foreshadow=$(jq --arg current "$CURRENT_CHAPTER" '
            [.foreshadowing[] |
             select(.status == "active" and .planted.chapter and
                    (($current | tonumber) - .planted.chapter) > 30)] |
            length' "$PLOT_TRACKER")

        active_conflicts=$(jq '.conflicts.active | length' "$PLOT_TRACKER")
    fi

    # Вывод в формате checklist
    cat <<EOF
# Чек-лист проверки сюжета

**Время проверки**: $(date '+%Y-%m-%d %H:%M:%S')
**Проверяемые объекты**: plot-tracker.json, outline.md, progress.json
**Текущий прогресс**: Глава ${CURRENT_CHAPTER} (Том ${CURRENT_VOLUME})

---

## Полнота файлов

- [$([ -f "$PLOT_TRACKER" ] && echo "x" || echo " ")] CHK001 Файл plot-tracker.json существует
- [$([ -f "$OUTLINE" ] && echo "x" || echo " ")] CHK002 Файл outline.md существует
- [$([ -f "$PROGRESS" ] && echo "x" || echo " ")] CHK003 Файл progress.json существует

## Прогресс сюжета

- [$([ "$plot_status" != "unknown" ] && echo "x" || echo " ")] CHK004 Статус основного сюжета обновлен (текущий: $plot_status)
- [x] CHK005 Прогресс узлов основного сюжета: $main_plot
- [$([ $completed_count -gt 0 ] && echo "x" || echo " ")] CHK006 Завершенные узлы сюжета ($completed_count шт.)
- [$([ $upcoming_count -gt 0 ] && echo "x" || echo " ")] CHK007 Запланированы последующие узлы сюжета ($upcoming_count шт.)

## Управление заделами

EOF

    if [ $total_foreshadow -gt 0 ]; then
        echo "- [x] CHK008 Записи о заделах существуют (всего $total_foreshadow шт.)"
        echo "- [x] CHK009 Отслеживание статуса заделов (активных $active_foreshadow шт., разрешенных $resolved_foreshadow шт.)"

        if [ $overdue_foreshadow -eq 0 ]; then
            echo "- [x] CHK010 Своевременное разрешение заделов (нет просроченных более 30 глав)"
        else
            echo "- [!] CHK010 Своевременное разрешение заделов (⚠️ ${overdue_foreshadow} шт. не обрабатывались более 30 глав)"
        fi

        if [ $active_foreshadow -le 5 ]; then
            echo "- [x] CHK011 Количество активных заделов в норме ($active_foreshadow ≤ 5)"
        elif [ $active_foreshadow -le 10 ]; then
            echo "- [!] CHK011 Количество активных заделов немного превышено ($active_foreshadow шт., рекомендуется частичное разрешение)"
        else
            echo "- [!] CHK011 Количество активных заделов чрезмерно (⚠️ $active_foreshadow > 10, возможно возникновение путаницы)"
        fi
    else
        echo "- [ ] CHK008 Записи о заделах существуют (записи о заделах не найдены)"
        echo "- [ ] CHK009 Отслеживание статуса заделов (нет данных)"
        echo "- [ ] CHK010 Своевременное разрешение заделов (нет данных)"
        echo "- [ ] CHK011 Количество активных заделов в норме (нет данных)"
    fi

    cat <<EOF

## Развитие конфликтов

EOF

    if [ $active_conflicts -gt 0 ]; then
        echo "- [x] CHK012 Существуют активные конфликты ($active_conflicts шт.)"
    elif [ $CURRENT_CHAPTER -gt 5 ]; then
        echo "- [!] CHK012 Существуют активные конфликты (⚠️ В настоящее время активных конфликтов нет, рекомендуется ввести точки напряжения)"
    else
        echo "- [x] CHK012 Существуют активные конфликты (ранние главы, конфликты могут отсутствовать)"
    fi

    cat <<EOF

## Рекомендации по темпу

EOF

    # Проверка на основе текущей главы
    if [ $CURRENT_CHAPTER -lt 10 ]; then
        echo "- [ ] CHK013 Настройка крючков в первых 10 главах (обеспечить достаточную привлекательность)"
    elif [ $CURRENT_CHAPTER -lt 30 ]; then
        echo "- [ ] CHK014 Подготовка к первому мини-кульминационному моменту (проверить интенсивность конфликтов)"
    elif [ $((CURRENT_CHAPTER % 60)) -gt 50 ]; then
        echo "- [ ] CHK015 Настройка кульминации в конце тома (подготовить завязку и кульминацию)"
    else
        echo "- [x] CHK016 Темп нормальный (нет особых напоминаний по этапу)"
    fi

    cat <<EOF

---

## Дальнейшие действия

EOF

    # Динамическая генерация дальнейших действий
    local has_actions=false

    if [ $overdue_foreshadow -gt 0 ]; then
        echo "- [ ] Разрешить просроченные заделы (${overdue_foreshadow} шт.)"
        has_actions=true
    fi

    if [ $active_foreshadow -gt 10 ]; then
        echo "- [ ] Сократить количество активных заделов (текущее: $active_foreshadow шт.)"
        has_actions=true
    fi

    if [ $active_conflicts -eq 0 ] && [ $CURRENT_CHAPTER -gt 5 ]; then
        echo "- [ ] Ввести новые точки конфликта"
        has_actions=true
    fi

    if [ $upcoming_count -eq 0 ]; then
        echo "- [ ] Спланировать последующие узлы сюжета"
        has_actions=true
    fi

    if [ "$has_actions" = false ]; then
        echo "*Текущее развитие сюжета хорошее, особых действий не требуется*"
    fi

    cat <<EOF

---

**Инструмент проверки**: check-plot.sh
**Версия**: 1.1 (поддержка вывода checklist)
EOF
}

# Основная функция
main() {
    if [ "$CHECKLIST_MODE" = true ]; then
        output_checklist
    else
        echo "🔍 Начинаем проверку согласованности сюжета..."
        echo ""

        # Проверка необходимых файлов
        check_required_files

        # Получение текущего прогресса
        get_current_progress

        # Выполнение проверок
        analyze_plot_alignment
        check_foreshadowing
        check_conflicts
        generate_suggestions

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━"
        echo "✅ Проверка завершена"
    fi

    # Обновление времени проверки
    if [ -f "$PLOT_TRACKER" ]; then
        TEMP_FILE=$(mktemp)
        jq --arg date "$(date -Iseconds)" '.lastUpdated = $date' "$PLOT_TRACKER" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$PLOT_TRACKER"
    fi
}

# Запуск основной функции
main