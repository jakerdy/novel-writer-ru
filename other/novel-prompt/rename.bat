@echo off
chcp 65001 >nul
cd /d "E:\Dev\2026-02-06 - NovelWriter-Rus\other\小说提示词"

REM Rename files in MBTI
ren "MBTI\初始(1).txt" "Initial(1).txt"
ren "MBTI\续写(1).txt" "Continue(1).txt"

REM Rename files in MBTI+人设模板
ren "MBTI+人设模板\个人文风分析师（个人语料与表达指纹）.txt" "PersonalStyleAnalyzer.txt"
ren "MBTI+人设模板\初始(1).txt" "Initial(1).txt"
ren "MBTI+人设模板\真人感写作指南模版.txt" "AuthenticWritingGuideTemplate.txt"
ren "MBTI+人设模板\续写(1).txt" "Continue(1).txt"

REM Rename files in MBTI+长矛人设
ren "MBTI+长矛人设\初始(1).txt" "Initial(1).txt"
ren "MBTI+长矛人设\真人感写作指南.txt" "AuthenticWritingGuide.txt"
ren "MBTI+长矛人设\续写(1).txt" "Continue(1).txt"

REM Rename file in gen+知识库3.1
ren "gen+知识库3.1\核心指令.txt" "CoreInstructions.txt"

REM Rename directories
ren "gen+知识库3.1" "gen+KnowledgeBase3.1"
ren "MBTI+人设模板" "MBTI+CharacterTemplate"
ren "MBTI+长矛人设" "MBTI+LongSpearCharacter"

echo All files and directories renamed successfully!
del rename.py
del rename.bat
