#!/usr/bin/env pwsh
# Генерация задач для написания

$STORIES_DIR = "stories"

# Поиск последней директории с историей
function Get-LatestStory {
    $latest = Get-ChildItem -Path $STORIES_DIR -Directory |
              Sort-Object Name -Descending |
              Select-Object -First 1

    if ($latest) {
        return $latest.FullName
    }
    return $null
}

$storyDir = Get-LatestStory

if (!$storyDir) {
    Write-Host "Ошибка: Проект истории не найден"
    Write-Host "Пожалуйста, сначала создайте историю с помощью команды /story"
    exit 1
}

$outlineFile = "$storyDir/outline.md"
$tasksFile = "$storyDir/tasks.md"
$progressFile = "$storyDir/progress.json"

if (!(Test-Path $outlineFile)) {
    Write-Host "Ошибка: План глав не найден"
    Write-Host "Пожалуйста, сначала создайте план глав с помощью команды /outline"
    exit 1
}

# Получение текущей даты
$currentDate = Get-Date -Format "yyyy-MM-dd"
$currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Создание файла задач с предварительно заполненной базовой информацией
$tasksContent = @"
# Список задач для написания

## Обзор задач
- **Дата создания**: $currentDate
- **Последнее обновление**: $currentDate
- **Статус задач**: Ожидается генерация

---
"@
$tasksContent | Out-File -FilePath $tasksFile -Encoding UTF8

# Создание или обновление файла прогресса
if (!(Test-Path $progressFile)) {
    $progressContent = @{
        created_at = $currentDateTime
        updated_at = $currentDateTime
        total_chapters = 0
        completed = 0
        in_progress = 0
        word_count = 0
    } | ConvertTo-Json
    $progressContent | Out-File -FilePath $progressFile -Encoding UTF8
}

Write-Host "Директория истории: $storyDir"
Write-Host "Файл плана: $outlineFile"
Write-Host "Файл задач: $tasksFile"
Write-Host "Текущая дата: $currentDate"
Write-Host ""
Write-Host "Генерация задач на основе плана глав:"
Write-Host "- Задачи по написанию глав"
Write-Host "- Задачи по доработке персонажей"
Write-Host "- Дополнение мира"
Write-Host "- Задачи по редактированию"