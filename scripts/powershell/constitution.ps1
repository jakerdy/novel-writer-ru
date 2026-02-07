```powershell
# Конституция управления сценариями романа
# Используется для команды /constitution

param(
    [string]$Command = "check"
)

# Импорт общих функций
. "$PSScriptRoot\common.ps1"

# Получение корневого каталога проекта
$ProjectRoot = Get-ProjectRoot
Set-Location $ProjectRoot

# Определение пути к файлу
$ConstitutionFile = "memory\constitution.md"

switch ($Command) {
    "check" {
        # Проверка существования файла конституции
        if (Test-Path $ConstitutionFile) {
            Write-Host "✅ Файл конституции существует: $ConstitutionFile" -ForegroundColor Green

            # Извлечение информации о версии
            $content = Get-Content $ConstitutionFile -Raw
            if ($content -match "- Версия：(.+)") {
                $version = $matches[1].Trim()
            } else {
                $version = "Неизвестно"
            }

            if ($content -match "- Последнее изменение：(.+)") {
                $updated = $matches[1].Trim()
            } else {
                $updated = "Неизвестно"
            }

            Write-Host "  Версия：$version"
            Write-Host "  Последнее изменение：$updated"
            exit 0
        }
        else {
            Write-Host "❌ Файл конституции ещё не создан" -ForegroundColor Red
            Write-Host "  Рекомендация: выполните /constitution для создания конституции творчества"
            exit 1
        }
    }

    "init" {
        # Инициализация файла конституции
        $dir = Split-Path $ConstitutionFile -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        if (Test-Path $ConstitutionFile) {
            Write-Host "Файл конституции существует, подготовка к обновлению"
        }
        else {
            Write-Host "Подготовка к созданию нового файла конституции"
        }
    }

    "validate" {
        # Проверка формата файла конституции
        if (-not (Test-Path $ConstitutionFile)) {
            Write-Host "Ошибка: файл конституции не существует" -ForegroundColor Red
            exit 1
        }

        Write-Host "Проверка файла конституции..."

        # Проверка необходимых разделов
        $requiredSections = @("Основные ценности", "Стандарты качества", "Стиль письма", "Нормы содержания", "Договор с читателем")
        $content = Get-Content $ConstitutionFile -Raw
        $missingSections = @()

        foreach ($section in $requiredSections) {
            if ($content -notmatch "## .* $section") {
                $missingSections += $section
            }
        }

        if ($missingSections.Count -gt 0) {
            Write-Host "⚠️ Отсутствуют следующие разделы:" -ForegroundColor Yellow
            foreach ($section in $missingSections) {
                Write-Host "  - $section"
            }
        }
        else {
            Write-Host "✅ Все необходимые разделы присутствуют" -ForegroundColor Green
        }

        # Проверка информации о версии
        if ($content -match "^- Версия：") {
            Write-Host "✅ Информация о версии полная" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️ Отсутствует информация о версии" -ForegroundColor Yellow
        }
    }

    "export" {
        # Экспорт резюме конституции
        if (-not (Test-Path $ConstitutionFile)) {
            Write-Host "Ошибка: файл конституции не существует" -ForegroundColor Red
            exit 1
        }

        Write-Host "# Резюме конституции творчества"
        Write-Host ""

        $content = Get-Content $ConstitutionFile -Raw

        # Извлечение основных принципов
        Write-Host "## Основные принципы"
        if ($content -match "### Принципы[\s\S]*?\*\*Заявление\*\*：(.+)") {
            Write-Host $matches[1]
        }
        else {
            Write-Host "（Заявление о принципах не найдено）"
        }

        Write-Host ""
        Write-Host "## Минимальные стандарты качества"
        if ($content -match "### Стандарты[\s\S]*?\*\*Требования\*\*：(.+)") {
            Write-Host $matches[1]
        }
        else {
            Write-Host "（Стандарты качества не найдены）"
        }

        Write-Host ""
        Write-Host "Подробное содержание см. по адресу: $ConstitutionFile"
    }

    default {
        Write-Host "Неизвестная команда: $Command" -ForegroundColor Red
        Write-Host "Поддерживаемые команды: check, init, validate, export"
        exit 1
    }
}
```