import express, { NextFunction, Request, Response } from "express";
import cors from "cors";
import { createProxyMiddleware } from "http-proxy-middleware";
import type { Member } from "@asocia/shared";

const PORT = Number(process.env.PORT ?? 4000);
const MEMBERSHIP_SERVICE_URL = process.env.MEMBERSHIP_SERVICE_URL ?? "http://localhost:4001";
const CHAT_SERVICE_URL = process.env.CHAT_SERVICE_URL ?? "http://localhost:4002";
const TRANSLATION_SERVICE_URL = process.env.TRANSLATION_SERVICE_URL ?? "http://localhost:4003";

const app = express();
app.use(cors());

app.get("/healthz", (_req, res) => res.json({ ok: true, service: "api-gateway" }));

// ---------------------------------------------------------------------------
// Único punto de entrada para la app iOS (y, mañana, para la app Android:
// ambas hablan exactamente el mismo API, definido por los tipos de
// packages/shared). Aquí es donde vive la traducción entre el Bearer token
// de sesión del socio y la identidad interna (X-User-Id/X-User-Name) que
// usan chat-service y las rutas de eventos — así esos servicios no necesitan
// saber nada sobre cómo se emiten o verifican los tokens.
// ---------------------------------------------------------------------------

/**
 * Resuelve el Bearer token contra membership-service y exige que el socio
 * tenga el alta CONFIRMADA (solo los socios activos tienen acceso al Chat,
 * ver docs/ARQUITECTURA.md). Si todo va bien, añade cabeceras internas de
 * identidad y dele reenvía la petición a chat-service.
 */
async function requireActiveMember(req: Request, res: Response, next: NextFunction) {
  const authorization = req.header("authorization");
  if (!authorization) return res.status(401).json({ error: "notAuthenticated" });

  try {
    const meResponse = await fetch(`${MEMBERSHIP_SERVICE_URL}/v1/members/me`, {
      headers: { authorization }
    });
    if (!meResponse.ok) return res.status(401).json({ error: "notAuthenticated" });

    const member = (await meResponse.json()) as Member;
    if (member.membershipStatus !== "active") {
      return res.status(403).json({ error: "membershipNotActive" });
    }

    const fullName = [member.firstName, member.firstSurname, member.secondSurname]
      .filter(Boolean)
      .join(" ");
    req.headers["x-user-id"] = member.id;
    req.headers["x-user-name"] = encodeURIComponent(fullName);
    next();
  } catch (error) {
    console.error("Error resolviendo socio contra membership-service:", error);
    res.status(502).json({ error: "upstreamUnavailable" });
  }
}

// Rutas de Chat: requieren alta confirmada.
app.use(
  ["/v1/directory", "/v1/conversations", "/v1/events"],
  requireActiveMember,
  createProxyMiddleware({ target: CHAT_SERVICE_URL, changeOrigin: true })
);

// Alta de socio (pública) y ficha propia (el propio membership-service
// valida el Bearer token) se proxean tal cual.
app.use(
  "/v1/members",
  createProxyMiddleware({ target: MEMBERSHIP_SERVICE_URL, changeOrigin: true })
);

// Traducción de idioma (pública).
app.use(
  "/v1/translate",
  createProxyMiddleware({ target: TRANSLATION_SERVICE_URL, changeOrigin: true })
);

// ---------------------------------------------------------------------------
// Administración (backoffice). Requiere la cabecera x-admin-key, que
// membership-service vuelve a comprobar por su cuenta. La sincronización
// del directorio del Chat (quién es "buscable") la hace membership-service
// directamente (ver syncChatDirectory en su src/index.ts) cada vez que
// cambia membershipStatus o isSearchable — el gateway aquí solo proxea.
// ---------------------------------------------------------------------------

// OJO con el orden: las rutas más específicas van antes que el genérico
// "/v1/admin", porque `app.use` hace match por prefijo (si "/v1/admin"
// fuera lo primero, se comería también las peticiones de "/v1/admin/events").
app.use(
  "/v1/admin/events",
  createProxyMiddleware({ target: CHAT_SERVICE_URL, changeOrigin: true })
);
app.use(
  "/v1/admin",
  createProxyMiddleware({ target: MEMBERSHIP_SERVICE_URL, changeOrigin: true })
);

app.listen(PORT, () => console.log(`api-gateway escuchando en :${PORT}`));
