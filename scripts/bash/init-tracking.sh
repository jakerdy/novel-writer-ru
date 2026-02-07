```bash
#!/bin/bash

echo "🚀 Инициализация системы отслеживания..."

# Проверка предварительных условий
story_exists=false
outline_exists=false

# Поиск файла спецификации
if ls stories/*/specification.md 1> /dev/null 2>&1; then
    story_exists=true
    story_file=$(ls stories/*/specification.md | head -1)
fi

# Поиск файла плана
if ls stories/*/outline.md 1> /dev/null 2>&1; then
    outline_exists=true
    outline_file=$(ls stories/*/outline.md | head -1)
fi

if [ "$story_exists" = false ] || [ "$outline_exists" = false ]; then
    echo "❌ Пожалуйста, сначала выполните команды /specify и /plan"
    echo "   Отсутствует: ${story_exists:+}${story_exists:-specification.md} ${outline_exists:+}${outline_exists:-outline.md}"
    exit 1
fi

# Создание каталога отслеживания
mkdir -p spec/tracking

# Получение названия истории
story_dir=$(dirname "$story_file")
story_name=$(basename "$story_dir")

echo "📖 Инициализация системы отслеживания для «${story_name}»..."

# Инициализация plot-tracker.json
if [ ! -f "spec/tracking/plot-tracker.json" ]; then
    echo "📝 Создание plot-tracker.json..."
    cat > spec/tracking/plot-tracker.json <<EOF
{
  "novel": "${story_name}",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "currentState": {
    "chapter": 0,
    "volume": 1,
    "mainPlotStage": "Подготовительная стадия",
    "location": "Не определено",
    "timepoint": "До начала истории"
  },
  "plotlines": {
    "main": {
      "name": "Основная сюжетная линия",
      "description": "Извлечь из плана",
      "status": "Не начато",
      "currentNode": "Стартовая точка",
      "completedNodes": [],
      "upcomingNodes": [],
      "plannedClimax": {
        "chapter": null,
        "description": "Планируется"
      }
    },
    "subplots": []
  },
  "foreshadowing": [],
  "conflicts": {
    "active": [],
    "resolved": [],
    "upcoming": []
  },
  "checkpoints": {
    "volumeEnd": [],
    "majorEvents": []
  },
  "notes": {
    "plotHoles": [],
    "inconsistencies": [],
    "reminders": ["Обновляйте данные отслеживания в соответствии с фактическим содержанием истории"]
  }
}
EOF
fi

# Инициализация timeline.json
if [ ! -f "spec/tracking/timeline.json" ]; then
    echo "⏰ Создание timeline.json..."
    cat > spec/tracking/timeline.json <<EOF
{
  "novel": "${story_name}",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "storyTimeUnit": "День",
  "realWorldReference": null,
  "timeline": [
    {
      "chapter": 0,
      "storyTime": "День 0",
      "description": "До начала истории",
      "events": ["Добавить"],
      "location": "Не определено"
    }
  ],
  "parallelEvents": [],
  "timeSpan": {
    "start": "День 0",
    "current": "День 0",
    "elapsed": "0 дней"
  }
}
EOF
fi

# Инициализация relationships.json
if [ ! -f "spec/tracking/relationships.json" ]; then
    echo "👥 Создание relationships.json..."
    cat > spec/tracking/relationships.json <<EOF
{
  "novel": "${story_name}",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "characters": {
    "主角": {
      "name": "Не определено",
      "relationships": {
        "allies": [],
        "enemies": [],
        "romantic": [],
        "neutral": []
      }
    }
  },
  "factions": {},
  "relationshipChanges": [],
  "currentTensions": []
}
EOF
fi

# Инициализация character-state.json
if [ ! -f "spec/tracking/character-state.json" ]; then
    echo "📍 Создание character-state.json..."
    cat > spec/tracking/character-state.json <<EOF
{
  "novel": "${story_name}",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "characters": {
    "主角": {
      "name": "Не определено",
      "status": "Здоров",
      "location": "Не определено",
      "possessions": [],
      "skills": [],
      "lastSeen": {
        "chapter": 0,
        "description": "Еще не появился"
      },
      "development": {
        "physical": 0,
        "mental": 0,
        "emotional": 0,
        "power": 0
      }
    }
  },
  "groupPositions": {},
  "importantItems": {}
}
EOF
fi

echo ""
echo "✅ Система отслеживания успешно инициализирована!"
echo ""
echo "📊 Созданы следующие файлы отслеживания:"
echo "   • spec/tracking/plot-tracker.json - Отслеживание сюжета"
echo "   • spec/tracking/timeline.json - Управление временной шкалой"
echo "   • spec/tracking/relationships.json - Сеть взаимоотношений"
echo "   • spec/tracking/character-state.json - Состояние персонажей"
echo ""
echo "💡 Следующие шаги:"
echo "   1. Используйте команду /write для начала написания (данные отслеживания будут обновляться автоматически)"
echo "   2. Регулярно используйте команду /track для просмотра сводного отчета"
echo "   3. Используйте команды, такие как /plot-check, для проверки на согласованность"
echo ""
echo "📝 Примечание: Файлы отслеживания предварительно заполнены базовой структурой и будут автоматически обновляться в процессе написания"
```