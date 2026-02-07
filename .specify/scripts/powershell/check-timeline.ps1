```powershell
#!/usr/bin/env pwsh
# Управление и проверка временной шкалы (PowerShell)

param(
  [ValidateSet('show','add','check','sync')]
  [string]$Command = 'show',
  [string]$Param1,
  [string]$Param2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"

$root = Get-ProjectRoot
$storyDir = Get-CurrentStoryDir
if (-not $storyDir) { throw "Проект истории (stories/*) не найден" }

$timelinePath = Join-Path $storyDir "spec/tracking/timeline.json"
if (-not (Test-Path $timelinePath)) { $timelinePath = Join-Path $root "spec/tracking/timeline.json" }

function Init-Timeline {
  if (-not (Test-Path $timelinePath)) {
    Write-Host "⚠️  Файл временной шкалы не найден, создаётся..."
    $tpl = Join-Path $root "templates/tracking/timeline.json"
    if (-not (Test-Path $tpl)) { throw "Невозможно найти файл шаблона" }
    New-Item -ItemType Directory -Path (Split-Path $timelinePath -Parent) -Force | Out-Null
    Copy-Item $tpl $timelinePath -Force
    Write-Host "✅ Файл временной шкалы создан"
  }
}

function Show-Timeline {
  Write-Host "📅 Временная шкала истории"
  Write-Host "━━━━━━━━━━━━━━━━━━━━"
  if (-not (Test-Path $timelinePath)) { Write-Host "Файл временной шкалы не найден"; return }
  $j = Get-Content -LiteralPath $timelinePath -Raw -Encoding UTF8 | ConvertFrom-Json
  $cur = $j.storyTime.current
  if (-not $cur) { $cur = 'Не установлено' }
  Write-Host "⏰ Текущее время: $cur"
  Write-Host ""
  $events = @($j.events)
  if ($events.Count -gt 0) {
    Write-Host "📖 Важные события:"
    Write-Host "───────────────"
    $events | Sort-Object chapter -Descending | Select-Object -First 5 | ForEach-Object {
      Write-Host ("Глава {0} | {1} | {2}" -f $_.chapter, $_.date, $_.event)
    }
  }
  $p = $j.parallelEvents.timepoints
  if ($p) {
    Write-Host ""
    Write-Host "🔄 Параллельные события:"
    $p.PSObject.Properties | ForEach-Object { Write-Host ("{0}: {1}" -f $_.Name, (@($_.Value) -join ', ')) }
  }
}

function Add-Event([int]$chapter, [string]$date, [string]$event) {
  if (-not $chapter -or -not $date -or -not $event) { throw "Использование: check-timeline.ps1 add <номер главы> <время> <описание события>" }
  Init-Timeline
  $j = Get-Content -LiteralPath $timelinePath -Raw -Encoding UTF8 | ConvertFrom-Json
  if (-not $j.events) { $j | Add-Member -NotePropertyName events -NotePropertyValue @() }
  $j.events += [pscustomobject]@{ chapter=$chapter; date=$date; event=$event; duration=''; participants=@() }
  $j.events = @($j.events | Sort-Object chapter)
  $j.lastUpdated = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
  $j | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $timelinePath -Encoding UTF8
  Write-Host "✅ Событие добавлено: Глава ${chapter} - $date - $event"
}

function Check-Continuity {
  Write-Host "🔍 Проверка непрерывности временной шкалы"
  Write-Host "━━━━━━━━━━━━━━━━━━━━"
  if (-not (Test-Path $timelinePath)) { throw "Файл временной шкалы не существует" }
  $j = Get-Content -LiteralPath $timelinePath -Raw -Encoding UTF8 | ConvertFrom-Json
  $chapters = @($j.events | Sort-Object chapter | ForEach-Object { $_.chapter })
  $issues = 0
  $prev = -1
  foreach ($c in $chapters) {
    if ($prev -ge 0 -and $c -le $prev) {
      Write-Host "⚠️  Неправильный порядок глав: Глава $c появилась после главы $prev"
      $issues++
    }
    $prev = $c
  }
  if ($issues -eq 0) { Write-Host "`n✅ Проверка временной шкалы пройдена, логических проблем не обнаружено" }
  else { Write-Host "`n⚠️  Обнаружено ${issues} потенциальных проблем, пожалуйста, проверьте" }
  $j.lastChecked = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
  if (-not $j.anomalies) { $j | Add-Member anomalies (@{}) }
  $j.anomalies.lastCheckIssues = $issues
  $j | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $timelinePath -Encoding UTF8
}

function Sync-Parallel([string]$timepoint, [string]$eventsCsv) {
  if (-not $timepoint -or -not $eventsCsv) { throw "Использование: check-timeline.ps1 sync <временная точка> <список событий, разделённых запятыми>" }
  Init-Timeline
  $j = Get-Content -LiteralPath $timelinePath -Raw -Encoding UTF8 | ConvertFrom-Json
  if (-not $j.parallelEvents) { $j | Add-Member -NotePropertyName parallelEvents -NotePropertyValue @{ timepoints=@{} } }
  $events = $eventsCsv.Split(',').Trim()
  $j.parallelEvents.timepoints[$timepoint] = $events
  $j.lastUpdated = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
  $j | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $timelinePath -Encoding UTF8
  Write-Host "✅ Параллельные события синхронизированы: $timepoint"
}

switch ($Command) {
  'show'  { Init-Timeline; Show-Timeline }
  'add'   { Add-Event -chapter ([int]$Param1) -date $Param2 -event ($args | Select-Object -Skip 2 | Out-String).Trim() }
  'check' { Check-Continuity }
  'sync'  { Sync-Parallel -timepoint $Param1 -eventsCsv $Param2 }
}
```