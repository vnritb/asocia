import { describe, it, expect, beforeEach } from 'vitest';

/**
 * Tests unitarios para el repositorio de miembros (sin base de datos real)
 */

describe('MemberRepository (unit)', () => {
  let repository: MockMemberRepository;

  beforeEach(() => {
    repository = new MockMemberRepository();
  });

  describe('create', () => {
    it('should create a new member with pending status', async () => {
      const memberData = {
        name: 'María García',
        email: 'maria@example.com',
        dni: '87654321X',
        phone: '+34600987654',
        address: 'Calle Test 456'
      };

      const created = await repository.create(memberData);

      expect(created).toMatchObject({
        id: expect.any(String),
        ...memberData,
        status: 'pending',
        createdAt: expect.any(Date),
        updatedAt: expect.any(Date)
      });
    });

    it('should generate unique IDs for each member', async () => {
      const member1 = await repository.create({ name: 'User 1', email: 'user1@test.com', dni: '11111111H', phone: '+34600111111' });
      const member2 = await repository.create({ name: 'User 2', email: 'user2@test.com', dni: '22222222J', phone: '+34600222222' });

      expect(member1.id).not.toBe(member2.id);
    });
  });

  describe('findById', () => {
    it('should return member when found', async () => {
      const created = await repository.create({
        name: 'Test User',
        email: 'test@example.com',
        dni: '12345678Z',
        phone: '+34600123456'
      });

      const found = await repository.findById(created.id);

      expect(found).toEqual(created);
    });

    it('should return null when member not found', async () => {
      const found = await repository.findById('non-existent-id');
      expect(found).toBeNull();
    });
  });

  describe('findByEmail', () => {
    it('should return member when email exists', async () => {
      const email = 'unique@example.com';
      const created = await repository.create({
        name: 'Unique User',
        email,
        dni: '12345678Z',
        phone: '+34600123456'
      });

      const found = await repository.findByEmail(email);

      expect(found).toEqual(created);
    });

    it('should return null when email does not exist', async () => {
      const found = await repository.findByEmail('nonexistent@example.com');
      expect(found).toBeNull();
    });
  });

  describe('findByDNI', () => {
    it('should return member when DNI exists', async () => {
      const dni = '87654321X';
      const created = await repository.create({
        name: 'DNI User',
        email: 'dni@example.com',
        dni,
        phone: '+34600123456'
      });

      const found = await repository.findByDNI(dni);

      expect(found).toEqual(created);
    });

    it('should return null when DNI does not exist', async () => {
      const found = await repository.findByDNI('00000000T');
      expect(found).toBeNull();
    });
  });

  describe('updateStatus', () => {
    it('should update member status to confirmed', async () => {
      const created = await repository.create({
        name: 'Pending User',
        email: 'pending@example.com',
        dni: '12345678Z',
        phone: '+34600123456'
      });

      expect(created.status).toBe('pending');

      const updated = await repository.updateStatus(created.id, 'confirmed');

      expect(updated.status).toBe('confirmed');
      expect(updated.updatedAt.getTime()).toBeGreaterThan(created.updatedAt.getTime());
    });

    it('should throw error when member not found', async () => {
      await expect(
        repository.updateStatus('non-existent', 'confirmed')
      ).rejects.toThrow('Member not found');
    });
  });

  describe('list', () => {
    it('should return all members', async () => {
      await repository.create({ name: 'User 1', email: 'u1@test.com', dni: '11111111H', phone: '+34600111111' });
      await repository.create({ name: 'User 2', email: 'u2@test.com', dni: '22222222J', phone: '+34600222222' });
      await repository.create({ name: 'User 3', email: 'u3@test.com', dni: '33333333P', phone: '+34600333333' });

      const all = await repository.list();

      expect(all).toHaveLength(3);
    });

    it('should filter by status', async () => {
      const member1 = await repository.create({ name: 'User 1', email: 'u1@test.com', dni: '11111111H', phone: '+34600111111' });
      await repository.create({ name: 'User 2', email: 'u2@test.com', dni: '22222222J', phone: '+34600222222' });
      
      await repository.updateStatus(member1.id, 'confirmed');

      const confirmed = await repository.list({ status: 'confirmed' });
      const pending = await repository.list({ status: 'pending' });

      expect(confirmed).toHaveLength(1);
      expect(pending).toHaveLength(1);
    });
  });

  describe('delete', () => {
    it('should delete existing member', async () => {
      const created = await repository.create({
        name: 'To Delete',
        email: 'delete@example.com',
        dni: '12345678Z',
        phone: '+34600123456'
      });

      await repository.delete(created.id);

      const found = await repository.findById(created.id);
      expect(found).toBeNull();
    });

    it('should throw error when deleting non-existent member', async () => {
      await expect(
        repository.delete('non-existent')
      ).rejects.toThrow('Member not found');
    });
  });
});

// Mock del repositorio para tests unitarios
interface Member {
  id: string;
  name: string;
  email: string;
  dni: string;
  phone: string;
  address?: string;
  status: 'pending' | 'confirmed';
  createdAt: Date;
  updatedAt: Date;
}

class MockMemberRepository {
  private members: Map<string, Member> = new Map();
  private idCounter = 0;

  async create(data: Partial<Member>): Promise<Member> {
    const member: Member = {
      id: `member-${++this.idCounter}`,
      name: data.name!,
      email: data.email!,
      dni: data.dni!,
      phone: data.phone!,
      address: data.address,
      status: 'pending',
      createdAt: new Date(),
      updatedAt: new Date()
    };

    this.members.set(member.id, member);
    return member;
  }

  async findById(id: string): Promise<Member | null> {
    return this.members.get(id) || null;
  }

  async findByEmail(email: string): Promise<Member | null> {
    for (const member of this.members.values()) {
      if (member.email === email) return member;
    }
    return null;
  }

  async findByDNI(dni: string): Promise<Member | null> {
    for (const member of this.members.values()) {
      if (member.dni === dni) return member;
    }
    return null;
  }

  async updateStatus(id: string, status: 'pending' | 'confirmed'): Promise<Member> {
    const member = this.members.get(id);
    if (!member) throw new Error('Member not found');

    member.status = status;
    member.updatedAt = new Date();
    return member;
  }

  async list(filters?: { status?: string }): Promise<Member[]> {
    const all = Array.from(this.members.values());
    if (!filters?.status) return all;
    return all.filter(m => m.status === filters.status);
  }

  async delete(id: string): Promise<void> {
    if (!this.members.has(id)) throw new Error('Member not found');
    this.members.delete(id);
  }
}
