```json
#!/usr/bin/env bash
# Самостоятельная проверка текста на «человечность» (офлайн): плотность связующих слов/пустых фраз, статистика длины предложений, плотность абстрактных слов

set -e

SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

PROJECT_ROOT=$(get_project_root)

FILE_PATH="$1"
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  echo "Использование: scripts/bash/text-audit.sh <файл>"
  exit 1
fi

# Выбор конфигурации: приоритет spec/knowledge проекта, затем .specify/templates/knowledge
CFG_PROJECT="$PROJECT_ROOT/spec/knowledge/audit-config.json"
CFG_TEMPLATE="$PROJECT_ROOT/.specify/templates/knowledge/audit-config.json"
if [ -f "$CFG_PROJECT" ]; then
  CFG="$CFG_PROJECT"
elif [ -f "$CFG_TEMPLATE" ]; then
  CFG="$CFG_TEMPLATE"
else
  CFG=""
fi

python3 - "$FILE_PATH" "$CFG" << 'PY'
import json, re, sys, os, math

path = sys.argv[1]
cfg_path = sys.argv[2] if len(sys.argv) > 2 else ''

text = open(path, 'r', encoding='utf-8', errors='ignore').read()

default_cfg = {
  "connector_phrases": ["首先","其次","再次","然后","然而","总而言之","综上所述","在某种程度","众所周知","在当下","随着"],
  "empty_phrases": ["广泛关注","引发热议","影响深远","具有重要意义","有效提升","具有一定的指导意义","值得我们思考"],
  "cliche_pairs": [],
  "sentence_length": {"max_run_long":4, "max_run_short":5, "short_threshold":12, "long_threshold":35},
  "abstract_nouns": ["价值","意义","认知","体系","模式","路径","方法论","趋势"],
  "min_concrete_details": 3
}

cfg = default_cfg
if cfg_path and os.path.exists(cfg_path):
  try:
    with open(cfg_path, 'r', encoding='utf-8') as f:
      loaded = json.load(f)
      cfg.update(loaded)
  except Exception:
    pass

def count_occurrences(text, phrases):
  res = {}
  for p in phrases:
    if not p: continue
    res[p] = len(re.findall(re.escape(p), text))
  return res

def split_sentences(t):
  parts = re.split(r'[。！？!?\n]+', t)
  return [s.strip() for s in parts if s.strip()]

def sentence_lengths(sents):
  lens = [len(s) for s in sents]
  if not lens:
    return lens, 0, 0
  avg = sum(lens)/len(lens)
  var = sum((x-avg)**2 for x in lens)/len(lens)
  return lens, avg, math.sqrt(var)

def runs(lens, short_th, long_th):
  run_short = 0; run_long = 0
  max_run_short = 0; max_run_long = 0
  marks = []
  for i, L in enumerate(lens):
    if L <= short_th:
      run_short += 1; max_run_short = max(max_run_short, run_short); run_long = 0
    elif L >= long_th:
      run_long += 1; max_run_long = max(max_run_long, run_long); run_short = 0
    else:
      run_short = 0; run_long = 0
  return max_run_short, max_run_long

def abstract_density(sent, abstract_words):
  cnt = sum(len(re.findall(re.escape(w), sent)) for w in abstract_words)
  return cnt

connectors = count_occurrences(text, cfg["connector_phrases"])
empties = count_occurrences(text, cfg["empty_phrases"])
sents = split_sentences(text)
lens, avg, std = sentence_lengths(sents)
mx_run_short, mx_run_long = runs(lens, cfg["sentence_length"]["short_threshold"], cfg["sentence_length"]["long_threshold"])

abstract_scores = [(i, abstract_density(s, cfg["abstract_nouns"])) for i, s in enumerate(sents)]
abstract_scores.sort(key=lambda x: x[1], reverse=True)
abstract_top = [ (i, sents[i]) for i,score in abstract_scores[:5] if score>=2 ]

total_chars = len(text)
def ratio(count):
  return (count / max(1,total_chars)) * 1000

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📊 Отчёт самопроверки текста на «человечность» (офлайн)")
print(f"Файл: {os.path.basename(path)}  Количество символов: {total_chars}")
print("")
print("Плотность связующих слов (количество на тысячу символов)")
total_conn = sum(connectors.values())
print(f"  Всего: {total_conn}  | Отношение: {ratio(total_conn):.2f}")
for k,v in sorted(connectors.items(), key=lambda x: -x[1])[:10]:
  if v>0: print(f"  - {k}: {v}")

print("")
print("Количество пустых/шаблонных фраз")
total_emp = sum(empties.values())
print(f"  Всего: {total_emp}  | Отношение: {ratio(total_emp):.2f}")
for k,v in sorted(empties.items(), key=lambda x: -x[1])[:10]:
  if v>0: print(f"  - {k}: {v}")

print("")
print("Статистика длины предложений")
print(f"  Количество предложений: {len(lens)}  | Среднее: {avg:.1f}  | Стандартное отклонение: {std:.1f}")
print(f"  Макс. последовательность коротких предложений: {mx_run_short} (порог {cfg['sentence_length']['max_run_short']})")
print(f"  Макс. последовательность длинных предложений: {mx_run_long} (порог {cfg['sentence_length']['max_run_long']})")

print("")
print("Абстрактная перегрузка (примеры фрагментов, ≥2 абстрактных слова)")
if abstract_top:
  for idx, s in abstract_top:
    snippet = s[:80] + ("…" if len(s)>80 else "")
    print(f"  - Предложение №{idx+1}: {snippet}")
else:
  print("  Нет значительных фрагментов с абстрактной перегрузкой")

print("")
print("Рекомендации")
print("  - Заменяйте пустые фразы и абстрактные существительные конкретными действиями/предметами/запахами")
print("  - Разбивайте слишком длинные предложения; объединяйте слишком короткие для создания ритмического разнообразия")
print("  - Проверьте, можно ли удалить связующие слова или заменить их более естественными переходами")
print("  - Перед написанием составьте список из 3 жизненных деталей в качестве опорных точек")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
PY
```