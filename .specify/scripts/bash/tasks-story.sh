#!/bin/bash

# Скрипт декомпозиции задач
# Используется для команды /tasks

set -e

# Подключение общих функций
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Разбор аргументов
STORY_NAME=""
if [ $# -gt 0 ]; then
    STORY_NAME="$1"
fi

# Получение корневого каталога проекта
PROJECT_ROOT=$(get_project_root)
cd "$PROJECT_ROOT"

# Определение имени истории
if [ -z "$STORY_NAME" ]; then
    STORY_NAME=$(get_active_story)
fi

STORY_DIR="stories/$STORY_NAME"
SPEC_FILE="$STORY_DIR/specification.md"
PLAN_FILE="$STORY_DIR/creative-plan.md"
TASKS_FILE="$STORY_DIR/tasks.md"

echo "Декомпозиция задач"
echo "=========="
echo "История: $STORY_NAME"
echo ""

# Проверка необходимых документов
missing=()

if [ ! -f "memory/writing-constitution.md" ] && [ ! -f ".specify/memory/writing-constitution.md" ]; then
    missing+=("Конституция письма")
fi

if [ ! -f "$SPEC_FILE" ]; then
    missing+=("Файл спецификаций")
fi

if [ ! -f "$PLAN_FILE" ]; then
    missing+=("Файл плана")
fi

if [ ${#missing[@]} -gt 0 ]; then
    echo "⚠️ Отсутствуют следующие предварительные документы:"
    for doc in "${missing[@]}"; do
        echo "  - $doc"
    done
    echo ""
    echo "Пожалуйста, сначала выполните:"
    if [ ! -f "memory/writing-constitution.md" ] && [ ! -f ".specify/memory/writing-constitution.md" ]; then
        echo "  1. /constitution - Создание конституции письма"
    fi
    if [ ! -f "$SPEC_FILE" ]; then
        echo "  2. /specify - Определение спецификаций истории"
    fi
    if [ ! -f "$PLAN_FILE" ]; then
        echo "  3. /plan - Разработка плана творчества"
    fi
    exit 1
fi

# Проверка файла задач
if [ -f "$TASKS_FILE" ]; then
    echo ""
    echo "📋 Файл задач уже существует, существующие задачи будут обновлены"

    # Отображение статистики задач
    total_tasks=$(grep -c "^- \[" "$TASKS_FILE" 2>/dev/null || echo "0")
    completed_tasks=$(grep -c "^- \[x\]" "$TASKS_FILE" 2>/dev/null || echo "0")
    echo "  Всего задач: $total_tasks"
    echo "  Завершено: $completed_tasks"
else
    echo ""
    echo "📝 Будет создан новый список задач"
fi

echo ""
echo "Путь к файлу задач: $TASKS_FILE"
echo ""
echo "Готово к декомпозиции задач"
echo ""
echo "Декомпозиция задач будет включать:"
echo "  - Задачи по написанию глав (на основе плана)"
echo "  - Улучшение профилей персонажей"
echo "  - Дополнение документации по миру"
echo "  - Этапы контроля качества"
echo "  - Задачи по проверке и доработке"