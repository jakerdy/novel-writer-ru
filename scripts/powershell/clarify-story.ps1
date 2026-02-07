```powershell
param(
    [switch]$Json,
    [switch]$PathsOnly
)

# Вспомогательный скрипт для уточнения структуры истории
# Используется для команды /clarify, сканирует и возвращает текущие пути к истории

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Получить каталог скрипта
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Загрузить общие функции
. "$ScriptDir\common.ps1"

# Получить корневой каталог проекта
$ProjectRoot = Get-ProjectRoot
Set-Location $ProjectRoot

# Найти текущий каталог истории
$StoriesDir = "stories"
if (-not (Test-Path $StoriesDir -PathType Container)) {
    if ($Json) {
        Write-Output '{"error": "Каталог stories не найден"}'
    } else {
        Write-Error "Ошибка: каталог stories не найден. Пожалуйста, сначала запустите /story для создания структуры истории."
    }
    exit 1
}

# Получить последнюю историю
$StoryDirs = Get-ChildItem -Path $StoriesDir -Directory | Sort-Object Name -Descending
if ($StoryDirs.Count -eq 0) {
    if ($Json) {
        Write-Output '{"error": "История не найдена"}'
    } else {
        Write-Error "Ошибка: история не найдена. Пожалуйста, сначала запустите /story для создания структуры истории."
    }
    exit 1
}

$StoryDir = $StoryDirs[0]
$StoryName = $StoryDir.Name

# Найти файл истории (новый формат specification.md)
$StoryFile = Join-Path $StoryDir.FullName "specification.md"

if (-not (Test-Path $StoryFile -PathType Leaf)) {
    if ($Json) {
        Write-Output '{"error": "Файл истории не найден (требуется specification.md)"}'
    } else {
        Write-Error "Ошибка: файл истории specification.md не найден."
    }
    exit 1
}

# Проверить, существует ли уже запись об уточнении
$ClarificationExists = $false
$StoryContent = Get-Content $StoryFile -Raw
if ($StoryContent -match "## 记录澄清") {
    $ClarificationExists = $true
}

# Подсчитать существующие сеансы уточнения
$ClarificationCount = 0
if ($ClarificationExists) {
    $matches = [regex]::Matches($StoryContent, "### 澄清会话")
    $ClarificationCount = $matches.Count
}

# Преобразовать пути в прямые слеши для JSON
$StoryFilePath = $StoryFile.Replace('\', '/')
$StoryDirPath = $StoryDir.FullName.Replace('\', '/')
$ProjectRootPath = $ProjectRoot.Replace('\', '/')

# Вывод в формате JSON, если запрошено
if ($Json) {
    if ($PathsOnly) {
        # Минимальный вывод для шаблона команды
        $output = @{
            STORY_PATH = $StoryFilePath
            STORY_NAME = $StoryName
            STORY_DIR = $StoryDirPath
        }
    } else {
        # Полный вывод для анализа
        $output = @{
            STORY_PATH = $StoryFilePath
            STORY_NAME = $StoryName
            STORY_DIR = $StoryDirPath
            CLARIFICATION_EXISTS = $ClarificationExists
            CLARIFICATION_COUNT = $ClarificationCount
            PROJECT_ROOT = $ProjectRootPath
        }
    }
    Write-Output (ConvertTo-Json $output -Compress)
} else {
    Write-Output "Найдена история: $StoryName"
    Write-Output "Путь к файлу: $StoryFile"
    if ($ClarificationExists) {
        Write-Output "Проведено сеансов уточнения: $ClarificationCount"
    } else {
        Write-Output "Уточнение еще не проводилось"
    }
}
```