#!/usr/bin/env node

import { Command } from '@commander-js/extra-typings';
import chalk from 'chalk';
import path from 'path';
import fs from 'fs-extra';
import ora from 'ora';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';
import { getVersion, getVersionInfo } from './version.js';
import { PluginManager } from './plugins/manager.js';
import { ensureProjectRoot, getProjectInfo } from './utils/project.js';
import
{
  displayProjectBanner,
  selectAIAssistant,
  selectWritingMethod,
  selectScriptType,
  confirmExpertMode,
  displayStep,
  isInteractive
} from './utils/interactive.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const program = new Command();

// Конфигурация AI-платформы — все поддерживаемые платформы
interface AIConfig
{
  name: string;
  dir: string;
  commandsDir: string;
  displayName: string;
  extraDirs?: string[];
}

const AI_CONFIGS: AIConfig[] = [
  { name: 'claude', dir: '.claude', commandsDir: 'commands', displayName: 'Claude Code' },
  { name: 'cursor', dir: '.cursor', commandsDir: 'commands', displayName: 'Cursor' },
  { name: 'gemini', dir: '.gemini', commandsDir: 'commands', displayName: 'Gemini CLI' },
  { name: 'windsurf', dir: '.windsurf', commandsDir: 'workflows', displayName: 'Windsurf' },
  { name: 'roocode', dir: '.roo', commandsDir: 'commands', displayName: 'Roo Code' },
  { name: 'copilot', dir: '.github', commandsDir: 'prompts', displayName: 'GitHub Copilot', extraDirs: ['.vscode'] },
  { name: 'qwen', dir: '.qwen', commandsDir: 'commands', displayName: 'Qwen Code' },
  { name: 'opencode', dir: '.opencode', commandsDir: 'command', displayName: 'OpenCode' },
  { name: 'codex', dir: '.codex', commandsDir: 'prompts', displayName: 'Codex CLI' },
  { name: 'kilocode', dir: '.kilocode', commandsDir: 'workflows', displayName: 'Kilo Code' },
  { name: 'auggie', dir: '.augment', commandsDir: 'commands', displayName: 'Auggie CLI' },
  { name: 'codebuddy', dir: '.codebuddy', commandsDir: 'commands', displayName: 'CodeBuddy' },
  { name: 'q', dir: '.amazonq', commandsDir: 'prompts', displayName: 'Amazon Q Developer' }
];

// Вспомогательная функция: генерация Markdown-команд из шаблона
function generateMarkdownCommand(template: string, scriptPath: string): string
{
  // Заменяем {SCRIPT} и возвращаем полное содержимое, сохраняя все frontmatter, включая раздел scripts
  return template.replace(/{SCRIPT}/g, scriptPath);
}

// Вспомогательная функция: генерация TOML-команд из шаблона
function generateTomlCommand(template: string, scriptPath: string): string
{
  // Извлекаем description
  const descMatch = template.match(/description:\s*(.+)/);
  const description = descMatch ? descMatch[1].trim() : 'Описание команды';

  // Удаляем YAML frontmatter
  const content = template.replace(/^---[\s\S]*?---\n/, '');

  // Заменяем {SCRIPT}
  const processedContent = content.replace(/{SCRIPT}/g, scriptPath);

  // Нормализуем символы новой строки, чтобы избежать ошибок парсинга TOML из-за CRLF в Windows
  const normalizedContent = processedContent.replace(/\r\n/g, '\n');
  const promptValue = JSON.stringify(normalizedContent);
  const escapedDescription = description
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"');

  return `description = "${escapedDescription}"

prompt = ${promptValue}
`;
}

// Отображение приветственного баннера
function displayBanner(): void
{
  const banner = `
╔═════════════════════════════════════════════════════════╗
║                 📚  Novel Writer 📝                     ║
║     AI-инструмент для создания китайских романов        ║
╚═════════════════════════════════════════════════════════╝
`;
  console.log(chalk.cyan(banner));
  console.log(chalk.gray(`  ${getVersionInfo()}\n`));
}

displayBanner();

program
  .name('novel')
  .description(chalk.cyan('Novel Writer - AI-инструмент для создания китайских романов'))
  .version(getVersion(), '-v, --version', 'Показать номер версии')
  .helpOption('-h, --help', 'Показать справку');

// Команда init — инициализация нового проекта романа (аналогично specify init)
program
  .command('init')
  .argument('[name]', 'Название проекта романа')
  .option('--here', 'Инициализировать в текущем каталоге')
  .option('--ai <type>', 'Выбрать AI-ассистента: claude | cursor | gemini | windsurf | roocode | copilot | qwen | opencode | codex | kilocode | auggie | codebuddy | q')
  .option('--all', 'Сгенерировать конфигурацию для всех поддерживаемых AI-ассистентов')
  .option('--method <type>', 'Выбрать метод написания: three-act | hero-journey | story-circle | seven-point | pixar | snowflake')
  .option('--no-git', 'Пропустить инициализацию Git')
  .option('--with-experts', 'Включить режим эксперта')
  .option('--plugins <names>', 'Предустановленные плагины, разделенные запятыми')
  .description('Инициализировать новый проект романа')
  .action(async (name, options) =>
  {
    // Если используется интерактивный терминал и параметры не указаны явно, показать интерактивный выбор
    const shouldShowInteractive = isInteractive() && !options.all;
    const needsAISelection = shouldShowInteractive && !options.ai;
    const needsMethodSelection = shouldShowInteractive && !options.method;
    const needsExpertConfirm = shouldShowInteractive && !options.withExperts;

    if (needsAISelection || needsMethodSelection || needsExpertConfirm)
    {
      // Отобразить баннер проекта
      displayProjectBanner();

      let stepCount = 0;
      const totalSteps = 4;

      // Интерактивный выбор AI-ассистента
      if (needsAISelection)
      {
        stepCount++;
        displayStep(stepCount, totalSteps, 'Выбор AI-ассистента');
        options.ai = await selectAIAssistant(AI_CONFIGS);
        console.log('');
      }

      // Интерактивный выбор метода написания
      if (needsMethodSelection)
      {
        stepCount++;
        displayStep(stepCount, totalSteps, 'Выбор метода написания');
        options.method = await selectWritingMethod();
        console.log('');
      }

      // Интерактивный выбор типа скрипта
      stepCount++;
      displayStep(stepCount, totalSteps, 'Выбор типа скрипта');
      const selectedScriptType = await selectScriptType();
      console.log('');

      // Интерактивное подтверждение режима эксперта
      if (needsExpertConfirm)
      {
        stepCount++;
        displayStep(stepCount, totalSteps, 'Режим эксперта');
        const enableExperts = await confirmExpertMode();
        if (enableExperts)
        {
          options.withExperts = true;
        }
        console.log('');
      }
    }

    // Установка значений по умолчанию (если не указаны через интерактивный ввод или параметры)
    if (!options.ai) options.ai = 'claude';
    if (!options.method) options.method = 'three-act';

    const spinner = ora('Инициализация проекта романа...').start();

    try
    {
      // Определение пути к проекту
      let projectPath: string;
      if (options.here)
      {
        projectPath = process.cwd();
        name = path.basename(projectPath);
      } else
      {
        if (!name)
        {
          spinner.fail('Пожалуйста, укажите название проекта или используйте параметр --here');
          process.exit(1);
        }
        projectPath = path.join(process.cwd(), name);
        if (await fs.pathExists(projectPath))
        {
          spinner.fail(`Каталог проекта "${name}" уже существует`);
          process.exit(1);
        }
        await fs.ensureDir(projectPath);
      }

      // Создание базовой структуры проекта
      const baseDirs = [
        '.specify',
        '.specify/memory',
        '.specify/scripts',
        '.specify/scripts/bash',
        '.specify/scripts/powershell',
        '.specify/templates',
        'stories',
        'spec',
        'spec/tracking',
        'spec/knowledge'
      ];

      for (const dir of baseDirs)
      {
        await fs.ensureDir(path.join(projectPath, dir));
      }

      // Создание специфичных каталогов в зависимости от типа AI
      const aiDirs: string[] = [];
      if (options.all)
      {
        // Создание каталогов для всех AI
        aiDirs.push(
          '.claude/commands',
          '.cursor/commands',
          '.gemini/commands',
          '.windsurf/workflows',
          '.roo/commands',
          '.github/prompts',
          '.vscode',
          '.qwen/commands',
          '.opencode/command',
          '.codex/prompts',
          '.kilocode/workflows',
          '.augment/commands',
          '.codebuddy/commands',
          '.amazonq/prompts'
        );
      } else
      {
        // Создание каталогов для выбранного AI
        switch (options.ai)
        {
          case 'claude':
            aiDirs.push('.claude/commands');
            break;
          case 'cursor':
            aiDirs.push('.cursor/commands');
            break;
          case 'gemini':
            aiDirs.push('.gemini/commands');
            break;
          case 'windsurf':
            aiDirs.push('.windsurf/workflows');
            break;
          case 'roocode':
            aiDirs.push('.roo/commands');
            break;
          case 'copilot':
            aiDirs.push('.github/prompts', '.vscode');
            break;
          case 'qwen':
            aiDirs.push('.qwen/commands');
            break;
          case 'opencode':
            aiDirs.push('.opencode/command');
            break;
          case 'codex':
            aiDirs.push('.codex/prompts');
            break;
          case 'kilocode':
            aiDirs.push('.kilocode/workflows');
            break;
          case 'auggie':
            aiDirs.push('.augment/commands');
            break;
          case 'codebuddy':
            aiDirs.push('.codebuddy/commands');
            break;
          case 'q':
            aiDirs.push('.amazonq/prompts');
            break;
        }
      }

      for (const dir of aiDirs)
      {
        await fs.ensureDir(path.join(projectPath, dir));
      }

      // Создание базового файла конфигурации
      const config = {
        name,
        type: 'novel',
        ai: options.ai,
        method: options.method || 'three-act',
        created: new Date().toISOString(),
        version: getVersion()
      };

      await fs.writeJson(path.join(projectPath, '.specify', 'config.json'), config, { spaces: 2 });

      // Копирование конфигурации AI и файлов команд из сборки
      const packageRoot = path.resolve(__dirname, '..');
      const scriptsDir = path.join(packageRoot, 'scripts');
      const sourceMap: Record<string, string> = {
        'claude': 'dist/claude',
        'gemini': 'dist/gemini',
        'cursor': 'dist/cursor',
        'windsurf': 'dist/windsurf',
        'roocode': 'dist/roocode',
        'copilot': 'dist/copilot',
        'qwen': 'dist/qwen',
        'opencode': 'dist/opencode',
        'codex': 'dist/codex',
        'kilocode': 'dist/kilocode',
        'auggie': 'dist/auggie',
        'codebuddy': 'dist/codebuddy',
        'q': 'dist/q'
      };

      // Определение целевых AI для копирования
      const targetAI: string[] = [];
      if (options.all)
      {
        targetAI.push('claude', 'gemini', 'cursor', 'windsurf', 'roocode', 'copilot', 'qwen', 'opencode', 'codex', 'kilocode', 'auggie', 'codebuddy', 'q');
      } else
      {
        targetAI.push(options.ai);
      }

      // Копирование каталогов конфигурации AI (включая файлы команд и каталог .specify)
      for (const ai of targetAI)
      {
        const sourceDir = path.join(packageRoot, sourceMap[ai]);
        if (await fs.pathExists(sourceDir))
        {
          // Копирование всего каталога сборки в проект
          await fs.copy(sourceDir, projectPath, { overwrite: false });
          spinner.text = `Установка конфигурации ${ai}...`;
        } else
        {
          console.log(chalk.yellow(`\nПредупреждение: Сборка ${ai} не найдена. Пожалуйста, выполните npm run build:commands`));
        }
      }

      // Копирование файлов скриптов в каталог .specify/scripts пользовательского проекта (уже включено в сборку)
      // Примечание: каталог .specify уже скопирован выше через fs.copy, здесь только резервная логика
      if (await fs.pathExists(scriptsDir) && !await fs.pathExists(path.join(projectPath, '.specify', 'scripts')))
      {
        const userScriptsDir = path.join(projectPath, '.specify', 'scripts');
        await fs.copy(scriptsDir, userScriptsDir);

        // Установка прав на выполнение для bash-скриптов
        const bashDir = path.join(userScriptsDir, 'bash');
        if (await fs.pathExists(bashDir))
        {
          const bashFiles = await fs.readdir(bashDir);
          for (const file of bashFiles)
          {
            if (file.endsWith('.sh'))
            {
              const filePath = path.join(bashDir, file);
              await fs.chmod(filePath, 0o755);
            }
          }
        }
      }

      // Копирование файлов шаблонов в каталог .specify/templates
      const fullTemplatesDir = path.join(packageRoot, 'templates');
      if (await fs.pathExists(fullTemplatesDir))
      {
        const userTemplatesDir = path.join(projectPath, '.specify', 'templates');
        await fs.copy(fullTemplatesDir, userTemplatesDir);
      }

      // Копирование файлов memory в каталог .specify/memory
      const memoryDir = path.join(packageRoot, 'memory');
      if (await fs.pathExists(memoryDir))
      {
        const userMemoryDir = path.join(projectPath, '.specify', 'memory');
        await fs.copy(memoryDir, userMemoryDir);
      }

      // Копирование шаблонов файлов отслеживания в каталог spec/tracking
      const trackingTemplatesDir = path.join(packageRoot, 'templates', 'tracking');
      if (await fs.pathExists(trackingTemplatesDir))
      {
        const userTrackingDir = path.join(projectPath, 'spec', 'tracking');
        await fs.copy(trackingTemplatesDir, userTrackingDir);
      }

      // Копирование шаблонов базы знаний в каталог spec/knowledge
      const knowledgeTemplatesDir = path.join(packageRoot, 'templates', 'knowledge');
      if (await fs.pathExists(knowledgeTemplatesDir))
      {
        const userKnowledgeDir = path.join(projectPath, 'spec', 'knowledge');
        await fs.copy(knowledgeTemplatesDir, userKnowledgeDir);

        // Обновление дат в шаблонах
        const knowledgeFiles = await fs.readdir(userKnowledgeDir);
        const currentDate = new Date().toISOString().split('T')[0];
        for (const file of knowledgeFiles)
        {
          if (file.endsWith('.md'))
          {
            const filePath = path.join(userKnowledgeDir, file);
            let content = await fs.readFile(filePath, 'utf-8');
            content = content.replace(/\[日期\]/g, currentDate);
            await fs.writeFile(filePath, content);
          }
        }
      }

      // Копирование структуры каталога spec (включая пресеты и спецификации для защиты от ИИ)
      // Примечание: сборка уже включает spec/presets и т. д., это резервный вариант для обеспечения полноты
      const specDir = path.join(packageRoot, 'spec');
      if (await fs.pathExists(specDir))
      {
        const userSpecDir = path.join(projectPath, 'spec');

        // Перебор и копирование всех подкаталогов spec
        const specItems = await fs.readdir(specDir);
        for (const item of specItems)
        {
          const sourcePath = path.join(specDir, item);
          const targetPath = path.join(userSpecDir, item);

          // presets, checklists, config.json и т. д. копируются напрямую (не перезаписывая существующие)
          // tracking и knowledge уже скопированы ранее из templates, пропускаем
          if (item !== 'tracking' && item !== 'knowledge')
          {
            await fs.copy(sourcePath, targetPath, { overwrite: false });
          }
        }
      }

      // Копирование дополнительных конфигурационных файлов для Gemini
      if (aiDirs.some(dir => dir.includes('.gemini')))
      {
        // Копирование settings.json
        const geminiSettingsSource = path.join(packageRoot, 'templates', 'gemini-settings.json');
        const geminiSettingsDest = path.join(projectPath, '.gemini', 'settings.json');
        if (await fs.pathExists(geminiSettingsSource))
        {
          await fs.copy(geminiSettingsSource, geminiSettingsDest);
          console.log('  ✓ Gemini settings.json скопирован');
        }

        // Копирование GEMINI.md
        const geminiMdSource = path.join(packageRoot, 'templates', 'GEMINI.md');
        const geminiMdDest = path.join(projectPath, '.gemini', 'GEMINI.md');
        if (await fs.pathExists(geminiMdSource))
        {
          await fs.copy(geminiMdSource, geminiMdDest);
          console.log('  ✓ GEMINI.md скопирован');
        }
      }

      // Копирование настроек VS Code для GitHub Copilot
      if (aiDirs.some(dir => dir.includes('.github') || dir.includes('.vscode')))
      {
        const vscodeSettingsSource = path.join(packageRoot, 'templates', 'vscode-settings.json');
        const vscodeSettingsDest = path.join(projectPath, '.vscode', 'settings.json');
        if (await fs.pathExists(vscodeSettingsSource))
        {
          await fs.copy(vscodeSettingsSource, vscodeSettingsDest);
          console.log('  ✓ GitHub Copilot settings.json скопирован');
        }
      }

      // Если указан --with-experts, копирование файлов экспертов и команды expert
      if (options.withExperts)
      {
        spinner.text = 'Установка режима эксперта...';

        // Копирование каталога экспертов
        const expertsSourceDir = path.join(packageRoot, 'experts');
        if (await fs.pathExists(expertsSourceDir))
        {
          const userExpertsDir = path.join(projectPath, 'experts');
          await fs.copy(expertsSourceDir, userExpertsDir);
        }

        // Копирование команды expert в каждый каталог AI
        const expertCommandSource = path.join(packageRoot, 'templates', 'commands', 'expert.md');
        if (await fs.pathExists(expertCommandSource))
        {
          const expertContent = await fs.readFile(expertCommandSource, 'utf-8');

          for (const aiDir of aiDirs)
          {
            if (aiDir.includes('claude') || aiDir.includes('cursor'))
            {
              const expertPath = path.join(projectPath, aiDir, 'expert.md');
              await fs.writeFile(expertPath, expertContent);
            }
            // Windsurf использует каталог workflows
            if (aiDir.includes('windsurf'))
            {
              const expertPath = path.join(projectPath, aiDir, 'expert.md');
              await fs.writeFile(expertPath, expertContent);
            }
            // Roo Code использует каталог Markdown команд
            if (aiDir.includes('.roo'))
            {
              const expertPath = path.join(projectPath, aiDir, 'expert.md');
              await fs.writeFile(expertPath, expertContent);
            }
            // Обработка Gemini
            if (aiDir.includes('gemini'))
            {
              const expertPath = path.join(projectPath, aiDir, 'expert.toml');
              const expertToml = generateTomlCommand(expertContent, '');
              await fs.writeFile(expertPath, expertToml);
            }
          }
        }
      }

      // Если указан --plugins, установка плагинов
      if (options.plugins)
      {
        spinner.text = 'Установка плагинов...';

        const pluginNames = options.plugins.split(',').map((p: string) => p.trim());
        const pluginManager = new PluginManager(projectPath);

        for (const pluginName of pluginNames)
        {
          // Проверка встроенных плагинов
          const builtinPluginPath = path.join(packageRoot, 'plugins', pluginName);
          if (await fs.pathExists(builtinPluginPath))
          {
            await pluginManager.installPlugin(pluginName, builtinPluginPath);
          } else
          {
            console.log(chalk.yellow(`\nПредупреждение: плагин "${pluginName}" не найден`));
          }
        }
      }

      // Инициализация Git
      if (options.git !== false)
      {
        try
        {
          execSync('git init', { cwd: projectPath, stdio: 'ignore' });

          // Создание .gitignore
          const gitignore = `# Временные файлы
*.tmp
*.swp
.DS_Store

# Конфигурация редактора
.vscode/
.idea/

# Кэш ИИ
.ai-cache/

# Узлы модулей
node_modules/
`;
          await fs.writeFile(path.join(projectPath, '.gitignore'), gitignore);

          execSync('git add .', { cwd: projectPath, stdio: 'ignore' });
          execSync('git commit -m "Инициализация проекта романа"', { cwd: projectPath, stdio: 'ignore' });
        } catch
        {
          console.log(chalk.yellow('\nПодсказка: Инициализация Git не удалась, но проект создан успешно'));
        }
      }

      spinner.succeed(chalk.green(`Проект романа "${name}" успешно создан!`));

      // Отображение следующих шагов
      console.log('\n' + chalk.cyan('Далее:'));
      console.log(chalk.gray('─────────────────────────────'));

      if (!options.here)
      {
        console.log(`  1. ${chalk.white(`cd ${name}`)} - Перейти в каталог проекта`);
      }

      const aiName = {
        'claude': 'Claude Code',
        'cursor': 'Cursor',
        'gemini': 'Gemini',
        'windsurf': 'Windsurf',
        'roocode': 'Roo Code',
        'copilot': 'GitHub Copilot',
        'qwen': 'Qwen Code',
        'opencode': 'OpenCode',
        'codex': 'Codex CLI',
        'kilocode': 'Kilo Code',
        'auggie': 'Auggie CLI',
        'codebuddy': 'CodeBuddy',
        'q': 'Amazon Q Developer'
      }[options.ai] || 'AI-помощник';

      if (options.all)
      {
        console.log(`  2. ${chalk.white('Открыть проект в любом из AI-помощников (Claude Code, Cursor, Gemini, Windsurf, Roo Code, GitHub Copilot, Qwen Code, OpenCode, Codex CLI, Kilo Code, Auggie CLI, CodeBuddy, Amazon Q Developer)')}`);
      } else
      {
        console.log(`  2. ${chalk.white(`Открыть проект в ${aiName}`)}`);
      }
      console.log(`  3. Используйте следующие команды с косой чертой для начала работы:`);

      console.log('\n' + chalk.yellow('     📝 Семишаговая методология:'));
      console.log(`     ${chalk.cyan('/constitution')} - Создать конституцию проекта, определяющую основные принципы`);
      console.log(`     ${chalk.cyan('/specify')}      - Определить спецификации истории, уточняя, что нужно создать`);
      console.log(`     ${chalk.cyan('/clarify')}      - Прояснить ключевые точки принятия решений, устраняя неопределенности`);
      console.log(`     ${chalk.cyan('/plan')}         - Разработать технический план, определив, как создавать`);
      console.log(`     ${chalk.cyan('/tasks')}        - Разбить задачи на выполнимые списки`);
      console.log(`     ${chalk.cyan('/write')}        - AI-ассистированное написание глав`);
      console.log(`     ${chalk.cyan('/analyze')}      - Комплексный анализ и проверка для обеспечения качества`);

      console.log('\n' + chalk.yellow('     📊 Команды управления отслеживанием:'));
      console.log(`     ${chalk.cyan('/plot-check')}  - Проверить согласованность сюжета`);
      console.log(`     ${chalk.cyan('/timeline')}    - Управлять временной шкалой истории`);
      console.log(`     ${chalk.cyan('/relations')}   - Отслеживать отношения персонажей`);
      console.log(`     ${chalk.cyan('/world-check')} - Проверить соответствие сеттинга`);
      console.log(`     ${chalk.cyan('/track')}       - Комплексное отслеживание и интеллектуальный анализ`);

      // Если установлен режим эксперта, отобразить подсказку
      if (options.withExperts)
      {
        console.log('\n' + chalk.yellow('     🎓 Режим эксперта:'));
        console.log(`     ${chalk.cyan('/expert')}       - Показать доступных экспертов`);
        console.log(`     ${chalk.cyan('/expert plot')} - Эксперт по структуре сюжета`);
        console.log(`     ${chalk.cyan('/expert character')} - Эксперт по созданию персонажей`);
      }

      // Если установлены плагины, отобразить команду плагина
      if (options.plugins)
      {
        const installedPlugins = options.plugins.split(',').map((p: string) => p.trim());
        if (installedPlugins.includes('translate'))
        {
          console.log('\n' + chalk.yellow('     🌍 Плагин перевода:'));
          console.log(`     ${chalk.cyan('/translate')}   - Перевод с китайского на английский`);
          console.log(`     ${chalk.cyan('/polish')}      - Редактирование английского текста`);
        }
      }

      console.log('\n' + chalk.gray('Рекомендуемый порядок: constitution → specify → clarify → plan → tasks → write → analyze'));
      console.log(chalk.dim('Подсказка: команды с косой чертой используются внутри AI-помощника, а не в терминале'));

    } catch (error)
    {
      spinner.fail(chalk.red('Инициализация проекта не удалась'));
      console.error(error);
      process.exit(1);
    }
  });

// Команда check - проверка окружения
program
  .command('check')
  .description('Проверить системное окружение и инструменты ИИ')
  .action(() =>
  {
    console.log(chalk.cyan('Проверка системного окружения...\n'));

    const checks = [
      { name: 'Node.js', command: 'node --version', installed: false },
      { name: 'Git', command: 'git --version', installed: false },
      { name: 'Claude CLI', command: 'claude --version', installed: false },
      { name: 'Cursor', command: 'cursor --version', installed: false },
      { name: 'Gemini CLI', command: 'gemini --version', installed: false }
    ];

    checks.forEach(check =>
    {
      try
      {
        execSync(check.command, { stdio: 'ignore' });
        check.installed = true;
        console.log(chalk.green('✓') + ` ${check.name} установлен`);
      } catch
      {
        console.log(chalk.yellow('⚠') + ` ${check.name} не установлен`);
      }
    });

    const hasAI = checks.slice(2).some(c => c.installed);
    if (!hasAI)
    {
      console.log('\n' + chalk.yellow('Предупреждение: Инструменты AI-помощников не обнаружены'));
      console.log('Пожалуйста, установите один из следующих инструментов:');
      console.log('  • Claude: https://claude.ai');
      console.log('  • Cursor: https://cursor.sh');
      console.log('  • Gemini: https://gemini.google.com');
      console.log('  • Roo Code: https://roocode.com');
    } else
    {
      console.log('\n' + chalk.green('Проверка среды пройдена!'));
    }
  });

// Команда plugins — управление плагинами
program
  .command('plugins')
  .description('Управление плагинами')
  .action(() =>
  {
    // Показать справку по подкомандам плагинов
    console.log(chalk.cyan('\n📦 Команды управления плагинами:\n'));
    console.log('  novel plugins list              - Показать список установленных плагинов');
    console.log('  novel plugins add <name>        - Установить плагин');
    console.log('  novel plugins remove <name>     - Удалить плагин');
    console.log('\n' + chalk.gray('Доступные плагины:'));
    console.log('  translate         - Плагин для перевода с китайского на английский');
    console.log('  authentic-voice   - Плагин для написания текстов с использованием реального голоса');
  });

program
  .command('plugins:list')
  .description('Показать список установленных плагинов')
  .action(async () =>
  {
    try
    {
      // Проверить проект
      const projectPath = await ensureProjectRoot();
      const projectInfo = await getProjectInfo(projectPath);

      if (!projectInfo)
      {
        console.log(chalk.red('❌ Не удалось прочитать информацию о проекте'));
        process.exit(1);
      }

      const pluginManager = new PluginManager(projectPath);
      const plugins = await pluginManager.listPlugins();

      console.log(chalk.cyan('\n📦 Установленные плагины\n'));
      console.log(chalk.gray(`Проект: ${path.basename(projectPath)}`));
      console.log(chalk.gray(`Конфигурация AI: ${projectInfo.installedAI.join(', ') || 'Нет'}\n`));

      if (plugins.length === 0)
      {
        console.log(chalk.yellow('Плагины не найдены'));
        console.log(chalk.gray('\nИспользуйте "novel plugins:add <name>" для установки плагина'));
        console.log(chalk.gray('Доступные плагины: translate, authentic-voice, book-analysis, genre-knowledge\n'));
        return;
      }

      for (const plugin of plugins)
      {
        console.log(chalk.yellow(`  ${plugin.name}`) + ` (v${plugin.version})`);
        console.log(chalk.gray(`    ${plugin.description}`));

        if (plugin.commands && plugin.commands.length > 0)
        {
          console.log(chalk.gray(`    Команды: ${plugin.commands.map(c => `/${c.id}`).join(', ')}`));
        }

        if (plugin.experts && plugin.experts.length > 0)
        {
          console.log(chalk.gray(`    Эксперты: ${plugin.experts.map(e => e.title).join(', ')}`));
        }
        console.log('');
      }
    } catch (error: any)
    {
      if (error.message === 'NOT_IN_PROJECT')
      {
        console.log(chalk.red('\n❌ Текущий каталог не является проектом novel-writer'));
        console.log(chalk.gray('   Запустите эту команду в корневом каталоге проекта\n'));
        process.exit(1);
      }

      console.error(chalk.red('❌ Ошибка при выводе списка плагинов:'), error);
      process.exit(1);
    }
  });

program
  .command('plugins:add <name>')
  .description('Установить плагин')
  .action(async (name) =>
  {
    try
    {
      // 1. Проверить проект
      const projectPath = await ensureProjectRoot();
      const projectInfo = await getProjectInfo(projectPath);

      if (!projectInfo)
      {
        console.log(chalk.red('❌ Не удалось прочитать информацию о проекте'));
        process.exit(1);
      }

      console.log(chalk.cyan('\n📦 Установка плагина Novel Writer\n'));
      console.log(chalk.gray(`Версия проекта: ${projectInfo.version}`));
      console.log(chalk.gray(`Конфигурация AI: ${projectInfo.installedAI.join(', ') || 'Нет'}\n`));

      // 2. Найти плагин
      const packageRoot = path.resolve(__dirname, '..');
      const builtinPluginPath = path.join(packageRoot, 'plugins', name);

      if (!await fs.pathExists(builtinPluginPath))
      {
        console.log(chalk.red(`❌ Плагин ${name} не найден\n`));
        console.log(chalk.gray('Доступные плагины:'));
        console.log(chalk.gray('  - translate (плагин для перевода с китайского на английский)'));
        console.log(chalk.gray('  - authentic-voice (плагин для написания текстов с использованием реального голоса)'));
        console.log(chalk.gray('  - book-analysis (плагин для анализа книг)'));
        console.log(chalk.gray('  - genre-knowledge (плагин для знаний о жанрах)'));
        process.exit(1);
      }

      // 3. Прочитать конфигурацию плагина
      const pluginConfigPath = path.join(builtinPluginPath, 'config.yaml');
      const yaml = await import('js-yaml');
      const pluginConfigContent = await fs.readFile(pluginConfigPath, 'utf-8');
      const pluginConfig = yaml.load(pluginConfigContent) as any;

      // 4. Показать информацию о плагине
      console.log(chalk.cyan(`Подготовка к установке: ${pluginConfig.description || name}`));
      console.log(chalk.gray(`Версия: ${pluginConfig.version}`));

      if (pluginConfig.commands && pluginConfig.commands.length > 0)
      {
        console.log(chalk.gray(`Количество команд: ${pluginConfig.commands.length}`));
      }

      if (pluginConfig.experts && pluginConfig.experts.length > 0)
      {
        console.log(chalk.gray(`Режим эксперта: ${pluginConfig.experts.length} шт.`));
      }

      if (projectInfo.installedAI.length > 0)
      {
        console.log(chalk.gray(`Целевой AI: ${projectInfo.installedAI.join(', ')}\n`));
      } else
      {
        console.log(chalk.yellow('\n⚠️  Каталог конфигурации AI не обнаружен'));
        console.log(chalk.gray('   Плагин будет скопирован, но команды не будут внедрены ни на одну AI-платформу\n'));
      }

      // 5. Установить плагин
      const spinner = ora('Установка плагина...').start();
      const pluginManager = new PluginManager(projectPath);

      await pluginManager.installPlugin(name, builtinPluginPath);
      spinner.succeed(chalk.green('Плагин успешно установлен!\n'));

      // 6. Показать следующие шаги
      if (pluginConfig.commands && pluginConfig.commands.length > 0)
      {
        console.log(chalk.cyan('Доступные команды:'));
        for (const cmd of pluginConfig.commands)
        {
          console.log(chalk.gray(`  /${cmd.id} - ${cmd.description || ''}`));
        }
      }

      if (pluginConfig.experts && pluginConfig.experts.length > 0)
      {
        console.log(chalk.cyan('\nРежим эксперта:'));
        for (const expert of pluginConfig.experts)
        {
          console.log(chalk.gray(`  /expert ${expert.id} - ${expert.title || ''}`));
        }
      }

      console.log('');
    } catch (error: any)
    {
      if (error.message === 'NOT_IN_PROJECT')
      {
        console.log(chalk.red('\n❌ Текущий каталог не является проектом novel-writer'));
        console.log(chalk.gray('   Запустите эту команду в корневом каталоге проекта или используйте novel init для создания нового проекта\n'));
        process.exit(1);
      }

      console.log(chalk.red('\n❌ Ошибка при установке плагина'));
      console.error(chalk.gray(error.message || error));
      console.log('');
      process.exit(1);
    }
  });

program
  .command('plugins:remove <name>')
  .description('Удалить плагин')
  .action(async (name) =>
  {
    try
    {
      // Проверить проект
      const projectPath = await ensureProjectRoot();
      const projectInfo = await getProjectInfo(projectPath);

      if (!projectInfo)
      {
        console.log(chalk.red('❌ Не удалось прочитать информацию о проекте'));
        process.exit(1);
      }

      const pluginManager = new PluginManager(projectPath);

      console.log(chalk.cyan('\n📦 Удаление плагина Novel Writer\n'));
      console.log(chalk.gray(`Подготовка к удалению плагина: ${name}`));
      console.log(chalk.gray(`Конфигурация AI: ${projectInfo.installedAI.join(', ') || 'Нет'}\n`));

      const spinner = ora('Удаление плагина...').start();
      await pluginManager.removePlugin(name);
      spinner.succeed(chalk.green('Плагин успешно удален!\n'));
    } catch (error: any)
    {
      if (error.message === 'NOT_IN_PROJECT')
      {
        console.log(chalk.red('\n❌ Текущий каталог не является проектом novel-writer'));
        console.log(chalk.gray('   Запустите эту команду в корневом каталоге проекта\n'));
        process.exit(1);
      }

      console.log(chalk.red('\n❌ Ошибка при удалении плагина'));
      console.error(chalk.gray(error.message || error));
      console.log('');
      process.exit(1);
    }
  });

// ============================================================================
// Вспомогательные функции для Upgrade
// ============================================================================

interface UpdateContent
{
  commands: boolean;
  scripts: boolean;
  templates: boolean;
  memory: boolean;
  spec: boolean;
  experts: boolean;
}

interface UpgradeStats
{
  commands: number;
  scripts: number;
  templates: number;
  memory: number;
  spec: number;
  experts: number;
  platforms: string[];
}

/**
 * Интерактивный выбор контента для обновления
 */
async function selectUpdateContentInteractive(): Promise<UpdateContent>
{
  const inquirer = (await import('inquirer')).default;

  const answers = await inquirer.prompt([
    {
      type: 'checkbox',
      name: 'content',
      message: 'Выберите контент для обновления:',
      choices: [
        { name: 'Файлы команд (Commands)', value: 'commands', checked: true },
        { name: 'Файлы скриптов (Scripts)', value: 'scripts', checked: true },
        { name: 'Спецификации и пресеты (Spec/Presets)', value: 'spec', checked: true },
        { name: 'Файлы экспертного режима (Experts)', value: 'experts', checked: false },
        { name: 'Файлы шаблонов (Templates)', value: 'templates', checked: false },
        { name: 'Файлы памяти (Memory)', value: 'memory', checked: false }
      ]
    }
  ]);

  return {
    commands: answers.content.includes('commands'),
    scripts: answers.content.includes('scripts'),
    templates: answers.content.includes('templates'),
    memory: answers.content.includes('memory'),
    spec: answers.content.includes('spec'),
    experts: answers.content.includes('experts')
  };
}

/**
 * Обновление файлов команд
 */
async function updateCommands(
  targetAI: string[],
  projectPath: string,
  packageRoot: string,
  dryRun: boolean
): Promise<number>
{
  let count = 0;

  const sourceMap: Record<string, string> = {
    'claude': 'dist/claude',
    'gemini': 'dist/gemini',
    'cursor': 'dist/cursor',
    'windsurf': 'dist/windsurf',
    'roocode': 'dist/roocode',
    'copilot': 'dist/copilot',
    'qwen': 'dist/qwen',
    'opencode': 'dist/opencode',
    'codex': 'dist/codex',
    'kilocode': 'dist/kilocode',
    'auggie': 'dist/auggie',
    'codebuddy': 'dist/codebuddy',
    'q': 'dist/q'
  };

  for (const ai of targetAI)
  {
    const sourceDir = path.join(packageRoot, sourceMap[ai]);
    const aiConfig = AI_CONFIGS.find(c => c.name === ai);

    if (!aiConfig) continue;

    if (await fs.pathExists(sourceDir))
    {
      const targetDir = path.join(projectPath, aiConfig.dir);

      // Копировать каталог с файлами команд
      const sourceCommandsDir = path.join(sourceDir, aiConfig.dir, aiConfig.commandsDir);
      const targetCommandsDir = path.join(targetDir, aiConfig.commandsDir);

      if (await fs.pathExists(sourceCommandsDir))
      {
        if (!dryRun)
        {
          await fs.copy(sourceCommandsDir, targetCommandsDir, { overwrite: true });
        }

        // Подсчитать количество файлов команд
        const commandFiles = await fs.readdir(sourceCommandsDir);
        const cmdCount = commandFiles.filter(f =>
          f.endsWith('.md') || f.endsWith('.toml')
        ).length;

        count += cmdCount;
        console.log(chalk.gray(`  ✓ ${aiConfig.displayName}: ${cmdCount} файлов`));
      }
      // Обработка дополнительных каталогов (например, .vscode для GitHub Copilot)
      if (aiConfig.extraDirs)
      {
        for (const extraDir of aiConfig.extraDirs)
        {
          const sourceExtraDir = path.join(sourceDir, extraDir);
          const targetExtraDir = path.join(projectPath, extraDir);

          if (await fs.pathExists(sourceExtraDir))
          {
            if (!dryRun)
            {
              await fs.copy(sourceExtraDir, targetExtraDir, { overwrite: true });
            }
            console.log(chalk.gray(`  ✓ ${aiConfig.displayName}: обновлен ${extraDir}`));
          }
        }
      }
    } else
    {
      console.log(chalk.yellow(`  ⚠ Сборка не найдена для ${aiConfig?.displayName || ai}`));
    }
  }

  return count;
}

/**
 * Обновление скриптов
 */
async function updateScripts(
  projectPath: string,
  packageRoot: string,
  dryRun: boolean
): Promise<number>
{
  const scriptsSource = path.join(packageRoot, 'scripts');
  const scriptsDest = path.join(projectPath, '.specify', 'scripts');

  if (!await fs.pathExists(scriptsSource))
  {
    console.log(chalk.yellow('  ⚠ Исходные файлы скриптов не найдены'));
    return 0;
  }

  if (!dryRun)
  {
    await fs.copy(scriptsSource, scriptsDest, { overwrite: true });

    // Установка прав на выполнение для bash скриптов
    const bashDir = path.join(scriptsDest, 'bash');
    if (await fs.pathExists(bashDir))
    {
      const bashFiles = await fs.readdir(bashDir);
      for (const file of bashFiles)
      {
        if (file.endsWith('.sh'))
        {
          const filePath = path.join(bashDir, file);
          await fs.chmod(filePath, 0o755);
        }
      }
    }
  }

  // Подсчет количества скриптов
  const bashScripts = await fs.readdir(path.join(scriptsSource, 'bash'));
  const psScripts = await fs.readdir(path.join(scriptsSource, 'powershell'));
  const totalScripts = bashScripts.length + psScripts.length;

  console.log(chalk.gray(`  ✓ Обновлено ${bashScripts.length} bash скриптов`));
  console.log(chalk.gray(`  ✓ Обновлено ${psScripts.length} powershell скриптов`));

  return totalScripts;
}

/**
 * Обновление шаблонов
 */
async function updateTemplates(
  projectPath: string,
  packageRoot: string,
  dryRun: boolean
): Promise<number>
{
  const templatesSource = path.join(packageRoot, 'templates');
  const templatesDest = path.join(projectPath, '.specify', 'templates');

  if (!await fs.pathExists(templatesSource))
  {
    console.log(chalk.yellow('  ⚠ Исходные файлы шаблонов не найдены'));
    return 0;
  }

  if (!dryRun)
  {
    await fs.copy(templatesSource, templatesDest, { overwrite: true });
  }

  // Подсчет файлов шаблонов
  const files = await fs.readdir(templatesSource);
  const templateCount = files.filter(f => f.endsWith('.md') || f.endsWith('.yaml')).length;

  console.log(chalk.gray(`  ✓ Обновлено ${templateCount} файлов шаблонов`));

  return templateCount;
}

/**
 * Обновление памяти
 */
async function updateMemory(
  projectPath: string,
  packageRoot: string,
  dryRun: boolean
): Promise<number>
{
  const memorySource = path.join(packageRoot, 'memory');
  const memoryDest = path.join(projectPath, '.specify', 'memory');

  if (!await fs.pathExists(memorySource))
  {
    console.log(chalk.yellow('  ⚠ Исходные файлы памяти не найдены'));
    return 0;
  }

  if (!dryRun)
  {
    await fs.copy(memorySource, memoryDest, { overwrite: true });
  }

  // Подсчет файлов памяти
  const files = await fs.readdir(memorySource);
  const memoryCount = files.filter(f => f.endsWith('.md')).length;

  console.log(chalk.gray(`  ✓ Обновлено ${memoryCount} файлов памяти`));

  return memoryCount;
}

/**
 * Обновление каталога spec (включая presets, правила анти-AI детекции и т. д.)
 */
async function updateSpec(
  projectPath: string,
  packageRoot: string,
  dryRun: boolean
): Promise<number>
{
  const specSource = path.join(packageRoot, 'spec');
  const specDest = path.join(projectPath, 'spec');

  if (!await fs.pathExists(specSource))
  {
    console.log(chalk.yellow('  ⚠ Исходные файлы spec не найдены'));
    return 0;
  }

  let count = 0;

  if (!dryRun)
  {
    // Обход каталога spec, обновление только presets, checklists, config.json и т. д.
    // Не перезаписывать tracking и knowledge (пользовательские данные)
    const specItems = await fs.readdir(specSource);
    for (const item of specItems)
    {
      if (item !== 'tracking' && item !== 'knowledge')
      {
        const sourcePath = path.join(specSource, item);
        const targetPath = path.join(specDest, item);
        await fs.copy(sourcePath, targetPath, { overwrite: true });

        // Подсчет файлов
        if (await fs.stat(sourcePath).then(s => s.isDirectory()))
        {
          const files = await fs.readdir(sourcePath);
          count += files.filter(f => f.endsWith('.md') || f.endsWith('.json')).length;
        } else
        {
          count += 1;
        }
      }
    }
  } else
  {
    // dry run - только подсчет
    const specItems = await fs.readdir(specSource);
    for (const item of specItems)
    {
      if (item !== 'tracking' && item !== 'knowledge')
      {
        const sourcePath = path.join(specSource, item);
        if (await fs.stat(sourcePath).then(s => s.isDirectory()))
        {
          const files = await fs.readdir(sourcePath);
          count += files.filter(f => f.endsWith('.md') || f.endsWith('.json')).length;
        } else
        {
          count += 1;
        }
      }
    }
  }

  console.log(chalk.gray(`  ✓ Обновлено spec/ (${count} файлов, включая presets)`));

  return count;
}

/**
 * Обновление файлов экспертного режима
 */
async function updateExperts(
  projectPath: string,
  packageRoot: string,
  dryRun: boolean
): Promise<number>
{
  const expertsSource = path.join(packageRoot, 'experts');
  const expertsDest = path.join(projectPath, '.specify', 'experts');

  // Проверка, установлен ли экспертный режим в проекте
  if (!await fs.pathExists(expertsDest))
  {
    console.log(chalk.gray('  ⓘ Экспертный режим не установлен в проекте, пропуск'));
    return 0;
  }

  if (!await fs.pathExists(expertsSource))
  {
    console.log(chalk.yellow('  ⚠ Исходные файлы экспертов не найдены'));
    return 0;
  }

  if (!dryRun)
  {
    await fs.copy(expertsSource, expertsDest, { overwrite: true });
  }

  // Подсчет файлов экспертов
  const countFiles = async (dir: string): Promise<number> =>
  {
    let count = 0;
    const items = await fs.readdir(dir);
    for (const item of items)
    {
      const itemPath = path.join(dir, item);
      const stat = await fs.stat(itemPath);
      if (stat.isDirectory())
      {
        count += await countFiles(itemPath);
      } else if (item.endsWith('.md'))
      {
        count += 1;
      }
    }
    return count;
  };

  const expertsCount = await countFiles(expertsSource);

  console.log(chalk.gray(`  ✓ Обновлено ${expertsCount} файлов экспертов`));

  return expertsCount;
}

/**
 * Создание выборочной резервной копии
 */
async function createBackup(
  projectPath: string,
  updateContent: UpdateContent,
  targetAI: string[],
  projectVersion: string
): Promise<string>
{
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
  const backupPath = path.join(projectPath, 'backup', timestamp);
  await fs.ensureDir(backupPath);

  console.log(chalk.cyan('📦 Создание резервной копии...'));

  // Резервное копирование файлов команд
  if (updateContent.commands)
  {
    for (const ai of targetAI)
    {
      const aiConfig = AI_CONFIGS.find(c => c.name === ai);
      if (!aiConfig) continue;

      const source = path.join(projectPath, aiConfig.dir);
      const dest = path.join(backupPath, aiConfig.dir);

      if (await fs.pathExists(source))
      {
        await fs.copy(source, dest);
        console.log(chalk.gray(`  ✓ Резервная копия ${aiConfig.dir}/`));
      }
    }
  }

  // Резервное копирование скриптов
  if (updateContent.scripts)
  {
    const scriptsSource = path.join(projectPath, '.specify', 'scripts');
    if (await fs.pathExists(scriptsSource))
    {
      await fs.copy(scriptsSource, path.join(backupPath, '.specify', 'scripts'));
      console.log(chalk.gray('  ✓ Резервная копия .specify/scripts/'));
    }
  }

  // Резервное копирование шаблонов
  if (updateContent.templates)
  {
    const templatesSource = path.join(projectPath, '.specify', 'templates');
    if (await fs.pathExists(templatesSource))
    {
      await fs.copy(templatesSource, path.join(backupPath, '.specify', 'templates'));
      console.log(chalk.gray('  ✓ Резервная копия .specify/templates/'));
    }
  }

  // Резервное копирование памяти
  if (updateContent.memory)
  {
    const memorySource = path.join(projectPath, '.specify', 'memory');
    if (await fs.pathExists(memorySource))
    {
      await fs.copy(memorySource, path.join(backupPath, '.specify', 'memory'));
      console.log(chalk.gray('  ✓ Резервная копия .specify/memory/'));
    }
  }

  // Сохранение информации о резервной копии
  const backupInfo = {
    timestamp,
    fromVersion: projectVersion,
    toVersion: getVersion(),
    upgradedAI: targetAI,
    updateContent,
    backupPath
  };
  await fs.writeJson(path.join(backupPath, 'BACKUP_INFO.json'), backupInfo, { spaces: 2 });

  console.log(chalk.green(`✓ Резервное копирование завершено: ${backupPath}\n`));

  return backupPath;
}

/**
 * Отображение отчета об обновлении
 */
function displayUpgradeReport(
  stats: UpgradeStats,
  projectVersion: string,
  backupPath: string,
  updateContent: UpdateContent
): void
{
  console.log(chalk.cyan('\n📊 Отчет об обновлении\n'));
  console.log(chalk.green('✅ Обновление завершено!\n'));

  console.log(chalk.yellow('Статистика обновления:'));
  console.log(`  • Версия: ${projectVersion} → ${getVersion()}`);
  console.log(`  • Платформы ИИ: ${stats.platforms.join(', ')}`);

  if (updateContent.commands && stats.commands > 0)
  {
    console.log(`  • Файлы команд: ${stats.commands} шт.`);
  }
  if (updateContent.scripts && stats.scripts > 0)
  {
    console.log(`  • Файлы скриптов: ${stats.scripts} шт.`);
  }
  if (updateContent.spec && stats.spec > 0)
  {
    console.log(`  • Правила написания и пресеты: ${stats.spec} шт.`);
  }
  if (updateContent.experts && stats.experts > 0)
  {
    console.log(`  • Файлы экспертного режима: ${stats.experts} шт.`);
  }
  if (updateContent.templates && stats.templates > 0)
  {
    console.log(`  • Файлы шаблонов: ${stats.templates} шт.`);
  }
  if (updateContent.memory && stats.memory > 0)
  {
    console.log(`  • Файлы памяти: ${stats.memory} шт.`);
  }

  if (backupPath)
  {
    console.log(chalk.gray(`\n📦 Местоположение резервной копии: ${backupPath}`));
    console.log(chalk.gray('   Для отката удалите текущие файлы и восстановите из резервной копии'));
  }

  console.log(chalk.cyan('\n✨ Обновление включает:'));
  console.log('  • Правила анти-AI детекции: Руководство по написанию с 0% ИИ-концентрацией, протестированное на реальных данных Zhuque');
  console.log('  • Улучшения экспертного режима: Основная экспертная система (персонажи, сюжет, стиль, мировоззрение)');
  console.log('  • Контроль температуры ИИ: Добавлены инструкции по усилению творчества в команду write');
  console.log('  • Поддержка нескольких платформ: Обновлены команды для всех 13 платформ ИИ');

  console.log(chalk.gray('\n📚 Просмотрите подробное руководство по обновлению: docs/upgrade-guide.md'));
  console.log(chalk.gray('   Или посетите: https://github.com/wordflowlab/novel-writer/blob/main/docs/upgrade-guide.md'));
}

// Команда upgrade - обновление существующего проекта
program
  .command('upgrade')
  .option('--ai <type>', 'Указать конфигурацию ИИ для обновления: claude | cursor | gemini | windsurf | roocode | copilot | qwen | opencode | codex | kilocode | auggie | codebuddy | q')
  .option('--all', 'Обновить все конфигурации ИИ')
  .option('-i, --interactive', 'Интерактивный выбор обновляемого контента')
  .option('--commands', 'Обновить только файлы команд')
  .option('--scripts', 'Обновить только файлы скриптов')
  .option('--spec', 'Обновить только правила написания и пресеты')
  .option('--experts', 'Обновить только файлы экспертного режима')
  .option('--templates', 'Обновить только файлы шаблонов')
  .option('--memory', 'Обновить только файлы памяти')
  .option('-y, --yes', 'Пропустить подтверждение')
  .option('--no-backup', 'Пропустить резервное копирование')
  .option('--dry-run', 'Предварительный просмотр обновлений без фактического изменения')
  .description('Обновить существующий проект до последней версии')
  .action(async (options) =>
  {
    const projectPath = process.cwd();
    const packageRoot = path.resolve(__dirname, '..');

    try
    {
      // 1. Проверка проекта
      const configPath = path.join(projectPath, '.specify', 'config.json');
      if (!await fs.pathExists(configPath))
      {
        console.log(chalk.red('❌ Текущий каталог не является проектом novel-writer'));
        console.log(chalk.gray('   Запустите эту команду в корневом каталоге проекта или используйте novel init для создания нового проекта'));
        process.exit(1);
      }

      // Чтение конфигурации проекта
      const config = await fs.readJson(configPath);
      const projectVersion = config.version || 'Неизвестно';

      console.log(chalk.cyan('\n📦 Обновление проекта Novel Writer\n'));
      console.log(chalk.gray(`Текущая версия: ${projectVersion}`));
      console.log(chalk.gray(`Целевая версия: ${getVersion()}\n`));

      // 2. Определение установленных конфигураций ИИ
      const installedAI: string[] = [];
      for (const aiConfig of AI_CONFIGS)
      {
        if (await fs.pathExists(path.join(projectPath, aiConfig.dir)))
        {
          installedAI.push(aiConfig.name);
        }
      }

      if (installedAI.length === 0)
      {
        console.log(chalk.yellow('⚠️  Не обнаружено ни одной директории с конфигурацией ИИ'));
        process.exit(1);
      }

      const displayNames = installedAI.map(name =>
      {
        const config = AI_CONFIGS.find(c => c.name === name);
        return config?.displayName || name;
      });

      console.log(chalk.green('✓') + ' Обнаружены конфигурации ИИ: ' + displayNames.join(', '));

      // 3. Определение целевых конфигураций ИИ для обновления
      let targetAI = installedAI;
      if (options.ai)
      {
        if (!installedAI.includes(options.ai))
        {
          console.log(chalk.red(`❌ Конфигурация ИИ "${options.ai}" не установлена`));
          process.exit(1);
        }
        targetAI = [options.ai];
      } else if (!options.all)
      {
        // По умолчанию обновляем все установленные конфигурации ИИ
        targetAI = installedAI;
      }

      const targetDisplayNames = targetAI.map(name =>
      {
        const config = AI_CONFIGS.find(c => c.name === name);
        return config?.displayName || name;
      });

      console.log(chalk.cyan(`\nЦель обновления: ${targetDisplayNames.join(', ')}\n`));

      // 4. Определение обновляемого контента
      let updateContent: UpdateContent;

      if (options.interactive)
      {
        // Интерактивный выбор
        updateContent = await selectUpdateContentInteractive();
      } else
      {
        // Определение контента для обновления на основе опций
        const hasSpecificOption = options.commands || options.scripts || options.spec || options.experts || options.templates || options.memory;

        updateContent = {
          commands: hasSpecificOption ? !!options.commands : true,
          scripts: hasSpecificOption ? !!options.scripts : true,
          spec: hasSpecificOption ? !!options.spec : true,
          experts: hasSpecificOption ? !!options.experts : false,
          templates: hasSpecificOption ? !!options.templates : false,
          memory: hasSpecificOption ? !!options.memory : false
        };
      }

      // Отображение обновляемого контента
      const updateList: string[] = [];
      if (updateContent.commands) updateList.push('файлы команд');
      if (updateContent.scripts) updateList.push('файлы скриптов');
      if (updateContent.spec) updateList.push('спецификации и пресеты для письма');
      if (updateContent.experts) updateList.push('режим эксперта');
      if (updateContent.templates) updateList.push('файлы шаблонов');
      if (updateContent.memory) updateList.push('файлы памяти');

      console.log(chalk.cyan(`Обновляемый контент: ${updateList.join(', ')}\n`));

      if (options.dryRun)
      {
        console.log(chalk.yellow('🔍 Режим предварительного просмотра (файлы не будут изменены)\n'));
      }

      // 5. Подтверждение выполнения
      if (!options.yes && !options.dryRun && !options.interactive)
      {
        const inquirer = (await import('inquirer')).default;
        const answers = await inquirer.prompt([
          {
            type: 'confirm',
            name: 'proceed',
            message: 'Подтвердите выполнение обновления?',
            default: true
          }
        ]);

        if (!answers.proceed)
        {
          console.log(chalk.yellow('\nОбновление отменено'));
          process.exit(0);
        }
      }

      // 6. Создание резервной копии
      let backupPath = '';
      if (options.backup !== false && !options.dryRun)
      {
        backupPath = await createBackup(projectPath, updateContent, targetAI, projectVersion);
      }

      // 7. Выполнение обновления
      const stats: UpgradeStats = {
        commands: 0,
        scripts: 0,
        templates: 0,
        memory: 0,
        spec: 0,
        experts: 0,
        platforms: targetDisplayNames
      };

      const dryRun = !!options.dryRun;

      if (updateContent.commands)
      {
        console.log(chalk.cyan('📝 Обновление файлов команд...'));
        stats.commands = await updateCommands(targetAI, projectPath, packageRoot, dryRun);
      }

      if (updateContent.scripts)
      {
        console.log(chalk.cyan('\n🔧 Обновление файлов скриптов...'));
        stats.scripts = await updateScripts(projectPath, packageRoot, dryRun);
      }

      if (updateContent.spec)
      {
        console.log(chalk.cyan('\n📋 Обновление спецификаций и пресетов для письма...'));
        stats.spec = await updateSpec(projectPath, packageRoot, dryRun);
      }

      if (updateContent.experts)
      {
        console.log(chalk.cyan('\n🎓 Обновление файлов режима эксперта...'));
        stats.experts = await updateExperts(projectPath, packageRoot, dryRun);
      }

      if (updateContent.templates)
      {
        console.log(chalk.cyan('\n📄 Обновление файлов шаблонов...'));
        stats.templates = await updateTemplates(projectPath, packageRoot, dryRun);
      }

      if (updateContent.memory)
      {
        console.log(chalk.cyan('\n🧠 Обновление файлов памяти...'));
        stats.memory = await updateMemory(projectPath, packageRoot, dryRun);
      }

      // 8. Отображение отчета об обновлении
      displayUpgradeReport(stats, projectVersion, backupPath, updateContent);

      // 9. Обновление номера версии проекта
      if (!options.dryRun)
      {
        config.version = getVersion();
        await fs.writeJson(configPath, config, { spaces: 2 });
      }

    } catch (error)
    {
      console.error(chalk.red('\n❌ Обновление не удалось:'), error);
      process.exit(1);
    }
  });

// Команда info - просмотр информации о методах (простая версия)
program
  .command('info')
  .description('Просмотр доступных методов письма')
  .action(() =>
  {
    console.log(chalk.cyan('\n📚 Доступные методы письма:\n'));
    console.log(chalk.yellow('  Структура из трех актов') + ' - Классическая структура истории, подходит для большинства жанров');
    console.log(chalk.yellow('  Путешествие героя') + ' - 12-этапное путешествие роста, подходит для фэнтези и приключений');
    console.log(chalk.yellow('  Круг историй') + ' - 8-этапная циклическая структура, подходит для историй, ориентированных на персонажей');
    console.log(chalk.yellow('  Семиточечная структура') + ' - Компактная структура сюжета, подходит для триллеров и детективов');
    console.log(chalk.yellow('  Формула Пиксар') + ' - Простой и мощный шаблон истории, подходит для коротких рассказов');
    console.log(chalk.yellow('  Снежинка в десять шагов') + ' - Систематическое пошаговое планирование, подходит для детального построения');
    console.log('\n' + chalk.gray('Подсказка: Используйте команду /method в ИИ-помощнике для интеллектуального выбора'));
    console.log(chalk.gray('ИИ-помощник поймет ваши потребности через диалог и порекомендует наиболее подходящий метод'));
    console.log(chalk.gray('Система отслеживания будет автоматически обновляться во время написания для синхронизации данных'));
  });

// Пользовательская помощь
program.on('--help', () =>
{
  console.log('');
  console.log(chalk.yellow('Примеры использования:'));
  console.log('');
  console.log('  $ novel init my-story           # Создать новый проект');
  console.log('  $ novel init --here              # Инициализировать в текущем каталоге');
  console.log('  $ novel check                    # Проверить окружение');
  console.log('  $ novel info                     # Просмотреть методы письма');
  console.log('');
  console.log(chalk.cyan('Основные команды для создания контента:'));
  console.log('  /method      - Интеллектуальный выбор метода письма (рекомендуется выполнить первым)');
  console.log('  /style       - Установка стиля и правил письма');
  console.log('  /story       - Создание синопсиса истории (с использованием выбранного метода)');
  console.log('  /outline     - Планирование структуры глав (на основе шаблона метода)');
  console.log('  /track-init  - Инициализация системы отслеживания');
  console.log('  /write       - Создание глав с помощью ИИ (автоматическое обновление отслеживания)');
  console.log('');
  console.log(chalk.cyan('Команды управления отслеживанием:'));
  console.log('  /plot-check  - Интеллектуальная проверка согласованности развития сюжета');
  console.log('  /timeline    - Управление и проверка временной шкалы');
  console.log('  /relations   - Отслеживание изменений в отношениях персонажей');
  console.log('  /track       - Комплексное отслеживание и интеллектуальный анализ');
  console.log('');
  console.log(chalk.gray('Дополнительная информация: https://github.com/wordflowlab/novel-writer'));
});

// Парсинг аргументов командной строки
program.parse(process.argv);

// Если не указана ни одна команда, отобразить справку
if (!process.argv.slice(2).length)
{
  program.outputHelp();
}