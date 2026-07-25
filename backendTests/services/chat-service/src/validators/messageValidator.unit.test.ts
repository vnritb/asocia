import { describe, it, expect, beforeEach } from 'vitest';

/**
 * Tests unitarios para validación de mensajes de chat
 */

describe('Message Validator', () => {
  describe('validateMessage', () => {
    it('should accept valid message', () => {
      const validMessage = {
        senderId: 'user-123',
        content: 'Hola, ¿cómo estás?',
        type: 'text'
      };

      const result = validateMessage(validMessage);
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should reject empty message content', () => {
      const emptyMessage = {
        senderId: 'user-123',
        content: '',
        type: 'text'
      };

      const result = validateMessage(emptyMessage);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Message content cannot be empty');
    });

    it('should reject message without senderId', () => {
      const noSenderMessage = {
        content: 'Hello',
        type: 'text'
      };

      const result = validateMessage(noSenderMessage);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('senderId is required');
    });

    it('should reject message that exceeds max length', () => {
      const longMessage = {
        senderId: 'user-123',
        content: 'a'.repeat(5001), // Máximo 5000 caracteres
        type: 'text'
      };

      const result = validateMessage(longMessage);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Message content exceeds maximum length of 5000 characters');
    });

    it('should accept message with exactly max length', () => {
      const maxLengthMessage = {
        senderId: 'user-123',
        content: 'a'.repeat(5000),
        type: 'text'
      };

      const result = validateMessage(maxLengthMessage);
      expect(result.isValid).toBe(true);
    });

    it('should accept different message types', () => {
      const types = ['text', 'image', 'file', 'system'];
      
      types.forEach(type => {
        const message = {
          senderId: 'user-123',
          content: 'Test content',
          type
        };

        const result = validateMessage(message);
        expect(result.isValid).toBe(true);
      });
    });

    it('should reject invalid message type', () => {
      const invalidTypeMessage = {
        senderId: 'user-123',
        content: 'Test',
        type: 'invalid-type'
      };

      const result = validateMessage(invalidTypeMessage);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Invalid message type');
    });
  });

  describe('sanitizeMessage', () => {
    it('should trim whitespace from message content', () => {
      const message = '  Hello World  ';
      expect(sanitizeMessage(message)).toBe('Hello World');
    });

    it('should remove potentially dangerous HTML', () => {
      const dangerous = '<script>alert("XSS")</script>Hello';
      const sanitized = sanitizeMessage(dangerous);
      expect(sanitized).not.toContain('<script>');
      expect(sanitized).toContain('Hello');
    });

    it('should preserve safe formatting', () => {
      const formatted = 'Hello **bold** and *italic*';
      const sanitized = sanitizeMessage(formatted);
      expect(sanitized).toBe(formatted);
    });
  });
});

/**
 * Tests unitarios para el repositorio de mensajes (mock)
 */
describe('MessageRepository (unit)', () => {
  let repository: MockMessageRepository;

  beforeEach(() => {
    repository = new MockMessageRepository();
  });

  describe('create', () => {
    it('should create a message with timestamp', async () => {
      const messageData = {
        senderId: 'user-123',
        recipientId: 'user-456',
        content: 'Hello!',
        type: 'text'
      };

      const created = await repository.create(messageData);

      expect(created).toMatchObject({
        id: expect.any(String),
        ...messageData,
        createdAt: expect.any(Date),
        read: false
      });
    });

    it('should generate unique message IDs', async () => {
      const msg1 = await repository.create({ senderId: '1', recipientId: '2', content: 'A', type: 'text' });
      const msg2 = await repository.create({ senderId: '1', recipientId: '2', content: 'B', type: 'text' });

      expect(msg1.id).not.toBe(msg2.id);
    });
  });

  describe('findById', () => {
    it('should return message when found', async () => {
      const created = await repository.create({
        senderId: 'user-1',
        recipientId: 'user-2',
        content: 'Test',
        type: 'text'
      });

      const found = await repository.findById(created.id);
      expect(found).toEqual(created);
    });

    it('should return null when not found', async () => {
      const found = await repository.findById('non-existent');
      expect(found).toBeNull();
    });
  });

  describe('findByConversation', () => {
    it('should return messages between two users', async () => {
      await repository.create({ senderId: 'A', recipientId: 'B', content: 'Hi B', type: 'text' });
      await repository.create({ senderId: 'B', recipientId: 'A', content: 'Hi A', type: 'text' });
      await repository.create({ senderId: 'C', recipientId: 'D', content: 'Other', type: 'text' });

      const conversation = await repository.findByConversation('A', 'B');

      expect(conversation).toHaveLength(2);
      expect(conversation.every(m => 
        (m.senderId === 'A' && m.recipientId === 'B') ||
        (m.senderId === 'B' && m.recipientId === 'A')
      )).toBe(true);
    });

    it('should return messages in chronological order', async () => {
      const msg1 = await repository.create({ senderId: 'A', recipientId: 'B', content: '1', type: 'text' });
      await new Promise(resolve => setTimeout(resolve, 10));
      const msg2 = await repository.create({ senderId: 'A', recipientId: 'B', content: '2', type: 'text' });
      await new Promise(resolve => setTimeout(resolve, 10));
      const msg3 = await repository.create({ senderId: 'A', recipientId: 'B', content: '3', type: 'text' });

      const conversation = await repository.findByConversation('A', 'B');

      expect(conversation[0].id).toBe(msg1.id);
      expect(conversation[1].id).toBe(msg2.id);
      expect(conversation[2].id).toBe(msg3.id);
    });
  });

  describe('markAsRead', () => {
    it('should mark message as read', async () => {
      const message = await repository.create({
        senderId: 'A',
        recipientId: 'B',
        content: 'Unread',
        type: 'text'
      });

      expect(message.read).toBe(false);

      const updated = await repository.markAsRead(message.id);
      expect(updated.read).toBe(true);
    });
  });

  describe('getUnreadCount', () => {
    it('should count unread messages for user', async () => {
      await repository.create({ senderId: 'A', recipientId: 'B', content: '1', type: 'text' });
      await repository.create({ senderId: 'A', recipientId: 'B', content: '2', type: 'text' });
      await repository.create({ senderId: 'C', recipientId: 'B', content: '3', type: 'text' });

      const unreadCount = await repository.getUnreadCount('B');
      expect(unreadCount).toBe(3);
    });

    it('should not count read messages', async () => {
      const msg1 = await repository.create({ senderId: 'A', recipientId: 'B', content: '1', type: 'text' });
      await repository.create({ senderId: 'A', recipientId: 'B', content: '2', type: 'text' });

      await repository.markAsRead(msg1.id);

      const unreadCount = await repository.getUnreadCount('B');
      expect(unreadCount).toBe(1);
    });
  });
});

// Funciones helper
interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

function validateMessage(data: any): ValidationResult {
  const errors: string[] = [];
  const validTypes = ['text', 'image', 'file', 'system'];

  if (!data.senderId) errors.push('senderId is required');
  if (!data.content || data.content.trim() === '') errors.push('Message content cannot be empty');
  if (data.content && data.content.length > 5000) errors.push('Message content exceeds maximum length of 5000 characters');
  if (data.type && !validTypes.includes(data.type)) errors.push('Invalid message type');

  return {
    isValid: errors.length === 0,
    errors
  };
}

function sanitizeMessage(content: string): string {
  // Trim whitespace
  let sanitized = content.trim();
  
  // Remove script tags and other potentially dangerous HTML
  sanitized = sanitized.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
  sanitized = sanitized.replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, '');
  
  return sanitized;
}

// Mock repository
interface Message {
  id: string;
  senderId: string;
  recipientId: string;
  content: string;
  type: string;
  createdAt: Date;
  read: boolean;
}

class MockMessageRepository {
  private messages: Map<string, Message> = new Map();
  private idCounter = 0;

  async create(data: Partial<Message>): Promise<Message> {
    const message: Message = {
      id: `msg-${++this.idCounter}`,
      senderId: data.senderId!,
      recipientId: data.recipientId!,
      content: data.content!,
      type: data.type || 'text',
      createdAt: new Date(),
      read: false
    };

    this.messages.set(message.id, message);
    return message;
  }

  async findById(id: string): Promise<Message | null> {
    return this.messages.get(id) || null;
  }

  async findByConversation(userId1: string, userId2: string): Promise<Message[]> {
    const messages = Array.from(this.messages.values())
      .filter(m => 
        (m.senderId === userId1 && m.recipientId === userId2) ||
        (m.senderId === userId2 && m.recipientId === userId1)
      )
      .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
    
    return messages;
  }

  async markAsRead(id: string): Promise<Message> {
    const message = this.messages.get(id);
    if (!message) throw new Error('Message not found');
    
    message.read = true;
    return message;
  }

  async getUnreadCount(userId: string): Promise<number> {
    return Array.from(this.messages.values())
      .filter(m => m.recipientId === userId && !m.read)
      .length;
  }
}
