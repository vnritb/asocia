import { defineConfig } from 'vitest/config';
import path from 'path';

/**
 * Tests de integración contra servicios reales ya levantados (docker-compose
 * con Postgres real + `npm run dev:gateway/membership/chat/translation`, y
 * ANTHROPIC_API_KEY configurada para translation-service). Usa las mismas
 * URLs por defecto que cada servicio en local (localhost:4000-4003),
 * sobreescribibles con API_GATEWAY_URL / MEMBERSHIP_SERVICE_URL /
 * CHAT_SERVICE_URL / TRANSLATION_SERVICE_URL.
 */
export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['../backendTests/**/*.integration.test.ts'],
    env: {
      INTEGRATION_TARGET: 'real'
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
