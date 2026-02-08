# Скрипт для создания плана истории
# Используется для команды /plan

param(
    [string]$StoryName
)

# Импорт общих функций
. "$PSScriptRoot\common.ps1"

# Получение корневого каталога проекта
$ProjectRoot = Get-ProjectRoot
Set-Location $ProjectRoot

# Определение имени истории
if ([string]::IsNullOrEmpty($StoryName)) {
    $StoryName = Get-ActiveStory
}

$StoryDir = "stories\$StoryName"
$SpecFile = "$StoryDir\specification.md"
$ClarifyFile = "$StoryDir\clarification.md"
$PlanFile = "$StoryDir\creative-plan.md"

Write-Host "Создание плана истории"
Write-Host "============"
Write-Host "История: $StoryName"
Write-Host ""

# Проверка предварительных документов
$missing = @()

if (-not (Test-Path "memory\constitution.md")) {
    $missing += "Конституция"
}

if (-not (Test-Path $SpecFile)) {
    $missing += "Спецификация"
}

if ($missing.Count -gt 0) {
    Write-Host "⚠️ Отсутствуют следующие предварительные документы:" -ForegroundColor Yellow
    foreach ($doc in $missing) {
        Write-Host "  - $doc"
    }
    Write-Host ""
    Write-Host "Пожалуйста, сначала завершите:"
    if (-not (Test-Path "memory\constitution.md")) {
        Write-Host "  1. /constitution - Создание конституции для творчества"
    }
    if (-not (Test-Path $SpecFile)) {
        Write-Host "  2. /specify - Определение спецификаций истории"
    }
    exit 1
}

# Проверка наличия неопределенных моментов
if (Test-Path $SpecFile) {
    $content = Get-Content $SpecFile -Raw
    $unclearCount = ([regex]::Matches($content, '\[需要澄清\]')).Count

    if ($unclearCount -gt 0) {
        Write-Host "⚠️ В спецификации есть $unclearCount пунктов, требующих уточнения" -ForegroundColor Yellow
        Write-Host "Рекомендуется сначала запустить /clarify для уточнения ключевых решений"
        Write-Host ""
    }
}

# Проверка записей об уточнении
if (Test-Path $ClarifyFile) {
    Write-Host "✅ Записи об уточнении найдены, план будет создан на основе уточненных решений" -ForegroundColor Green
}
else {
    Write-Host "📝 Записи об уточнении не найдены, план будет создан на основе исходной спецификации"
}

# Проверка файла плана
if (Test-Path $PlanFile) {
    Write-Host ""
    Write-Host "📋 Файл плана уже существует, существующий план будет обновлен"

    # Отображение текущей версии
    $planContent = Get-Content $PlanFile -Raw
    if ($planContent -match "版本：(.+)") {
        Write-Host "  Текущая версия: $($matches[1])"
    }
}
else {
    Write-Host ""
    Write-Host "📝 Будет создан новый план истории"
}

Write-Host ""
Write-Host "Путь к файлу плана: $PlanFile"
Write-Host ""
Write-Host "Готово к созданию плана истории"