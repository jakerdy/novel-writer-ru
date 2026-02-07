```xml
#!/bin/bash

# Скрипт проверки состояния написания
# Используется для команды /write

set -e

# Подключение общих функций
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Проверка, включен ли режим checklist
CHECKLIST_MODE=false
if [ "$1" = "--checklist" ]; then
    CHECKLIST_MODE=true
fi

# Получение корневого каталога проекта
PROJECT_ROOT=$(get_project_root)
cd "$PROJECT_ROOT"

# Получение текущей истории
STORY_NAME=$(get_active_story)
STORY_DIR="stories/$STORY_NAME"

# Проверка документов методологии
check_methodology_docs() {
    local missing=()

    [ ! -f "memory/novel-constitution.md" ] && missing+=("Конституция")
    [ ! -f "$STORY_DIR/specification.md" ] && missing+=("Спецификация")
    [ ! -f "$STORY_DIR/creative-plan.md" ] && missing+=("План")
    [ ! -f "$STORY_DIR/tasks.md" ] && missing+=("Задачи")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "⚠️ Отсутствуют следующие базовые документы:"
        for doc in "${missing[@]}"; do
            echo "  - $doc"
        done
        echo ""
        echo "Рекомендуется выполнить предварительные шаги в соответствии с семишаговой методологией:"
        echo "1. /constitution - Создание конституции творчества"
        echo "2. /specify - Определение спецификации истории"
        echo "3. /clarify - Уточнение ключевых решений"
        echo "4. /plan - Составление плана творчества"
        echo "5. /tasks - Генерация списка задач"
        return 1
    fi

    echo "✅ Документы методологии в полном порядке"
    return 0
}

# Проверка ожидающих задач
check_pending_tasks() {
    local tasks_file="$STORY_DIR/tasks.md"

    if [ ! -f "$tasks_file" ]; then
        echo "❌ Файл задач отсутствует"
        return 1
    fi

    # Подсчет статусов задач
    local pending=$(grep -c "^- \[ \]" "$tasks_file" 2>/dev/null || echo 0)
    local in_progress=$(grep -c "^- \[~\]" "$tasks_file" 2>/dev/null || echo 0)
    local completed=$(grep -c "^- \[x\]" "$tasks_file" 2>/dev/null || echo 0)

    echo ""
    echo "Статус задач:"
    echo "  К выполнению: $pending"
    echo "  В процессе: $in_progress"
    echo "  Завершено: $completed"

    if [ $pending -eq 0 ] && [ $in_progress -eq 0 ]; then
        echo ""
        echo "🎉 Все задачи выполнены!"
        echo "Рекомендуется запустить /analyze для комплексной проверки"
        return 0
    fi

    # Отображение следующей задачи к выполнению
    echo ""
    echo "Следующая задача к выполнению:"
    grep "^- \[ \]" "$tasks_file" | head -n 1 || echo "（Нет ожидающих задач）"
}

# Проверка завершенного контента
check_completed_content() {
    local content_dir="$STORY_DIR/content"
    local validation_rules="spec/tracking/validation-rules.json"
    local min_words=2000
    local max_words=4000

    # Чтение правил валидации (если существуют)
    if [ -f "$validation_rules" ]; then
        if command -v jq >/dev/null 2>&1; then
            min_words=$(jq -r '.rules.chapterMinWords // 2000' "$validation_rules")
            max_words=$(jq -r '.rules.chapterMaxWords // 4000' "$validation_rules")
        fi
    fi

    if [ -d "$content_dir" ]; then
        local chapter_count=$(ls "$content_dir"/*.md 2>/dev/null | wc -l)
        if [ $chapter_count -gt 0 ]; then
            echo ""
            echo "Завершенные главы: $chapter_count"
            echo "Требования к объему: ${min_words}-${max_words} слов"
            echo ""
            echo "Последние записи:"
            for file in $(ls -t "$content_dir"/*.md 2>/dev/null | head -n 3); do
                local filename=$(basename "$file")
                local words=$(count_chinese_words "$file")
                local status="✅"

                if [ "$words" -lt "$min_words" ]; then
                    status="⚠️ Недостаточно слов"
                elif [ "$words" -gt "$max_words" ]; then
                    status="⚠️ Превышен объем"
                fi

                echo "  - $filename: $words слов $status"
            done
        fi
    else
        echo ""
        echo "Написание еще не начато"
    fi
}

# Генерация вывода в формате checklist
output_checklist() {
    local has_constitution=false
    local has_specification=false
    local has_plan=false
    local has_tasks=false
    local pending=0
    local in_progress=0
    local completed=0
    local chapter_count=0
    local bad_chapters=0
    local min_words=2000
    local max_words=4000

    # Проверка документов
    [ -f "memory/novel-constitution.md" ] && has_constitution=true
    [ -f "$STORY_DIR/specification.md" ] && has_specification=true
    [ -f "$STORY_DIR/creative-plan.md" ] && has_plan=true
    [ -f "$STORY_DIR/tasks.md" ] && has_tasks=true

    # Подсчет задач
    if [ "$has_tasks" = true ]; then
        pending=$(grep -c "^- \[ \]" "$STORY_DIR/tasks.md" 2>/dev/null || echo 0)
        in_progress=$(grep -c "^- \[~\]" "$STORY_DIR/tasks.md" 2>/dev/null || echo 0)
        completed=$(grep -c "^- \[x\]" "$STORY_DIR/tasks.md" 2>/dev/null || echo 0)
    fi

    # Чтение правил валидации
    local validation_rules="$STORY_DIR/spec/tracking/validation-rules.json"
    if [ -f "$validation_rules" ] && command -v jq >/dev/null 2>&1; then
        min_words=$(jq -r '.rules.chapterMinWords // 2000' "$validation_rules")
        max_words=$(jq -r '.rules.chapterMaxWords // 4000' "$validation_rules")
    fi

    # Проверка глав
    local content_dir="$STORY_DIR/content"
    if [ -d "$content_dir" ]; then
        chapter_count=$(ls "$content_dir"/*.md 2>/dev/null | wc -l | tr -d ' ')

        # Подсчет глав, не соответствующих требованиям по объему
        for file in "$content_dir"/*.md; do
            [ -f "$file" ] || continue
            local words=$(count_chinese_words "$file")
            if [ "$words" -lt "$min_words" ] || [ "$words" -gt "$max_words" ]; then
                bad_chapters=$((bad_chapters + 1))
            fi
        done
    fi

    # Расчет общего количества задач и процента выполнения
    local total_tasks=$((pending + in_progress + completed))
    local completion_rate=0
    if [ $total_tasks -gt 0 ]; then
        completion_rate=$((completed * 100 / total_tasks))
    fi

    # Вывод checklist
    cat <<EOF
# Чек-лист проверки состояния написания

**Время проверки**: $(date '+%Y-%m-%d %H:%M:%S')
**Текущая история**: $STORY_NAME
**Стандарт объема**: ${min_words}-${max_words} слов

---

## Полнота документации

- [$([ "$has_constitution" = true ] && echo "x" || echo " ")] CHK001 novel-constitution.md присутствует
- [$([ "$has_specification" = true ] && echo "x" || echo " ")] CHK002 specification.md присутствует
- [$([ "$has_plan" = true ] && echo "x" || echo " ")] CHK003 creative-plan.md присутствует
- [$([ "$has_tasks" = true ] && echo "x" || echo " ")] CHK004 tasks.md присутствует

## Прогресс выполнения задач

EOF

    if [ "$has_tasks" = true ]; then
        echo "- [$([ $in_progress -gt 0 ] && echo "x" || echo " ")] CHK005 Есть задачи в процессе выполнения ($in_progress шт.)"
        echo "- [x] CHK006 Количество задач к выполнению ($pending шт.)"
        echo "- [$([ $completed -gt 0 ] && echo "x" || echo " ")] CHK007 Прогресс выполнения задач ($completed/$total_tasks = $completion_rate%)"
    else
        echo "- [ ] CHK005 Есть задачи в процессе выполнения (tasks.md отсутствует)"
        echo "- [ ] CHK006 Количество задач к выполнению (tasks.md отсутствует)"
        echo "- [ ] CHK007 Прогресс выполнения задач (tasks.md отсутствует)"
    fi

    cat <<EOF

## Качество контента

- [$([ $chapter_count -gt 0 ] && echo "x" || echo " ")] CHK008 Количество завершенных глав ($chapter_count шт.)
EOF

    if [ $chapter_count -gt 0 ]; then
        echo "- [$([ $bad_chapters -eq 0 ] && echo "x" || echo "!")] CHK009 Объем соответствует стандарту ($([ $bad_chapters -eq 0 ] && echo "Все соответствует" || echo "$bad_chapters шт. не соответствуют")）"
    else
        echo "- [ ] CHK009 Объем соответствует стандарту (Написание еще не начато)"
    fi

    cat <<EOF

---

## Последующие действия

EOF

    local has_actions=false

    # Проверка отсутствующих документов
    if [ "$has_constitution" = false ] || [ "$has_specification" = false ] || [ "$has_plan" = false ] || [ "$has_tasks" = false ]; then
        echo "- [ ] Завершить документы методологии (запустить соответствующие команды: /constitution, /specify, /plan, /tasks)"
        has_actions=true
    fi

    # Проверка задач
    if [ $pending -gt 0 ] || [ $in_progress -gt 0 ]; then
        if [ $in_progress -gt 0 ]; then
            echo "- [ ] Продолжить выполнение задач в процессе ($in_progress шт.)"
        else
            echo "- [ ] Начать выполнение следующей задачи к выполнению (всего $pending шт.)"
        fi
        has_actions=true
    fi

    # Проверка качества глав
    if [ $bad_chapters -gt 0 ]; then
        echo "- [ ] Исправить главы с несоответствующим объемом ($bad_chapters шт.)"
        has_actions=true
    fi

    # Рекомендации по завершению
    if [ $pending -eq 0 ] && [ $in_progress -eq 0 ] && [ $completed -gt 0 ]; then
        echo "- [ ] Запустить /analyze для комплексной проверки"
        has_actions=true
    fi

    if [ "$has_actions" = false ]; then
        echo "*Состояние написания хорошее, никаких особых действий не требуется*"
    fi

    cat <<EOF

---

**Инструмент проверки**: check-writing-state.sh
**Версия**: 1.1 (поддержка вывода checklist)
EOF
}

# Основной процесс
main() {
    # В режиме checklist вывод осуществляется напрямую и скрипт завершается
    if [ "$CHECKLIST_MODE" = true ]; then
        output_checklist
        exit 0
    fi

    # Исходный режим подробного вывода
    echo "Проверка состояния написания"
    echo "============"
    echo "Текущая история: $STORY_NAME"
    echo ""

    if ! check_methodology_docs; then
        exit 1
    fi

    check_pending_tasks
    check_completed_content

    echo ""
    echo "Готово к началу написания"
}

main
```