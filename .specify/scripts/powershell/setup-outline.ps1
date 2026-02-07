#!/usr/bin/env pwsh
# Настройка плана глав

$STORIES_DIR = "stories"

# Поиск самой последней директории с историей
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
    Write-Host "Ошибка: не найдено ни одного проекта истории"
    Write-Host "Пожалуйста, сначала создайте историю с помощью команды /story"
    exit 1
}

$outlineFile = "$storyDir/outline.md"
$chaptersDir = "$storyDir/chapters"

# Создание директории для глав
if (!(Test-Path $chaptersDir)) {
    New-Item -ItemType Directory -Path $chaptersDir | Out-Null
}

Write-Host "Директория истории: $storyDir"
Write-Host "Файл плана: $outlineFile"
Write-Host "Подготовка к созданию плана глав..."
Write-Host ""
Write-Host "Пожалуйста, создайте план на основе общей структуры истории:"
Write-Host "- Общая структура"
Write-Host "- Разделение на тома/части"
Write-Host "- Подробные главы"
Write-Host "- Контроль темпа"