import fs from 'fs-extra';
import path from 'path';
import yaml from 'js-yaml';
import { logger } from '../utils/logger.js';

interface PluginConfig {
  name: string
  version: string
  description: string
  type: 'feature' | 'expert' | 'workflow'
  commands?: Array<{
    id: string
    file: string
    description: string
  }>
  experts?: Array<{
    id: string
    file: string
    title: string
    description: string
  }>
  dependencies?: {
    core: string
  }
  installation?: {
    files?: Array<{
      source: string
      target: string
      prefix?: string
    }>
    message?: string
  }
}

export class PluginManager {
  private pluginsDir: string
  private commandsDirs: {
    claude: string
    cursor: string
    gemini: string
    windsurf: string
    roocode: string
  }
  private expertsDir: string

  constructor(projectRoot: string) {
    this.pluginsDir = path.join(projectRoot, 'plugins')
    this.commandsDirs = {
      claude: path.join(projectRoot, '.claude', 'commands'),
      cursor: path.join(projectRoot, '.cursor', 'commands'),
      gemini: path.join(projectRoot, '.gemini', 'commands'),
      windsurf: path.join(projectRoot, '.windsurf', 'workflows'),
      roocode: path.join(projectRoot, '.roo', 'commands')
    }
    this.expertsDir = path.join(projectRoot, 'experts')
  }

  /**
   * Сканирует и загружает все плагины
   */
  async loadPlugins(): Promise<void> {
    try {
      // Убедиться, что директория плагинов существует
      await fs.ensureDir(this.pluginsDir)

      // Сканировать директорию плагинов
      const plugins = await this.scanPlugins()

      if (plugins.length === 0) {
        logger.info('Плагины не найдены')
        return
      }

      logger.info(`Найдено ${plugins.length} плагинов`)

      // Загрузить каждый плагин
      for (const pluginName of plugins) {
        await this.loadPlugin(pluginName)
      }

      logger.success('Все плагины загружены')
    } catch (error) {
      logger.error('Ошибка загрузки плагинов:', error)
    }
  }

  /**
   * Сканирует директорию плагинов, возвращает имена всех плагинов
   */
  private async scanPlugins(): Promise<string[]> {
    try {
      // Проверить, существует ли директория плагинов
      if (!await fs.pathExists(this.pluginsDir)) {
        return []
      }

      const entries = await fs.promises.readdir(this.pluginsDir, { withFileTypes: true })

      // Отфильтровать директории, содержащие config.yaml
      const plugins = []
      for (const entry of entries) {
        if (entry.isDirectory()) {
          const configPath = path.join(this.pluginsDir, entry.name, 'config.yaml')
          if (await fs.pathExists(configPath)) {
            plugins.push(entry.name)
          }
        }
      }

      return plugins
    } catch (error) {
      logger.error('Ошибка сканирования директории плагинов:', error)
      return []
    }
  }

  /**
   * Загружает отдельный плагин
   */
  private async loadPlugin(pluginName: string): Promise<void> {
    try {
      logger.info(`Загрузка плагина: ${pluginName}`)

      // Читать конфигурацию плагина
      const configPath = path.join(this.pluginsDir, pluginName, 'config.yaml')
      const config = await this.loadConfig(configPath)

      if (!config) {
        logger.warn(`Недействительная конфигурация плагина ${pluginName}`)
        return
      }

      // Проверить зависимости
      if (!this.checkDependencies(config)) {
        logger.warn(`Не выполнены зависимости плагина ${pluginName}`)
        return
      }

      // Внедрить команды
      if (config.commands && config.commands.length > 0) {
        await this.injectCommands(pluginName, config.commands)
      }

      // Зарегистрировать экспертов
      if (config.experts && config.experts.length > 0) {
        await this.registerExperts(pluginName, config.experts)
      }

      logger.success(`Плагин ${pluginName} успешно загружен`)

      // Показать информацию об установке
      if (config.installation?.message) {
        console.log(config.installation.message)
      }
    } catch (error) {
      logger.error(`Ошибка загрузки плагина ${pluginName}:`, error)
    }
  }

  /**
   * Читает и парсит конфигурацию плагина
   */
  private async loadConfig(configPath: string): Promise<PluginConfig | null> {
    try {
      const content = await fs.readFile(configPath, 'utf-8')
      const config = yaml.load(content) as PluginConfig

      // Проверить обязательные поля
      if (!config.name || !config.version) {
        return null
      }

      return config
    } catch (error) {
      logger.error(`Ошибка чтения файла конфигурации: ${configPath}`, error)
      return null
    }
  }

  /**
   * Проверяет зависимости плагина
   */
  private checkDependencies(config: PluginConfig): boolean {
    if (!config.dependencies) {
      return true
    }

    // Проверить зависимость версии ядра
    if (config.dependencies.core) {
      // Здесь упрощенная обработка, в реальности следует сравнивать номера версий
      // Можно использовать библиотеку semver для сравнения версий
      const requiredVersion = config.dependencies.core
      logger.debug(`Требуется версия ядра: ${requiredVersion}`)
      // TODO: Реализовать логику сравнения версий
    }

    return true
  }

  /**
   * Определяет поддерживаемые ИИ проекта
   */
  private async detectSupportedAIs(): Promise<{
    claude: boolean
    cursor: boolean
    gemini: boolean
    windsurf: boolean
    roocode: boolean
  }> {
    return {
      claude: await fs.pathExists(this.commandsDirs.claude),
      cursor: await fs.pathExists(this.commandsDirs.cursor),
      gemini: await fs.pathExists(this.commandsDirs.gemini),
      windsurf: await fs.pathExists(this.commandsDirs.windsurf),
      roocode: await fs.pathExists(this.commandsDirs.roocode)
    }
  }

  /**
   * Внедряет команды плагина в соответствующие директории ИИ
   */
  private async injectCommands(
    pluginName: string,
    commands: PluginConfig['commands']
  ): Promise<void> {
    if (!commands) return

    // Определить, какие ИИ поддерживает проект
    const supportedAIs = await this.detectSupportedAIs()

    for (const cmd of commands) {
      try {
        // Обработка формата Markdown (Claude, Cursor, Windsurf)
        const sourcePath = path.join(this.pluginsDir, pluginName, cmd.file)

        if (supportedAIs.claude) {
          const destPath = path.join(this.commandsDirs.claude, `${cmd.id}.md`)
          await fs.ensureDir(this.commandsDirs.claude)
          await fs.copy(sourcePath, destPath)
          logger.debug(`Внедрена команда в Claude: /${cmd.id}`)
        }

        if (supportedAIs.cursor) {
          const destPath = path.join(this.commandsDirs.cursor, `${cmd.id}.md`)
          await fs.ensureDir(this.commandsDirs.cursor)
          await fs.copy(sourcePath, destPath)
          logger.debug(`Внедрена команда в Cursor: /${cmd.id}`)
        }

        if (supportedAIs.windsurf) {
          const destPath = path.join(this.commandsDirs.windsurf, `${cmd.id}.md`)
          await fs.ensureDir(this.commandsDirs.windsurf)
          await fs.copy(sourcePath, destPath)
          logger.debug(`Внедрена команда в Windsurf: /${cmd.id}`)
        }

        if (supportedAIs.roocode) {
          const destPath = path.join(this.commandsDirs.roocode, `${cmd.id}.md`)
          await fs.ensureDir(this.commandsDirs.roocode)
          await fs.copy(sourcePath, destPath)
          logger.debug(`Внедрена команда в Roo Code: /${cmd.id}`)
        }

        // Обработка формата TOML (Gemini)
        if (supportedAIs.gemini) {
          // Проверить наличие предопределенной версии TOML
          const cmdId = path.basename(cmd.id, path.extname(cmd.id))
          const tomlSourcePath = path.join(this.pluginsDir, pluginName, 'commands-gemini', `${cmdId}.toml`)

          if (await fs.pathExists(tomlSourcePath)) {
            const destPath = path.join(this.commandsDirs.gemini, `${cmdId}.toml`)
            await fs.ensureDir(this.commandsDirs.gemini)
            await fs.copy(tomlSourcePath, destPath)
            logger.debug(`Внедрена команда в Gemini: /${cmdId} (TOML)`)
          } else {
            // Если предопределенный TOML отсутствует, попытаться преобразовать из Markdown
            try {
              const mdContent = await fs.readFile(sourcePath, 'utf-8')
              const tomlContent = this.convertMarkdownToToml(mdContent, cmd)
              if (tomlContent) {
                const destPath = path.join(this.commandsDirs.gemini, `${cmdId}.toml`)
                await fs.ensureDir(this.commandsDirs.gemini)
                await fs.writeFile(destPath, tomlContent)
                logger.debug(`Автоматически преобразована и внедрена команда в Gemini: /${cmdId}`)
              } else {
                logger.debug(`Команда ${cmdId} плагина ${pluginName} не может быть преобразована в TOML`)
              }
            } catch (err) {
              logger.debug(`Ошибка преобразования команды ${cmdId} плагина ${pluginName} в TOML: ${err}`)
            }
          }
        }
      } catch (error) {
        logger.error(`Ошибка внедрения команды ${cmd.id}:`, error)
      }
    }
  }

  /**
   * Регистрирует экспертов плагина
   */
  private async registerExperts(
    pluginName: string,
    experts: PluginConfig['experts']
  ): Promise<void> {
    if (!experts) return

    const pluginExpertsDir = path.join(this.expertsDir, 'plugins', pluginName)
    await fs.ensureDir(pluginExpertsDir)

    for (const expert of experts) {
      try {
        const sourcePath = path.join(this.pluginsDir, pluginName, expert.file)
        const destPath = path.join(pluginExpertsDir, `${expert.id}.md`)

        // Копировать файл эксперта
        await fs.copy(sourcePath, destPath)
        logger.debug(`Зарегистрирован эксперт: ${expert.title} (${expert.id})`)
      } catch (error) {
        logger.error(`Ошибка регистрации эксперта ${expert.id}:`, error)
      }
    }
  }

  /**
   * Выводит список всех установленных плагинов
   */
  async listPlugins(): Promise<PluginConfig[]> {
    const plugins = await this.scanPlugins()
    const configs: PluginConfig[] = []

    for (const pluginName of plugins) {
      const configPath = path.join(this.pluginsDir, pluginName, 'config.yaml')
      const config = await this.loadConfig(configPath)
      if (config) {
        configs.push(config)
      }
    }

    return configs
  }

  /**
   * Устанавливает плагин (из шаблона или удаленно)
   */
  async installPlugin(pluginName: string, source?: string): Promise<void> {
    try {
      logger.info(`Установка плагина: ${pluginName}`)

      // Если указан исходный путь, скопировать из источника
      if (source) {
        const destPath = path.join(this.pluginsDir, pluginName)
        await fs.copy(source, destPath)
      } else {
        // TODO: Реализовать установку из удаленного репозитория или реестра
        logger.warn('Функция удаленной установки еще не реализована')
        return
      }

      // Загрузить только что установленный плагин
      await this.loadPlugin(pluginName)
      logger.success(`Плагин ${pluginName} успешно установлен`)
    } catch (error) {
      logger.error(`Ошибка установки плагина ${pluginName}:`, error)
    }
  }

  /**
   * Удаляет плагин
   */
  async removePlugin(pluginName: string): Promise<void> {
    try {
      logger.info(`Удаление плагина: ${pluginName}`)

      // Удалить директорию плагина
      const pluginPath = path.join(this.pluginsDir, pluginName)
      await fs.remove(pluginPath)

      // Удалить внедренные команды (из всех директорий ИИ)
      const supportedAIs = await this.detectSupportedAIs()

      if (supportedAIs.claude && await fs.pathExists(this.commandsDirs.claude)) {
        const commandFiles = await fs.promises.readdir(this.commandsDirs.claude)
        for (const file of commandFiles) {
          if (file.startsWith(`plugin-${pluginName}-`)) {
            await fs.remove(path.join(this.commandsDirs.claude, file))
            logger.debug(`Удален файл команды: ${file}`)
          }
        }
      }

      // Выполнить ту же очистку для других директорий ИИ
      for (const [aiType, dir] of Object.entries(this.commandsDirs)) {
        if (aiType !== 'claude' && await fs.pathExists(dir)) {
          const commandFiles = await fs.promises.readdir(dir)
          for (const file of commandFiles) {
            if (file.startsWith(`plugin-${pluginName}-`)) {
              await fs.remove(path.join(dir, file))
              logger.debug(`Удален файл команды ${aiType}: ${file}`)
            }
          }
        }
      }
      // Удаление зарегистрированных экспертов
      const pluginExpertsDir = path.join(this.expertsDir, 'plugins', pluginName)
      if (await fs.pathExists(pluginExpertsDir)) {
        await fs.remove(pluginExpertsDir)
        logger.debug(`Удалена директория экспертов: ${pluginExpertsDir}`)
      }

      logger.success(`Плагин ${pluginName} успешно удалён`)
    } catch (error) {
      logger.error(`Ошибка при удалении плагина ${pluginName}:`, error)
    }
  }

  /**
   * Преобразование команды Markdown в формат TOML
   */
  private convertMarkdownToToml(mdContent: string, cmd: any): string | null {
    try {
      // Извлечение frontmatter
      const frontmatterMatch = mdContent.match(/^---\n([\s\S]*?)\n---/)
      let description = cmd.description || ''

      if (frontmatterMatch) {
        const yamlContent = frontmatterMatch[1]
        const descMatch = yamlContent.match(/description:\s*(.+)/)
        if (descMatch) {
          description = descMatch[1].trim().replace(/^['"]|['"]$/g, '')
        }
      }

      // Извлечение содержимого (удаление frontmatter)
      const content = mdContent.replace(/^---\n[\s\S]*?\n---\n/, '')

      // Формирование содержимого TOML
      const tomlContent = `description = "${description}"

prompt = """
${content}

Ввод пользователя: {{args}}
"""`

      return tomlContent
    } catch (error) {
      return null
    }
  }

  /**
   * Обновление плагина
   */
  async updatePlugin(pluginName: string, source?: string): Promise<void> {
    logger.info(`Обновление плагина: ${pluginName}`)

    // Сначала удаляем старую версию
    await this.removePlugin(pluginName)

    // Устанавливаем новую версию
    await this.installPlugin(pluginName, source)
  }
}