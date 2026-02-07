```xml
# Скрипт проверки анализа истории
# Используется для команды /analyze

param(
    [string]$StoryName,
    [string]$AnalysisType = "full"  # full, compliance, quality, progress
)

# Импорт общих функций
. "$PSScriptRoot\common.ps1"

# Получение корневого каталога проекта
$ProjectRoot = Get-ProjectRoot
Set-Location $ProjectRoot

# Определение пути к истории
if ([string]::IsNullOrEmpty($StoryName)) {
    $StoryName = Get-ActiveStory
}

$StoryDir = "stories\$StoryName"

# Проверка необходимых файлов
function Test-StoryFiles {
    $missingFiles = @()

    # Проверка базовых документов
    if (-not (Test-Path "memory\constitution.md")) {
        $missingFiles += "Файл конституции"
    }
    if (-not (Test-Path "$StoryDir\specification.md")) {
        $missingFiles += "Файл спецификации"
    }
    if (-not (Test-Path "$StoryDir\creative-plan.md")) {
        $missingFiles += "Файл плана"
    }

    if ($missingFiles.Count -gt 0) {
        Write-Host "⚠️ Отсутствуют следующие базовые документы:" -ForegroundColor Yellow
        foreach ($file in $missingFiles) {
            Write-Host "  - $file"
        }
        return $false
    }

    return $true
}

# Статистика контента
function Get-ContentAnalysis {
    $contentDir = "$StoryDir\content"
    $totalWords = 0
    $chapterCount = 0

    if (Test-Path $contentDir) {
        $mdFiles = Get-ChildItem "$contentDir\*.md" -ErrorAction SilentlyContinue

        foreach ($file in $mdFiles) {
            $chapterCount++
            # Простая статистика слов (для китайского языка считается по символам)
            $content = Get-Content $file.FullName -Raw
            $words = ($content -replace '\s', '').Length
            $totalWords += $words
        }
    }

    Write-Host "Статистика контента:"
    Write-Host "  Общее количество слов: $totalWords"
    Write-Host "  Количество глав: $chapterCount"

    if ($chapterCount -gt 0) {
        $avgLength = [math]::Round($totalWords / $chapterCount)
        Write-Host "  Средняя длина главы: $avgLength"
    }
}

# Проверка выполнения задач
function Test-TaskCompletion {
    $tasksFile = "$StoryDir\tasks.md"

    if (-not (Test-Path $tasksFile)) {
        Write-Host "Файл задач отсутствует"
        return
    }

    $content = Get-Content $tasksFile -Raw
    $totalTasks = ([regex]::Matches($content, '^- \[', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    $completedTasks = ([regex]::Matches($content, '^- \[x\]', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    $inProgress = ([regex]::Matches($content, '^- \[~\]', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    $pending = $totalTasks - $completedTasks - $inProgress

    Write-Host "Прогресс выполнения задач:"
    Write-Host "  Всего задач: $totalTasks"
    Write-Host "  Выполнено: $completedTasks"
    Write-Host "  В процессе: $inProgress"
    Write-Host "  Ожидают: $pending"

    if ($totalTasks -gt 0) {
        $completionRate = [math]::Round(($completedTasks * 100) / $totalTasks)
        Write-Host "  Процент выполнения: $completionRate%"
    }
}

# Проверка соответствия спецификации
function Test-SpecificationCompliance {
    $specFile = "$StoryDir\specification.md"

    Write-Host "Проверка соответствия спецификации:"

    if (Test-Path $specFile) {
        $content = Get-Content $specFile -Raw

        # Проверка требований P0 (упрощенная версия)
        if ($content -match "### 必须包含（P0）") {
            Write-Host "  Требования P0: обнаружены, требуется ручная проверка"
        }

        # Проверка наличия маркеров [需要澄清] (требуется уточнение)
        $unclearCount = ([regex]::Matches($content, '\[需要澄清\]')).Count
        if ($unclearCount -gt 0) {
            Write-Host "  ⚠️ Осталось $unclearCount пунктов, требующих уточнения" -ForegroundColor Yellow
        }
        else {
            Write-Host "  ✅ Все решения уточнены" -ForegroundColor Green
        }
    }
}

# Основной процесс анализа
Write-Host "Отчет об анализе истории"
Write-Host "============"
Write-Host "История: $StoryName"
Write-Host "Время анализа: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# Проверка базовых документов
if (-not (Test-StoryFiles)) {
    Write-Host ""
    Write-Host "❌ Невозможно выполнить полный анализ, пожалуйста, сначала завершите базовые документы" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Базовые документы полные" -ForegroundColor Green
Write-Host ""

# Выполнение в зависимости от типа анализа
switch ($AnalysisType) {
    "full" {
        Get-ContentAnalysis
        Write-Host ""
        Test-TaskCompletion
        Write-Host ""
        Test-SpecificationCompliance
    }
    "quality" {
        Get-ContentAnalysis
    }
    "progress" {
        Test-TaskCompletion
    }
    "compliance" {
        Test-SpecificationCompliance
    }
    default {
        Write-Host "Неизвестный тип анализа: $AnalysisType" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Анализ завершен. Подробный отчет сохранен в: $StoryDir\analysis-report.md"
```