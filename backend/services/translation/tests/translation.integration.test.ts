import { describe, it, expect } from 'vitest';
import request from 'supertest';

/**
 * Tests de integración del servicio de Translation
 */

describe('Translation Service Integration', () => {
  const baseURL = process.env.TRANSLATION_SERVICE_URL || 'http://localhost:4003';

  describe('POST /translate', () => {
    it('should translate Spanish to English', async () => {
      const translationRequest = {
        text: 'Hola mundo',
        sourceLang: 'es',
        targetLang: 'en'
      };

      const response = await request(baseURL)
        .post('/translate')
        .send(translationRequest)
        .expect(200);

      expect(response.body).toHaveProperty('translated');
      expect(typeof response.body.translated).toBe('string');
      expect(response.body.translated.length).toBeGreaterThan(0);
      expect(response.body).toHaveProperty('sourceLang', 'es');
      expect(response.body).toHaveProperty('targetLang', 'en');
    });

    it('should translate English to Spanish', async () => {
      const translationRequest = {
        text: 'Hello world',
        sourceLang: 'en',
        targetLang: 'es'
      };

      const response = await request(baseURL)
        .post('/translate')
        .send(translationRequest)
        .expect(200);

      expect(response.body.translated).toBeDefined();
      expect(response.body.sourceLang).toBe('en');
      expect(response.body.targetLang).toBe('es');
    });

    it('should translate Spanish to Catalan', async () => {
      const translationRequest = {
        text: 'Buenos días, ¿cómo estás?',
        sourceLang: 'es',
        targetLang: 'ca'
      };

      const response = await request(baseURL)
        .post('/translate')
        .send(translationRequest)
        .expect(200);

      expect(response.body.translated).toBeDefined();
      expect(response.body.targetLang).toBe('ca');
    });

    it('should auto-detect source language', async () => {
      const translationRequest = {
        text: 'Hello, how are you?',
        targetLang: 'es'
        // No sourceLang especificado
      };

      const response = await request(baseURL)
        .post('/translate')
        .send(translationRequest)
        .expect(200);

      expect(response.body.translated).toBeDefined();
      expect(response.body.detectedSourceLang).toBeDefined();
      expect(response.body.targetLang).toBe('es');
    });

    it('should handle long text translation', async () => {
      const longText = `
        La asociación de vecinos celebra su reunión anual el próximo sábado.
        Todos los socios están invitados a participar y compartir sus ideas
        sobre las mejoras que se pueden realizar en el barrio. Habrá café
        y pasteles para todos los asistentes.
      `.trim();

      const translationRequest = {
        text: longText,
        sourceLang: 'es',
        targetLang: 'en'
      };

      const response = await request(baseURL)
        .post('/translate')
        .send(translationRequest)
        .expect(200);

      expect(response.body.translated).toBeDefined();
      expect(response.body.translated.length).toBeGreaterThan(0);
    });

    it('should reject translation without text', async () => {
      const invalidRequest = {
        sourceLang: 'es',
        targetLang: 'en'
      };

      const response = await request(baseURL)
        .post('/translate')
        .send(invalidRequest)
        .expect(400);

      expect(response.body.error).toMatch(/text.*required/i);
    });

    it('should reject translation with empty text', async () => {
      const invalidRequest = {
        text: '',
        sourceLang: 'es',
        targetLang: 'en'
      };

      const response = await request(baseURL)
        .post('/translate')
        .send(invalidRequest)
        .expect(400);

      expect(response.body.error).toBeDefined();
    });

    it('should reject translation without target language', async () => {
      const invalidRequest = {
        text: 'Hello world',
        sourceLang: 'en'
      };

      const response = await request(baseURL)
        .post('/translate')
        .send(invalidRequest)
        .expect(400);

      expect(response.body.error).toMatch(/target.*language.*required/i);
    });

    it('should reject unsupported target language', async () => {
      const invalidRequest = {
        text: 'Hello world',
        sourceLang: 'en',
        targetLang: 'invalid'
      };

      const response = await request(baseURL)
        .post('/translate')
        .send(invalidRequest)
        .expect(400);

      expect(response.body.error).toMatch(/unsupported.*language/i);
    });

    it('should reject text exceeding max length', async () => {
      const tooLongText = 'a'.repeat(10001);
      
      const invalidRequest = {
        text: tooLongText,
        sourceLang: 'en',
        targetLang: 'es'
      };

      const response = await request(baseURL)
        .post('/translate')
        .send(invalidRequest)
        .expect(400);

      expect(response.body.error).toMatch(/exceeds.*maximum/i);
    });

    it('should preserve special characters in translation', async () => {
      const textWithSpecialChars = '¡Hola! ¿Cómo estás? (muy bien)';
      
      const translationRequest = {
        text: textWithSpecialChars,
        sourceLang: 'es',
        targetLang: 'en'
      };

      const response = await request(baseURL)
        .post('/translate')
        .send(translationRequest)
        .expect(200);

      expect(response.body.translated).toBeDefined();
      // La traducción debería mantener algún tipo de puntuación
      expect(/[!?().]/.test(response.body.translated)).toBe(true);
    });

    it('should handle numbers in text', async () => {
      const textWithNumbers = 'Tengo 25 años y vivo en el número 123';
      
      const translationRequest = {
        text: textWithNumbers,
        sourceLang: 'es',
        targetLang: 'en'
      };

      const response = await request(baseURL)
        .post('/translate')
        .send(translationRequest)
        .expect(200);

      expect(response.body.translated).toBeDefined();
      expect(response.body.translated).toMatch(/25/);
      expect(response.body.translated).toMatch(/123/);
    });
  });

  describe('POST /detect-language', () => {
    it('should detect Spanish text', async () => {
      const request_body = {
        text: 'Hola, ¿cómo estás? Buenos días.'
      };

      const response = await request(baseURL)
        .post('/detect-language')
        .send(request_body)
        .expect(200);

      expect(response.body.detectedLang).toBe('es');
      expect(response.body.confidence).toBeGreaterThan(0);
    });

    it('should detect English text', async () => {
      const request_body = {
        text: 'Hello, how are you? Good morning.'
      };

      const response = await request(baseURL)
        .post('/detect-language')
        .send(request_body)
        .expect(200);

      expect(response.body.detectedLang).toBe('en');
    });

    it('should detect Catalan text', async () => {
      const request_body = {
        text: 'Bon dia, com estàs?'
      };

      const response = await request(baseURL)
        .post('/detect-language')
        .send(request_body)
        .expect(200);

      expect(response.body.detectedLang).toBe('ca');
    });

    it('should reject detection without text', async () => {
      const response = await request(baseURL)
        .post('/detect-language')
        .send({})
        .expect(400);

      expect(response.body.error).toMatch(/text.*required/i);
    });
  });

  describe('GET /supported-languages', () => {
    it('should return list of supported languages', async () => {
      const response = await request(baseURL)
        .get('/supported-languages')
        .expect(200);

      expect(Array.isArray(response.body.languages)).toBe(true);
      expect(response.body.languages.length).toBeGreaterThan(0);
      
      // Verificar que incluye al menos español, inglés y catalán
      expect(response.body.languages).toContain('es');
      expect(response.body.languages).toContain('en');
      expect(response.body.languages).toContain('ca');
    });

    it('should include language metadata', async () => {
      const response = await request(baseURL)
        .get('/supported-languages')
        .expect(200);

      // Debería incluir información adicional como nombres de idiomas
      if (response.body.languageDetails) {
        expect(response.body.languageDetails).toHaveProperty('es');
        expect(response.body.languageDetails.es).toHaveProperty('name');
      }
    });
  });

  describe('Translation Cache', () => {
    it('should return same translation for repeated requests', async () => {
      const translationRequest = {
        text: 'Cache test text',
        sourceLang: 'en',
        targetLang: 'es'
      };

      // Primera petición
      const response1 = await request(baseURL)
        .post('/translate')
        .send(translationRequest)
        .expect(200);

      // Segunda petición (debería usar caché)
      const response2 = await request(baseURL)
        .post('/translate')
        .send(translationRequest)
        .expect(200);

      expect(response1.body.translated).toBe(response2.body.translated);
      
      // Si el servicio incluye un flag de caché
      if (response2.body.fromCache !== undefined) {
        expect(response2.body.fromCache).toBe(true);
      }
    });
  });

  describe('Batch Translation', () => {
    it('should translate multiple texts at once', async () => {
      const batchRequest = {
        texts: [
          'Hola',
          'Buenos días',
          'Adiós'
        ],
        sourceLang: 'es',
        targetLang: 'en'
      };

      const response = await request(baseURL)
        .post('/translate/batch')
        .send(batchRequest)
        .expect(200);

      expect(Array.isArray(response.body.translations)).toBe(true);
      expect(response.body.translations.length).toBe(3);
      
      response.body.translations.forEach((translation: string) => {
        expect(typeof translation).toBe('string');
        expect(translation.length).toBeGreaterThan(0);
      });
    });

    it('should reject batch with empty array', async () => {
      const invalidRequest = {
        texts: [],
        sourceLang: 'es',
        targetLang: 'en'
      };

      const response = await request(baseURL)
        .post('/translate/batch')
        .send(invalidRequest)
        .expect(400);

      expect(response.body.error).toBeDefined();
    });
  });
});
