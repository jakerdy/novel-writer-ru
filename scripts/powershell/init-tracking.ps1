#!/usr/bin/env pwsh
# Инициализация системы отслеживания (PowerShell)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"

Write-Host "🚀 Инициализация системы отслеживания..."

$root = Get-ProjectRoot
$storyDir = Get-CurrentStoryDir
if (-not $storyDir) { throw "Пожалуйста, сначала завершите /story и /outline, каталог stories/*/ не найден" }

$storyName = Split-Path $storyDir -Leaf
$specTrack = Join-Path $root "spec/tracking"
New-Item -ItemType Directory -Path $specTrack -Force | Out-Null

Write-Host "📖 Инициализация системы отслеживания для «$storyName»..."

$utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# plot-tracker.json
$plotPath = Join-Path $specTrack "plot-tracker.json"
if (-not (Test-Path $plotPath)) {
  Write-Host "📝 Создание plot-tracker.json..."
  $plot = @{
    novel = $storyName
    lastUpdated = $utc
    currentState = @{ chapter = 0; volume = 1; mainPlotStage = 'Этап подготовки'; location = 'Не определено'; timepoint = 'До начала истории' }
    plotlines = @{ main = @{ name='Основная сюжетная линия'; description='Извлечь из плана'; status='Не начато'; currentNode='Стартовая точка'; completedNodes=@(); upcomingNodes=@(); plannedClimax=@{ chapter=$null; description='Планируется' } }; subplots=@() }
    foreshadowing = @()
    conflicts = @{ active=@(); resolved=@(); upcoming=@() }
    checkpoints = @{ volumeEnd=@(); majorEvents=@() }
    notes = @{ plotHoles=@(); inconsistencies=@(); reminders=@('Пожалуйста, обновите данные отслеживания в соответствии с фактическим содержанием истории') }
  } | ConvertTo-Json -Depth 12
  Set-Content -LiteralPath $plotPath -Value $plot -Encoding UTF8
}

# timeline.json
$timelinePath = Join-Path $specTrack "timeline.json"
if (-not (Test-Path $timelinePath)) {
  Write-Host "⏰ Создание timeline.json..."
  $timeline = @{
    novel = $storyName
    lastUpdated = $utc
    storyTimeUnit = 'дней'
    realWorldReference = $null
    timeline = @(@{ chapter=0; storyTime='День 0'; description='До начала истории'; events=@('Добавить'); location='Не определено' })
    parallelEvents = @()
    timeSpan = @{ start='День 0'; current='День 0'; elapsed='0 дней' }
  } | ConvertTo-Json -Depth 12
  Set-Content -LiteralPath $timelinePath -Value $timeline -Encoding UTF8
}

# relationships.json
$relationsPath = Join-Path $specTrack "relationships.json"
if (-not (Test-Path $relationsPath)) {
  Write-Host "👥 Создание relationships.json..."
  $relations = @{
    novel = $storyName
    lastUpdated = $utc
    characters = @{ 'Главный герой' = @{ name='Установить'; relationships=@{ allies=@(); enemies=@(); romantic=@(); neutral=@() } } }
    factions = @{}
    relationshipChanges = @()
    currentTensions = @()
  } | ConvertTo-Json -Depth 12
  Set-Content -LiteralPath $relationsPath -Value $relations -Encoding UTF8
}

# character-state.json
$charStatePath = Join-Path $specTrack "character-state.json"
if (-not (Test-Path $charStatePath)) {
  Write-Host "📍 Создание character-state.json..."
  $cs = @{
    novel = $storyName
    lastUpdated = $utc
    characters = @{ 'Главный герой' = @{ name='Установить'; status='Здоров'; location='Не определено'; possessions=@(); skills=@(); lastSeen=@{ chapter=0; description='Еще не появился' }; development=@{ physical=0; mental=0; emotional=0; power=0 } } }
    groupPositions = @{}
    importantItems = @{}
  } | ConvertTo-Json -Depth 12
  Set-Content -LiteralPath $charStatePath -Value $cs -Encoding UTF8
}

Write-Host ""
Write-Host "✅ Система отслеживания успешно инициализирована!"
Write-Host ""
Write-Host "📊 Созданы следующие файлы отслеживания:"
Write-Host "   • spec/tracking/plot-tracker.json - Отслеживание сюжета"
Write-Host "   • spec/tracking/timeline.json - Управление временной шкалой"
Write-Host "   • spec/tracking/relationships.json - Сеть взаимоотношений"
Write-Host "   • spec/tracking/character-state.json - Состояние персонажей"
Write-Host ""
Write-Host "💡 Следующие шаги:"
Write-Host "   1. Используйте /write для начала написания (данные отслеживания будут обновляться автоматически)"
Write-Host "   2. Регулярно используйте /track для просмотра сводного отчета"
Write-Host "   3. Используйте команды, такие как /plot-check, для проверки на согласованность"