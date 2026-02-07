```powershell
# Определение спецификации истории
# Используется для команды /specify

param(
    [switch]$Json,
    [string]$StoryName
)

# Импорт общих функций
. "$PSScriptRoot\common.ps1"

# Получение корневого каталога проекта
$ProjectRoot = Get-ProjectRoot
Set-Location $ProjectRoot

# Определение имени и пути к истории
if ([string]::IsNullOrEmpty($StoryName)) {
    # Поиск последней истории
    $StoriesDir = "stories"
    if (Test-Path $StoriesDir) {
        $latestStory = Get-ChildItem $StoriesDir -Directory |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($latestStory) {
            $StoryName = $latestStory.Name
        }
    }

    # Если все еще нет, генерация имени по умолчанию
    if ([string]::IsNullOrEmpty($StoryName)) {
        $StoryName = "story-$(Get-Date -Format 'yyyyMMdd')"
    }
}

# Установка путей
$StoryDir = "stories\$StoryName"
$SpecFile = "$StoryDir\specification.md"

# Создание каталога
if (-not (Test-Path $StoryDir)) {
    New-Item -ItemType Directory -Path $StoryDir -Force | Out-Null
}

# Проверка состояния файла
$SpecExists = $false
$Status = "new"

if (Test-Path $SpecFile) {
    $SpecExists = $true
    $Status = "exists"
}

# Вывод в формате JSON
if ($Json) {
    @{
        STORY_NAME = $StoryName
        STORY_DIR = $StoryDir
        SPEC_PATH = $SpecFile
        STATUS = $Status
        PROJECT_ROOT = $ProjectRoot
    } | ConvertTo-Json
}
else {
    Write-Host "Инициализация спецификации истории"
    Write-Host "================================"
    Write-Host "Имя истории: $StoryName"
    Write-Host "Путь к спецификации: $SpecFile"

    if ($SpecExists) {
        Write-Host "Статус: Файл спецификации существует, подготовка к обновлению"
    }
    else {
        Write-Host "Статус: Подготовка к созданию новой спецификации"
    }

    # Проверка конституции
    if (Test-Path "memory\constitution.md") {
        Write-Host ""
        Write-Host "✅ Обнаружена конституция для творчества, спецификация будет соответствовать принципам конституции" -ForegroundColor Green
    }
}
```