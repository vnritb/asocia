import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import request from 'supertest';
import { randomEmail, randomDNI, generateMemberData } from '../../../test-helpers/database';

/**
 * Tests de integración del servicio de Membership
 * Estos tests asumen que hay un servidor corriendo o usan un servidor de test
 */

describe('Membership Service Integration', () => {
  const baseURL = process.env.MEMBERSHIP_SERVICE_URL || 'http://localhost:4001';
  let createdMemberIds: string[] = [];

  beforeEach(() => {
    createdMemberIds = [];
  });

  afterAll(async () => {
    // Cleanup: eliminar miembros creados durante los tests
    for (const id of createdMemberIds) {
      try {
        await request(baseURL).delete(`/members/${id}`);
      } catch (e) {
        // Ignorar errores de cleanup
      }
    }
  });

  describe('POST /members', () => {
    it('should create a new member with valid data', async () => {
      const memberData = generateMemberData({
        name: 'Integration Test User',
        address: 'Calle Test 123, Madrid'
      });

      const response = await request(baseURL)
        .post('/members')
        .send(memberData)
        .expect(201);

      expect(response.body).toMatchObject({
        id: expect.any(String),
        name: memberData.name,
        email: memberData.email,
        dni: memberData.dni,
        phone: memberData.phone,
        status: 'pending',
        createdAt: expect.any(String)
      });

      createdMemberIds.push(response.body.id);
    });

    it('should reject member with duplicate email', async () => {
      const memberData = generateMemberData();

      // Crear primer miembro
      const first = await request(baseURL)
        .post('/members')
        .send(memberData)
        .expect(201);

      createdMemberIds.push(first.body.id);

      // Intentar crear otro con el mismo email
      const duplicateData = {
        ...memberData,
        dni: randomDNI() // DNI diferente pero mismo email
      };

      const response = await request(baseURL)
        .post('/members')
        .send(duplicateData)
        .expect(409);

      expect(response.body.error).toMatch(/email.*already exists/i);
    });

    it('should reject member with duplicate DNI', async () => {
      const memberData = generateMemberData();

      // Crear primer miembro
      const first = await request(baseURL)
        .post('/members')
        .send(memberData)
        .expect(201);

      createdMemberIds.push(first.body.id);

      // Intentar crear otro con el mismo DNI
      const duplicateData = {
        ...memberData,
        email: randomEmail() // Email diferente pero mismo DNI
      };

      const response = await request(baseURL)
        .post('/members')
        .send(duplicateData)
        .expect(409);

      expect(response.body.error).toMatch(/dni.*already exists/i);
    });

    it('should reject member with invalid email', async () => {
      const invalidData = generateMemberData({
        email: 'not-an-email'
      });

      const response = await request(baseURL)
        .post('/members')
        .send(invalidData)
        .expect(400);

      expect(response.body.error).toMatch(/invalid.*email/i);
    });

    it('should reject member with invalid DNI', async () => {
      const invalidData = generateMemberData({
        dni: '123' // DNI inválido
      });

      const response = await request(baseURL)
        .post('/members')
        .send(invalidData)
        .expect(400);

      expect(response.body.error).toMatch(/invalid.*dni/i);
    });

    it('should reject member with missing required fields', async () => {
      const incompleteData = {
        name: 'Incomplete User'
        // Faltan email, dni, phone
      };

      const response = await request(baseURL)
        .post('/members')
        .send(incompleteData)
        .expect(400);

      expect(response.body.error).toBeDefined();
    });
  });

  describe('GET /members/:id', () => {
    it('should retrieve member by id', async () => {
      // Crear un miembro primero
      const memberData = generateMemberData();
      const created = await request(baseURL)
        .post('/members')
        .send(memberData)
        .expect(201);

      createdMemberIds.push(created.body.id);

      // Recuperarlo por ID
      const response = await request(baseURL)
        .get(`/members/${created.body.id}`)
        .expect(200);

      expect(response.body).toMatchObject({
        id: created.body.id,
        name: memberData.name,
        email: memberData.email,
        status: 'pending'
      });
    });

    it('should return 404 for non-existent member', async () => {
      const response = await request(baseURL)
        .get('/members/non-existent-id-12345')
        .expect(404);

      expect(response.body.error).toMatch(/not found/i);
    });
  });

  describe('GET /members', () => {
    it('should list all members', async () => {
      // Crear algunos miembros
      const member1 = await request(baseURL)
        .post('/members')
        .send(generateMemberData())
        .expect(201);

      const member2 = await request(baseURL)
        .post('/members')
        .send(generateMemberData())
        .expect(201);

      createdMemberIds.push(member1.body.id, member2.body.id);

      // Listar todos
      const response = await request(baseURL)
        .get('/members')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThanOrEqual(2);
    });

    it('should filter members by status', async () => {
      // Crear miembro pendiente
      const pending = await request(baseURL)
        .post('/members')
        .send(generateMemberData())
        .expect(201);

      createdMemberIds.push(pending.body.id);

      // Listar solo pendientes
      const response = await request(baseURL)
        .get('/members?status=pending')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.every((m: any) => m.status === 'pending')).toBe(true);
    });
  });

  describe('PATCH /members/:id/status', () => {
    it('should update member status from pending to confirmed', async () => {
      // Crear miembro pendiente
      const created = await request(baseURL)
        .post('/members')
        .send(generateMemberData())
        .expect(201);

      createdMemberIds.push(created.body.id);
      expect(created.body.status).toBe('pending');

      // Confirmar el miembro
      const response = await request(baseURL)
        .patch(`/members/${created.body.id}/status`)
        .send({ status: 'confirmed' })
        .expect(200);

      expect(response.body.status).toBe('confirmed');
    });

    it('should reject invalid status', async () => {
      const created = await request(baseURL)
        .post('/members')
        .send(generateMemberData())
        .expect(201);

      createdMemberIds.push(created.body.id);

      const response = await request(baseURL)
        .patch(`/members/${created.body.id}/status`)
        .send({ status: 'invalid-status' })
        .expect(400);

      expect(response.body.error).toBeDefined();
    });

    it('should return 404 when updating non-existent member', async () => {
      await request(baseURL)
        .patch('/members/non-existent-id/status')
        .send({ status: 'confirmed' })
        .expect(404);
    });
  });

  describe('PUT /members/:id', () => {
    it('should update member data', async () => {
      const created = await request(baseURL)
        .post('/members')
        .send(generateMemberData())
        .expect(201);

      createdMemberIds.push(created.body.id);

      const updatedData = {
        name: 'Updated Name',
        phone: '+34700999888',
        address: 'New Address 456'
      };

      const response = await request(baseURL)
        .put(`/members/${created.body.id}`)
        .send(updatedData)
        .expect(200);

      expect(response.body).toMatchObject(updatedData);
    });

    it('should not allow updating email to duplicate', async () => {
      const member1 = await request(baseURL)
        .post('/members')
        .send(generateMemberData())
        .expect(201);

      const member2 = await request(baseURL)
        .post('/members')
        .send(generateMemberData())
        .expect(201);

      createdMemberIds.push(member1.body.id, member2.body.id);

      // Intentar actualizar member2 con el email de member1
      const response = await request(baseURL)
        .put(`/members/${member2.body.id}`)
        .send({ email: member1.body.email })
        .expect(409);

      expect(response.body.error).toMatch(/email.*already exists/i);
    });
  });

  describe('DELETE /members/:id', () => {
    it('should delete existing member', async () => {
      const created = await request(baseURL)
        .post('/members')
        .send(generateMemberData())
        .expect(201);

      // Eliminar
      await request(baseURL)
        .delete(`/members/${created.body.id}`)
        .expect(204);

      // Verificar que ya no existe
      await request(baseURL)
        .get(`/members/${created.body.id}`)
        .expect(404);
    });

    it('should return 404 when deleting non-existent member', async () => {
      await request(baseURL)
        .delete('/members/non-existent-id')
        .expect(404);
    });
  });
});
