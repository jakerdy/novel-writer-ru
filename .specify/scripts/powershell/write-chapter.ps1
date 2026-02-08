#!/usr/bin/env pwsh
# Написание содержания главы

$STORIES_DIR = "stories"
$MEMORY_DIR = "memory"

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

# Парсинг информации о томе из outline.md
function Parse-VolumeInfo {
    param(
        [string]$OutlineFile,
        [int]$ChapterNum
    )

    if (Test-Path $OutlineFile) {
        $content = Get-Content $OutlineFile -Raw
        $volumeNum = 1

        # Сопоставление тома и диапазона глав
        $pattern = '###\s+第.*?卷.*?\n[\s\S]*?章节范围.*?第(\d+)-(\d+)章'
        $matches = [regex]::Matches($content, $pattern)

        foreach ($match in $matches) {
            $startCh = [int]$match.Groups[1].Value
            $endCh = [int]$match.Groups[2].Value

            if ($ChapterNum -ge $startCh -and $ChapterNum -le $endCh) {
                return "volume-$volumeNum"
            }
            $volumeNum++
        }
    }

    # Правило по умолчанию: один том на каждые 60 глав
    $volume = [math]::Floor(($ChapterNum - 1) / 60) + 1
    return "volume-$volume"
}

# Определение тома, к которому относится глава
function Get-Volume {
    param([int]$ChapterNum)

    $outlineFile = "$storyDir/outline.md"
    return Parse-VolumeInfo -OutlineFile $outlineFile -ChapterNum $ChapterNum
}

# Получение следующей главы для написания
function Get-NextChapter {
    param([string]$ChaptersDir)

    # Получение общего количества глав из outline.md
    $maxChapters = 500  # Значение по умолчанию
    $outlineFile = "$storyDir/outline.md"

    if (Test-Path $outlineFile) {
        $content = Get-Content $outlineFile -Raw
        if ($content -match '总章节数.*?(\d+)章') {
            $maxChapters = [int]$matches[1]
        }
    }

    # Перебор всех возможных глав для поиска первой ненаписанной
    for ($i = 1; $i -le $maxChapters; $i++) {
        $volume = Get-Volume -ChapterNum $i
        $chapterNumFormatted = "{0:D3}" -f $i
        $chapterFile = "$ChaptersDir/$volume/chapter-$chapterNumFormatted.md"

        if (!(Test-Path $chapterFile)) {
            return $i
        }
    }
    return $maxChapters + 1  # Все главы написаны
}

$storyDir = Get-LatestStory

if (!$storyDir) {
    Write-Host "Ошибка: Проект истории не найден"
    exit 1
}

$chaptersDir = "$storyDir/chapters"
$outlineFile = "$storyDir/outline.md"
$storyFile = "$storyDir/story.md"
$styleFile = "$MEMORY_DIR/writing-constitution.md"

# Проверка наличия необходимых файлов
if (!(Test-Path $outlineFile)) {
    Write-Host "Ошибка: План глав не найден"
    Write-Host "Пожалуйста, сначала создайте план глав с помощью команды /outline"
    exit 1
}

$nextChapter = Get-NextChapter -ChaptersDir $chaptersDir
$volume = Get-Volume -ChapterNum $nextChapter
$chapterNumFormatted = "{0:D3}" -f $nextChapter
$volumeDir = "$chaptersDir/$volume"

# Создание директории тома (если она не существует)
if (!(Test-Path $volumeDir)) {
    New-Item -ItemType Directory -Path $volumeDir | Out-Null
}

$chapterFile = "$volumeDir/chapter-$chapterNumFormatted.md"

Write-Host "Директория истории: $storyDir"
Write-Host "Файл главы: $chapterFile"
Write-Host "Текущая глава: Глава $nextChapter ($volume)"
Write-Host ""
Write-Host "Связанные файлы:"
if (Test-Path $styleFile) {
    Write-Host "- Стиль письма: $styleFile"
}
Write-Host "- План истории: $storyFile"
Write-Host "- План глав: $outlineFile"
Write-Host ""
Write-Host "Начинаем написание главы $nextChapter..."