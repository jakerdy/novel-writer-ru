#!/usr/bin/env bash
set -euo pipefail

# Игнорировать SIGPIPE для предотвращения случайных ошибок 141
trap '' PIPE

# generate-commands.sh
# На основе архитектуры spec-kit для генерации многоплатформенных команд для novel-writer
# Поддерживает пространства имен для избежания конфликтов с spec-kit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔨 Система сборки команд Novel Writer"
echo "================================"

# Очистка старых артефактов сборки
rm -rf "$PROJECT_ROOT/dist"
mkdir -p "$PROJECT_ROOT/dist"

# Функция переписывания путей (преобразование относительных путей в пути .specify/)
# Использует временные маркеры для защиты уже корректных путей .specify/, чтобы избежать повторного добавления префикса
rewrite_paths() {
  sed -E \
    -e 's@\.specify/memory/@__SPECIFY_MEMORY__@g' \
    -e 's@\.specify/scripts/@__SPECIFY_SCRIPTS__@g' \
    -e 's@\.specify/templates/@__SPECIFY_TEMPLATES__@g' \
    -e 's@(/?)memory/@.specify/memory/@g' \
    -e 's@(/?)scripts/@.specify/scripts/@g' \
    -e 's@(/?)templates/@.specify/templates/@g' \
    -e 's@__SPECIFY_MEMORY__@.specify/memory/@g' \
    -e 's@__SPECIFY_SCRIPTS__@.specify/scripts/@g' \
    -e 's@__SPECIFY_TEMPLATES__@.specify/templates/@g'
}

# Основная функция: генерация файлов команд
generate_commands() {
  local agent=$1           # claude, gemini, cursor, windsurf, roocode
  local ext=$2             # md или toml
  local arg_format=$3      # $ARGUMENTS или {{args}}
  local output_dir=$4      # выходной каталог
  local script_variant=$5  # sh или ps
  local namespace=$6       # префикс пространства имен (например, "novel.")
  local frontmatter_type=$7 # full, partial, minimal, none (тип Markdown frontmatter)

  mkdir -p "$output_dir"

  echo "  📝 Генерация команд для $agent ($script_variant скрипт, frontmatter: $frontmatter_type)..."

  for template in "$PROJECT_ROOT/templates/commands"/*.md; do
    [[ -f "$template" ]] || continue

    local name description argument_hint script_command body prompt_body
    name=$(basename "$template" .md)

    # Нормализация конца строки
    file_content=$(tr -d '\r' < "$template")

    # Извлечение полей frontmatter (|| true предотвращает broken pipe)
    description=$(echo "$file_content" | awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}' || true)
    argument_hint=$(echo "$file_content" | awk '/^argument-hint:/ {sub(/^argument-hint:[[:space:]]*/, ""); print; exit}' || true)

    # Извлечение команды для соответствующего варианта скрипта
    script_command=$(echo "$file_content" | awk -v sv="$script_variant" '/^[[:space:]]*'"$script_variant"':[[:space:]]*/ {sub(/^[[:space:]]*'"$script_variant"':[[:space:]]*/, ""); print; exit}' || true)

    if [[ -z $script_command ]]; then
      echo "    ⚠️  Предупреждение: команда скрипта $script_variant не найдена в $template" >&2
      script_command="echo 'Missing script command for $script_variant'"
    fi

    # Замена плейсхолдера {SCRIPT}
    body=$(echo "$file_content" | sed "s|{SCRIPT}|${script_command}|g" || true)

    # Удаление секции scripts: (так как она уже заменена)
    body=$(echo "$body" | awk '
      /^---$/ { print; if (++dash_count == 1) in_frontmatter=1; else in_frontmatter=0; next }
      in_frontmatter && /^scripts:$/ { skip_scripts=1; next }
      in_frontmatter && /^[a-zA-Z].*:/ && skip_scripts { skip_scripts=0 }
      in_frontmatter && skip_scripts && /^[[:space:]]/ { next }
      { print }
    ' || true)

    # Применение других замен
    body=$(echo "$body" | sed "s/{ARGS}/$arg_format/g" | sed "s/\$ARGUMENTS/$arg_format/g" | sed "s/__AGENT__/$agent/g" | rewrite_paths || true)

    # Извлечение чистого содержимого prompt для Gemini (удаление YAML frontmatter)
    prompt_body=$(echo "$body" | awk '
      /^---$/ { if (++dash_count == 2) { in_content=1; next } next }
      in_content { print }
    ' || true)

    # Генерация вывода в зависимости от формата файла
    case $ext in
      toml)
        # Формат TOML (Gemini, Qwen) - поддерживаются только description и prompt
        local output_file="${namespace}${name}.$ext"
        {
          [[ -n "$description" ]] && echo "description = \"$description\""
          [[ -n "$description" ]] && echo
          echo "prompt = \"\"\""
          echo "$prompt_body"
          echo "\"\"\""
        } > "$output_dir/$output_file"
        ;;
      md|prompt.md)
        # Формат Markdown - генерация разного вывода в зависимости от frontmatter_type
        local output_file="${namespace}${name}.$ext"

        case $frontmatter_type in
          none)
            # Чистый Markdown, без frontmatter (Cursor, GitHub Copilot, Codex, Auggie, CodeBuddy, Amazon Q)
            echo "$prompt_body" > "$output_dir/$output_file"
            ;;
          minimal)
            # Минимальный frontmatter, только description (OpenCode)
            {
              echo "---"
              [[ -n "$description" ]] && echo "description: $description"
              echo "---"
              echo
              echo "$prompt_body"
            } > "$output_dir/$output_file"
            ;;
          partial)
            # Частичный frontmatter, description + argument-hint (Roo Code, Windsurf, Kilo Code)
            {
              echo "---"
              [[ -n "$description" ]] && echo "description: $description"
              [[ -n "$argument_hint" ]] && echo "argument-hint: $argument_hint"
              echo "---"
              echo
              echo "$prompt_body"
            } > "$output_dir/$output_file"
            ;;
          full|*)
            # Полный frontmatter, включая все поля (Claude)
            echo "$body" > "$output_dir/$output_file"
            ;;
        esac
        ;;
    esac
  done

  local file_count=$(find "$output_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "    ✅ Готово ($file_count файлов)"
}

# Копирование вспомогательных файлов в каталог сборки
copy_support_files() {
  local base_dir=$1
  local script_variant=$2

  local spec_dir="$base_dir/.specify"
  mkdir -p "$spec_dir"

  # Копирование каталога memory (если существует)
  if [[ -d "$PROJECT_ROOT/memory" ]]; then
    cp -r "$PROJECT_ROOT/memory" "$spec_dir/"
    echo "    📁 Копирование memory/ → .specify/"
  fi

  # Копирование соответствующего каталога варианта скрипта
  if [[ -d "$PROJECT_ROOT/scripts" ]]; then
    mkdir -p "$spec_dir/scripts"
    case $script_variant in
      sh)
        if [[ -d "$PROJECT_ROOT/scripts/bash" ]]; then
          cp -r "$PROJECT_ROOT/scripts/bash" "$spec_dir/scripts/"
          echo "    📁 Копирование scripts/bash/ → .specify/scripts/"
        fi
        ;;
      ps)
        if [[ -d "$PROJECT_ROOT/scripts/powershell" ]]; then
          cp -r "$PROJECT_ROOT/scripts/powershell" "$spec_dir/scripts/"
          echo "    📁 Копирование scripts/powershell/ → .specify/scripts/"
        fi
        ;;
    esac

    # Копирование файлов скриптов верхнего уровня
    find "$PROJECT_ROOT/scripts" -maxdepth 1 -type f -exec cp {} "$spec_dir/scripts/" \; 2>/dev/null || true
  fi

  # Копирование шаблонов (исключая каталог commands)
  if [[ -d "$PROJECT_ROOT/templates" ]]; then
    mkdir -p "$spec_dir/templates"
    find "$PROJECT_ROOT/templates" -type f -not -path "*/commands/*" -not -path "*/commands-*/*" | while read -r file; do
      rel_path="${file#$PROJECT_ROOT/templates/}"
      target_dir="$spec_dir/templates/$(dirname "$rel_path")"
      mkdir -p "$target_dir"
      cp "$file" "$target_dir/"
    done
    echo "    📁 Копирование templates/ → .specify/templates/"
  fi

  # Копирование каталога experts (если существует)
  if [[ -d "$PROJECT_ROOT/experts" ]]; then
    cp -r "$PROJECT_ROOT/experts" "$spec_dir/"
    echo "    📁 Копирование experts/ → .specify/experts/"
  fi

  # Копирование каталога spec (включая presets, правила против AI-детекции и т. д.)
  if [[ -d "$PROJECT_ROOT/spec" ]]; then
    local target_spec_dir="$base_dir/spec"
    mkdir -p "$target_spec_dir"

    # Копирование всего содержимого каталога spec (но исключая конкретное содержимое tracking и knowledge, сохраняя структуру каталогов)
    for item in "$PROJECT_ROOT/spec"/*; do
      if [[ -e "$item" ]]; then
        item_name=$(basename "$item")
        # Копирование presets, config.json и т. д. в корень проекта spec/
        if [[ "$item_name" != "tracking" && "$item_name" != "knowledge" ]]; then
          cp -r "$item" "$target_spec_dir/"
        else
          # Для tracking и knowledge создаются только пустые каталоги (шаблоны находятся в templates/)
          mkdir -p "$target_spec_dir/$item_name"
        fi
      fi
    done
    echo "    📁 Копирование spec/ (presets, config.json и т. д.)"
  fi
}

# Сборка вариантов для конкретных платформ
build_variant() {
  local agent=$1
  local script=$2

  echo
  echo "🏗️  Сборка для $agent ($script скрипт)..."
  echo "--------------------------------"
  echo "    📋 Агент: $agent, Вариант скрипта: $script"

  local base_dir="$PROJECT_ROOT/dist/$agent"
  mkdir -p "$base_dir"

  # Копирование вспомогательных файлов
  copy_support_files "$base_dir" "$script"

  # Генерация файлов команд
  case $agent in
    claude)
      mkdir -p "$base_dir/.claude/commands"
      generate_commands claude md "\$ARGUMENTS" "$base_dir/.claude/commands" "$script" "novel." "full"
      ;;
    gemini)
      mkdir -p "$base_dir/.gemini/commands/novel"
      generate_commands gemini toml "{{args}}" "$base_dir/.gemini/commands/novel" "$script" "" ""
      ;;
    cursor)
      mkdir -p "$base_dir/.cursor/commands"
      generate_commands cursor md "\$ARGUMENTS" "$base_dir/.cursor/commands" "$script" "" "none"
      ;;
    windsurf)
      mkdir -p "$base_dir/.windsurf/workflows"
      generate_commands windsurf md "\$ARGUMENTS" "$base_dir/.windsurf/workflows" "$script" "" "partial"
      ;;
    roocode)
      mkdir -p "$base_dir/.roo/commands"
      generate_commands roocode md "\$ARGUMENTS" "$base_dir/.roo/commands" "$script" "" "partial"
      ;;
    copilot)
      mkdir -p "$base_dir/.github/prompts"
      generate_commands copilot prompt.md "\$ARGUMENTS" "$base_dir/.github/prompts" "$script" "" "none"
      ;;
    qwen)
      mkdir -p "$base_dir/.qwen/commands"
      generate_commands qwen toml "{{args}}" "$base_dir/.qwen/commands" "$script" "" ""
      ;;
    opencode)
      mkdir -p "$base_dir/.opencode/command"
      generate_commands opencode md "\$ARGUMENTS" "$base_dir/.opencode/command" "$script" "" "minimal"
      ;;
    codex)
      mkdir -p "$base_dir/.codex/prompts"
      generate_commands codex md "\$ARGUMENTS" "$base_dir/.codex/prompts" "$script" "novel-" "none"
      ;;
    kilocode)
      mkdir -p "$base_dir/.kilocode/workflows"
      generate_commands kilocode md "\$ARGUMENTS" "$base_dir/.kilocode/workflows" "$script" "" "partial"
      ;;
    auggie)
      mkdir -p "$base_dir/.augment/commands"
      generate_commands auggie md "\$ARGUMENTS" "$base_dir/.augment/commands" "$script" "" "none"
      ;;
    codebuddy)
      mkdir -p "$base_dir/.codebuddy/commands"
      generate_commands codebuddy md "\$ARGUMENTS" "$base_dir/.codebuddy/commands" "$script" "" "none"
      ;;
    q)
      mkdir -p "$base_dir/.amazonq/prompts"
      generate_commands q md "\$ARGUMENTS" "$base_dir/.amazonq/prompts" "$script" "" "none"
      ;;
  esac

  echo "  ✅ Сборка $agent завершена"
}

# Поддерживаемые платформы и типы скриптов
ALL_AGENTS=(claude gemini cursor windsurf roocode copilot qwen opencode codex kilocode auggie codebuddy q)
ALL_SCRIPTS=(sh ps)

# Разбор аргументов командной строки
AGENTS=()
SCRIPTS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --agents=*)
      IFS=',' read -ra AGENTS <<< "${1#*=}"
      shift
      ;;
    --scripts=*)
      IFS=',' read -ra SCRIPTS <<< "${1#*=}"
      shift
      ;;
    --help)
      echo "Использование: $0 [опции]"
      echo
      echo "Опции:"
      echo "  --agents=AGENT1,AGENT2   Укажите платформы для сборки (по умолчанию: все)"
      echo "                           Доступно: claude,gemini,cursor,windsurf,roocode,copilot,qwen,opencode,codex,kilocode,auggie,codebuddy,q"
      echo "  --scripts=SCRIPT1,...    Укажите тип скрипта (по умолчанию: все)"
      echo "                           Доступно: sh,ps"
      echo "  --help                   Показать эту справку"
      echo
      echo "Примеры:"
      echo "  $0                                    # Собрать все платформы и скрипты"
      echo "  $0 --agents=claude --scripts=sh       # Собрать только Claude (sh)"
      echo "  $0 --agents=claude,gemini             # Собрать Claude и Gemini (все скрипты)"
      exit 0
      ;;
    *)
      echo "Неизвестный аргумент: $1"
      exit 1
      ;;
  esac
done

# Если агенты или скрипты не указаны, используем все доступные
if [ ${#AGENTS[@]} -eq 0 ]; then
  AGENTS=("${ALL_AGENTS[@]}")
fi
if [ ${#SCRIPTS[@]} -eq 0 ]; then
  SCRIPTS=("${ALL_SCRIPTS[@]}")
fi

echo
echo "📋 Конфигурация сборки:"
echo "  Платформы: ${AGENTS[*]}"
echo "  Скрипты: ${SCRIPTS[*]}"
echo

# Запуск сборки для выбранных агентов и скриптов
for script in "${SCRIPTS[@]}"; do
  for agent in "${AGENTS[@]}"; do
    build_variant "$agent" "$script"
  done
done

echo
echo "================================"
echo "✅ Сборка завершена!"
echo
echo "📦 Результаты сборки находятся в: $PROJECT_ROOT/dist/"
echo
echo "💡 Подсказки:"
echo "  - Пользователям Claude: используйте команды /novel.constitution, /novel.specify и т. д."
echo "  - Пользователям Gemini: используйте команды /novel:constitution, /novel:specify и т. д."
echo "  - Другим пользователям: используйте команды /constitution, /specify и т. д."