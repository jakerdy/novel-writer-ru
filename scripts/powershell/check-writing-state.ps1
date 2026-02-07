```powershell
# Проверка статуса написания
# Используется для команды /write

# Импорт общих функций
. "$PSScriptRoot\common.ps1"

# Получение корневого каталога проекта
$ProjectRoot = Get-ProjectRoot
Set-Location $ProjectRoot

# Получение текущей истории
$StoryName = Get-ActiveStory
$StoryDir = "stories\$StoryName"

Write-Host "Проверка статуса написания"
Write-Host "============"
Write-Host "Текущая история: $StoryName"
Write-Host ""

# Проверка документов методологии
function Test-MethodologyDocs {
    $missing = @()

    if (-not (Test-Path "memory\constitution.md")) {
        $missing += "Конституция"
    }
    if (-not (Test-Path "$StoryDir\specification.md")) {
        $missing += "Спецификация"
    }
    if (-not (Test-Path "$StoryDir\creative-plan.md")) {
        $missing += "План"
    }
    if (-not (Test-Path "$StoryDir\tasks.md")) {
        $missing += "Задачи"
    }

    if ($missing.Count -gt 0) {
        Write-Host "⚠️ Отсутствуют следующие базовые документы:" -ForegroundColor Yellow
        foreach ($doc in $missing) {
            Write-Host "  - $doc"
        }
        Write-Host ""
        Write-Host "Рекомендуется выполнить предварительные шаги в соответствии с семиэтапной методологией:"
        Write-Host "1. /constitution - Создать конституцию творчества"
        Write-Host "2. /specify - Определить спецификацию истории"
        Write-Host "3. /clarify - Уточнить ключевые решения"
        Write-Host "4. /plan - Составить план творчества"
        Write-Host "5. /tasks - Сгенерировать список задач"
        return $false
    }

    Write-Host "✅ Документы методологии в полном порядке" -ForegroundColor Green
    return $true
}

# Проверка ожидающих задач
function Test-PendingTasks {
    $tasksFile = "$StoryDir\tasks.md"

    if (-not (Test-Path $tasksFile)) {
        Write-Host "❌ Файл задач не существует" -ForegroundColor Red
        return $false
    }

    # Подсчет статусов задач
    $content = Get-Content $tasksFile -Raw
    $pending = ([regex]::Matches($content, '^- \[ \]', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    $inProgress = ([regex]::Matches($content, '^- \[~\]', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    $completed = ([regex]::Matches($content, '^- \[x\]', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count

    Write-Host ""
    Write-Host "Статус задач:"
    Write-Host "  К выполнению: $pending"
    Write-Host "  В процессе: $inProgress"
    Write-Host "  Завершено: $completed"

    if ($pending -eq 0 -and $inProgress -eq 0) {
        Write-Host ""
        Write-Host "🎉 Все задачи выполнены!" -ForegroundColor Green
        Write-Host "Рекомендуется выполнить /analyze для комплексной проверки"
        return $true
    }

    # Отображение следующей задачи для написания
    Write-Host ""
    Write-Host "Следующая задача для написания:"
    $lines = $content -split "`n"
    foreach ($line in $lines) {
        if ($line -match '^- \[ \]') {
            Write-Host $line
            break
        }
    }

    return $true
}

# Проверка завершенного контента
function Test-CompletedContent {
    $contentDir = "$StoryDir\content"

    if (Test-Path $contentDir) {
        $mdFiles = Get-ChildItem "$contentDir\*.md" -ErrorAction SilentlyContinue
        $chapterCount = $mdFiles.Count

        if ($chapterCount -gt 0) {
            Write-Host ""
            Write-Host "Завершенные главы: $chapterCount"
            Write-Host "Последнее написанное:"

            $recentFiles = $mdFiles |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 3

            foreach ($file in $recentFiles) {
                Write-Host "  - $($file.Name)"
            }
        }
    }
    else {
        Write-Host ""
        Write-Host "Написание еще не начато"
    }
}

# Основной процесс
if (-not (Test-MethodologyDocs)) {
    exit 1
}

Test-PendingTasks | Out-Null
Test-CompletedContent

Write-Host ""
Write-Host "Готово к написанию"
```