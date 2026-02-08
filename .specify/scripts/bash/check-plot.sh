#!/usr/bin/env bash
# Проверка согласованности и связности развития сюжета

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
            echo "Ошибка: Не удалось найти файл шаблона" >&2
            exit 1
        fi
    fi

    if [ ! -f "$OUTLINE" ]; then
        echo "Ошибка: Файл плана глав (outline.md) не найден" >&2
        echo "Пожалуйста, сначала используйте команду /outline для создания плана" >&2
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

# Анализ соответствия сюжета
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
        echo "✅ Завершено узлов: ${COMPLETED_COUNT} шт."
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

# Проверка статуса завязок
check_foreshadowing() {
    echo ""
    echo "🎯 Отслеживание завязок"
    echo "───────────"

    if [ -f "$PLOT_TRACKER" ]; then
        # Статистика завязок
        TOTAL_FORESHADOW=$(jq '.foreshadowing | length' "$PLOT_TRACKER")
        ACTIVE_FORESHADOW=$(jq '[.foreshadowing[] | select(.status == "active")] | length' "$PLOT_TRACKER")
        RESOLVED_FORESHADOW=$(jq '[.foreshadowing[] | select(.status == "resolved")] | length' "$PLOT_TRACKER")

        echo "Статистика: всего ${TOTAL_FORESHADOW} шт., активно ${ACTIVE_FORESHADOW} шт., разрешено ${RESOLVED_FORESHADOW} шт."

        # Список активных завязок
        if [ "$ACTIVE_FORESHADOW" -gt 0 ]; then
            echo ""
            echo "⚠️ Активные завязки:"
            jq -r '.foreshadowing[] | select(.status == "active") |
                "  • " + .content + " (заложено в главе " + (.planted.chapter | tostring) + ")" ' \
                "$PLOT_TRACKER" 2>/dev/null || true
        fi

        # Проверка просроченных завязок (не разрешены более чем за 30 глав)
        OVERDUE=$(jq --arg current "$CURRENT_CHAPTER" '
            [.foreshadowing[] |
             select(.status == "active" and .planted.chapter and
                    (($current | tonumber) - .planted.chapter) > 30)] |
            length' "$PLOT_TRACKER")

        if [ "$OVERDUE" -gt 0 ]; then
            echo ""
            echo "⚠️ Предупреждение: ${OVERDUE} завязок не разрешены более 30 глав"
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
            echo "Текущих активных конфликтов: ${ACTIVE_CONFLICTS} шт."
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
        echo "• Первые 10 глав — ключевые, убедитесь, что достаточно крючков для привлечения читателя"
    elif [ "$CURRENT_CHAPTER" -lt 30 ]; then
        echo "• Приближается первый кульминационный момент, проверьте, достаточно ли напряжены конфликты"
    elif [ "$((CURRENT_CHAPTER % 60))" -gt 50 ]; then
        echo "• Близок конец тома, готовьтесь к кульминации и установке интриги"
    fi

    # Предложения на основе статуса завязок
    if [ "$ACTIVE_FORESHADOW" -gt 5 ]; then
        echo "• Активно много завязок, рассмотрите возможность разрешения некоторых из них в ближайших главах"
    fi

    # Предложения на основе статуса конфликтов
    if [ "$ACTIVE_CONFLICTS" -eq 0 ] && [ "$CURRENT_CHAPTER" -gt 5 ]; then
        echo "• Текущих конфликтов нет, рассмотрите возможность введения новой точки напряжения"
    fi
}

# Основная функция
main() {
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

    # Обновление времени проверки
    if [ -f "$PLOT_TRACKER" ]; then
        TEMP_FILE=$(mktemp)
        jq --arg date "$(date -Iseconds)" '.lastUpdated = $date' "$PLOT_TRACKER" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$PLOT_TRACKER"
    fi
}

# Выполнение основной функции
main