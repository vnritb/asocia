import { Pool } from 'pg';

/**
 * Helper para crear una conexión de test a PostgreSQL
 */
export function createTestDatabaseConnection(): Pool {
  return new Pool({
    host: process.env.POSTGRES_HOST || 'localhost',
    port: parseInt(process.env.POSTGRES_PORT || '5432'),
    database: process.env.POSTGRES_DB_TEST || 'asocia_test',
    user: process.env.POSTGRES_USER || 'asocia',
    password: process.env.POSTGRES_PASSWORD || 'asocia_secret'
  });
}

/**
 * Limpia todas las tablas de la base de datos de test
 */
export async function cleanDatabase(pool: Pool): Promise<void> {
  await pool.query('TRUNCATE TABLE messages CASCADE');
  await pool.query('TRUNCATE TABLE members CASCADE');
}

/**
 * Cierra la conexión de la base de datos
 */
export async function closeDatabaseConnection(pool: Pool): Promise<void> {
  await pool.end();
}

/**
 * Espera un tiempo determinado (útil para tests asíncronos)
 */
export function wait(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Genera un email aleatorio para tests
 */
export function randomEmail(): string {
  return `test-${Date.now()}-${Math.random().toString(36).substring(7)}@example.com`;
}

/**
 * Genera un DNI válido para tests
 */
export function randomDNI(): string {
  const numbers = Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
  const letters = 'TRWAGMYFPDXBNJZSQVHLCKE';
  const letter = letters[parseInt(numbers) % 23];
  return `${numbers}${letter}`;
}

/**
 * Genera datos de miembro válidos para tests
 */
export function generateMemberData(overrides: any = {}) {
  return {
    name: 'Test Member',
    email: randomEmail(),
    dni: randomDNI(),
    phone: '+34600000000',
    address: 'Test Address 123',
    birthDate: '1990-01-01',
    ...overrides
  };
}
