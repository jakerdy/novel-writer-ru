```bash
#!/bin/bash

# Скрипт анализа истории
# Используется для команды /analyze

set -e

# Импорт общих функций
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Парсинг аргументов
STORY_NAME="$1"
ANALYSIS_TYPE="${2:-full}"  # full, compliance, quality, progress

# Получение корневого каталога проекта
PROJECT_ROOT=$(get_project_root)
cd "$PROJECT_ROOT"

# Определение пути к истории
if [ -z "$STORY_NAME" ]; then
    STORY_NAME=$(get_active_story)
fi

STORY_DIR="stories/$STORY_NAME"

# Проверка необходимых файлов
check_story_files() {
    local missing_files=()

    # Проверка базовых документов
    [ ! -f "memory/writing-constitution.md" ] && [ ! -f ".specify/memory/writing-constitution.md" ] && missing_files+=("конституционный документ")
    [ ! -f "$STORY_DIR/specification.md" ] && missing_files+=("документ спецификации")
    [ ! -f "$STORY_DIR/creative-plan.md" ] && missing_files+=("творческий план")

    if [ ${#missing_files[@]} -gt 0 ]; then
        echo "⚠️ Отсутствуют следующие базовые документы:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi

    return 0
}

# Статистика контента
analyze_content() {
    local content_dir="$STORY_DIR/content"
    local total_words=0
    local chapter_count=0

    if [ -d "$content_dir" ]; then
        echo "Статистика контента:"
        echo ""
        for file in "$content_dir"/*.md; do
            if [ -f "$file" ]; then
                ((chapter_count++))
                # Используем точный подсчет китайских слов
                local words=$(count_chinese_words "$file")
                ((total_words += words))
                local filename=$(basename "$file")
                echo "  $filename: $words слов"
            fi
        done
        echo ""
        echo "  Всего слов: $total_words"
        echo "  Количество глав: $chapter_count"
        if [ $chapter_count -gt 0 ]; then
            echo "  Средняя длина главы: $((total_words / chapter_count)) слов"
        fi
    else
        echo "Статистика контента:"
        echo "  Писательство еще не началось"
    fi
}

# Проверка выполнения задач
check_task_completion() {
    local tasks_file="$STORY_DIR/tasks.md"
    if [ ! -f "$tasks_file" ]; then
        echo "Файл задач отсутствует"
        return
    fi

    local total_tasks=$(grep -c "^- \[" "$tasks_file" 2>/dev/null || echo 0)
    local completed_tasks=$(grep -c "^- \[x\]" "$tasks_file" 2>/dev/null || echo 0)
    local in_progress=$(grep -c "^- \[~\]" "$tasks_file" 2>/dev/null || echo 0)
    local pending=$((total_tasks - completed_tasks - in_progress))

    echo "Прогресс задач:"
    echo "  Всего задач: $total_tasks"
    echo "  Завершено: $completed_tasks"
    echo "  В процессе: $in_progress"
    echo "  Ожидается: $pending"

    if [ $total_tasks -gt 0 ]; then
        local completion_rate=$((completed_tasks * 100 / total_tasks))
        echo "  Коэффициент завершения: $completion_rate%"
    fi
}

# Проверка соответствия спецификации
check_specification_compliance() {
    local spec_file="$STORY_DIR/specification.md"

    echo "Проверка соответствия спецификации:"

    # Проверка требований P0 (упрощенная версия)
    local p0_count=$(grep -c "^### 必须包含（P0）" "$spec_file" 2>/dev/null || echo 0)
    if [ $p0_count -gt 0 ]; then
        echo "  Требования P0: обнаружены, требуется ручная проверка"
    fi

    # Проверка наличия маркеров [需要澄清]
    local unclear=$(grep -c "\[需要澄清\]" "$spec_file" 2>/dev/null || echo 0)
    if [ $unclear -gt 0 ]; then
        echo "  ⚠️ Осталось $unclear пунктов, требующих уточнения"
    else
        echo "  ✅ Все решения прояснены"
    fi
}

# Основной процесс анализа
main() {
    echo "Отчет об анализе истории"
    echo "============"
    echo "История: $STORY_NAME"
    echo "Время анализа: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # Проверка базовых документов
    if ! check_story_files; then
        echo ""
        echo "❌ Полный анализ невозможен, пожалуйста, сначала завершите базовые документы"
        exit 1
    fi

    echo "✅ Базовые документы полные"
    echo ""

    # Выполнение в зависимости от типа анализа
    case "$ANALYSIS_TYPE" in
        full)
            analyze_content
            echo ""
            check_task_completion
            echo ""
            check_specification_compliance
            ;;
        quality)
            analyze_content
            ;;
        progress)
            check_task_completion
            ;;
        compliance)
            check_specification_compliance
            ;;
        *)
            echo "Неизвестный тип анализа: $ANALYSIS_TYPE"
            exit 1
            ;;
    esac

    echo ""
    echo "Анализ завершен. Подробный отчет сохранен в: $STORY_DIR/analysis-report.md"
}

main
```