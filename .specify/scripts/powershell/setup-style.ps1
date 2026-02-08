#!/usr/bin/env pwsh
# Установка стиля и правил творчества

$MEMORY_DIR = ".specify/memory"

# Создание директории для памяти
if (!(Test-Path $MEMORY_DIR)) {
    New-Item -ItemType Directory -Path $MEMORY_DIR | Out-Null
    Write-Host "Создана директория $MEMORY_DIR"
}

$STYLE_FILE = "$MEMORY_DIR/writing-constitution.md"

# Проверка существования файла
if (Test-Path $STYLE_FILE) {
    Write-Host "Обновление файла стиля творчества: $STYLE_FILE"
} else {
    Write-Host "Создание файла стиля творчества: $STYLE_FILE"
}

Write-Host "Подготовка к заполнению содержимого стиля творчества..."
Write-Host "Пожалуйста, установите на основе описания пользователя:"
Write-Host "- Повествовательная перспектива"
Write-Host "- Стиль письма"
Write-Host "- Принципы творчества"
Write-Host "- Стандарты качества"