import http, { type Server } from "node:http";
import type { Express } from "express";

export interface MockStackURLs {
  gateway: string;
  membership: string;
  chat: string;
  translation: string;
}

export interface MockStack extends MockStackURLs {
  close(): Promise<void>;
}

async function listenOnEphemeralPort(app: Express): Promise<{ url: string; server: Server }> {
  const server = http.createServer(app);
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  if (!address || typeof address === "string") throw new Error("No se pudo levantar el servidor de test");
  return { url: `http://127.0.0.1:${address.port}`, server };
}

/**
 * Levanta los 4 servicios reales (Express real, rutas reales) en el mismo
 * proceso, con `pg` sustituido por el almacén en memoria (ver mockSetup.ts,
 * cargado vía `setupFiles`) y sin llamar a la API real de Anthropic. El
 * gateway se importa el último porque necesita conocer, por variables de
 * entorno, los puertos efímeros ya asignados a los otros tres.
 */
export async function startMockedStack(): Promise<MockStack> {
  process.env.NODE_ENV = "test";
  process.env.ADMIN_API_KEY ??= "test-admin-key";
  process.env.INTERNAL_API_KEY ??= "test-internal-key";

  const { app: chatApp } = await import("../../backend/services/chat-service/src/index");
  const chat = await listenOnEphemeralPort(chatApp);
  process.env.CHAT_SERVICE_URL = chat.url;

  const { app: translationApp } = await import("../../backend/services/translation-service/src/index");
  const translation = await listenOnEphemeralPort(translationApp);
  process.env.TRANSLATION_SERVICE_URL = translation.url;

  const { app: membershipApp } = await import("../../backend/services/membership-service/src/index");
  const membership = await listenOnEphemeralPort(membershipApp);
  process.env.MEMBERSHIP_SERVICE_URL = membership.url;

  const { app: gatewayApp } = await import("../../backend/services/api-gateway/src/index");
  const gateway = await listenOnEphemeralPort(gatewayApp);

  return {
    gateway: gateway.url,
    membership: membership.url,
    chat: chat.url,
    translation: translation.url,
    async close() {
      await Promise.all(
        [gateway, membership, translation, chat].map(
          ({ server }) => new Promise<void>((resolve) => server.close(() => resolve()))
        )
      );
    }
  };
}
