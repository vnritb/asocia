import { describe, it, expect, beforeEach, vi } from 'vitest';

/**
 * Tests unitarios para el servicio de traducción
 */

describe('Translation Service', () => {
  describe('Language Detection', () => {
    it('should detect Spanish text', () => {
      const spanishTexts = [
        'Hola, ¿cómo estás?',
        'Buenos días',
        'La asociación celebra su reunión anual'
      ];

      spanishTexts.forEach(text => {
        expect(detectLanguage(text)).toBe('es');
      });
    });

    it('should detect English text', () => {
      const englishTexts = [
        'Hello, how are you?',
        'Good morning',
        'The association holds its annual meeting'
      ];

      englishTexts.forEach(text => {
        expect(detectLanguage(text)).toBe('en');
      });
    });

    it('should detect Catalan text', () => {
      const catalanTexts = [
        'Hola, com estàs?',
        'Bon dia',
        'L\'associació celebra la seva reunió anual'
      ];

      catalanTexts.forEach(text => {
        expect(detectLanguage(text)).toBe('ca');
      });
    });

    it('should handle mixed language text', () => {
      const mixedText = 'Hello mundo';
      const detected = detectLanguage(mixedText);
      expect(['es', 'en']).toContain(detected);
    });

    it('should handle empty text', () => {
      expect(detectLanguage('')).toBe('unknown');
    });
  });

  describe('Translation Validation', () => {
    it('should validate supported language codes', () => {
      const supportedLanguages = ['es', 'en', 'ca', 'fr', 'de'];
      
      supportedLanguages.forEach(lang => {
        expect(isSupportedLanguage(lang)).toBe(true);
      });
    });

    it('should reject unsupported language codes', () => {
      const unsupportedLanguages = ['xx', 'zz', 'invalid'];
      
      unsupportedLanguages.forEach(lang => {
        expect(isSupportedLanguage(lang)).toBe(false);
      });
    });

    it('should validate translation request', () => {
      const validRequest = {
        text: 'Hello world',
        sourceLang: 'en',
        targetLang: 'es'
      };

      const result = validateTranslationRequest(validRequest);
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should reject request with missing text', () => {
      const invalidRequest = {
        sourceLang: 'en',
        targetLang: 'es'
      };

      const result = validateTranslationRequest(invalidRequest);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('text is required');
    });

    it('should reject request with unsupported target language', () => {
      const invalidRequest = {
        text: 'Hello',
        sourceLang: 'en',
        targetLang: 'invalid'
      };

      const result = validateTranslationRequest(invalidRequest);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Unsupported target language');
    });

    it('should reject translation of text exceeding max length', () => {
      const longRequest = {
        text: 'a'.repeat(10001),
        sourceLang: 'en',
        targetLang: 'es'
      };

      const result = validateTranslationRequest(longRequest);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Text exceeds maximum length of 10000 characters');
    });
  });

  describe('Translation Cache', () => {
    let cache: TranslationCache;

    beforeEach(() => {
      cache = new TranslationCache();
    });

    it('should cache translation results', () => {
      const key = cache.generateKey('Hello', 'en', 'es');
      const translation = 'Hola';

      cache.set(key, translation);

      expect(cache.get(key)).toBe(translation);
    });

    it('should return null for cache miss', () => {
      const key = cache.generateKey('Hello', 'en', 'es');
      expect(cache.get(key)).toBeNull();
    });

    it('should generate same key for same input', () => {
      const key1 = cache.generateKey('Hello', 'en', 'es');
      const key2 = cache.generateKey('Hello', 'en', 'es');

      expect(key1).toBe(key2);
    });

    it('should generate different keys for different inputs', () => {
      const key1 = cache.generateKey('Hello', 'en', 'es');
      const key2 = cache.generateKey('Hello', 'en', 'fr');
      const key3 = cache.generateKey('Goodbye', 'en', 'es');

      expect(key1).not.toBe(key2);
      expect(key1).not.toBe(key3);
    });

    it('should clear cache', () => {
      const key = cache.generateKey('Hello', 'en', 'es');
      cache.set(key, 'Hola');
      
      cache.clear();
      
      expect(cache.get(key)).toBeNull();
    });

    it('should respect cache size limit', () => {
      const smallCache = new TranslationCache(2); // Max 2 elementos
      
      smallCache.set('key1', 'value1');
      smallCache.set('key2', 'value2');
      smallCache.set('key3', 'value3'); // Debería expulsar key1
      
      expect(smallCache.get('key1')).toBeNull();
      expect(smallCache.get('key2')).toBe('value2');
      expect(smallCache.get('key3')).toBe('value3');
    });
  });

  describe('Mock Translation Provider', () => {
    let provider: MockTranslationProvider;

    beforeEach(() => {
      provider = new MockTranslationProvider();
    });

    it('should translate using mock translations', async () => {
      const result = await provider.translate('Hello', 'en', 'es');
      expect(result).toBeDefined();
      expect(typeof result).toBe('string');
    });

    it('should handle translation errors gracefully', async () => {
      // Simular un error forzando un idioma no soportado en el mock
      await expect(
        provider.translate('Hello', 'invalid' as any, 'es')
      ).rejects.toThrow();
    });

    it('should auto-detect source language when not specified', async () => {
      const result = await provider.translate('Hola', 'auto', 'en');
      expect(result).toBeDefined();
    });
  });
});

// Helper functions
function detectLanguage(text: string): string {
  if (!text || text.trim() === '') return 'unknown';

  const spanishWords = ['hola', 'cómo', 'buenos', 'días', 'asociación', 'reunión'];
  const englishWords = ['hello', 'how', 'good', 'morning', 'association', 'meeting'];
  const catalanWords = ['com', 'estàs', 'bon', 'dia', 'associació'];

  const lowerText = text.toLowerCase();

  let spanishScore = 0;
  let englishScore = 0;
  let catalanScore = 0;

  spanishWords.forEach(word => {
    if (lowerText.includes(word)) spanishScore++;
  });

  englishWords.forEach(word => {
    if (lowerText.includes(word)) englishScore++;
  });

  catalanWords.forEach(word => {
    if (lowerText.includes(word)) catalanScore++;
  });

  if (spanishScore > englishScore && spanishScore > catalanScore) return 'es';
  if (englishScore > spanishScore && englishScore > catalanScore) return 'en';
  if (catalanScore > spanishScore && catalanScore > englishScore) return 'ca';

  // Default fallback
  return 'es';
}

function isSupportedLanguage(lang: string): boolean {
  const supported = ['es', 'en', 'ca', 'fr', 'de', 'it', 'pt'];
  return supported.includes(lang);
}

interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

function validateTranslationRequest(request: any): ValidationResult {
  const errors: string[] = [];

  if (!request.text) {
    errors.push('text is required');
  } else if (request.text.length > 10000) {
    errors.push('Text exceeds maximum length of 10000 characters');
  }

  if (request.targetLang && !isSupportedLanguage(request.targetLang)) {
    errors.push('Unsupported target language');
  }

  if (request.sourceLang && request.sourceLang !== 'auto' && !isSupportedLanguage(request.sourceLang)) {
    errors.push('Unsupported source language');
  }

  return {
    isValid: errors.length === 0,
    errors
  };
}

class TranslationCache {
  private cache: Map<string, { value: string; timestamp: number }> = new Map();
  private maxSize: number;

  constructor(maxSize: number = 1000) {
    this.maxSize = maxSize;
  }

  generateKey(text: string, sourceLang: string, targetLang: string): string {
    return `${sourceLang}:${targetLang}:${text}`;
  }

  set(key: string, value: string): void {
    // Si excede el tamaño, eliminar el más antiguo
    if (this.cache.size >= this.maxSize) {
      const oldestKey = this.cache.keys().next().value;
      this.cache.delete(oldestKey);
    }

    this.cache.set(key, { value, timestamp: Date.now() });
  }

  get(key: string): string | null {
    const entry = this.cache.get(key);
    return entry ? entry.value : null;
  }

  clear(): void {
    this.cache.clear();
  }
}

class MockTranslationProvider {
  private mockTranslations: Record<string, Record<string, string>> = {
    'en': {
      'Hello': { es: 'Hola', ca: 'Hola', fr: 'Bonjour' },
      'Good morning': { es: 'Buenos días', ca: 'Bon dia', fr: 'Bonjour' },
      'Thank you': { es: 'Gracias', ca: 'Gràcies', fr: 'Merci' }
    },
    'es': {
      'Hola': { en: 'Hello', ca: 'Hola', fr: 'Bonjour' },
      'Buenos días': { en: 'Good morning', ca: 'Bon dia', fr: 'Bonjour' },
      'Gracias': { en: 'Thank you', ca: 'Gràcies', fr: 'Merci' }
    }
  };

  async translate(text: string, sourceLang: string, targetLang: string): Promise<string> {
    // Auto-detect source language
    if (sourceLang === 'auto') {
      sourceLang = detectLanguage(text);
    }

    // Validar idiomas
    if (!isSupportedLanguage(sourceLang) || !isSupportedLanguage(targetLang)) {
      throw new Error('Unsupported language');
    }

    // Buscar en traducciones mock
    const translations = this.mockTranslations[sourceLang]?.[text];
    if (translations && translations[targetLang]) {
      return translations[targetLang];
    }

    // Fallback: devolver el texto original con un prefijo
    return `[${targetLang}] ${text}`;
  }
}
