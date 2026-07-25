import { defineConfig } from 'vitest/config';
import path from 'path';

/**
 * Tests de integración "mockeados": levanta los 4 servicios reales (Express
 * real, rutas reales) en el mismo proceso, con `pg` sustituido por un
 * almacén en memoria y sin llamar a la API real de Anthropic (ver
 * backendTests/test-helpers/mockStack.ts y mockSetup.ts). No necesita
 * Postgres, Docker, ni ANTHROPIC_API_KEY: rápido y aislado, pensado para
 * correr en cualquier máquina o en CI.
 */
export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['../backendTests/**/*.integration.test.ts'],
    setupFiles: ['../backendTests/test-helpers/mockSetup.ts'],
    env: {
      INTEGRATION_TARGET: 'mock'
    },
    testTimeout: 30000,
    hookTimeout: 30000
  },
  resolve: {
    alias: {
      '@shared': path.resolve(__dirname, './packages/shared/src'),
      supertest: path.resolve(__dirname, './node_modules/supertest')
    }
  }
});
