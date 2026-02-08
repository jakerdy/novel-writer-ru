#!/usr/bin/env pwsh
# Настройка плана глав

$STORIES_DIR = "stories"

# Поиск последней директории истории
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
$chaptersDir = "$storyDir/chapters"

# Создание директории для глав
if (!(Test-Path $chaptersDir)) {
    New-Item -ItemType Directory -Path $chaptersDir | Out-Null
}

Write-Host "Директория истории: $storyDir"
Write-Host "Файл плана: $outlineFile"
Write-Host "Подготовка к созданию плана глав..."
Write-Host ""
Write-Host "Пожалуйста, создайте план на основе:"
Write-Host "- Общей структуры"
Write-Host "- Разделения на тома/части"
Write-Host "- Детальных глав"
Write-Host "- Контроля темпа"