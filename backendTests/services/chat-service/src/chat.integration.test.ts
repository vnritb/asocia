import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import request from 'supertest';

/**
 * Tests de integración del servicio de Chat
 */

describe('Chat Service Integration', () => {
  const baseURL = process.env.CHAT_SERVICE_URL || 'http://localhost:4002';
  let testUserIds: string[] = ['test-user-1', 'test-user-2', 'test-user-3'];
  let createdMessageIds: string[] = [];

  beforeEach(() => {
    createdMessageIds = [];
  });

  afterAll(async () => {
    // Cleanup: eliminar mensajes creados durante los tests
    for (const id of createdMessageIds) {
      try {
        await request(baseURL).delete(`/messages/${id}`);
      } catch (e) {
        // Ignorar errores de cleanup
      }
    }
  });

  describe('POST /messages', () => {
    it('should send a text message', async () => {
      const messageData = {
        senderId: testUserIds[0],
        recipientId: testUserIds[1],
        content: 'Hello from integration test!',
        type: 'text'
      };

      const response = await request(baseURL)
        .post('/messages')
        .send(messageData)
        .expect(201);

      expect(response.body).toMatchObject({
        id: expect.any(String),
        senderId: messageData.senderId,
        recipientId: messageData.recipientId,
        content: messageData.content,
        type: 'text',
        createdAt: expect.any(String),
        read: false
      });

      createdMessageIds.push(response.body.id);
    });

    it('should reject message with empty content', async () => {
      const invalidMessage = {
        senderId: testUserIds[0],
        recipientId: testUserIds[1],
        content: '',
        type: 'text'
      };

      const response = await request(baseURL)
        .post('/messages')
        .send(invalidMessage)
        .expect(400);

      expect(response.body.error).toMatch(/content.*empty/i);
    });

    it('should reject message without senderId', async () => {
      const invalidMessage = {
        recipientId: testUserIds[1],
        content: 'Test',
        type: 'text'
      };

      const response = await request(baseURL)
        .post('/messages')
        .send(invalidMessage)
        .expect(400);

      expect(response.body.error).toMatch(/senderId.*required/i);
    });

    it('should reject message without recipientId', async () => {
      const invalidMessage = {
        senderId: testUserIds[0],
        content: 'Test',
        type: 'text'
      };

      const response = await request(baseURL)
        .post('/messages')
        .send(invalidMessage)
        .expect(400);

      expect(response.body.error).toMatch(/recipientId.*required/i);
    });

    it('should reject message exceeding max length', async () => {
      const tooLongMessage = {
        senderId: testUserIds[0],
        recipientId: testUserIds[1],
        content: 'a'.repeat(5001),
        type: 'text'
      };

      const response = await request(baseURL)
        .post('/messages')
        .send(tooLongMessage)
        .expect(400);

      expect(response.body.error).toMatch(/exceeds.*maximum/i);
    });
  });

  describe('GET /messages/:id', () => {
    it('should retrieve message by id', async () => {
      // Crear un mensaje primero
      const messageData = {
        senderId: testUserIds[0],
        recipientId: testUserIds[1],
        content: 'Retrieve this message',
        type: 'text'
      };

      const created = await request(baseURL)
        .post('/messages')
        .send(messageData)
        .expect(201);

      createdMessageIds.push(created.body.id);

      // Recuperarlo por ID
      const response = await request(baseURL)
        .get(`/messages/${created.body.id}`)
        .expect(200);

      expect(response.body).toMatchObject({
        id: created.body.id,
        content: messageData.content,
        senderId: messageData.senderId
      });
    });

    it('should return 404 for non-existent message', async () => {
      await request(baseURL)
        .get('/messages/non-existent-id-12345')
        .expect(404);
    });
  });

  describe('GET /conversations/:userId1/:userId2', () => {
    it('should retrieve conversation between two users', async () => {
      // Enviar varios mensajes entre dos usuarios
      const msg1 = await request(baseURL)
        .post('/messages')
        .send({
          senderId: testUserIds[0],
          recipientId: testUserIds[1],
          content: 'First message',
          type: 'text'
        })
        .expect(201);

      const msg2 = await request(baseURL)
        .post('/messages')
        .send({
          senderId: testUserIds[1],
          recipientId: testUserIds[0],
          content: 'Reply message',
          type: 'text'
        })
        .expect(201);

      const msg3 = await request(baseURL)
        .post('/messages')
        .send({
          senderId: testUserIds[0],
          recipientId: testUserIds[1],
          content: 'Third message',
          type: 'text'
        })
        .expect(201);

      createdMessageIds.push(msg1.body.id, msg2.body.id, msg3.body.id);

      // Recuperar la conversación
      const response = await request(baseURL)
        .get(`/conversations/${testUserIds[0]}/${testUserIds[1]}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThanOrEqual(3);
      
      // Verificar que están en orden cronológico
      const timestamps = response.body.map((m: any) => new Date(m.createdAt).getTime());
      for (let i = 1; i < timestamps.length; i++) {
        expect(timestamps[i]).toBeGreaterThanOrEqual(timestamps[i - 1]);
      }
    });

    it('should not include messages from other conversations', async () => {
      // Crear mensaje entre user-0 y user-1
      const msg1 = await request(baseURL)
        .post('/messages')
        .send({
          senderId: testUserIds[0],
          recipientId: testUserIds[1],
          content: 'For user 1',
          type: 'text'
        })
        .expect(201);

      // Crear mensaje entre user-0 y user-2 (diferente conversación)
      const msg2 = await request(baseURL)
        .post('/messages')
        .send({
          senderId: testUserIds[0],
          recipientId: testUserIds[2],
          content: 'For user 2',
          type: 'text'
        })
        .expect(201);

      createdMessageIds.push(msg1.body.id, msg2.body.id);

      // Recuperar conversación entre user-0 y user-1
      const response = await request(baseURL)
        .get(`/conversations/${testUserIds[0]}/${testUserIds[1]}`)
        .expect(200);

      // No debería incluir el mensaje para user-2
      const hasMessageForUser2 = response.body.some((m: any) => m.id === msg2.body.id);
      expect(hasMessageForUser2).toBe(false);
    });
  });

  describe('GET /conversations/:userId', () => {
    it('should list all conversations for a user', async () => {
      // Usuario 0 envía mensajes a usuario 1 y usuario 2
      const msg1 = await request(baseURL)
        .post('/messages')
        .send({
          senderId: testUserIds[0],
          recipientId: testUserIds[1],
          content: 'To user 1',
          type: 'text'
        })
        .expect(201);

      const msg2 = await request(baseURL)
        .post('/messages')
        .send({
          senderId: testUserIds[0],
          recipientId: testUserIds[2],
          content: 'To user 2',
          type: 'text'
        })
        .expect(201);

      createdMessageIds.push(msg1.body.id, msg2.body.id);

      // Listar conversaciones de usuario 0
      const response = await request(baseURL)
        .get(`/conversations/${testUserIds[0]}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThanOrEqual(2);
    });
  });

  describe('PATCH /messages/:id/read', () => {
    it('should mark message as read', async () => {
      const created = await request(baseURL)
        .post('/messages')
        .send({
          senderId: testUserIds[0],
          recipientId: testUserIds[1],
          content: 'Unread message',
          type: 'text'
        })
        .expect(201);

      createdMessageIds.push(created.body.id);
      expect(created.body.read).toBe(false);

      // Marcar como leído
      const response = await request(baseURL)
        .patch(`/messages/${created.body.id}/read`)
        .expect(200);

      expect(response.body.read).toBe(true);
    });

    it('should return 404 when marking non-existent message', async () => {
      await request(baseURL)
        .patch('/messages/non-existent-id/read')
        .expect(404);
    });
  });

  describe('GET /messages/unread/:userId', () => {
    it('should count unread messages for user', async () => {
      // Enviar varios mensajes sin leer al usuario 1
      const msg1 = await request(baseURL)
        .post('/messages')
        .send({
          senderId: testUserIds[0],
          recipientId: testUserIds[1],
          content: 'Unread 1',
          type: 'text'
        })
        .expect(201);

      const msg2 = await request(baseURL)
        .post('/messages')
        .send({
          senderId: testUserIds[2],
          recipientId: testUserIds[1],
          content: 'Unread 2',
          type: 'text'
        })
        .expect(201);

      createdMessageIds.push(msg1.body.id, msg2.body.id);

      // Obtener conteo de mensajes sin leer
      const response = await request(baseURL)
        .get(`/messages/unread/${testUserIds[1]}`)
        .expect(200);

      expect(response.body.count).toBeGreaterThanOrEqual(2);
    });

    it('should not count read messages', async () => {
      const created = await request(baseURL)
        .post('/messages')
        .send({
          senderId: testUserIds[0],
          recipientId: testUserIds[1],
          content: 'Will be read',
          type: 'text'
        })
        .expect(201);

      createdMessageIds.push(created.body.id);

      // Obtener conteo inicial
      const before = await request(baseURL)
        .get(`/messages/unread/${testUserIds[1]}`)
        .expect(200);

      const countBefore = before.body.count;

      // Marcar como leído
      await request(baseURL)
        .patch(`/messages/${created.body.id}/read`)
        .expect(200);

      // Obtener conteo después
      const after = await request(baseURL)
        .get(`/messages/unread/${testUserIds[1]}`)
        .expect(200);

      const countAfter = after.body.count;

      expect(countAfter).toBeLessThan(countBefore);
    });
  });

  describe('DELETE /messages/:id', () => {
    it('should delete a message', async () => {
      const created = await request(baseURL)
        .post('/messages')
        .send({
          senderId: testUserIds[0],
          recipientId: testUserIds[1],
          content: 'To be deleted',
          type: 'text'
        })
        .expect(201);

      // Eliminar
      await request(baseURL)
        .delete(`/messages/${created.body.id}`)
        .expect(204);

      // Verificar que ya no existe
      await request(baseURL)
        .get(`/messages/${created.body.id}`)
        .expect(404);
    });

    it('should return 404 when deleting non-existent message', async () => {
      await request(baseURL)
        .delete('/messages/non-existent-id')
        .expect(404);
    });
  });
});
