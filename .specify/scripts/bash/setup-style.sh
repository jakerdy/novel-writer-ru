#!/usr/bin/env bash
# Установка стиля письма

set -e

# Загрузка общих функций
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

# Получение корневого каталога проекта
PROJECT_ROOT=$(get_project_root)
MEMORY_DIR="$PROJECT_ROOT/.specify/memory"

# Создание каталога memory
mkdir -p "$MEMORY_DIR"

# Создание или обновление файла руководства по стилю письма
CONSTITUTION_FILE="$MEMORY_DIR/writing-constitution.md"
TEMPLATE="$PROJECT_ROOT/.specify/templates/writing-constitution-template.md"

ensure_file "$CONSTITUTION_FILE" "$TEMPLATE"

# Вывод результата
echo "CONSTITUTION_FILE: $CONSTITUTION_FILE"
echo "STATUS: ready"