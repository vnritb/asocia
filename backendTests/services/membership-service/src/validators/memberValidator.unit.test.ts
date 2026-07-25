import { describe, it, expect } from 'vitest';

/**
 * Tests unitarios para validación de datos de miembro
 */

describe('Member Validator', () => {
  describe('validateEmail', () => {
    it('should accept valid email addresses', () => {
      const validEmails = [
        'user@example.com',
        'test.user@domain.co.uk',
        'name+tag@company.org',
        'user123@test-domain.com'
      ];

      validEmails.forEach(email => {
        expect(isValidEmail(email)).toBe(true);
      });
    });

    it('should reject invalid email addresses', () => {
      const invalidEmails = [
        'not-an-email',
        '@example.com',
        'user@',
        'user @example.com',
        'user@exam ple.com',
        ''
      ];

      invalidEmails.forEach(email => {
        expect(isValidEmail(email)).toBe(false);
      });
    });
  });

  describe('validateDNI', () => {
    it('should accept valid Spanish DNI', () => {
      const validDNIs = [
        '12345678Z',
        '87654321X',
        '00000000T'
      ];

      validDNIs.forEach(dni => {
        expect(isValidDNI(dni)).toBe(true);
      });
    });

    it('should reject invalid DNI format', () => {
      const invalidDNIs = [
        '123',
        '12345678',
        'ABCDEFGH',
        '1234567ZZ',
        '123456789Z'
      ];

      invalidDNIs.forEach(dni => {
        expect(isValidDNI(dni)).toBe(false);
      });
    });

    it('should reject DNI with wrong check letter', () => {
      expect(isValidDNI('12345678A')).toBe(false); // Should be Z
    });
  });

  describe('validatePhone', () => {
    it('should accept valid Spanish phone numbers', () => {
      const validPhones = [
        '+34600123456',
        '+34700987654',
        '+34912345678'
      ];

      validPhones.forEach(phone => {
        expect(isValidPhone(phone)).toBe(true);
      });
    });

    it('should reject invalid phone numbers', () => {
      const invalidPhones = [
        '600123456',
        '+34 600 123 456',
        '+34500123456', // 500 no es válido
        '+1234567890',
        ''
      ];

      invalidPhones.forEach(phone => {
        expect(isValidPhone(phone)).toBe(false);
      });
    });
  });

  describe('validateMemberData', () => {
    it('should accept complete valid member data', () => {
      const validData = {
        name: 'Juan Pérez García',
        email: 'juan@example.com',
        dni: '12345678Z',
        phone: '+34600123456',
        address: 'Calle Principal 123, 28001 Madrid',
        birthDate: '1990-05-15'
      };

      const result = validateMemberData(validData);
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should reject member data with missing required fields', () => {
      const incompleteData = {
        name: 'Juan Pérez',
        email: 'juan@example.com'
        // Faltan dni, phone
      };

      const result = validateMemberData(incompleteData);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('dni is required');
      expect(result.errors).toContain('phone is required');
    });

    it('should reject member data with invalid email', () => {
      const invalidData = {
        name: 'Juan Pérez',
        email: 'not-an-email',
        dni: '12345678Z',
        phone: '+34600123456'
      };

      const result = validateMemberData(invalidData);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Invalid email format');
    });

    it('should reject member with age under 18', () => {
      const today = new Date();
      const recentDate = new Date(today.getFullYear() - 16, today.getMonth(), today.getDate());
      
      const minorData = {
        name: 'Joven Menor',
        email: 'joven@example.com',
        dni: '12345678Z',
        phone: '+34600123456',
        birthDate: recentDate.toISOString().split('T')[0]
      };

      const result = validateMemberData(minorData);
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Member must be at least 18 years old');
    });
  });
});

// Funciones de validación (estas deberían estar en el código real del servicio)
function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

function isValidDNI(dni: string): boolean {
  if (!/^\d{8}[A-Z]$/.test(dni)) return false;
  
  const letters = 'TRWAGMYFPDXBNJZSQVHLCKE';
  const number = parseInt(dni.substring(0, 8));
  const letter = dni.charAt(8);
  
  return letters[number % 23] === letter;
}

function isValidPhone(phone: string): boolean {
  // Formato español: +34 seguido de 9 dígitos (6xx, 7xx, 9xx)
  const phoneRegex = /^\+34[679]\d{8}$/;
  return phoneRegex.test(phone);
}

interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

function validateMemberData(data: any): ValidationResult {
  const errors: string[] = [];

  if (!data.name) errors.push('name is required');
  if (!data.email) errors.push('email is required');
  else if (!isValidEmail(data.email)) errors.push('Invalid email format');
  
  if (!data.dni) errors.push('dni is required');
  else if (!isValidDNI(data.dni)) errors.push('Invalid DNI format');
  
  if (!data.phone) errors.push('phone is required');
  else if (!isValidPhone(data.phone)) errors.push('Invalid phone format');

  if (data.birthDate) {
    const birthDate = new Date(data.birthDate);
    const today = new Date();
    const age = today.getFullYear() - birthDate.getFullYear();
    if (age < 18) errors.push('Member must be at least 18 years old');
  }

  return {
    isValid: errors.length === 0,
    errors
  };
}
