```powershell
#!/usr/bin/env pwsh
# Создание нового проекта истории

param(
    [string]$Json = ""
)

$STORIES_DIR = "stories"

# Создание каталога историй
if (!(Test-Path $STORIES_DIR)) {
    New-Item -ItemType Directory -Path $STORIES_DIR | Out-Null
}

# Парсинг JSON параметров
$storyData = @{
    name = "Безымянная история"
    genre = "Общий"
    description = ""
}

if ($Json) {
    try {
        $parsed = $Json | ConvertFrom-Json
        if ($parsed.name) { $storyData.name = $parsed.name }
        if ($parsed.genre) { $storyData.genre = $parsed.genre }
        if ($parsed.description) { $storyData.description = $parsed.description }
    } catch {
        Write-Host "Предупреждение: Не удалось разобрать JSON параметры, используются значения по умолчанию"
    }
}

# Получение следующего номера
function Get-NextNumber {
    param([string]$Dir, [string]$Prefix)

    $maxNum = 0
    Get-ChildItem -Path $Dir -Directory | ForEach-Object {
        if ($_.Name -match "^(\d{3})-") {
            $num = [int]$Matches[1]
            if ($num -gt $maxNum) { $maxNum = $num }
        }
    }
    return $maxNum + 1
}

# Создание каталога с номером (по аналогии со spec-kit)
$storyNum = Get-NextNumber -Dir $STORIES_DIR -Prefix "story"
$storyNumFormatted = "{0:D3}" -f $storyNum

# Генерация безопасного имени каталога (только английские слова)
$safeName = $storyData.name.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''

# Извлечение первых 3 слов
if ($safeName) {
    $words = $safeName -split '-' | Where-Object { $_ -ne '' } | Select-Object -First 3
    $safeName = $words -join '-'
}

# Если имя пустое (например, только китайские иероглифы), используется имя по умолчанию
if (-not $safeName) {
    $safeName = "story"
}

$storyDirName = "$storyNumFormatted-$safeName"
$storyPath = "$STORIES_DIR/$storyDirName"

New-Item -ItemType Directory -Path $storyPath | Out-Null
New-Item -ItemType Directory -Path "$storyPath/chapters" | Out-Null
New-Item -ItemType Directory -Path "$storyPath/characters" | Out-Null
New-Item -ItemType Directory -Path "$storyPath/worldbuilding" | Out-Null
New-Item -ItemType Directory -Path "$storyPath/notes" | Out-Null

# Вывод JSON результата
$result = @{
    STORY_NAME = $storyData.name
    STORY_FILE = "$storyPath/story.md"
    STORY_DIR = $storyPath
} | ConvertTo-Json -Compress

Write-Host $result
```