```powershell
#!/usr/bin/env pwsh
# Управление отношениями персонажей (PowerShell)

param(
  [ValidateSet('show','update','history','check')]
  [string]$Command = 'show',
  [string]$A,
  [ValidateSet('allies','enemies','romantic','neutral','family','mentors')]
  [string]$Relation,
  [string]$B,
  [int]$Chapter,
  [string]$Note
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"

$root = Get-ProjectRoot
$storyDir = Get-CurrentStoryDir
$relPath = $null
if ($storyDir -and (Test-Path (Join-Path $storyDir 'spec/tracking/relationships.json'))) {
  $relPath = Join-Path $storyDir 'spec/tracking/relationships.json'
} elseif (Test-Path (Join-Path $root 'spec/tracking/relationships.json')) {
  $relPath = Join-Path $root 'spec/tracking/relationships.json'
} else {
  $tpl1 = Join-Path $root '.specify/templates/tracking/relationships.json'
  $tpl2 = Join-Path $root 'templates/tracking/relationships.json'
  $dest = Join-Path $root 'spec/tracking/relationships.json'
  New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
  if (Test-Path $tpl1) { Copy-Item $tpl1 $dest -Force; $relPath = $dest }
  elseif (Test-Path $tpl2) { Copy-Item $tpl2 $dest -Force; $relPath = $dest }
  else { throw 'Не найден relationships.json, и невозможно создать из шаблона' }
}

function Show-Header { Write-Host "👥 Управление отношениями персонажей"; Write-Host "━━━━━━━━━━━━━━━━━━━━" }

function Show-Relations {
  Show-Header
  try { $j = Get-Content -LiteralPath $relPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { throw 'Неверный формат relationships.json' }
  Write-Host "Файл: $relPath"; Write-Host ''
  $main = $j.characters.PSObject.Properties.Name | Select-Object -First 1
  if (-not $main) { Write-Host 'Нет записей о персонажах'; return }
  Write-Host "Главный герой: $main"
  $c = $j.characters.$main
  $r = if ($c.relationships) { $c.relationships } else { $c }
  $map = @{
    romantic = '💕 Любовные'; allies='🤝 Союзники'; mentors='📚 Наставники'; enemies='⚔️ Враги'; family='👪 Семья'; neutral='・ Нейтральные'
  }
  foreach ($k in 'romantic','allies','mentors','enemies','family','neutral') {
    $lst = @($r.$k)
    if ($lst.Count -gt 0) { Write-Host ("├─ {0}：{1}" -f $map[$k], ($lst -join '、')) }
  }
  Write-Host ''
  if ($j.history) {
    Write-Host 'Последние изменения:'
    $last = $j.history[-1]
    if ($last) { $last.changes | ForEach-Object { Write-Host ("- " + ($_.characters -join '↔') + "：" + ($_.relation ?? $_.type)) } }
  } elseif ($j.relationshipChanges) {
    Write-Host 'Последние изменения:'
    $j.relationshipChanges | Select-Object -Last 5 | ForEach-Object { Write-Host ("- " + ($_.type ?? 'Изменение') + ": " + ($_.characters -join '↔')) }
  }
}

function Ensure-Character($json, [string]$name) {
  if (-not $json.characters.$name) {
    $json.characters | Add-Member -NotePropertyName $name -NotePropertyValue (@{ name=$name; relationships=@{ allies=@(); enemies=@(); romantic=@(); family=@(); mentors=@(); neutral=@() } })
  }
}

function Update-Relation([string]$a, [string]$rel, [string]$b) {
  if (-not $a -or -not $rel -or -not $b) { throw 'Использование: manage-relations.ps1 update -A ПерсонажA -Relation allies|enemies|romantic|neutral|family|mentors -B ПерсонажB [-Chapter N] [-Note Примечание]' }
  $j = Get-Content -LiteralPath $relPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Ensure-Character $j $a
  Ensure-Character $j $b
  $lst = @($j.characters.$a.relationships.$rel)
  if ($lst -notcontains $b) { $lst += $b }
  $j.characters.$a.relationships.$rel = $lst
  $j.lastUpdated = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
  if ($j.history) {
    $chg = [pscustomobject]@{ type='update'; characters=@($a,$b); relation=$rel; note=($Note ?? '') }
    $rec = [pscustomobject]@{ chapter=($Chapter ? $Chapter : $null); date=(Get-Date).ToString('s'); changes=@($chg) }
    $j.history += $rec
  } elseif ($j.relationshipChanges) {
    $j.relationshipChanges += [pscustomobject]@{ type='update'; characters=@($a,$b); relation=$rel }
  } else {
    $j | Add-Member -NotePropertyName history -NotePropertyValue @()
  }
  $j | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $relPath -Encoding UTF8
  Write-Host "✅ Отношения обновлены: $a [$rel] $b"
}

function Show-History {
  Show-Header
  $j = Get-Content -LiteralPath $relPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($j.history) {
    foreach ($h in $j.history) {
      $chap = if ($h.chapter) { $h.chapter } else { 0 }
      $desc = ($h.changes | ForEach-Object { ($_.characters -join '↔') + '→' + ($_.relation ?? $_.type) }) -join '；'
      Write-Host ("Глава {0}：{1}" -f $chap, $desc)
    }
  } elseif ($j.relationshipChanges) {
    foreach ($h in $j.relationshipChanges) { Write-Host ((($h.date ?? '') + ' ' + ($h.type ?? '') + ': ' + ($h.characters -join '↔') + '→' + ($h.relation ?? ''))) }
  } else { Write-Host 'Нет истории изменений' }
}

function Check-Relations {
  Show-Header
  $j = Get-Content -LiteralPath $relPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $names = @($j.characters.PSObject.Properties.Name)
  $refs = @()
  foreach ($name in $names) {
    $rel = $j.characters.$name.relationships
    if (-not $rel) { continue }
    foreach ($k in 'allies','enemies','romantic','family','mentors','neutral') {
      $refs += @($rel.$k)
    }
  }
  $refs = $refs | Where-Object { $_ } | Select-Object -Unique
  $missing = @($refs | Where-Object { $names -notcontains $_ })
  if ($missing.Count -gt 0) {
    Write-Host "⚠ Обнаружены ссылки на персонажей без записей, рекомендуется добавить:"
    $missing | ForEach-Object { Write-Host "  - $_" }
  } else { Write-Host "✅ Проверка данных отношений пройдена" }
}

switch ($Command) {
  'show'   { Show-Relations }
  'update' { Update-Relation -a $A -rel $Relation -b $B }
  'history'{ Show-History }
  'check'  { Check-Relations }
}
```