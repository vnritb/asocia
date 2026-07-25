export interface IntegrationTarget {
  gateway: string;
  membership: string;
  chat: string;
  close(): Promise<void>;
}

/**
 * URLs de los 3 servicios ya levantados por separado (docker compose / `npm
 * run dev:*`), con los mismos valores por defecto que usa cada uno en
 * local. Sobreescribibles con las variables de entorno *_SERVICE_URL.
 */
export async function resolveIntegrationTarget(): Promise<IntegrationTarget> {
  return {
    gateway: process.env.API_GATEWAY_URL ?? "http://localhost:4000",
    membership: process.env.MEMBERSHIP_SERVICE_URL ?? "http://localhost:4001",
    chat: process.env.CHAT_SERVICE_URL ?? "http://localhost:4002",
    async close() {}
  };
}
