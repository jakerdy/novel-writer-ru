#!/bin/bash

# Скрипт управления конституцией романа
# Используется для команды /constitution

set -e

# Подключение общих функций
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Получение параметров команды
COMMAND="${1:-check}"

# Получение корневого каталога проекта
PROJECT_ROOT=$(get_project_root)
cd "$PROJECT_ROOT"

# Определение пути к файлу
CONSTITUTION_FILE="memory/constitution.md"

case "$COMMAND" in
    check)
        # Проверка существования файла конституции
        if [ -f "$CONSTITUTION_FILE" ]; then
            echo "✅ Файл конституции существует: $CONSTITUTION_FILE"
            # Извлечение информации о версии
            VERSION=$(grep -E "^- Версия：" "$CONSTITUTION_FILE" 2>/dev/null | cut -d'：' -f2 | tr -d ' ' || echo "Неизвестно")
            UPDATED=$(grep -E "^- Последнее изменение：" "$CONSTITUTION_FILE" 2>/dev/null | cut -d'：' -f2 | tr -d ' ' || echo "Неизвестно")
            echo "  Версия: $VERSION"
            echo "  Последнее изменение: $UPDATED"
            exit 0
        else
            echo "❌ Файл конституции еще не создан"
            echo "  Рекомендация: выполните /constitution для создания конституции романа"
            exit 1
        fi
        ;;

    init)
        # Инициализация файла конституции
        mkdir -p "$(dirname "$CONSTITUTION_FILE")"

        if [ -f "$CONSTITUTION_FILE" ]; then
            echo "Файл конституции существует, подготовка к обновлению"
        else
            echo "Подготовка к созданию нового файла конституции"
        fi
        ;;

    validate)
        # Проверка формата файла конституции
        if [ ! -f "$CONSTITUTION_FILE" ]; then
            echo "Ошибка: файл конституции не существует"
            exit 1
        fi

        echo "Проверка файла конституции..."

        # Проверка обязательных разделов
        REQUIRED_SECTIONS=("Основные ценности" "Стандарты качества" "Стиль письма" "Нормы содержания" "Договор с читателем")
        MISSING_SECTIONS=()

        for section in "${REQUIRED_SECTIONS[@]}"; do
            if ! grep -q "## .* $section" "$CONSTITUTION_FILE"; then
                MISSING_SECTIONS+=("$section")
            fi
        done

        if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
            echo "⚠️ Отсутствуют следующие разделы:"
            for section in "${MISSING_SECTIONS[@]}"; do
                echo "  - $section"
            done
        else
            echo "✅ Все необходимые разделы присутствуют"
        fi

        # Проверка информации о версии
        if grep -q "^- Версия:" "$CONSTITUTION_FILE"; then
            echo "✅ Информация о версии полная"
        else
            echo "⚠️ Отсутствует информация о версии"
        fi
        ;;

    export)
        # Экспорт краткого содержания конституции
        if [ ! -f "$CONSTITUTION_FILE" ]; then
            echo "Ошибка: файл конституции не существует"
            exit 1
        fi

        echo "# Краткое содержание конституции романа"
        echo ""

        # Извлечение основных принципов
        echo "## Основные принципы"
        grep -A 1 "^### Принципы" "$CONSTITUTION_FILE" | grep "^**Заявление**" | cut -d'：' -f2- || echo "（Заявление принципов не найдено）"

        echo ""
        echo "## Минимальные стандарты качества"
        grep -A 1 "^### Стандарты" "$CONSTITUTION_FILE" | grep "^**Требования**" | cut -d'：' -f2- || echo "（Стандарты качества не найдены）"

        echo ""
        echo "Подробности см. в: $CONSTITUTION_FILE"
        ;;

    *)
        echo "Неизвестная команда: $COMMAND"
        echo "Поддерживаемые команды: check, init, validate, export"
        exit 1
        ;;
esac