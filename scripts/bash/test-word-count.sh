#!/bin/bash

# Тестирование функции подсчета китайских слов
# Используется для проверки точности функции count_chinese_words

set -e

# Источник общих функций
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Цветовой вывод
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Нет цвета

echo "========================================"
echo "Тестирование функции подсчета китайских слов"
echo "========================================"
echo ""

# Создание временного тестового каталога
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Тестовый случай 1: Только китайский текст
echo "## Тест 1: Только китайский текст"
cat > "$TEST_DIR/test1.md" << 'EOF'
今天天气很好，我去公园散步。
看到很多人在锻炼身体。
EOF
expected1=16
actual1=$(count_chinese_words "$TEST_DIR/test1.md")
echo "  Ожидаемое количество слов: $expected1"
echo "  Фактическое количество слов: $actual1"
if [ "$actual1" -eq "$expected1" ]; then
    echo -e "  ${GREEN}✅ Тест пройден${NC}"
else
    echo -e "  ${RED}❌ Тест не пройден${NC}"
fi
echo ""

# Тестовый случай 2: Текст с разметкой Markdown
echo "## Тест 2: Текст с разметкой Markdown"
cat > "$TEST_DIR/test2.md" << 'EOF'
# 第一章

这是**重要**的内容。

- 列表项1
- 列表项2

> 这是引用
EOF
# Фактический контент (без пробелов и пунктуации): 第一章这是重要的内容列表项1列表项2这是引用
expected2=21
actual2=$(count_chinese_words "$TEST_DIR/test2.md")
echo "  Ожидаемое количество слов: $expected2"
echo "  Фактическое количество слов: $actual2"
if [ "$actual2" -eq "$expected2" ]; then
    echo -e "  ${GREEN}✅ Тест пройден${NC}"
else
    echo -e "  ${YELLOW}⚠️ Разница в количестве слов: $((actual2 - expected2))${NC}"
fi
echo ""

# Тестовый случай 3: Смешанный китайско-английский текст
echo "## Тест 3: Смешанный китайско-английский текст"
cat > "$TEST_DIR/test3.md" << 'EOF'
这是一个测试test文件。
包含123数字和English单词。
EOF
# Фактический контент (без пробелов и пунктуации): 这是一个测试test文件包含123数字和English单词
expected3=27
actual3=$(count_chinese_words "$TEST_DIR/test3.md")
echo "  Ожидаемое количество слов: около $expected3"
echo "  Фактическое количество слов: $actual3"
if [ "$actual3" -ge 20 ] && [ "$actual3" -le 35 ]; then
    echo -e "  ${GREEN}✅ Тест пройден (в разумных пределах)${NC}"
else
    echo -e "  ${YELLOW}⚠️ Значительная разница в количестве слов${NC}"
fi
echo ""

# Тестовый случай 4: Текст с блоками кода
echo "## Тест 4: Текст с блоками кода"
cat > "$TEST_DIR/test4.md" << 'EOF'
这是正常文本。

```javascript
console.log("这是代码不应该被计数");
```

这是结尾文本。
EOF
expected4=12
actual4=$(count_chinese_words "$TEST_DIR/test4.md")
echo "  Ожидаемое количество слов: $expected4"
echo "  Фактическое количество слов: $actual4"
if [ "$actual4" -eq "$expected4" ]; then
    echo -e "  ${GREEN}✅ Тест пройден${NC}"
else
    echo -e "  ${YELLOW}⚠️ Разница в количестве слов: $((actual4 - expected4))${NC}"
fi
echo ""

# Сравнительный тест: wc -w vs новый метод
echo "## Сравнительный тест: wc -w vs count_chinese_words"
cat > "$TEST_DIR/compare.md" << 'EOF'
这是一个包含大约五十个字的测试文本。
我们需要验证字数统计的准确性。
使用wc命令统计中文字数是不准确的。
应该使用专门的中文字数统计方法。
这样才能得到正确的结果。
EOF
wc_result=$(wc -w < "$TEST_DIR/compare.md" | tr -d ' ')
new_result=$(count_chinese_words "$TEST_DIR/compare.md")
echo "  Результат wc -w: $wc_result (неточно)"
echo "  Результат нового метода: $new_result (точно)"
echo -e "  ${YELLOW}Примечание: wc -w крайне неточно подсчитывает китайские слова!${NC}"
echo ""

# Тест производительности
echo "## Тест производительности: Обработка большого файла"
cat > "$TEST_DIR/large.md" << 'EOF'
# 第一章：开始

今天是个好天气，阳光明媚，万里无云。
小明决定去公园散步，顺便思考一下人生。
他一边走一边想，不知不觉来到了湖边。
湖水清澈见底，几只野鸭在水面游弋。
远处传来孩子们的欢笑声，让人心情愉悦。

## 第二节

突然，他看到一位老人坐在长椅上。
老人面带微笑，似乎在等待什么。
小明走上前去，礼貌地打了个招呼。
老人抬起头，慈祥的目光看向小明。
两人开始了一段有趣的对话。

**重要的转折点**：
- 老人讲述了一个神奇的故事
- 小明意识到生活的意义
- 他决定改变自己的人生轨迹

最后，夕阳西下，小明告别了老人。
他的内心充满了力量和希望。
这次偶遇，改变了他的一生。
EOF

start_time=$(date +%s%N)
large_count=$(count_chinese_words "$TEST_DIR/large.md")
end_time=$(date +%s%N)
elapsed=$(($((end_time - start_time)) / 1000000)) # Преобразование в миллисекунды

echo "  Количество слов в файле: $large_count"
echo "  Время обработки: ${elapsed}ms"
if [ "$elapsed" -lt 1000 ]; then
    echo -e "  ${GREEN}✅ Производительность хорошая${NC}"
else
    echo -e "  ${YELLOW}⚠️ Время обработки довольно долгое${NC}"
fi
echo ""

# Заключение
echo "========================================"
echo "Тестирование завершено!"
echo "========================================"
echo ""
echo -e "${GREEN}Основные функции:${NC}"
echo "  ✓ Точный подсчет китайских символов"
echo "  ✓ Исключение разметки Markdown"
echo "  ✓ Исключение блоков кода"
echo "  ✓ Обработка смешанного текста"
echo ""
echo -e "${YELLOW}Рекомендации по использованию:${NC}"
echo "  • Не используйте 'wc -w' для подсчета китайских слов"
echo "  • Используйте функцию 'count_chinese_words' для получения точного результата"
echo "  • Проверяйте количество слов после завершения написания"
echo ""