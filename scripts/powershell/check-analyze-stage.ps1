#!/usr/bin/env pwsh
# Определяет фазу, которую должна выполнить команда analyze
# Возвращает информацию о фазе в формате JSON

param(
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Загрузка общих функций
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir "common.ps1")

# Получение корневой директории проекта и директории истории
try {
    $projectRoot = Get-ProjectRoot
    $storyDir = Get-CurrentStoryDir
} catch {
    Write-Error "Ошибка: $_"
    exit 1
}

if (-not $storyDir) {
    Write-Error "Ошибка: Директория истории не найдена"
    exit 1
}

# Значения по умолчанию
$analyzeType = "content"
$chapterCount = 0
$hasSpec = $false
$hasPlan = $false
$hasTasks = $false
$reason = ""

# Проверка файла спецификации
$specPath = Join-Path $storyDir "specification.md"
if (Test-Path $specPath) {
    $hasSpec = $true
}

# Проверка файла плана
$planPath = Join-Path $storyDir "creative-plan.md"
if (Test-Path $planPath) {
    $hasPlan = $true
}

# Проверка файла задач
$tasksPath = Join-Path $storyDir "tasks.md"
if (Test-Path $tasksPath) {
    $hasTasks = $true
}

# Подсчет количества глав
$contentDir = Join-Path $storyDir "content"
if (-not (Test-Path $contentDir)) {
    $contentDir = Join-Path $storyDir "chapters"
}

if (Test-Path $contentDir) {
    # Подсчет файлов .md (исключая индексные файлы)
    $chapters = Get-ChildItem -Path $contentDir -Filter "*.md" -File |
                Where-Object { $_.Name -notin @("README.md", "index.md") }
    $chapterCount = $chapters.Count
}

# Логика принятия решений
if ($chapterCount -eq 0) {
    # Нет контента глав → анализ структуры
    $analyzeType = "framework"
    $reason = "Нет контента глав, рекомендуется провести анализ согласованности структуры"
} elseif ($chapterCount -lt 3) {
    # Недостаточно глав → анализ структуры (с подсказкой о возможности начать писать)
    $analyzeType = "framework"
    $reason = "Мало глав ($chapterCount), рекомендуется продолжить написание или провести проверку структуры"
} else {
    # Достаточно глав → анализ контента
    $analyzeType = "content"
    $reason = "Завершено $chapterCount глав, возможен анализ качества контента"
}

# Вывод в формате JSON или читаемом для человека
if ($Json) {
    # Вывод в формате JSON
    $output = @{
        analyze_type = $analyzeType
        chapter_count = $chapterCount
        has_spec = $hasSpec
        has_plan = $hasPlan
        has_tasks = $hasTasks
        story_dir = $storyDir
        reason = $reason
    }

    $output | ConvertTo-Json -Compress
} else {
    # Вывод в читаемом для человека формате
    Write-Host "Результаты определения фазы анализа"
    Write-Host "=================="
    Write-Host "Директория истории: $storyDir"
    Write-Host "Количество глав: $chapterCount"
    Write-Host "Файл спецификации: $(if ($hasSpec) { '✅' } else { '❌' })"
    Write-Host "Файл плана: $(if ($hasPlan) { '✅' } else { '❌' })"
    Write-Host "Файл задач: $(if ($hasTasks) { '✅' } else { '❌' })"
    Write-Host ""
    Write-Host "Рекомендуемый режим: $analyzeType"
    Write-Host "Причина: $reason"
}