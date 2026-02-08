import os

base_path = r'E:\Dev\2026-02-06 - NovelWriter-Rus\other\小说提示词'

# Rename files first, then directories
renames = [
    # Files in MBTI
    (os.path.join(base_path, 'MBTI', '初始(1).txt'), os.path.join(base_path, 'MBTI', 'Initial(1).txt')),
    (os.path.join(base_path, 'MBTI', '续写(1).txt'), os.path.join(base_path, 'MBTI', 'Continue(1).txt')),
    
    # Files in MBTI+人设模板
    (os.path.join(base_path, 'MBTI+人设模板', '个人文风分析师（个人语料与表达指纹）.txt'), 
     os.path.join(base_path, 'MBTI+人设模板', 'PersonalStyleAnalyzer.txt')),
    (os.path.join(base_path, 'MBTI+人设模板', '初始(1).txt'), 
     os.path.join(base_path, 'MBTI+人设模板', 'Initial(1).txt')),
    (os.path.join(base_path, 'MBTI+人设模板', '真人感写作指南模版.txt'), 
     os.path.join(base_path, 'MBTI+人设模板', 'AuthenticWritingGuideTemplate.txt')),
    (os.path.join(base_path, 'MBTI+人设模板', '续写(1).txt'), 
     os.path.join(base_path, 'MBTI+人设模板', 'Continue(1).txt')),
    
    # Files in MBTI+长矛人设
    (os.path.join(base_path, 'MBTI+长矛人设', '初始(1).txt'), 
     os.path.join(base_path, 'MBTI+长矛人设', 'Initial(1).txt')),
    (os.path.join(base_path, 'MBTI+长矛人设', '真人感写作指南.txt'), 
     os.path.join(base_path, 'MBTI+长矛人设', 'AuthenticWritingGuide.txt')),
    (os.path.join(base_path, 'MBTI+长矛人设', '续写(1).txt'), 
     os.path.join(base_path, 'MBTI+长矛人设', 'Continue(1).txt')),
    
    # Files in gen+知识库3.1
    (os.path.join(base_path, 'gen+知识库3.1', '核心指令.txt'), 
     os.path.join(base_path, 'gen+知识库3.1', 'CoreInstructions.txt')),
    
    # Directories
    (os.path.join(base_path, 'gen+知识库3.1'), 
     os.path.join(base_path, 'gen+KnowledgeBase3.1')),
    (os.path.join(base_path, 'MBTI+人设模板'), 
     os.path.join(base_path, 'MBTI+CharacterTemplate')),
    (os.path.join(base_path, 'MBTI+长矛人设'), 
     os.path.join(base_path, 'MBTI+LongSpearCharacter')),
]

for old, new in renames:
    if os.path.exists(old):
        os.rename(old, new)
        print(f'Renamed: {os.path.basename(old)} -> {os.path.basename(new)}')
    else:
        print(f'Not found: {old}')

print('\nAll files and directories renamed successfully!')
