#!/usr/bin/env bash
# Управление отношениями между персонажами (Bash)

set -e

SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

PROJECT_ROOT=$(get_project_root)
STORY_DIR=$(get_current_story)

REL_FILE=""
if [ -n "$STORY_DIR" ] && [ -f "$STORY_DIR/spec/tracking/relationships.json" ]; then
  REL_FILE="$STORY_DIR/spec/tracking/relationships.json"
elif [ -f "$PROJECT_ROOT/spec/tracking/relationships.json" ]; then
  REL_FILE="$PROJECT_ROOT/spec/tracking/relationships.json"
else
  # Попытка инициализации из шаблона
  mkdir -p "$PROJECT_ROOT/spec/tracking"
  if [ -f "$PROJECT_ROOT/.specify/templates/tracking/relationships.json" ]; then
    cp "$PROJECT_ROOT/.specify/templates/tracking/relationships.json" "$PROJECT_ROOT/spec/tracking/relationships.json"
    REL_FILE="$PROJECT_ROOT/spec/tracking/relationships.json"
  elif [ -f "$SCRIPT_DIR/../../templates/tracking/relationships.json" ]; then
    cp "$SCRIPT_DIR/../../templates/tracking/relationships.json" "$PROJECT_ROOT/spec/tracking/relationships.json"
    REL_FILE="$PROJECT_ROOT/spec/tracking/relationships.json"
  else
    echo "❌ Файл relationships.json не найден и не может быть создан из шаблона" >&2
    exit 1
  fi
fi

CMD=${1:-show}
shift || true

print_header() {
  echo "👥 Управление отношениями между персонажами"
  echo "━━━━━━━━━━━━━━━━━━━━"
}

cmd_show() {
  print_header
  if ! jq empty "$REL_FILE" >/dev/null 2>&1; then
    echo "❌ Некорректный формат relationships.json" >&2; exit 1
  fi

  echo "Файл: $REL_FILE"
  echo ""
  # Вывод сводки отношений главного или первого персонажа
  local main_char=$(jq -r '.characters | keys[0] // ""' "$REL_FILE")
  if [ -z "$main_char" ] || [ "$main_char" = "null" ]; then
    echo "Нет записей о персонажах"
    exit 0
  fi
  echo "Главный персонаж: $main_char"
  # Поддержка двух структур: вложенные relationships или прямые ключи категорий
  jq -r --arg name "$main_char" '
    .characters[$name] as $c | 
    ($c.relationships // $c) as $r |
    [
      {k:"romantic", v:($r.romantic // [])},
      {k:"allies", v:($r.allies // [])},
      {k:"mentors", v:($r.mentors // [])},
      {k:"enemies", v:($r.enemies // [])},
      {k:"family", v:($r.family // [])},
      {k:"neutral", v:($r.neutral // [])}
    ] | .[] | select((.v|length)>0) |
    "├─ " + (if .k=="romantic" then "💕 Романтические" elseif .k=="allies" then "🤝 Союзники" elseif .k=="mentors" then "📚 Наставники" elseif .k=="enemies" then "⚔️ Враги" elseif .k=="family" then "👪 Семья" else "・ Отношения" end) + "：" + (.v | join("、"))
  ' "$REL_FILE"

  # Последние изменения
  echo ""
  if jq -e '.history' "$REL_FILE" >/dev/null 2>&1; then
    local recent=$(jq -r '.history[-1] // empty' "$REL_FILE")
    if [ -n "$recent" ]; then
      echo "Последние изменения："
      jq -r '.history[-1].changes[]? | "- " + (.characters|join("↔")) + "：" + (.relation // .type // "изменение")' "$REL_FILE"
    fi
  elif jq -e '.relationshipChanges' "$REL_FILE" >/dev/null 2>&1; then
    echo "Последние изменения："
    jq -r '.relationshipChanges[-5:][]? | "- " + (.type // "изменение") + ": " + (.characters|join("↔"))' "$REL_FILE" 2>/dev/null || true
  fi
}

cmd_update() {
  local a="$1"; local rel="$2"; local b="$3"; shift 3 || true
  local chapter=""; local note=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --chapter) chapter="$2"; shift 2;;
      --note) note="$2"; shift 2;;
      *) shift;;
    esac
  done
  if [ -z "$a" ] || [ -z "$rel" ] || [ -z "$b" ]; then
    echo "Использование: manage-relations.sh update <ПерсонажA> <allies|enemies|romantic|neutral|family|mentors> <ПерсонажB> [--chapter N] [--note Описание]" >&2
    exit 1
  fi

  # Убедиться, что узлы персонажей существуют
  for name in "$a" "$b"; do
    if ! jq --arg n "$name" '(.characters[$n] // null) != null' "$REL_FILE" | grep -q true; then
      tmp=$(mktemp)
      jq --arg n "$name" '.characters[$n] = (.characters[$n] // {name:$n, relationships:{allies:[],enemies:[],romantic:[],family:[],mentors:[],neutral:[]}})' "$REL_FILE" > "$tmp"
      mv "$tmp" "$REL_FILE"
    fi
  done

  # Запись отношений
  tmp=$(mktemp)
  jq --arg a "$a" --arg b "$b" --arg rel "$rel" '
    .characters[$a].relationships[$rel] = ((.characters[$a].relationships[$rel] // []) + [$b] | unique) |
    .lastUpdated = now | todate
  ' "$REL_FILE" > "$tmp"
  mv "$tmp" "$REL_FILE"

  # Запись истории (history имеет приоритет, иначе relationshipChanges)
  local now=$(date -Iseconds)
  if jq -e '.history' "$REL_FILE" >/dev/null 2>&1; then
    tmp=$(mktemp)
    jq --arg ch "${chapter:-null}" --arg a "$a" --arg b "$b" --arg rel "$rel" --arg note "$note" --arg t "$now" '
      .history += [{
        chapter: ( ($ch|tonumber) // null ),
        date: $t,
        changes: [{ type: "update", characters: [$a,$b], relation: $rel, note: ($note // "") }]
      }]
    ' "$REL_FILE" > "$tmp" && mv "$tmp" "$REL_FILE"
  else
    tmp=$(mktemp)
    jq --arg a "$a" --arg b "$b" --arg rel "$rel" '.relationshipChanges += [{type:"update", characters:[$a,$b], relation:$rel}]' "$REL_FILE" > "$tmp" && mv "$tmp" "$REL_FILE"
  fi

  echo "✅ Отношения обновлены: $a [$rel] $b"
}

cmd_history() {
  print_header
  if jq -e '.history' "$REL_FILE" >/dev/null 2>&1; then
    jq -r '.history[] | "Глава " + ((.chapter // 0|tostring)) + "：" + (.changes | map((.characters|join("↔"))+"→"+(.relation // .type)) | join("；"))' "$REL_FILE"
  elif jq -e '.relationshipChanges' "$REL_FILE" >/dev/null 2>&1; then
    jq -r '.relationshipChanges[] | (.date // "") + " " + (.type // "") + ": " + (.characters|join("↔")) + "→" + (.relation // "")' "$REL_FILE"
  else
    echo "Нет истории изменений"
  fi
}

cmd_check() {
  print_header
  local issues=0
  # Проверка всех ссылочных персонажей на наличие в characters
  missing=$(jq -r '
    .characters as $c |
    [
      .characters | to_entries[] | .value.relationships // empty |
      to_entries[] | .value[]
    ] | flatten | unique | map(select(has(.) | not))
  ' "$REL_FILE" 2>/dev/null || true)
  if [ -n "$missing" ]; then
    echo "⚠️  Обнаружены ссылки на персонажей без профилей, рекомендуется добавить:"
    echo "$missing"
    issues=1
  fi
  if [ "$issues" -eq 0 ]; then
    echo "✅ Проверка данных отношений прошла успешно"
  fi
}

case "$CMD" in
  show) cmd_show ;;
  update) cmd_update "$@" ;;
  history) cmd_history ;;
  check) cmd_check ;;
  *) echo "Использование: $0 [show|update|history|check]" >&2; exit 1;;
esac