```powershell
#!/usr/bin/env pwsh
# Автоматическая проверка текста на "человечность" (PowerShell)

param(
  [Parameter(Mandatory=$true)][string]$File
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"

$root = Get-ProjectRoot
$cfgProject = Join-Path $root "spec/knowledge/audit-config.json"
$cfgTemplate = Join-Path $root ".specify/templates/knowledge/audit-config.json"
$cfg = if (Test-Path $cfgProject) { $cfgProject } elseif (Test-Path $cfgTemplate) { $cfgTemplate } else { '' }

if (-not (Test-Path $File)) { throw "Использование: text-audit.ps1 -File <путь>" }

python3 - << PY
import json, re, sys, os, math
path = r'''$File'''
cfg_path = r'''$cfg'''
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
  try: cfg.update(json.load(open(cfg_path,'r',encoding='utf-8')))
  except: pass
def count_occurrences(text, phrases):
  return {p: len(re.findall(re.escape(p), text)) for p in phrases if p}
def split_sentences(t):
  parts = re.split(r'[。！？!?\n]+', t)
  return [s.strip() for s in parts if s.strip()]
def sentence_lengths(sents):
  lens = [len(s) for s in sents]
  if not lens: return lens, 0, 0
  avg = sum(lens)/len(lens)
  var = sum((x-avg)**2 for x in lens)/len(lens)
  return lens, avg, var**0.5
def runs(lens, short_th, long_th):
  rs=rl=0; mrs=mrl=0
  for L in lens:
    if L<=short_th: rs+=1; mrs=max(mrs,rs); rl=0
    elif L>=long_th: rl+=1; mrl=max(mrl,rl); rs=0
    else: rs=rl=0
  return mrs, mrl
def abstract_density(sent, words):
  return sum(len(re.findall(re.escape(w), sent)) for w in words)
connectors = count_occurrences(text, cfg["connector_phrases"])
empties = count_occurrences(text, cfg["empty_phrases"])
sents = split_sentences(text)
lens, avg, std = sentence_lengths(sents)
mx_run_short, mx_run_long = runs(lens, cfg["sentence_length"]["short_threshold"], cfg["sentence_length"]["long_threshold"])
abstract_scores = [(i, abstract_density(s, cfg["abstract_nouns"])) for i,s in enumerate(sents)]
abstract_scores.sort(key=lambda x: x[1], reverse=True)
abstract_top = [(i,sents[i]) for i,sc in abstract_scores[:5] if sc>=2]
total_chars = len(text)
def ratio(c): return (c/max(1,total_chars))*1000
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📊 Отчёт о проверке текста на «человечность»")
print(f"Файл: {os.path.basename(path)}  Количество символов: {total_chars}")
print("")
print("Плотность связующих слов (количество на тысячу символов)")
tc=sum(connectors.values()); print(f"  Всего: {tc}  | Соотношение: {ratio(tc):.2f}")
for k,v in sorted(connectors.items(), key=lambda x: -x[1])[:10]:
  if v>0: print(f"  - {k}: {v}")
print("")
print("Подсчёт пустых/шаблонных фраз")
te=sum(empties.values()); print(f"  Всего: {te}  | Соотношение: {ratio(te):.2f}")
for k,v in sorted(empties.items(), key=lambda x: -x[1])[:10]:
  if v>0: print(f"  - {k}: {v}")
print("")
print("Статистика длины предложений")
print(f"  Количество предложений: {len(lens)}  | Среднее: {avg:.1f}  | Стандартное отклонение: {std:.1f}")
print(f"  Макс. последовательность коротких предложений: {mx_run_short} (порог {cfg['sentence_length']['max_run_short']})")
print(f"  Макс. последовательность длинных предложений: {mx_run_long} (порог {cfg['sentence_length']['max_run_long']})")
print("")
print("Абстрактная перегрузка (примеры предложений, ≥2 абстрактных слова)")
if abstract_top:
  for idx,s in abstract_top:
    sn = s[:80] + ("…" if len(s)>80 else "")
    print(f"  - Предложение {idx+1}: {sn}")
else:
  print("  Нет явных признаков абстрактной перегрузки")
print("")
print("Рекомендации")
print("  - Заменяйте пустые фразы и абстрактные существительные конкретными действиями/предметами/запахами")
print("  - Разбивайте слишком длинные предложения; объединяйте слишком короткие для создания ритма")
print("  - Проверьте, можно ли удалить связующие слова или заменить их более естественными переходами")
print("  - Перед написанием сформулируйте 3 детали из жизни в качестве опорных точек")
PY
```