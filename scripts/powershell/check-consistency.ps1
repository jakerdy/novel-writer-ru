#!/usr/bin/env pwsh
# Комплексная проверка согласованности (PowerShell)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"

$root = Get-ProjectRoot
$storyDir = Get-CurrentStoryDir
if (-not $storyDir) { throw "Проект истории (stories/*) не найден" }

$progress = Join-Path $storyDir "progress.json"
$plot = Join-Path $storyDir "spec/tracking/plot-tracker.json"
if (-not (Test-Path $plot)) { $plot = Join-Path $root "spec/tracking/plot-tracker.json" }
$timeline = Join-Path $storyDir "spec/tracking/timeline.json"
if (-not (Test-Path $timeline)) { $timeline = Join-Path $root "spec/tracking/timeline.json" }
$rels = Join-Path $storyDir "spec/tracking/relationships.json"
if (-not (Test-Path $rels)) { $rels = Join-Path $root "spec/tracking/relationships.json" }
$charState = Join-Path $storyDir "spec/tracking/character-state.json"
if (-not (Test-Path $charState)) { $charState = Join-Path $root "spec/tracking/character-state.json" }

$TOTAL=0; $PASS=0; $WARN=0; $ERR=0
function Check([string]$name, [bool]$ok, [string]$msg) {
  $script:TOTAL++
  if ($ok) { Write-Host "✓ $name" -ForegroundColor Green; $script:PASS++ }
  else { Write-Host "✗ $name: $msg" -ForegroundColor Red; $script:ERR++ }
}
function Warn([string]$msg) { Write-Host "⚠ $msg" -ForegroundColor Yellow; $script:WARN++ }

function Check-FileIntegrity {
  Write-Host "📁 Проверка целостности файлов"
  Write-Host "────────────────"
  Check "progress.json" (Test-Path $progress) "Файл не существует"
  Check "plot-tracker.json" (Test-Path $plot) "Файл не существует"
  Check "timeline.json" (Test-Path $timeline) "Файл не существует"
  Check "relationships.json" (Test-Path $rels) "Файл не существует"
  Check "character-state.json" (Test-Path $charState) "Файл не существует"
  Write-Host ""
}

function Check-ChapterConsistency {
  Write-Host "📖 Проверка согласованности номеров глав"
  Write-Host "───────────────────"
  if ((Test-Path $progress) -and (Test-Path $plot)) {
    $p = Get-Content -LiteralPath $progress -Raw -Encoding UTF8 | ConvertFrom-Json
    $j = Get-Content -LiteralPath $plot -Raw -Encoding UTF8 | ConvertFrom-Json
    $pCh = [int]($p.statistics.currentChapter ?? 0)
    $plCh = [int]($j.currentState.chapter ?? 0)
    Check "Синхронизация номеров глав" ($pCh -eq $plCh) "progress($pCh) != plot-tracker($plCh)"
    if (Test-Path $charState) {
      $cs = Get-Content -LiteralPath $charState -Raw -Encoding UTF8 | ConvertFrom-Json
      # Поле protagonist в примере структуры нестабильно, откатываемся к characters->主角
      $csCh = [int]($cs.protagonist.currentStatus.chapter)
      if (-not $csCh) { $csCh = [int]($cs.characters.'主角'.lastSeen.chapter) }
      if ($csCh) { Check "Синхронизация глав в состоянии персонажа" ($pCh -eq $csCh) "Несоответствие с character-state($csCh)" }
    }
  } else { Warn "Некоторые файлы отслеживания отсутствуют, невозможно завершить проверку глав" }
  Write-Host ""
}

function Check-TimelineConsistency {
  Write-Host "⏰ Проверка непрерывности временной шкалы"
  Write-Host "───────────────────"
  if (Test-Path $timeline) {
    $j = Get-Content -LiteralPath $timeline -Raw -Encoding UTF8 | ConvertFrom-Json
    $events = @($j.events | Sort-Object chapter)
    $issues=0; $prev=-1
    foreach ($e in $events) { if ($prev -ge 0 -and $e.chapter -le $prev) { $issues++ }; $prev=$e.chapter }
    Check "Порядок событий временной шкалы" ($issues -eq 0) "Обнаружено ${issues} неупорядоченных событий"
    $curTime = $j.storyTime.current
    Check "Настройка текущего времени" ([bool]$curTime) "Текущее время истории не установлено"
  } else { Warn "Файл временной шкалы отсутствует" }
  Write-Host ""
}

function Check-CharacterConsistency {
  Write-Host "👥 Проверка разумности состояния персонажей"
  Write-Host "─────────────────────"
  if ((Test-Path $charState) -and (Test-Path $rels)) {
    $cs = Get-Content -LiteralPath $charState -Raw -Encoding UTF8 | ConvertFrom-Json
    $rel = Get-Content -LiteralPath $rels -Raw -Encoding UTF8 | ConvertFrom-Json
    $name = $cs.protagonist.name
    if (-not $name) { $name = $cs.characters.'主角'.name }
    if ($name) {
      $has = $false
      if ($rel.characters) { $has = $rel.characters.PSObject.Properties.Name -contains $name }
      Check "Запись отношений главного героя" $has "Главный герой '$name' не найден в relationships"
    }
    $loc = $cs.protagonist.currentStatus.location
    if (-not $loc) { $loc = $cs.characters.'主角'.location }
    Check "Запись местоположения главного героя" ([bool]$loc) "Текущее местоположение главного героя не записано"
  } else { Warn "Файлы отслеживания персонажей неполные" }
  Write-Host ""
}

function Check-ForeshadowingPlan {
  Write-Host "🎯 Проверка управления предзнаменованиями"
  Write-Host "──────────────"
  if (Test-Path $plot) {
    $j = Get-Content -LiteralPath $plot -Raw -Encoding UTF8 | ConvertFrom-Json
    $fs = @($j.foreshadowing)
    $total = $fs.Count
    $active = @($fs | Where-Object { $_.status -eq 'active' }).Count
    Write-Host "  📊 Статистика предзнаменований: Всего ${total}, активно ${active}"
    if ($active -gt 10) { Warn "Слишком много активных предзнаменований (${active}), что может сбить с толку читателя" }
  } else { Warn "Файл отслеживания сюжета отсутствует" }
  Write-Host ""
}

Write-Host "═══════════════════════════════════════"
Write-Host "📊 Отчет о комплексной проверке согласованности"
Write-Host "═══════════════════════════════════════"
Write-Host ""

Check-FileIntegrity
Check-ChapterConsistency
Check-TimelineConsistency
Check-CharacterConsistency
Check-ForeshadowingPlan

Write-Host "═══════════════════════════════════════"
Write-Host "📈 Сводка результатов проверки"
Write-Host "───────────────────"
Write-Host "  Всего проверок: $TOTAL"
Write-Host "  Пройдено: $PASS"
Write-Host "  Предупреждений: $WARN"
Write-Host "  Ошибок: $ERR"

if ($ERR -eq 0 -and $WARN -eq 0) { Write-Host "`n✅ Отлично! Все проверки пройдены" -ForegroundColor Green }
elseif ($ERR -eq 0) { Write-Host "`n⚠️  Обнаружено $WARN предупреждений, рекомендуется обратить внимание" -ForegroundColor Yellow }
else { Write-Host "`n❌ Обнаружено $ERR ошибок, требуется исправление" -ForegroundColor Red }

Write-Host "═══════════════════════════════════════"
Write-Host "Время проверки: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

if ($ERR -gt 0) { exit 1 } else { exit 0 }