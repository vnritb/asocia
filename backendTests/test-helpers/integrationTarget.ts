import { startMockedStack, type MockStackURLs } from "./mockStack";

export interface IntegrationTarget extends MockStackURLs {
  close(): Promise<void>;
}

/**
 * Resuelve contra qué URLs deben correr los tests de integración.
 *
 * - Modo "mock" (INTEGRATION_TARGET=mock, ver vitest.integration.mock.config.ts):
 *   levanta los 4 servicios reales en memoria (ver mockStack.ts) y devuelve
 *   sus puertos efímeros.
 * - Modo "real" (por defecto, ver vitest.integration.real.config.ts): usa
 *   las URLs de servicios ya levantados por separado (docker-compose / `npm
 *   run dev:*`), vía las variables de entorno *_SERVICE_URL, con los mismos
 *   valores por defecto que usa cada servicio en local.
 */
export async function resolveIntegrationTarget(): Promise<IntegrationTarget> {
  if (process.env.INTEGRATION_TARGET === "mock") {
    return startMockedStack();
  }

  return {
    gateway: process.env.API_GATEWAY_URL ?? "http://localhost:4000",
    membership: process.env.MEMBERSHIP_SERVICE_URL ?? "http://localhost:4001",
    chat: process.env.CHAT_SERVICE_URL ?? "http://localhost:4002",
    translation: process.env.TRANSLATION_SERVICE_URL ?? "http://localhost:4003",
    async close() {}
  };
}
