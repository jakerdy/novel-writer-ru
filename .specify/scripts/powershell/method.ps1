#!/usr/bin/env pwsh
# Скрипт помощника по методам интеллектуального письма (PowerShell)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Get-Location).Path
$configPath = Join-Path $projectRoot ".specify/config.json"

if (-not (Test-Path $configPath)) {
  Write-Host "❌ Конфигурационный файл проекта не найден"
  Write-Host "Пожалуйста, запустите эту команду в каталоге проекта романа"
  exit 1
}

$json = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$currentMethod = $json.method.current

Write-Host "📚 Помощник по методам письма запущен"
Write-Host "Текущий метод: $($currentMethod ?? 'three-act')"
Write-Host ""
Write-Host "Доступные методы письма:"
Write-Host "- three-act: Трехактная структура"
Write-Host "- hero-journey: Путешествие героя"
Write-Host "- story-circle: Круг историй"
Write-Host "- seven-point: Семиточечная структура"
Write-Host "- pixar-formula: Формула Пиксар"
Write-Host "- snowflake: Метод снежинки"
Write-Host ""
Write-Host "Интерфейс ИИ готов, пожалуйста, узнайте потребности пользователя через диалог"

exit 0