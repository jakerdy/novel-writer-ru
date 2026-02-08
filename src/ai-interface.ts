/**
 * AI Interface Layer
 * Provides a simplified functional call interface for AI assistants
 * Supports natural language parameters and guided interaction
 */

import { MethodAdvisor } from './method-advisor.js';
import { MethodConverter } from './method-converter.js';
import { HybridMethodManager } from './hybrid-method.js';
import fs from 'fs-extra';
import path from 'path';

/**
 * AI-friendly parameter interface
 */
interface StoryContext {
  genre?: string;
  description?: string;
  estimatedLength?: string;
  targetAudience?: string;
  tone?: string;
  themes?: string[];
}

/**
 * Method selection result
 */
interface MethodSelection {
  method: string;
  reason: string;
  template: string;
  tips: string[];
}

/**
 * Main class for AI Interface
 */
export class AIInterface {
  private advisor: MethodAdvisor;
  private converter: MethodConverter;
  private hybridManager: HybridMethodManager;

  constructor() {
    this.advisor = new MethodAdvisor();
    this.converter = new MethodConverter();
    this.hybridManager = new HybridMethodManager();
  }

  /**
   * Intelligently guides method selection
   * Called by AI after collecting information through dialogue
   */
  async guideMethodSelection(context: StoryContext): Promise<MethodSelection> {
    // Parse natural language parameters
    const features = this.parseContext(context);

    // Get recommendations
    const scores = this.advisor.recommend(features);
    const top = scores[0];

    // Load corresponding template
    const templatePath = await this.getMethodTemplate(top.method);

    return {
      method: top.method,
      reason: top.reasons.join('；'),
      template: templatePath,
      tips: this.getMethodTips(top.method)
    };
  }

  /**
   * Guided Q&A for information gathering
   * Returns questions to ask the user
   */
  getGuidingQuestions(): string[] {
    return [
      "What genre is this story? (Fantasy/Sci-Fi/Romance/Mystery/Realistic/Other)",
      "What is the estimated length? (Short story under 30k words / Novella around 100k words / Novel over 200k words)",
      "Who is the target audience? (Children/Teens/Adults/General)",
      "What kind of pacing do you want for the story? (Fast-paced and exciting / Steady progression / Slow and in-depth)",
      "What do you prioritize most? (Exciting plot / Rich characters / Profound themes)"
    ];
  }

  /**
   * Parses context into feature parameters
   */
  private parseContext(context: StoryContext): any {
    // Intelligent length parsing
    let length = 100000; // Default 100k words
    if (context.estimatedLength) {
      if (context.estimatedLength.includes('short')) length = 30000;
      else if (context.estimatedLength.includes('long')) length = 200000;
      else if (context.estimatedLength.includes('very long')) length = 500000;

      // Extract numbers
      const match = context.estimatedLength.match(/(\d+)/);
      if (match) {
        const num = parseInt(match[1]);
        if (context.estimatedLength.includes('万')) { // Ten thousand
          length = num * 10000;
        } else if (context.estimatedLength.includes('千')) { // Thousand
          length = num * 1000;
        } else {
          length = num;
        }
      }
    }

    // Intelligent pace parsing
    let pace = 'medium';
    if (context.tone?.includes('fast') || context.tone?.includes('exciting')) pace = 'fast';
    else if (context.tone?.includes('slow') || context.tone?.includes('deep')) pace = 'slow';

    // Intelligent complexity parsing
    let complexity = 'medium';
    if (length > 200000 || context.description?.includes('complex')) complexity = 'complex';
    else if (length < 50000 || context.description?.includes('simple')) complexity = 'simple';

    // Intelligent experience parsing (inferred from description)
    let experience = 'beginner';
    if (context.description?.includes('series') || complexity === 'complex') experience = 'intermediate';

    return {
      genre: context.genre || 'general',
      length,
      audience: context.targetAudience || 'general',
      experience,
      focus: this.parseFocus(context),
      pace,
      complexity
    };
  }

  /**
   * Parses the creative focus
   */
  private parseFocus(context: StoryContext): string {
    if (context.description?.includes('character') || context.description?.includes('characters')) {
      return 'character';
    }
    if (context.description?.includes('plot') || context.description?.includes('storyline')) {
      return 'plot';
    }
    if (context.themes && context.themes.length > 0) {
      return 'theme';
    }
    return 'balanced';
  }

  /**
   * Gets the template path for a given method
   */
  private async getMethodTemplate(method: string): Promise<string> {
    const methodMap: Record<string, string> = {
      'three-act': 'three-act',
      'hero-journey': 'hero-journey',
      'story-circle': 'story-circle',
      'seven-point': 'seven-point',
      'pixar-formula': 'pixar-formula'
    };

    const methodDir = methodMap[method] || 'three-act';
    return `spec/presets/${methodDir}/specification.md`;
  }

  /**
   * Gets usage tips for a method
   */
  private getMethodTips(method: string): string[] {
    const tips: Record<string, string[]> = {
      'three-act': [
        'Act 1 should quickly establish conflict',
        'Act 2 can feature multiple mini-climaxes to avoid dragging',
        'Act 3 should be concise and impactful'
      ],
      'hero-journey': [
        'Not all 12 stages need to be strictly followed',
        'Focus on the character\'s internal transformation',
        'The mentor figure can be diverse'
      ],
      'story-circle': [
        'The character\'s need must be strong enough',
        'Each step should drive internal change',
        'Nested loops can add depth'
      ],
      'seven-point': [
        'Ensure each point advances the story',
        'The midpoint must be a true turning point',
        'The tight ending is crucial, do not omit it'
      ],
      'pixar-formula': [
        'Keep it simple, avoid excessive description',
        'Emphasize clear connections in causality',
        'The ending should be satisfying but leave room for thought'
      ]
    };

    return tips[method] || ['Follow the basic structure of the method', 'Maintain story coherence'];
  }

  /**
   * Suggests intelligent conversion
   * Analyzes the current project and suggests whether conversion is needed
   */
  async suggestConversion(currentMethod: string, storyProgress: any): Promise<any> {
    // Analyze progress
    const hasContent = storyProgress.chapters && storyProgress.chapters.length > 0;

    if (!hasContent) {
      return {
        needConversion: false,
        reason: 'The project is just starting, you can switch methods directly'
      };
    }

    // Analyze content features
    const contentFeatures = this.analyzeContent(storyProgress);

    // Get recommended method
    const recommended = this.advisor.recommend(contentFeatures)[0];

    if (recommended.method === currentMethod) {
      return {
        needConversion: false,
        reason: 'The current method is already the most suitable'
      };
    }

    // Generate conversion plan
    const conversionMap = this.converter.convert(storyProgress, recommended.method);

    return {
      needConversion: true,
      targetMethod: recommended.method,
      reason: recommended.reasons[0],
      conversionMap,
      impact: this.assessConversionImpact(storyProgress, conversionMap)
    };
  }

  /**
   * Analyzes content features
   */
  private analyzeContent(progress: any): any {
    // Analyze based on actual content
    return {
      genre: progress.genre || 'general',
      length: progress.plannedLength || 100000,
      audience: progress.audience || 'general',
      experience: 'intermediate',
      focus: progress.focus || 'balanced',
      pace: progress.pace || 'medium',
      complexity: progress.complexity || 'medium'
    };
  }

  /**
   * Assesses conversion impact
   */
  private assessConversionImpact(progress: any, conversionMap: any): string {
    const chaptersWritten = progress.chapters?.filter((c: any) => c.written).length || 0;

    if (chaptersWritten === 0) {
      return 'No impact, writing has not started yet';
    } else if (chaptersWritten < 5) {
      return 'Minor impact, only a few chapters need adjustment';
    } else if (chaptersWritten < 20) {
      return 'Moderate impact, some content needs reorganization';
    } else {
      return 'Significant impact, it is recommended to complete the work with the current method';
    }
  }

  /**
   * Intelligent hybrid scheme generation
   * Automatically designs a hybrid scheme based on story characteristics
   */
  async designHybridScheme(context: StoryContext): Promise<any> {
    const features = this.parseContext(context);

    // Determine if hybrid is needed
    if (features.complexity === 'simple' || features.length < 50000) {
      return {
        needHybrid: false,
        reason: 'Simple stories can be handled with a single method',
        recommendation: this.advisor.recommend(features)[0].method
      };
    }

    // Recommend hybrid scheme
    const hybrid = this.hybridManager.recommendHybrid(
      features.genre,
      features.length,
      features.complexity
    );

    if (!hybrid) {
      return {
        needHybrid: false,
        reason: 'This type of story is suitable for a single method',
        recommendation: this.advisor.recommend(features)[0].method
      };
    }

    // Generate detailed scheme
    const structure = this.hybridManager.createHybridStructure(hybrid, {
      ...features,
      subPlots: context.description?.includes('subplots') ? ['subplot1'] : [],
      characters: context.description?.includes('ensemble') ? ['character1', 'character2'] : []
    });

    return {
      needHybrid: true,
      reason: this.getHybridReason(features),
      scheme: hybrid,
      structure,
      guidelines: structure.guidelines
    };
  }

  /**
   * Gets the reason for using a hybrid method
   */
  private getHybridReason(features: any): string {
    if (features.genre === 'fantasy' && features.length > 200000) {
      return 'Long fantasy stories benefit from the Hero\'s Journey for the main plot and the Story Circle for character development.';
    }
    if (features.genre === 'mystery' && features.complexity === 'complex') {
      return 'Complex mysteries are well-suited for the Seven-Point Structure to control pacing, with chapters organized using the Three-Act Structure.';
    }
    if (features.focus === 'character' && features.length > 150000) {
      return 'Character-driven novels benefit from hybrid methods, handling the main plot and character arcs separately.';
    }
    return 'The story is relatively complex, and a hybrid approach can better organize the structure.';
  }

  /**
   * Gets the current project configuration
   */
  async getCurrentConfig(): Promise<any> {
    const configPath = path.join(process.cwd(), '.specify', 'config.json');
    if (await fs.pathExists(configPath)) {
      return await fs.readJson(configPath);
    }
    return null;
  }

  /**
   * Updates the project method configuration
   */
  async updateProjectMethod(method: string | any): Promise<void> {
    const configPath = path.join(process.cwd(), '.specify', 'config.json');
    if (await fs.pathExists(configPath)) {
      const config = await fs.readJson(configPath);

      if (typeof method === 'string') {
        config.method = method;
      } else {
        // Hybrid method configuration
        config.method = 'hybrid';
        config.hybridScheme = method;
      }

      config.updatedAt = new Date().toISOString();
      await fs.writeJson(configPath, config, { spaces: 2 });
    }
  }

  /**
   * Gets the Chinese name of a method
   */
  getMethodDisplayName(method: string): string {
    const names: Record<string, string> = {
      'three-act': '三幕结构',
      'hero-journey': '英雄之旅',
      'story-circle': '故事圈',
      'seven-point': '七点结构',
      'pixar-formula': '皮克斯公式',
      'hybrid': '混合方法'
    };
    return names[method] || method;
  }
}

/**
 * Export a singleton instance for direct use by AI
 */
export const aiInterface = new AIInterface();