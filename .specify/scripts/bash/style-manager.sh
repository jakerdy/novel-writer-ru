#!/usr/bin/env bash
# Менеджер стилей — поддержка начальной настройки и интеграция внешних предложений

set -e

# Загрузка общих функций
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

# Получение корневого каталога проекта
PROJECT_ROOT=$(get_project_root)
MEMORY_DIR="$PROJECT_ROOT/.specify/memory"
SPEC_DIR="$PROJECT_ROOT/spec"
KNOWLEDGE_DIR="$SPEC_DIR/knowledge"
TRACKING_DIR="$SPEC_DIR/tracking"

# Режим команды
MODE=${1:-init}
shift || true

# Создание необходимых каталогов
mkdir -p "$MEMORY_DIR" "$KNOWLEDGE_DIR" "$TRACKING_DIR"

# Функция: Инициализация стиля письма
init_style() {
    echo "📝 Инициализация стиля письма..."

    # Создание или обновление файла правил письма
    CONSTITUTION_FILE="$MEMORY_DIR/writing-constitution.md"
    TEMPLATE="$PROJECT_ROOT/.specify/templates/writing-constitution-template.md"

    ensure_file "$CONSTITUTION_FILE" "$TEMPLATE"

    # Опционально: интеграция резюме личных материалов для повышения индивидуальности выражения
    integrate_personal_voice "$CONSTITUTION_FILE"

    # Фиксированная глава: Базовая линия индивидуального выражения (автоматическая синхронизация)
    sync_personal_baseline "$CONSTITUTION_FILE"

    # Вывод результата
    echo "CONSTITUTION_FILE: $CONSTITUTION_FILE"
    echo "STATUS: ready"
    echo "✅ Инициализация стиля письма завершена"
}

# Извлечение ключевых моментов из personal-voice.md и добавление к правилам письма
integrate_personal_voice() {
    local constitution_file="$1"
    local pv_file="$PROJECT_ROOT/.specify/memory/personal-voice.md"

    if [ -f "$pv_file" ]; then
        local tmp="/tmp/pv_summary_$$.md"
        echo "" > "$tmp"
        echo "## Резюме личных материалов (автоматическая ссылка)" >> "$tmp"
        echo "Источник: .specify/memory/personal-voice.md" >> "$tmp"
        echo "" >> "$tmp"

        # Извлечение заголовков второго уровня и 2 ближайших пунктов списка в качестве резюме
        awk '
            /^## / { if(h>6) exit; h++; if(cnt>0) {print ""}; print $0; lc=0; next }
            /^- / && lc<2 { print $0; lc++; next }
        ' "$pv_file" >> "$tmp"

        # Предотвращение повторного добавления: проверка наличия текущего резюме (приблизительная проверка по дате + заголовку раздела)
        if ! grep -q "Резюме личных материалов (автоматическая ссылка)" "$constitution_file"; then
            echo "" >> "$constitution_file"
            cat "$tmp" >> "$constitution_file"
            echo "    ✅ Резюме личных материалов добавлено"
        fi
        rm -f "$tmp"
    fi
}

# Синхронизация ключевых моментов personal-voice в виде фиксированной главы (может выполняться повторно, идемпотентно)
sync_personal_baseline() {
    local constitution_file="$1"
    local pv_file="$PROJECT_ROOT/.specify/memory/personal-voice.md"
    [ -f "$pv_file" ] || return 0

    local tmp="/tmp/pv_baseline_$$.md"
    echo "<!-- BEGIN: PERSONAL_BASELINE_AUTO -->" > "$tmp"
    echo "## Базовая линия индивидуального выражения (автоматическая синхронизация)" >> "$tmp"
    echo "Источник: .specify/memory/personal-voice.md (только для чтения, для изменений используйте исходный файл)" >> "$tmp"
    echo "" >> "$tmp"

    # Функция: получение первых N пунктов списка по заголовку
    fetch_section() {
        local title="$1"; local n="$2"; local label="$3"
        echo "### $label" >> "$tmp"
        awk -v t="$title" -v n="$n" '
            BEGIN{hit=0;cnt=0}
            $0 ~ "^## " t "$" {hit=1; next}
            hit==1 && $0 ~ /^## / {hit=0}
            hit==1 && $0 ~ /^- / && cnt<n {print $0; cnt++}
        ' "$pv_file" >> "$tmp"
        echo "" >> "$tmp"
    }

    fetch_section "Слова-паразиты и часто используемые выражения" 6 "Слова-паразиты и часто используемые выражения"
    fetch_section "Фиксированные фразы и предпочтения в ритме" 6 "Фиксированные фразы и ритм"
    fetch_section "Отраслевая/региональная лексика (сленг, жаргон, термины)" 6 "Отраслевая/региональная лексика"
    fetch_section "Предпочтения в метафорах и библиотека образов" 8 "Метафоры и образы"
    fetch_section "Писательские табу и ограничения" 6 "Писательские табу"

    echo "<!-- END: PERSONAL_BASELINE_AUTO -->" >> "$tmp"

    # Запись или замена блока маркеров в правилах письма
    if grep -q "<!-- BEGIN: PERSONAL_BASELINE_AUTO -->" "$constitution_file"; then
        # Замена существующего блока
        awk -v RS='' -v ORS='\n\n' -v file="$tmp" '
            BEGIN{while((getline l<file)>0){blk=blk l "\n"}} 
            {gsub(/<!-- BEGIN: PERSONAL_BASELINE_AUTO -->[\s\S]*<!-- END: PERSONAL_BASELINE_AUTO -->/, blk) }1
        ' "$constitution_file" > "$constitution_file.tmp" && mv "$constitution_file.tmp" "$constitution_file"
    else
        echo "" >> "$constitution_file"
        cat "$tmp" >> "$constitution_file"
    fi

    rm -f "$tmp"
    echo "    ✅ Базовая линия индивидуального выражения синхронизирована"
}

# Функция: Парсинг JSON-предложений
parse_json_suggestions() {
    local input="$1"
    local temp_file="/tmp/suggestions_$$.json"

    # Сохранение ввода во временный файл
    echo "$input" > "$temp_file"

    # Проверка формата JSON
    if ! python3 -m json.tool "$temp_file" > /dev/null 2>&1; then
        echo "❌ Неверный формат JSON"
        rm -f "$temp_file"
        return 1
    fi

    # Извлечение ключевой информации
    local source=$(python3 -c "import json; data=json.load(open('$temp_file')); print(data.get('source', 'Unknown'))")
    local date=$(python3 -c "import json; data=json.load(open('$temp_file')); print(data.get('analysis_date', '$(date +%Y-%m-%d)'))")

    echo "📊 Анализ предложений от $source ($date)"

    # Обработка различных предложений
    process_style_suggestions "$temp_file"
    process_character_suggestions "$temp_file"
    process_plot_suggestions "$temp_file"
    process_world_suggestions "$temp_file"
    process_dialogue_suggestions "$temp_file"

    # Очистка временного файла
    rm -f "$temp_file"
}

# Функция: Парсинг Markdown-предложений
parse_markdown_suggestions() {
    local input="$1"
    local temp_file="/tmp/suggestions_$$.md"

    echo "$input" > "$temp_file"

    echo "📊 Анализ предложений в формате Markdown..."

    # Извлечение базовой информации
    local source=$(grep "Аналитический инструмент:" "$temp_file" | sed 's/.*Аналитический инструмент://')
    local date=$(grep "Дата анализа:" "$temp_file" | sed 's/.*Дата анализа://')

    echo "Источник: ${source:-Unknown}"
    echo "Дата: ${date:-$(date +%Y-%m-%d)}"

    # Обработка предложений (упрощенная версия)
    process_markdown_style "$temp_file"
    process_markdown_characters "$temp_file"

    rm -f "$temp_file"
}

# Функция: Обработка предложений по стилю
process_style_suggestions() {
    local json_file="$1"

    # Проверка наличия предложений по стилю
    local has_style=$(python3 -c "
import json
data = json.load(open('$json_file'))
print('yes' if 'style' in data.get('suggestions', {}) else 'no')
")

    if [ "$has_style" = "yes" ]; then
        echo "  📝 Обработка предложений по стилю..."

        # Обновление writing-constitution.md
        local constitution_file="$MEMORY_DIR/writing-constitution.md"
        local temp_update="/tmp/constitution_update_$$.md"

        # Извлечение предложений по стилю и добавление
        python3 -c "
import json
data = json.load(open('$json_file'))
style = data.get('suggestions', {}).get('style', {})
items = style.get('items', [])

with open('$temp_update', 'w') as f:
    f.write('\n## Внешние предложения по оптимизации ($(date +%Y-%m-%d))\n\n')
    for item in items:
        f.write(f\"### {item.get('type', 'Не классифицировано')}\n\")
        f.write(f\"- **Проблема**：{item.get('current', '')}\n\")
        f.write(f\"- **Предложение**：{item.get('suggestion', '')}\n\")
        f.write(f\"- **Ожидаемый эффект**：{item.get('impact', '')}\n\n\")
"

        if [ -f "$temp_update" ]; then
            cat "$temp_update" >> "$constitution_file"
            rm -f "$temp_update"
            echo "    ✅ Правила письма обновлены"
        fi
    fi
}

# Функция: Обработка предложений по персонажам
process_character_suggestions() {
    local json_file="$1"

    local has_chars=$(python3 -c "
import json
data = json.load(open('$json_file'))
print('yes' if 'characters' in data.get('suggestions', {}) else 'no')
")

    if [ "$has_chars" = "yes" ]; then
        echo "  👥 Обработка предложений по персонажам..."

        # Обновление профилей персонажей
        local profiles_file="$KNOWLEDGE_DIR/character-profiles.md"
        local temp_update="/tmp/profiles_update_$$.md"

        python3 -c "
import json
data = json.load(open('$json_file'))
chars = data.get('suggestions', {}).get('characters', {})
items = chars.get('items', [])

with open('$temp_update', 'w') as f:
    f.write('\n## Предложения по развитию персонажей ($(date +%Y-%m-%d))\n\n')
    for item in items:
        f.write(f\"### {item.get('character', 'Неизвестный персонаж')}\n\")
        f.write(f\"- **Проблема**：{item.get('issue', '')}\n\")
        f.write(f\"- **Предложение**：{item.get('suggestion', '')}\n\")
        f.write(f\"- **Кривая развития**：{item.get('development_curve', '')}\n\")
        chapters = item.get('chapters_affected', [])
        if chapters:
            f.write(f\"- **Затронутые главы**：{', '.join(map(str, chapters))}\n\")
        f.write('\n')
"

        if [ -f "$temp_update" ] && [ -f "$profiles_file" ]; then
            cat "$temp_update" >> "$profiles_file"
            rm -f "$temp_update"
            echo "    ✅ Профили персонажей обновлены"
        fi
    fi
}

# Функция: Обработка предложений по сюжету
process_plot_suggestions() {
    local json_file="$1"

    local has_plot=$(python3 -c "
import json
data = json.load(open('$json_file'))
print('yes' if 'plot' in data.get('suggestions', {}) else 'no')
")

    if [ "$has_plot" = "yes" ]; then
        echo "  📖 Обработка предложений по сюжету..."

        # Обновление трекера сюжета
        local plot_file="$TRACKING_DIR/plot-tracker.json"

        if [ -f "$plot_file" ]; then
            python3 -c "
import json

# Чтение существующего файла отслеживания
with open('$plot_file', 'r') as f:
    tracker = json.load(f)

# Чтение предложений
data = json.load(open('$json_file'))
plot = data.get('suggestions', {}).get('plot', {})
items = plot.get('items', [])

# Добавление предложений в трекер
if 'suggestions' not in tracker:
    tracker['suggestions'] = []

for item in items:
    tracker['suggestions'].append({
        'date': '$(date +%Y-%m-%d)',
        'type': item.get('type', ''),
        'location': item.get('location', ''),
        'suggestion': item.get('suggestion', ''),
        'importance': item.get('importance', 'medium'),
        'status': 'pending'
    })

# Сохранение обновлений
with open('$plot_file', 'w') as f:
    json.dump(tracker, f, indent=2, ensure_ascii=False)
"
            echo "    ✅ Трекер сюжета обновлен"
        fi
    fi
}

# Функция: Обработка предложений по мироустройству
process_world_suggestions() {
    local json_file="$1"

    local has_world=$(python3 -c "
import json
data = json.load(open('$json_file'))
print('yes' if 'worldbuilding' in data.get('suggestions', {}) else 'no')
")

    if [ "$has_world" = "yes" ]; then
        echo "  🌍 Обработка предложений по мироустройству..."

        # Обновление настроек мира
        local world_file="$KNOWLEDGE_DIR/world-setting.md"
        local temp_update="/tmp/world_update_$$.md"

        python3 -c "
import json
data = json.load(open('$json_file'))
world = data.get('suggestions', {}).get('worldbuilding', {})
items = world.get('items', [])

with open('$temp_update', 'w') as f:
    f.write('\n## Предложения по доработке мироустройства ($(date +%Y-%m-%d))\n\n')
    for item in items:
        f.write(f\"### {item.get('aspect', 'Не классифицировано')}\n\")
        f.write(f\"- **Проблема**：{item.get('issue', '')}\n\")
        f.write(f\"- **Предложение**：{item.get('suggestion', '')}\n\")
        chapters = item.get('reference_chapters', [])
        if chapters:
            f.write(f\"- **Рекомендуемые главы**：{', '.join(map(str, chapters))}\n\")
        f.write('\n')
"

        if [ -f "$temp_update" ] && [ -f "$world_file" ]; then
            cat "$temp_update" >> "$world_file"
            rm -f "$temp_update"
            echo "    ✅ Настройки мира обновлены"
        fi
    fi
}

# Функция: Обработка предложений по диалогам
process_dialogue_suggestions() {
    local json_file="$1"

    local has_dialogue=$(python3 -c "
import json
data = json.load(open('$json_file'))
print('yes' if 'dialogue' in data.get('suggestions', {}) else 'no')
")

    if [ "$has_dialogue" = "yes" ]; then
        echo "  💬 Обработка предложений по диалогам..."

        # Создание или обновление спецификаций голосов персонажей
        local voices_file="$KNOWLEDGE_DIR/character-voices.md"

        if [ ! -f "$voices_file" ]; then
            echo "# Спецификации голосов персонажей" > "$voices_file"
            echo "" >> "$voices_file"
            echo "## Общие принципы" >> "$voices_file"
            echo "" >> "$voices_file"
        fi

        local temp_update="/tmp/voices_update_$$.md"

        python3 -c "
import json
data = json.load(open('$json_file'))
dialogue = data.get('suggestions', {}).get('dialogue', {})
items = dialogue.get('items', [])

with open('$temp_update', 'w') as f:
    f.write('\n## Предложения по оптимизации диалогов ($(date +%Y-%m-%d))\n\n')
    for item in items:
        f.write(f\"### {item.get('character', 'Общее')}\n\")
        f.write(f\"- **Проблема**：{item.get('issue', '')}\n\")
        f.write(f\"- **Предложение**：{item.get('suggestion', '')}\n\")

        examples = item.get('examples', [])
        alternatives = item.get('alternatives', [])

        if examples and alternatives:
            f.write('- **Примеры замены**：\n')
            for i, ex in enumerate(examples):
                if i < len(alternatives):
                    f.write(f\"  - {ex} → {alternatives[i]}\n\")
        f.write('\n')
"

        if [ -f "$temp_update" ]; then
            cat "$temp_update" >> "$voices_file"
            rm -f "$temp_update"
            echo "    ✅ Диалектные рекомендации обновлены"
        fi
    fi
}

# Функция: Обработка предложений по стилю Markdown
process_markdown_style() {
    local md_file="$1"

    if grep -q "Предложения по стилю письма" "$md_file"; then
        echo "  📝 Обработка предложений по стилю..."

        # Извлечение раздела стиля и добавление в constitution
        local constitution_file="$MEMORY_DIR/writing-constitution.md"

        echo "" >> "$constitution_file"
        echo "## Внешние предложения по оптимизации ($(date +%Y-%m-%d))" >> "$constitution_file"
        echo "" >> "$constitution_file"

        # Извлечение предложений по стилю (упрощенная обработка)
        awk '/## Предложения по стилю письма/,/## [^П]/' "$md_file" | grep -v "^##" >> "$constitution_file"

        echo "    ✅ Редакционные принципы обновлены"
    fi
}

# Функция: Обработка предложений по персонажам Markdown
process_markdown_characters() {
    local md_file="$1"

    if grep -q "Предложения по оптимизации персонажей" "$md_file"; then
        echo "  👥 Обработка предложений по персонажам..."

        local profiles_file="$KNOWLEDGE_DIR/character-profiles.md"

        if [ -f "$profiles_file" ]; then
            echo "" >> "$profiles_file"
            echo "## Внешние предложения по оптимизации ($(date +%Y-%m-%d))" >> "$profiles_file"
            echo "" >> "$profiles_file"

            # Извлечение предложений по персонажам
            awk '/## Предложения по оптимизации персонажей/,/## [^П]/' "$md_file" | grep -v "^##" >> "$profiles_file"

            echo "    ✅ Профили персонажей обновлены"
        fi
    fi
}

# Функция: Обновление журнала улучшений
update_improvement_log() {
    local source="$1"
    local summary="$2"

    local log_file="$KNOWLEDGE_DIR/improvement-log.md"

    # Если файл не существует, создать заголовок
    if [ ! -f "$log_file" ]; then
        cat > "$log_file" << EOF
# История улучшений

Запись всех внешних предложений ИИ и их принятия.

EOF
    fi

    # Добавление новой записи
    cat >> "$log_file" << EOF

## $(date +%Y-%m-%d) - $source

### Резюме предложения
$summary

### Статус принятия
- [x] Автоматически интегрировано в нормативные файлы
- [ ] Ожидает ручного подтверждения
- [ ] Ожидает внесения изменений

### Затронутые файлы
EOF

    # Перечисление измененных файлов
    echo "- writing-constitution.md" >> "$log_file"
    [ -f "$KNOWLEDGE_DIR/character-profiles.md" ] && echo "- character-profiles.md" >> "$log_file"
    [ -f "$TRACKING_DIR/plot-tracker.json" ] && echo "- plot-tracker.json" >> "$log_file"
    [ -f "$KNOWLEDGE_DIR/world-setting.md" ] && echo "- world-setting.md" >> "$log_file"
    [ -f "$KNOWLEDGE_DIR/character-voices.md" ] && echo "- character-voices.md" >> "$log_file"

    echo "" >> "$log_file"
    echo "---" >> "$log_file"
}

# Функция: Интеграция внешних предложений
refine_style() {
    echo "🔄 Начинается интеграция внешних предложений..."

    # Чтение ввода (из стандартного ввода или параметров)
    local input="$*"
    if [ -z "$input" ]; then
        # Попытка чтения из стандартного ввода
        if [ ! -t 0 ]; then
            input=$(cat)
        else
            echo "Пожалуйста, предоставьте содержание предложений"
            exit 1
        fi
    fi

    # Автоматическое определение формата - улучшенная логика определения
    if echo "$input" | grep -q '"version"' && echo "$input" | grep -q '"suggestions"'; then
        echo "Обнаружен формат JSON"
        parse_json_suggestions "$input"
        update_improvement_log "Внешний ИИ" "Предложения в формате JSON обработаны"
    elif echo "$input" | grep -q "# Отчет с предложениями по написанию романа"; then
        echo "Обнаружен формат Markdown"
        parse_markdown_suggestions "$input"
        update_improvement_log "Внешний ИИ" "Предложения в формате Markdown обработаны"
    else
        echo "❌ Не удалось распознать формат предложений"
        echo "Используйте стандартный формат JSON или Markdown"
        echo "См.: docs/ai-suggestion-prompt-template.md"
        exit 1
    fi

    # Генерация отчета
    echo ""
    echo "✅ Интеграция предложений завершена"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Отчет об интеграции:"
    echo "  - Обновлено файлов: $(find $MEMORY_DIR $KNOWLEDGE_DIR $TRACKING_DIR -type f -mmin -1 2>/dev/null | wc -l) шт."
    echo "  - Источник предложений: Анализ внешнего ИИ"
    echo "  - Время обработки: $(date +%H:%M:%S)"
    echo ""
    echo "📋 Следующие шаги:"
    echo "  1. Просмотрите improvement-log.md для получения подробной информации"
    echo "  2. При использовании /write будут применены новые правила"
    echo "  3. Рекомендуется пересмотреть соответствующие главы"
    echo ""
    echo "Подробнее: $KNOWLEDGE_DIR/improvement-log.md"
}

# Функция: Слияние предложений из нескольких источников
merge_suggestions() {
    echo "🔀 Слияние предложений из нескольких источников..."
    echo "（Функция в разработке）"
    # TODO: Реализовать интеллектуальное слияние предложений из нескольких источников
}

# Основная логика
case "$MODE" in
    init)
        init_style
        ;;
    refine)
        refine_style "$@"
        ;;
    merge)
        merge_suggestions "$@"
        ;;
    *)
        echo "❌ Неизвестный режим: $MODE"
        echo "Доступные режимы: init, refine, merge"
        exit 1
        ;;
esac