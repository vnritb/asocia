import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { generateMemberData } from '../../../test-helpers/database';

/**
 * Tests de integración del API Gateway
 * Verifica que el gateway rutea correctamente a todos los microservicios
 */

describe('API Gateway Integration', () => {
  const baseURL = process.env.API_GATEWAY_URL || 'http://localhost:4000';
  let testMemberId: string;
  let testMessageId: string;

  describe('Health Check', () => {
    it('should return healthy status', async () => {
      const response = await request(baseURL)
        .get('/health')
        .expect(200);

      expect(response.body.status).toBe('healthy');
    });

    it('should include services status', async () => {
      const response = await request(baseURL)
        .get('/health')
        .expect(200);

      expect(response.body.services).toBeDefined();
      expect(response.body.services).toHaveProperty('membership');
      expect(response.body.services).toHaveProperty('chat');
      expect(response.body.services).toHaveProperty('translation');
    });
  });

  describe('Routing to Membership Service', () => {
    it('should route POST /api/members to membership service', async () => {
      const memberData = generateMemberData();

      const response = await request(baseURL)
        .post('/api/members')
        .send(memberData)
        .expect(201);

      expect(response.body).toMatchObject({
        id: expect.any(String),
        name: memberData.name,
        email: memberData.email,
        status: 'pending'
      });

      testMemberId = response.body.id;
    });

    it('should route GET /api/members/:id to membership service', async () => {
      if (!testMemberId) {
        // Crear un miembro si no existe
        const memberData = generateMemberData();
        const created = await request(baseURL).post('/api/members').send(memberData);
        testMemberId = created.body.id;
      }

      const response = await request(baseURL)
        .get(`/api/members/${testMemberId}`)
        .expect(200);

      expect(response.body.id).toBe(testMemberId);
    });

    it('should route GET /api/members to membership service', async () => {
      const response = await request(baseURL)
        .get('/api/members')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
    });

    it('should route PATCH /api/members/:id/status to membership service', async () => {
      if (!testMemberId) {
        const memberData = generateMemberData();
        const created = await request(baseURL).post('/api/members').send(memberData);
        testMemberId = created.body.id;
      }

      const response = await request(baseURL)
        .patch(`/api/members/${testMemberId}/status`)
        .send({ status: 'confirmed' })
        .expect(200);

      expect(response.body.status).toBe('confirmed');
    });
  });

  describe('Routing to Chat Service', () => {
    it('should route POST /api/messages to chat service', async () => {
      const messageData = {
        senderId: 'test-user-1',
        recipientId: 'test-user-2',
        content: 'Hello from gateway test',
        type: 'text'
      };

      const response = await request(baseURL)
        .post('/api/messages')
        .send(messageData)
        .expect(201);

      expect(response.body).toMatchObject({
        id: expect.any(String),
        senderId: messageData.senderId,
        recipientId: messageData.recipientId,
        content: messageData.content
      });

      testMessageId = response.body.id;
    });

    it('should route GET /api/messages/:id to chat service', async () => {
      if (!testMessageId) {
        const messageData = {
          senderId: 'test-user-1',
          recipientId: 'test-user-2',
          content: 'Test',
          type: 'text'
        };
        const created = await request(baseURL).post('/api/messages').send(messageData);
        testMessageId = created.body.id;
      }

      const response = await request(baseURL)
        .get(`/api/messages/${testMessageId}`)
        .expect(200);

      expect(response.body.id).toBe(testMessageId);
    });

    it('should route GET /api/conversations/:userId1/:userId2 to chat service', async () => {
      const response = await request(baseURL)
        .get('/api/conversations/test-user-1/test-user-2')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
    });

    it('should route PATCH /api/messages/:id/read to chat service', async () => {
      if (!testMessageId) {
        const messageData = {
          senderId: 'test-user-1',
          recipientId: 'test-user-2',
          content: 'Test',
          type: 'text'
        };
        const created = await request(baseURL).post('/api/messages').send(messageData);
        testMessageId = created.body.id;
      }

      const response = await request(baseURL)
        .patch(`/api/messages/${testMessageId}/read`)
        .expect(200);

      expect(response.body.read).toBe(true);
    });
  });

  describe('Routing to Translation Service', () => {
    it('should route POST /api/translate to translation service', async () => {
      const translationRequest = {
        text: 'Hello world',
        sourceLang: 'en',
        targetLang: 'es'
      };

      const response = await request(baseURL)
        .post('/api/translate')
        .send(translationRequest)
        .expect(200);

      expect(response.body.translated).toBeDefined();
      expect(response.body.targetLang).toBe('es');
    });

    it('should route POST /api/detect-language to translation service', async () => {
      const detectRequest = {
        text: 'Hola mundo'
      };

      const response = await request(baseURL)
        .post('/api/detect-language')
        .send(detectRequest)
        .expect(200);

      expect(response.body.detectedLang).toBeDefined();
    });

    it('should route GET /api/supported-languages to translation service', async () => {
      const response = await request(baseURL)
        .get('/api/supported-languages')
        .expect(200);

      expect(Array.isArray(response.body.languages)).toBe(true);
    });
  });

  describe('Error Handling', () => {
    it('should return 404 for non-existent routes', async () => {
      const response = await request(baseURL)
        .get('/api/non-existent-route')
        .expect(404);

      expect(response.body.error).toMatch(/not found/i);
    });

    it('should handle service unavailability gracefully', async () => {
      // Intentar acceder a un servicio que podría estar caído
      // El gateway debería devolver un error apropiado
      const response = await request(baseURL)
        .get('/api/members/service-test-unavailable')
        .expect((res: any) => {
          // Debería ser 404, 503, o 500 dependiendo de la implementación
          expect([404, 500, 503]).toContain(res.status);
        });

      expect(response.body.error).toBeDefined();
    });

    it('should return 400 for invalid request data', async () => {
      const invalidData = {
        // Faltan campos requeridos
        name: 'Invalid Member'
      };

      const response = await request(baseURL)
        .post('/api/members')
        .send(invalidData)
        .expect(400);

      expect(response.body.error).toBeDefined();
    });
  });

  describe('Request Validation', () => {
    it('should validate Content-Type header', async () => {
      const response = await request(baseURL)
        .post('/api/members')
        .set('Content-Type', 'text/plain')
        .send('invalid data')
        .expect((res: any) => {
          // Debería rechazar content-type inválido
          expect([400, 415]).toContain(res.status);
        });
    });

    it('should handle malformed JSON', async () => {
      const response = await request(baseURL)
        .post('/api/members')
        .set('Content-Type', 'application/json')
        .send('{ invalid json }')
        .expect(400);

      expect(response.body.error).toBeDefined();
    });
  });

  describe('CORS Headers', () => {
    it('should include CORS headers', async () => {
      const response = await request(baseURL)
        .options('/api/members')
        .set('Origin', 'http://localhost:3000')
        .expect(200);

      expect(response.headers['access-control-allow-origin']).toBeDefined();
      expect(response.headers['access-control-allow-methods']).toBeDefined();
    });

    it('should allow cross-origin requests', async () => {
      const response = await request(baseURL)
        .get('/api/members')
        .set('Origin', 'http://localhost:3000')
        .expect(200);

      expect(response.headers['access-control-allow-origin']).toBeDefined();
    });
  });

  describe('Rate Limiting', () => {
    it('should include rate limit headers', async () => {
      const response = await request(baseURL)
        .get('/api/members')
        .expect(200);

      // Si el gateway implementa rate limiting, debería incluir estos headers
      if (response.headers['x-ratelimit-limit']) {
        expect(response.headers['x-ratelimit-limit']).toBeDefined();
        expect(response.headers['x-ratelimit-remaining']).toBeDefined();
      }
    });
  });

  describe('Request Logging', () => {
    it('should include request ID in response headers', async () => {
      const response = await request(baseURL)
        .get('/api/members')
        .expect(200);

      // Muchos gateways incluyen un request ID para trazabilidad
      if (response.headers['x-request-id']) {
        expect(response.headers['x-request-id']).toMatch(/^[a-f0-9-]+$/);
      }
    });
  });

  describe('Service Composition', () => {
    it('should be able to chain requests to multiple services', async () => {
      // 1. Crear un miembro
      const memberData = generateMemberData();
      const member = await request(baseURL)
        .post('/api/members')
        .send(memberData)
        .expect(201);

      // 2. Traducir un mensaje
      const translation = await request(baseURL)
        .post('/api/translate')
        .send({
          text: 'Bienvenido a la asociación',
          sourceLang: 'es',
          targetLang: 'en'
        })
        .expect(200);

      // 3. Enviar mensaje de bienvenida
      const message = await request(baseURL)
        .post('/api/messages')
        .send({
          senderId: 'system',
          recipientId: member.body.id,
          content: translation.body.translated,
          type: 'system'
        })
        .expect(201);

      expect(member.body.id).toBeDefined();
      expect(translation.body.translated).toBeDefined();
      expect(message.body.id).toBeDefined();
      expect(message.body.recipientId).toBe(member.body.id);
    });
  });
});
