#!/usr/bin/env pwsh
# Проверка согласованности и связности развития сюжета (PowerShell)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"

$root = Get-ProjectRoot
$storyDir = Get-CurrentStoryDir
if (-not $storyDir) { throw "Не найден проект истории (stories/*)" }

$plotPath = Join-Path $storyDir "spec/tracking/plot-tracker.json"
if (-not (Test-Path $plotPath)) { $plotPath = Join-Path $root "spec/tracking/plot-tracker.json" }
$outlinePath = Join-Path $storyDir "outline.md"
$progressPath = Join-Path $storyDir "progress.json"

function Ensure-PlotTracker {
  if (-not (Test-Path $plotPath)) {
    Write-Host "⚠️  Файл отслеживания сюжета не найден, создаётся..."
    $tpl = Join-Path $root "templates/tracking/plot-tracker.json"
    if (-not (Test-Path $tpl)) { throw "Невозможно найти файл шаблона" }
    New-Item -ItemType Directory -Path (Split-Path $plotPath -Parent) -Force | Out-Null
    Copy-Item $tpl $plotPath -Force
  }
  if (-not (Test-Path $outlinePath)) { throw "Не найден план глав outline.md, используйте сначала /outline" }
}

function Get-CurrentProgress {
  if (Test-Path $progressPath) {
    $p = Get-Content -LiteralPath $progressPath -Raw -Encoding UTF8 | ConvertFrom-Json
    return @{ chapter = ($p.statistics.currentChapter ?? 1); volume = ($p.statistics.currentVolume ?? 1) }
  }
  if (Test-Path $plotPath) {
    $j = Get-Content -LiteralPath $plotPath -Raw -Encoding UTF8 | ConvertFrom-Json
    return @{ chapter = ($j.currentState.chapter ?? 1); volume = ($j.currentState.volume ?? 1) }
  }
  return @{ chapter = 1; volume = 1 }
}

function Analyze-PlotAlignment {
  Write-Host "📊 Отчёт о проверке развития сюжета"
  Write-Host "━━━━━━━━━━━━━━━━━━━━"
  $cur = Get-CurrentProgress
  Write-Host "📍 Текущий прогресс: Глава $($cur.chapter) (Том $($cur.volume))"

  if (Test-Path $plotPath) {
    $j = Get-Content -LiteralPath $plotPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $main = $j.plotlines.main
    $mainPlot = $main.currentNode
    $status = $main.status
    Write-Host "📖 Прогресс основной линии: $mainPlot [$status]"

    $completed = @($main.completedNodes)
    Write-Host ""
    Write-Host "✅ Завершённые узлы: $($completed.Count) шт."
    $completed | ForEach-Object { Write-Host "  • $_" }

    $upcoming = @($main.upcomingNodes)
    if ($upcoming.Count -gt 0) {
      Write-Host ""
      Write-Host "→ Следующие узлы:"
      $upcoming | Select-Object -First 3 | ForEach-Object { Write-Host "  • $_" }
    }
    return @{ cur = $cur; json = $j }
  }
}

function Check-Foreshadowing($state) {
  Write-Host ""
  Write-Host "🎯 Отслеживание намёков"
  Write-Host "───────────"
  $j = $state.json
  $curCh = [int]$state.cur.chapter
  $fs = @($j.foreshadowing)
  $total = $fs.Count
  $active = @($fs | Where-Object { $_.status -eq 'active' }).Count
  $resolved = @($fs | Where-Object { $_.status -eq 'resolved' }).Count
  Write-Host "Статистика: всего ${total}, активно ${active}, разрешено ${resolved}"

  if ($active -gt 0) {
    Write-Host ""
    Write-Host "⚠️ Намёки в ожидании:"
    $fs | Where-Object { $_.status -eq 'active' } | ForEach-Object {
      $ch = $_.planted.chapter
      Write-Host "  • $($_.content) (заложено в главе $ch)"
    }
  }

  $overdue = @($fs | Where-Object { $_.status -eq 'active' -and $_.planted.chapter -and ($curCh - [int]$_.planted.chapter) -gt 30 }).Count
  if ($overdue -gt 0) { Write-Host ""; Write-Host "⚠️ Предупреждение: ${overdue} намёков не обрабатывались более 30 глав" }
}

function Check-Conflicts($state) {
  Write-Host ""
  Write-Host "⚔️ Отслеживание конфликтов"
  Write-Host "───────────"
  $active = @($state.json.conflicts.active)
  $count = $active.Count
  if ($count -gt 0) {
    Write-Host "Текущих активных конфликтов: ${count} шт."
    $active | ForEach-Object { Write-Host ("  • " + $_.name + " [" + $_.intensity + "]") }
  } else { Write-Host "Активных конфликтов нет" }
}

function Generate-Suggestions($state) {
  Write-Host ""
  Write-Host "💡 Предложения"
  Write-Host "───────"
  $ch = [int]$state.cur.chapter
  if ($ch -lt 10) { Write-Host "• Первые 10 глав — ключевые, убедитесь, что в них достаточно крючков для привлечения читателя" }
  elseif ($ch -lt 30) { Write-Host "• Приближается первый кульминационный момент, проверьте, достаточно ли напряжены конфликты" }
  elseif (($ch % 60) -gt 50) { Write-Host "• Близок конец тома, подготовьте кульминацию и задел на будущее" }

  $activeFo = @($state.json.foreshadowing | Where-Object { $_.status -eq 'active' }).Count
  if ($activeFo -gt 5) { Write-Host "• Активно много намёков, рассмотрите возможность разрешения части из них в ближайших главах" }
  $activeConf = @($state.json.conflicts.active).Count
  if ($activeConf -eq 0 -and $ch -gt 5) { Write-Host "• Отсутствуют активные конфликты, рассмотрите возможность введения новых точек напряжения" }
}

Write-Host "🔍 Начинается проверка согласованности сюжета..."
Write-Host ""
Ensure-PlotTracker
$st = Analyze-PlotAlignment
Check-Foreshadowing $st
Check-Conflicts $st
Generate-Suggestions $st

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━"
Write-Host "✅ Проверка завершена"

# Обновление временной метки
if (Test-Path $plotPath) {
  $json = Get-Content -LiteralPath $plotPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $json.lastUpdated = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
  $json | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $plotPath -Encoding UTF8
}