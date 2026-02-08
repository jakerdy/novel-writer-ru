#!/usr/bin/env pwsh
# Менеджер стилей (PowerShell) — полная реализация по мотивам Bash версии

param(
  [string]$Mode = "init"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot {
  # Ищет вверх от текущего каталога каталог, содержащий .specify/config.json
  $current = (Get-Location).Path
  while ($true) {
    $cfg = Join-Path $current ".specify/config.json"
    if (Test-Path $cfg) { return $current }
    $parent = Split-Path $current -Parent
    if (-not $parent -or $parent -eq $current) { break }
    $current = $parent
  }
  throw "Корневой каталог проекта романа не найден (отсутствует .specify/config.json)"
}

function Ensure-Dir($path) {
  if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path | Out-Null }
}

function Ensure-File($file, $template) {
  if (-not (Test-Path $file)) {
    if ($template -and (Test-Path $template)) {
      Copy-Item $template $file -Force
    } else {
      New-Item -ItemType File -Path $file | Out-Null
    }
  }
}

$ProjectRoot = Get-ProjectRoot
$MemoryDir   = Join-Path $ProjectRoot ".specify/memory"
$SpecDir     = Join-Path $ProjectRoot "spec"
$KnowledgeDir= Join-Path $SpecDir "knowledge"
$TrackingDir = Join-Path $SpecDir "tracking"

Ensure-Dir $MemoryDir
Ensure-Dir $KnowledgeDir
Ensure-Dir $TrackingDir

function Integrate-PersonalVoice([string]$constitutionFile) {
  $pvFile = Join-Path $ProjectRoot ".specify/memory/personal-voice.md"
  if (-not (Test-Path $pvFile)) { return }

  $lines = Get-Content -LiteralPath $pvFile -Encoding UTF8
  $out = @()
  $out += ""
  $out += "## Сводка личных материалов (автоматическая ссылка)"
  $out += "Источник: .specify/memory/personal-voice.md"
  $out += ""

  # Имитация Bash версии: взять первые 2 элемента списка из нескольких H2
  $countSections = 0
  $take = 2
  $inSection = $false
  $takenInSection = 0
  foreach ($l in $lines) {
    if ($l -match '^## ') {
      $countSections++
      if ($countSections -gt 6) { break }
      $out += $l
      $inSection = $true
      $takenInSection = 0
      continue
    }
    if ($inSection -and $l -match '^## ') {
      $inSection = $false
      $takenInSection = 0
    }
    if ($inSection -and $l -match '^- ' -and $takenInSection -lt $take) {
      $out += $l
      $takenInSection++
    }
  }

  $constText = if (Test-Path $constitutionFile) { Get-Content -LiteralPath $constitutionFile -Raw -Encoding UTF8 } else { "" }
  if ($constText -notmatch 'Сводка личных материалов (автоматическая ссылка)') {
    Add-Content -LiteralPath $constitutionFile -Value ($out -join "`n") -Encoding UTF8
    Write-Host "    ✅ Сводка личных материалов импортирована"
  }
}

function Sync-PersonalBaseline([string]$constitutionFile) {
  $pvFile = Join-Path $ProjectRoot ".specify/memory/personal-voice.md"
  if (-not (Test-Path $pvFile)) { return }

  $sections = @(
    @{ title='Коронные фразы и часто используемые выражения'; label='Коронные фразы и выражения'; take=6 },
    @{ title='Фиксированные конструкции и предпочтения в ритме'; label='Фиксированные конструкции и ритм'; take=6 },
    @{ title='Отраслевая/региональная лексика (акцент, сленг, термины)'; label='Отраслевая/региональная лексика'; take=6 },
    @{ title='Предпочтения в метафорах и банк образов'; label='Метафоры и образы'; take=8 },
    @{ title='Писательские табу и ограничения'; label='Писательские табу'; take=6 }
  )

  $lines = Get-Content -LiteralPath $pvFile -Encoding UTF8

  function FetchList($title, $take) {
    $result = @()
    $hit = $false; $cnt = 0
    foreach ($l in $lines) {
      if ($l -match "^## \Q$title\E$") { $hit = $true; $cnt = 0; continue }
      if ($hit -and $l -match '^## ') { break }
      if ($hit -and $l -match '^- ' -and $cnt -lt $take) { $result += $l; $cnt++ }
    }
    return $result
  }

  $block = @()
  $block += "<!-- BEGIN: PERSONAL_BASELINE_AUTO -->"
  $block += "## Базовая линия личного стиля (автоматическая синхронизация)"
  $block += "Источник: .specify/memory/personal-voice.md (только для чтения, для внесения изменений используйте исходный файл)"
  $block += ""
  foreach ($sec in $sections) {
    $block += "### $($sec.label)"
    $block += (FetchList $sec.title $sec.take)
    $block += ""
  }
  $block += "<!-- END: PERSONAL_BASELINE_AUTO -->"
  $blockText = ($block -join "`n")

  $constText = if (Test-Path $constitutionFile) { Get-Content -LiteralPath $constitutionFile -Raw -Encoding UTF8 } else { "" }
  if ($constText -match '<!-- BEGIN: PERSONAL_BASELINE_AUTO -->') {
    $constText = [regex]::Replace($constText, "<!-- BEGIN: PERSONAL_BASELINE_AUTO -->[\s\S]*<!-- END: PERSONAL_BASELINE_AUTO -->", [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $blockText })
  } else {
    if (-not [string]::IsNullOrWhiteSpace($constText)) { $constText += "`n" }
    $constText += $blockText
  }
  Set-Content -LiteralPath $constitutionFile -Value $constText -Encoding UTF8
  Write-Host "    ✅ Базовая линия личного стиля синхронизирована"
}

function Init-Style {
  Write-Host "📝 Инициализация стиля письма..."
  $constitution = Join-Path $MemoryDir "writing-constitution.md"
  $template = Join-Path $ProjectRoot ".specify/templates/writing-constitution-template.md"
  Ensure-File $constitution $template
  Integrate-PersonalVoice $constitution
  Sync-PersonalBaseline $constitution
  Write-Host "CONSTITUTION_FILE: $constitution"
  Write-Host "STATUS: ready"
  Write-Host "✅ Инициализация стиля письма завершена"
}

function Append-Lines($path, [string[]]$lines) {
  Ensure-Dir (Split-Path $path -Parent)
  if (-not (Test-Path $path)) { New-Item -ItemType File -Path $path | Out-Null }
  Add-Content -LiteralPath $path -Value ($lines -join "`n") -Encoding UTF8
}

function Process-StyleSuggestions($data) {
  if (-not $data.suggestions -or -not $data.suggestions.style) { return }
  Write-Host "  📝 Обработка предложений по стилю..."
  $items = $data.suggestions.style.items
  if (-not $items) { return }
  $constitution = Join-Path $MemoryDir "writing-constitution.md"
  $hdr = @()
  $date = (Get-Date -Format 'yyyy-MM-dd')
  $hdr += ""
  $hdr += "## Оптимизация внешними предложениями ($date)"
  $hdr += ""
  $body = @()
  foreach ($it in $items) {
    $body += "### $($it.type ?? 'Без категории')"
    $body += "- **Проблема**: $($it.current)"
    $body += "- **Предложение**: $($it.suggestion)"
    $body += "- **Ожидаемый эффект**: $($it.impact)"
    $body += ""
  }
  Append-Lines $constitution ($hdr + $body)
  Write-Host "    ✅ Редакционные правила обновлены"
}

function Process-CharacterSuggestions($data) {
  if (-not $data.suggestions -or -not $data.suggestions.characters) { return }
  Write-Host "  👥 Обработка предложений по персонажам..."
  $items = $data.suggestions.characters.items
  if (-not $items) { return }
  $profiles = Join-Path $KnowledgeDir "character-profiles.md"
  if (-not (Test-Path $profiles)) { return }
  $date = (Get-Date -Format 'yyyy-MM-dd')
  $lines = @("", "## Предложения по оптимизации персонажей ($date)", "")
  foreach ($it in $items) {
    $lines += "### $($it.character ?? 'Неизвестный персонаж')"
    $lines += "- **Проблема**: $($it.issue)"
    $lines += "- **Предложение**: $($it.suggestion)"
    $lines += "- **Кривая развития**: $($it.development_curve)"
    if ($it.chapters_affected) {
      $lines += "- **Затронутые главы**: $((@($it.chapters_affected) -join ', '))"
    }
    $lines += ""
  }
  Append-Lines $profiles $lines
  Write-Host "    ✅ Профили персонажей обновлены"
}

function Process-PlotSuggestions($data) {
  if (-not $data.suggestions -or -not $data.suggestions.plot) { return }
  Write-Host "  📖 Обработка предложений по сюжету..."
  $file = Join-Path $TrackingDir "plot-tracker.json"
  if (-not (Test-Path $file)) { return }
  $tracker = Get-Content -LiteralPath $file -Raw -Encoding UTF8 | ConvertFrom-Json
  if (-not $tracker.suggestions) { $tracker | Add-Member -NotePropertyName suggestions -NotePropertyValue @() }
  $date = (Get-Date -Format 'yyyy-MM-dd')
  foreach ($it in $data.suggestions.plot.items) {
    $tracker.suggestions += [pscustomobject]@{
      date = $date
      type = $it.type
      location = $it.location
      suggestion = $it.suggestion
      importance = ($it.importance ?? 'medium')
      status = 'pending'
    }
  }
  $tracker | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $file -Encoding UTF8
  Write-Host "    ✅ Трекер сюжета обновлен"
}

function Process-WorldSuggestions($data) {
  if (-not $data.suggestions -or -not $data.suggestions.worldbuilding) { return }
  Write-Host "  🌍 Обработка предложений по мироустройству..."
  $items = $data.suggestions.worldbuilding.items
  if (-not $items) { return }
  $file = Join-Path $KnowledgeDir "world-setting.md"
  if (-not (Test-Path $file)) { return }
  $date = (Get-Date -Format 'yyyy-MM-dd')
  $lines = @("", "## Предложения по улучшению мироустройства ($date)", "")
  foreach ($it in $items) {
    $lines += "### $($it.aspect ?? 'Без категории')"
    $lines += "- **Проблема**: $($it.issue)"
    $lines += "- **Предложение**: $($it.suggestion)"
    if ($it.reference_chapters) {
      $lines += "- **Рекомендуемые главы**: $((@($it.reference_chapters) -join ', '))"
    }
    $lines += ""
  }
  Append-Lines $file $lines
  Write-Host "    ✅ Настройки мира обновлены"
}

function Process-DialogueSuggestions($data) {
  if (-not $data.suggestions -or -not $data.suggestions.dialogue) { return }
  Write-Host "  💬 Обработка предложений по диалогам..."
  $items = $data.suggestions.dialogue.items
  if (-not $items) { return }
  $file = Join-Path $KnowledgeDir "character-voices.md"
  if (-not (Test-Path $file)) {
    Set-Content -LiteralPath $file -Value "# Языковые нормы персонажей`n`n## Общие принципы`n" -Encoding UTF8
  }
  $date = (Get-Date -Format 'yyyy-MM-dd')
  $lines = @("", "## Предложения по улучшению диалогов ($date)", "")
  foreach ($it in $items) {
    $lines += "### $($it.character ?? 'Общее')"
    $lines += "- **Проблема**: $($it.issue)"
    $lines += "- **Предложение**: $($it.suggestion)"
    if ($it.examples -and $it.alternatives) {
      $lines += "- **Примеры замены:"
      for ($i=0; $i -lt $it.examples.Count; $i++) {
        $ex = $it.examples[$i]
        $alt = if ($i -lt $it.alternatives.Count) { $it.alternatives[$i] } else { $null }
        if ($alt) { $lines += "  - $ex → $alt" }
      }
    }
    $lines += ""
  }
  Append-Lines $file $lines
  Write-Host "    ✅ Языковые нормы персонажей обновлены"
}

function Parse-JsonSuggestions([string]$jsonText) {
  try { $data = $jsonText | ConvertFrom-Json } catch { throw "Неверный формат JSON" }
  $source = if ($data.source) { $data.source } else { 'Unknown' }
  $date = if ($data.analysis_date) { $data.analysis_date } else { (Get-Date -Format 'yyyy-MM-dd') }
  Write-Host "📊 Анализ предложений от $source ($date)"
  Process-StyleSuggestions $data
  Process-CharacterSuggestions $data
  Process-PlotSuggestions $data
  Process-WorldSuggestions $data
  Process-DialogueSuggestions $data
}

function Parse-MarkdownSuggestions([string]$md) {
  Write-Host "📊 Анализ предложений в формате Markdown..."
  # Упрощено: извлекаются два блока "Предложения по стилю письма" и "Предложения по оптимизации персонажей"
  $constitution = Join-Path $MemoryDir "writing-constitution.md"
  $profiles = Join-Path $KnowledgeDir "character-profiles.md"
  $date = (Get-Date -Format 'yyyy-MM-dd')

  if ($md -match "## 写作风格建议") {
    $lines = @("", "## Оптимизация внешними предложениями ($date)", "")
    $segment = ($md -split "## 写作风格建议")[1]
    if ($segment) { $segment = ($segment -split "\n## ")[0] }
    if ($segment) { $lines += ($segment.TrimEnd()).Split("`n") }
    Append-Lines $constitution $lines
    Write-Host "    ✅ Редакционные правила обновлены"
  }

  if ((Test-Path $profiles) -and ($md -match "## 角色优化建议")) {
    $lines = @("", "## Внешние предложения по оптимизации ($date)", "")
    $segment = ($md -split "## 角色优化建议")[1]
    if ($segment) { $segment = ($segment -split "\n## ")[0] }
    if ($segment) { $lines += ($segment.TrimEnd()).Split("`n") }
    Append-Lines $profiles $lines
    Write-Host "    ✅ Профили персонажей обновлены"
  }
}

function Update-ImprovementLog([string]$source, [string]$summary) {
  $log = Join-Path $KnowledgeDir "improvement-log.md"
  if (-not (Test-Path $log)) {
    Set-Content -LiteralPath $log -Value "# История предложений по улучшению`n`nЗаписывает все внешние предложения ИИ и принятые изменения. `n" -Encoding UTF8
  }
  $lines = @()
  $lines += ""
  $lines += "## $(Get-Date -Format 'yyyy-MM-dd') - $source"
  $lines += ""
  $lines += "### Краткий обзор предложений"
  $lines += $summary
  $lines += ""
  $lines += "### Статус принятия"
  $lines += "- [x] Автоматически интегрировано в файл спецификаций"
  $lines += "- [ ] Ожидает ручной проверки"
  $lines += "- [ ] Ожидает внедрения изменений"
  $lines += ""
  $lines += "### Затронутые файлы"
  $lines += "- writing-constitution.md"
  if (Test-Path (Join-Path $KnowledgeDir "character-profiles.md")) { $lines += "- character-profiles.md" }
  if (Test-Path (Join-Path $TrackingDir "plot-tracker.json")) { $lines += "- plot-tracker.json" }
  if (Test-Path (Join-Path $KnowledgeDir "world-setting.md")) { $lines += "- world-setting.md" }
  if (Test-Path (Join-Path $KnowledgeDir "character-voices.md")) { $lines += "- character-voices.md" }
  $lines += ""
  $lines += "---"
  Append-Lines $log $lines
}

function Refine-Style {
  Write-Host "🔄 Начинаем интеграцию внешних предложений..."
  $text = $null
  # Читаем из конвейера или параметров
  if ($MyInvocation.ExpectingInput) {
    $text = ($input | Out-String)
  } elseif ($args.Count -gt 0) {
    $text = [string]::Join(' ', $args)
  }
  if (-not $text -or [string]::IsNullOrWhiteSpace($text)) { throw "Необходимо предоставить содержание предложений" }

  $isJson = ($text -match '"version"') -and ($text -match '"suggestions"')
  if ($isJson) {
    Write-Host "Обнаружен формат JSON"
    Parse-JsonSuggestions $text
    Update-ImprovementLog "Внешний ИИ" "Предложения в формате JSON обработаны"
  } elseif ($text -match '# 小说创作建议报告') {
    Write-Host "Обнаружен формат Markdown"
    Parse-MarkdownSuggestions $text
    Update-ImprovementLog "Внешний ИИ" "Предложения в формате Markdown обработаны"
  } else {
    throw "Не удалось распознать формат предложений. Пожалуйста, используйте стандартный формат JSON или Markdown (см. docs/ai-suggestion-prompt-template.md)"
  }

  Write-Host ""
  Write-Host "✅ Интеграция предложений завершена"
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  Write-Host "📊 Отчет об интеграции:"
  # Упрощенная статистика: количество файлов, измененных за последние 2 минуты
  $changed = Get-ChildItem $MemoryDir, $KnowledgeDir, $TrackingDir -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-2) }
  Write-Host "  - Обновлено файлов: $($changed.Count)"
  Write-Host "  - Источник предложений: Внешний анализ ИИ"
  Write-Host "  - Время обработки: $(Get-Date -Format 'HH:mm:ss')"
  Write-Host ""
}

switch ($Mode.ToLower()) {
  'init'   { Init-Style }
  'refine' { Refine-Style }
  default  { throw "Неизвестный режим: $Mode (доступные: init, refine)" }
}