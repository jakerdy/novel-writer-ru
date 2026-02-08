/**
 * Система интеллектуальных рекомендаций по методам написания
 * Рекомендует наиболее подходящие методы написания на основе характеристик произведения
 */

interface StoryFeatures {
  genre: string;           // Жанр
  length: number;          // Предполагаемый объем (количество символов)
  audience: string;        // Целевая аудитория
  experience: string;      // Опыт автора
  focus: string;          // Основной акцент (сюжет/персонажи/тема)
  pace: string;           // Предпочтение темпа (быстрый/средний/медленный)
  complexity: string;     // Сложность (простая/средняя/сложная)
}

interface MethodScore {
  method: string;
  score: number;
  reasons: string[];
  pros: string[];
  cons: string[];
}

export class MethodAdvisor {
  private methodProfiles = {
    'three-act': {
      genres: ['Общий', 'Реализм', 'Любовь', 'История'],
      lengthRange: { min: 50000, max: 500000 },
      audiences: ['Массовая', 'Взрослая', 'Подростковая'],
      experience: ['Начинающий', 'Средний', 'Продвинутый'],
      focus: ['Баланс', 'Сюжет'],
      pace: ['Средний', 'Быстрый'],
      complexity: ['Простая', 'Средняя']
    },
    'hero-journey': {
      genres: ['Фэнтези', 'Научная фантастика', 'Приключения', 'Взросление'],
      lengthRange: { min: 100000, max: 1000000 },
      audiences: ['Подростковая', 'Взрослая', 'Любители фэнтези'],
      experience: ['Средний', 'Продвинутый'],
      focus: ['Персонажи', 'Взросление'],
      pace: ['Средний', 'Медленный'],
      complexity: ['Сложная']
    },
    'story-circle': {
      genres: ['Персонажи', 'Психология', 'Взросление', 'Серия'],
      lengthRange: { min: 30000, max: 200000 },
      audiences: ['Взрослая', 'Любители литературы'],
      experience: ['Средний', 'Продвинутый'],
      focus: ['Персонажи', 'Внутренний мир'],
      pace: ['Средний', 'Медленный'],
      complexity: ['Средняя']
    },
    'seven-point': {
      genres: ['Детектив', 'Триллер', 'Боевик', 'Коммерческий'],
      lengthRange: { min: 50000, max: 300000 },
      audiences: ['Массовая', 'Коммерческая аудитория'],
      experience: ['Начинающий', 'Средний'],
      focus: ['Сюжет', 'Напряжение'],
      pace: ['Быстрый', 'Средний'],
      complexity: ['Средняя']
    },
    'pixar-formula': {
      genres: ['Детский', 'Короткий', 'Теплый', 'Притча'],
      lengthRange: { min: 5000, max: 50000 },
      audiences: ['Детская', 'Семейная', 'Все возрасты'],
      experience: ['Начинающий'],
      focus: ['Эмоции', 'Лаконичность'],
      pace: ['Быстрый', 'Средний'],
      complexity: ['Простая']
    }
  };

  /**
   * Рекомендует наиболее подходящий метод написания
   */
  recommend(features: StoryFeatures): MethodScore[] {
    const scores: MethodScore[] = [];

    for (const [method, profile] of Object.entries(this.methodProfiles)) {
      const score = this.calculateScore(features, profile);
      const analysis = this.analyzeMatch(features, profile, method);

      scores.push({
        method,
        score: score.total,
        reasons: score.reasons,
        pros: analysis.pros,
        cons: analysis.cons
      });
    }

    // Сортировка по убыванию оценки
    return scores.sort((a, b) => b.score - a.score);
  }

  /**
   * Расчет оценки соответствия
   */
  private calculateScore(features: StoryFeatures, profile: any): { total: number; reasons: string[] } {
    let score = 0;
    const reasons: string[] = [];

    // Соответствие жанра (вес: 30)
    if (profile.genres.includes(features.genre) || profile.genres.includes('Общий')) {
      score += 30;
      reasons.push(`Очень подходит для жанра ${features.genre}`);
    } else {
      score += 10;
    }

    // Соответствие длины (вес: 20)
    if (features.length >= profile.lengthRange.min && features.length <= profile.lengthRange.max) {
      score += 20;
      reasons.push('Диапазон длины идеально соответствует');
    } else if (features.length < profile.lengthRange.min * 0.5 || features.length > profile.lengthRange.max * 2) {
      score -= 10;
      reasons.push('Длина не очень подходит');
    } else {
      score += 10;
    }

    // Соответствие аудитории (вес: 15)
    if (profile.audiences.includes(features.audience)) {
      score += 15;
      reasons.push(`Подходит для читателей ${features.audience}`);
    } else {
      score += 5;
    }

    // Соответствие опыта (вес: 15)
    if (profile.experience.includes(features.experience)) {
      score += 15;
      reasons.push(`Соответствует уровню автора ${features.experience}`);
    } else {
      score += 5;
    }

    // Соответствие фокуса (вес: 10)
    if (profile.focus.includes(features.focus)) {
      score += 10;
      reasons.push(`Специализируется на описании ${features.focus}`);
    }

    // Соответствие темпа (вес: 5)
    if (profile.pace.includes(features.pace)) {
      score += 5;
      reasons.push('Стиль темпа совпадает');
    }

    // Соответствие сложности (вес: 5)
    if (profile.complexity.includes(features.complexity)) {
      score += 5;
      reasons.push('Сложность подходит');
    }

    return { total: score, reasons };
  }

  /**
   * Анализ преимуществ и недостатков
   */
  private analyzeMatch(features: StoryFeatures, profile: any, method: string): { pros: string[]; cons: string[] } {
    const pros: string[] = [];
    const cons: string[] = [];

    // Анализ преимуществ
    if (profile.genres.includes(features.genre)) {
      pros.push('Жанр полностью соответствует');
    }
    if (profile.experience.includes(features.experience)) {
      pros.push('Уровень сложности подходящий');
    }
    if (features.length >= profile.lengthRange.min && features.length <= profile.lengthRange.max) {
      pros.push('Длина подходящая');
    }

    // Анализ недостатков
    if (!profile.genres.includes(features.genre) && !profile.genres.includes('Общий')) {
      cons.push('Жанр не самый подходящий');
    }
    if (!profile.experience.includes(features.experience)) {
      if (features.experience === 'Начинающий' && !profile.experience.includes('Начинающий')) {
        cons.push('Может быть слишком сложным');
      } else if (features.experience === 'Продвинутый' && !profile.experience.includes('Продвинутый')) {
        cons.push('Может быть слишком простым');
      }
    }
    if (features.length < profile.lengthRange.min) {
      cons.push('Может быть слишком коротким, структура не раскроется');
    } else if (features.length > profile.lengthRange.max) {
      cons.push('Может быть слишком длинным, структура будет затянутой');
    }

    return { pros, cons };
  }

  /**
   * Получение подробных рекомендаций
   */
  getDetailedRecommendation(features: StoryFeatures): string {
    const scores = this.recommend(features);
    const top = scores[0];
    const second = scores[1];

    let recommendation = `## 📊 Отчет о рекомендуемых методах написания\n\n`;
    recommendation += `### Анализ характеристик произведения\n`;
    recommendation += `- Жанр: ${features.genre}\n`;
    recommendation += `- Длина: ${(features.length / 10000).toFixed(1)}万字\n`;
    recommendation += `- Читатели: ${features.audience}\n`;
    recommendation += `- Опыт: ${features.experience}\n`;
    recommendation += `- Фокус: ${features.focus}\n`;
    recommendation += `- Темп: ${features.pace}\n`;
    recommendation += `- Сложность: ${features.complexity}\n\n`;

    recommendation += `### 🏆 Основная рекомендация: ${this.getMethodName(top.method)}\n`;
    recommendation += `**Соответствие: ${top.score}%**\n\n`;
    recommendation += `**Причины рекомендации:**\n`;
    top.reasons.forEach(reason => {
      recommendation += `- ✅ ${reason}\n`;
    });
    recommendation += `\n**Преимущества:**\n`;
    top.pros.forEach(pro => {
      recommendation += `- ${pro}\n`;
    });
    if (top.cons.length > 0) {
      recommendation += `\n**Примечания:**\n`;
      top.cons.forEach(con => {
        recommendation += `- ⚠️ ${con}\n`;
      });
    }

    if (second && second.score >= 70) {
      recommendation += `\n### 🥈 Альтернативная рекомендация: ${this.getMethodName(second.method)}\n`;
      recommendation += `**Соответствие: ${second.score}%**\n\n`;
      recommendation += `**Причины рекомендации:**\n`;
      second.reasons.forEach(reason => {
        recommendation += `- ${reason}\n`;
      });
    }

    recommendation += `\n### 💡 Советы по созданию\n`;
    recommendation += this.getSpecificTips(top.method, features);

    return recommendation;
  }

  /**
   * Получение китайского названия метода
   */
  private getMethodName(method: string): string {
    const names: Record<string, string> = {
      'three-act': '三幕结构',
      'hero-journey': '英雄之旅',
      'story-circle': '故事圈',
      'seven-point': '七点结构',
      'pixar-formula': '皮克斯公式'
    };
    return names[method] || method;
  }

  /**
   * Получение конкретных советов
   */
  private getSpecificTips(method: string, features: StoryFeatures): string {
    const tips: Record<string, string> = {
      'three-act': `
- Первая часть должна составлять около 25%, быстро создавая конфликт.
- Во второй части избегайте затягивания середины, можно ввести несколько небольших кульминаций.
- Третья часть должна быть сжатой и сильной, не заканчивайте слишком поспешно.`,
      'hero-journey': `
- Не обязательно строго следовать всем 12 этапам, можно корректировать по мере необходимости.
- Сосредоточьтесь на внутреннем преображении персонажа, а не только на внешних приключениях.
- Роль наставника может быть разнообразной, не обязательно традиционный мудрец.`,
      'story-circle': `
- Подчеркните, что потребность персонажа должна быть достаточно сильной.
- Каждый шаг должен продвигать внутренние изменения персонажа.
- Можно вкладывать маленькие циклы в большие для увеличения глубины.`,
      'seven-point': `
- Убедитесь, что каждый узел действительно продвигает сюжет.
- Середина должна быть настоящим поворотным моментом, меняющим правила игры.
- Не пропускайте точки завершения, они важны для поддержания напряжения.`,
      'pixar-formula': `
- Сохраняйте лаконичность, не перегружайте описаниями.
- Подчеркните четкую связь причинно-следственных связей.
- Финал должен быть удовлетворительным, но может оставлять пространство для размышлений.`
    };

    return tips[method] || '';
  }
}

/**
 * Функция быстрой рекомендации
 */
export function quickRecommend(
  genre: string,
  length: number,
  experience: string = 'Начинающий'
): string {
  // Быстрые правила
  if (length < 30000) return 'pixar-formula';
  if (genre === 'Фэнтези' || genre === 'Приключения') return 'hero-journey';
  if (genre === 'Детектив' || genre === 'Триллер') return 'seven-point';
  if (genre === 'Психология' || genre === 'Взросление') return 'story-circle';
  return 'three-act'; // По умолчанию
}

/**
 * Рекомендация гибридных методов
 */
export function recommendHybrid(features: StoryFeatures): string {
  const recommendations: string[] = [];

  // Основная структура
  if (features.length > 100000 && (features.genre === 'Фэнтези' || features.genre === 'Приключения')) {
    recommendations.push('Основная линия использует "Героя в путешествии"');
  } else if (features.genre === 'Детектив') {
    recommendations.push('Основная линия использует "Семь точек"');
  } else {
    recommendations.push('Основная линия использует "Трехактную структуру"');
  }

  // Структура второстепенных линий
  if (features.focus === 'Персонажи') {
    recommendations.push('Второстепенные линии используют "Круг историй"');
  }

  // Структура глав
  if (features.pace === 'Быстрый') {
    recommendations.push('Отдельные главы можно организовать по "Формуле Пиксар"');
  }

  return recommendations.join('\n');
}
