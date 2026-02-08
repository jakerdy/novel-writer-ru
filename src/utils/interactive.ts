#!/usr/bin/env node
/**
 * Интерактивные утилиты выбора для Novel Writer
 * Предоставляет интерфейс выбора на основе клавиш со стрелками, аналогичный spec-kit
 */

import inquirer from 'inquirer';
import chalk from 'chalk';

export interface AIConfig {
  name: string;
  dir: string;
  commandsDir: string;
  displayName: string;
  extraDirs?: string[];
}

/**
 * Отображение баннера проекта
 */
export function displayProjectBanner(): void {
  console.log('');
  console.log(chalk.cyan.bold('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
  console.log(chalk.cyan.bold('  Novel Writer - Инструмент для создания китайских романов на базе ИИ'));
  console.log(chalk.cyan.bold('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
  console.log('');
}

/**
 * Интерактивный выбор ИИ-ассистента
 */
export async function selectAIAssistant(aiConfigs: AIConfig[]): Promise<string> {
  const choices = aiConfigs.map(config => ({
    name: `${chalk.cyan(config.name.padEnd(12))} ${chalk.dim(`(${config.displayName})`)}`,
    value: config.name,
    short: config.name
  }));

  const answer = await inquirer.prompt([
    {
      type: 'list',
      name: 'ai',
      message: chalk.bold('Выберите вашего ИИ-ассистента:'),
      choices,
      default: 'claude',
      pageSize: 15
    }
  ]);

  return answer.ai;
}

/**
 * Интерактивный выбор метода написания
 */
export async function selectWritingMethod(): Promise<string> {
  const methodChoices = [
    {
      name: `${chalk.cyan('three-act'.padEnd(15))} ${chalk.dim('(Трёхактная структура - классическая структура сюжета)')}`,
      value: 'three-act',
      short: 'three-act'
    },
    {
      name: `${chalk.cyan('hero-journey'.padEnd(15))} ${chalk.dim('(Путешествие героя - 12 этапов роста)')}`,
      value: 'hero-journey',
      short: 'hero-journey'
    },
    {
      name: `${chalk.cyan('story-circle'.padEnd(15))} ${chalk.dim('(Круг истории - 8-этапный цикл)')}`,
      value: 'story-circle',
      short: 'story-circle'
    },
    {
      name: `${chalk.cyan('seven-point'.padEnd(15))} ${chalk.dim('(Семиточечная структура - компактный сюжет)')}`,
      value: 'seven-point',
      short: 'seven-point'
    },
    {
      name: `${chalk.cyan('pixar'.padEnd(15))} ${chalk.dim('(Формула Pixar - простая и сильная)')}`,
      value: 'pixar',
      short: 'pixar'
    },
    {
      name: `${chalk.cyan('snowflake'.padEnd(15))} ${chalk.dim('(Снежинка - систематическое планирование)')}`,
      value: 'snowflake',
      short: 'snowflake'
    }
  ];

  const answer = await inquirer.prompt([
    {
      type: 'list',
      name: 'method',
      message: chalk.bold('Выберите метод написания:'),
      choices: methodChoices,
      default: 'three-act'
    }
  ]);

  return answer.method;
}

/**
 * Интерактивный выбор типа скрипта
 */
export async function selectScriptType(): Promise<string> {
  const scriptChoices = [
    {
      name: `${chalk.cyan('sh'.padEnd(12))} ${chalk.dim('(POSIX Shell - macOS/Linux)')}`,
      value: 'sh',
      short: 'sh'
    },
    {
      name: `${chalk.cyan('ps'.padEnd(12))} ${chalk.dim('(PowerShell - Windows)')}`,
      value: 'ps',
      short: 'ps'
    }
  ];

  const answer = await inquirer.prompt([
    {
      type: 'list',
      name: 'scriptType',
      message: chalk.bold('Выберите тип скрипта:'),
      choices: scriptChoices,
      default: 'sh'
    }
  ]);

  return answer.scriptType;
}

/**
 * Подтверждение экспертного режима
 */
export async function confirmExpertMode(): Promise<boolean> {
  const answer = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'experts',
      message: chalk.bold('Вы хотите включить экспертный режим?'),
      default: false
    }
  ]);

  return answer.experts;
}

/**
 * Отображение шага инициализации
 */
export function displayStep(step: number, total: number, message: string): void {
  console.log(chalk.dim(`[${step}/${total}]`) + ' ' + message);
}

/**
 * Проверка, запущен ли интерактивный терминал
 */
export function isInteractive(): boolean {
  return process.stdin.isTTY === true && process.stdout.isTTY === true;
}