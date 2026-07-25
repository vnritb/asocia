import { defineConfig } from 'vitest/config';
import path from 'path';

/**
 * Tests de integración contra los servicios reales ya levantados (docker
 * compose con Postgres real + los 4 servicios, o `npm run dev:gateway/
 * membership/chat/translation`). Usa las mismas URLs por defecto que cada
 * servicio en local (localhost:4000-4003), sobreescribibles con
 * API_GATEWAY_URL / MEMBERSHIP_SERVICE_URL / CHAT_SERVICE_URL /
 * TRANSLATION_SERVICE_URL. translation-service necesita además
 * ANTHROPIC_API_KEY para traducir a idiomas distintos del español; sin ella
 * degrada devolviendo el texto original (ver translation.integration.test.ts).
 */
export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['../backendTests/**/*.integration.test.ts'],
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
