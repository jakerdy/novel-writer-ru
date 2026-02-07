#!/usr/bin/env pwsh
# Установка стиля и правил создания контента

$MEMORY_DIR = ".specify/memory"

# Создание директории для памяти
if (!(Test-Path $MEMORY_DIR)) {
    New-Item -ItemType Directory -Path $MEMORY_DIR | Out-Null
    Write-Host "Создана директория $MEMORY_DIR"
}

$STYLE_FILE = "$MEMORY_DIR/writing-constitution.md"

# Проверка существования файла
if (Test-Path $STYLE_FILE) {
    Write-Host "Обновление файла стиля создания контента: $STYLE_FILE"
} else {
    Write-Host "Создание файла стиля создания контента: $STYLE_FILE"
}

Write-Host "Подготовка к заполнению контента стиля..."
Write-Host "Пожалуйста, установите следующие параметры на основе описания пользователя:"
Write-Host "- Повествовательная перспектива"
Write-Host "- Стиль письма"
Write-Host "- Принципы создания контента"
Write-Host "- Стандарты качества"