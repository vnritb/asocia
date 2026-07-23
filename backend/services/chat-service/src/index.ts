import express, { NextFunction, Request, Response } from "express";
import cors from "cors";
import crypto from "node:crypto";
import type { ActivityEvent, ActivitySummary, ChatMessage, ChatUser, Conversation, ConversationKind } from "@asocia/shared";
import { pool, ensureSchema } from "./db";

const PORT = Number(process.env.PORT ?? 4002);
const INTERNAL_API_KEY = process.env.INTERNAL_API_KEY ?? "changeme-internal-key";

const app = express();
app.use(cors());
app.use(express.json({ limit: "10mb" }));

// ---------------------------------------------------------------------------
// Identidad: este servicio NO valida tokens de sesión. Confía en que quien
// le habla es el api-gateway, que ya ha resuelto el Bearer token contra
// membership-service (y comprobado que el socio tiene el alta confirmada) y
// reenvía la identidad en estas cabeceras internas.
// ---------------------------------------------------------------------------
function requireUser(req: Request, res: Response, next: NextFunction) {
  const userId = req.header("x-user-id");
  const userName = req.header("x-user-name");
  if (!userId || !userName) return res.status(401).json({ error: "notAuthenticated" });
  (req as any).userId = userId;
  (req as any).userName = decodeURIComponent(userName);
  next();
}

function requireInternal(req: Request, res: Response, next: NextFunction) {
  if (req.header("x-internal-key") !== INTERNAL_API_KEY) return res.status(403).json({ error: "forbidden" });
  next();
}

// ---------------------------------------------------------------------------
// Mapeo de filas -> JSON de la app
// ---------------------------------------------------------------------------

async function participantsOf(conversationId: string): Promise<string[]> {
  const result = await pool.query(
    "SELECT user_id FROM chat.conversation_participants WHERE conversation_id = $1",
    [conversationId]
  );
  return result.rows.map((r) => r.user_id);
}

async function toConversationJSON(row: any): Promise<Conversation> {
  return {
    id: row.id,
    kind: row.kind as ConversationKind,
    title: row.title,
    participantIDs: await participantsOf(row.id),
    lastMessagePreview: row.last_message_preview,
    lastMessageAt: row.last_message_at ? new Date(row.last_message_at).toISOString() : null,
    photoData: row.photo_base64
  };
}

function toMessageJSON(row: any): ChatMessage {
  return {
    id: row.id,
    conversationID: row.conversation_id,
    senderID: row.sender_id,
    senderName: row.sender_name,
    text: row.text,
    sentAt: new Date(row.sent_at).toISOString()
  };
}

async function toEventJSON(row: any): Promise<ActivityEvent> {
  const attendees = await pool.query(
    "SELECT user_id, name, status FROM chat.event_attendees WHERE event_id = $1",
    [row.id]
  );
  return {
    id: row.id,
    conversationID: row.conversation_id,
    title: row.title,
    eventDescription: row.event_description,
    startDate: new Date(row.start_date).toISOString(),
    endDate: row.end_date ? new Date(row.end_date).toISOString() : null,
    location: row.location,
    attendees: attendees.rows.map((a) => ({ id: a.user_id, name: a.name, status: a.status }))
  };
}

async function isParticipant(conversationId: string, userId: string): Promise<boolean> {
  const result = await pool.query(
    "SELECT 1 FROM chat.conversation_participants WHERE conversation_id = $1 AND user_id = $2",
    [conversationId, userId]
  );
  return (result.rowCount ?? 0) > 0;
}

app.get("/healthz", (_req, res) => res.json({ ok: true, service: "chat-service" }));

// ---------------------------------------------------------------------------
// Directorio: lo mantiene sincronizado membership-service (llamada directa
// servicio-a-servicio, con INTERNAL_API_KEY) cada vez que cambia el
// membershipStatus o el consentimiento isSearchable de un socio. Solo
// aparecen aquí los socios "active" que han dado su consentimiento
// explícito para ser buscables — ver Member.isSearchable en la app iOS.
// ---------------------------------------------------------------------------

app.post("/internal/directory/upsert", requireInternal, async (req, res) => {
  const { userId, fullName, photoBase64 } = req.body as { userId: string; fullName: string; photoBase64?: string | null };
  if (!userId || !fullName) return res.status(422).json({ error: "invalidPayload" });

  await pool.query(
    `INSERT INTO chat.directory (user_id, full_name, photo_base64) VALUES ($1, $2, $3)
     ON CONFLICT (user_id) DO UPDATE SET full_name = EXCLUDED.full_name, photo_base64 = EXCLUDED.photo_base64`,
    [userId, fullName, photoBase64 ?? null]
  );
  res.status(204).end();
});

// Retira a un socio del directorio (deja de ser "chateable"): lo llama
// membership-service en cuanto membershipStatus deja de ser "active" o el
// socio desactiva su consentimiento de búsqueda (isSearchable=false).
app.post("/internal/directory/remove", requireInternal, async (req, res) => {
  const { userId } = req.body as { userId: string };
  if (!userId) return res.status(422).json({ error: "invalidPayload" });
  await pool.query("DELETE FROM chat.directory WHERE user_id = $1", [userId]);
  res.status(204).end();
});

/**
 * Búsqueda de socios "a lo Google": no un simple ILIKE, sino similitud de
 * texto con pg_trgm (operador `%`, con el umbral por defecto de Postgres,
 * 0.3) para tolerar erratas — p.ej. buscar "Pedro Gimenez" encuentra antes
 * a "Pedro Jiménez" que a "Antonio Giménez", porque comparte más trigramas
 * (nombre completo) que solo el apellido. Se combina con ILIKE como
 * refuerzo para que las coincidencias literales de subcadena (más
 * habituales con nombres cortos) nunca se queden fuera aunque su similitud
 * global sea baja.
 */
app.get("/v1/directory", requireUser, async (req, res) => {
  const query = typeof req.query.query === "string" ? req.query.query.trim() : "";
  const userId = (req as any).userId as string;

  const result = query
    ? await pool.query(
        `SELECT *, similarity(full_name, $2) AS score
         FROM chat.directory
         WHERE user_id != $1 AND (full_name % $2 OR full_name ILIKE '%' || $2 || '%')
         ORDER BY score DESC, full_name ASC
         LIMIT 30`,
        [userId, query]
      )
    : await pool.query(
        "SELECT *, 0 AS score FROM chat.directory WHERE user_id != $1 ORDER BY full_name ASC LIMIT 100",
        [userId]
      );

  const users: ChatUser[] = result.rows.map((r) => ({ id: r.user_id, fullName: r.full_name, photoData: r.photo_base64 }));
  res.json(users);
});

// ---------------------------------------------------------------------------
// Conversaciones
// ---------------------------------------------------------------------------

app.get("/v1/conversations", requireUser, async (req, res) => {
  const result = await pool.query(
    `SELECT c.* FROM chat.conversations c
     JOIN chat.conversation_participants p ON p.conversation_id = c.id
     WHERE p.user_id = $1
     ORDER BY c.last_message_at DESC NULLS LAST`,
    [(req as any).userId]
  );
  res.json(await Promise.all(result.rows.map(toConversationJSON)));
});

/**
 * Abre (o devuelve la ya existente) una conversación individual con
 * `otherUserId`. La unicidad la garantiza `chat.individual_conversation_pairs`
 * a nivel de base de datos (constraint `ordered_pair`), no solo en la
 * lógica de la aplicación.
 */
app.post("/v1/conversations/individual", requireUser, async (req, res) => {
  const me = (req as any).userId as string;
  const other = req.body?.otherUserId as string | undefined;
  if (!other) return res.status(422).json({ error: "missingOtherUserId" });

  const [userA, userB] = [me, other].sort();

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const existing = await client.query(
      "SELECT conversation_id FROM chat.individual_conversation_pairs WHERE user_a = $1 AND user_b = $2",
      [userA, userB]
    );
    if ((existing.rowCount ?? 0) > 0) {
      await client.query("COMMIT");
      const conv = await pool.query("SELECT * FROM chat.conversations WHERE id = $1", [existing.rows[0].conversation_id]);
      return res.json(await toConversationJSON(conv.rows[0]));
    }

    const id = crypto.randomUUID();
    await client.query(
      "INSERT INTO chat.conversations (id, kind, title) VALUES ($1, 'individual', '')",
      [id]
    );
    await client.query(
      "INSERT INTO chat.conversation_participants (conversation_id, user_id) VALUES ($1, $2), ($1, $3)",
      [id, userA, userB]
    );
    await client.query(
      "INSERT INTO chat.individual_conversation_pairs (user_a, user_b, conversation_id) VALUES ($1, $2, $3)",
      [userA, userB, id]
    );

    await client.query("COMMIT");
    const conv = await pool.query("SELECT * FROM chat.conversations WHERE id = $1", [id]);
    res.status(201).json(await toConversationJSON(conv.rows[0]));
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
});

async function createMultiPartyConversation(kind: "group" | "activity", req: Request, res: Response) {
  const me = (req as any).userId as string;
  const title = (req.body?.title as string | undefined)?.trim();
  const participantIds = (req.body?.participantIds as string[] | undefined) ?? [];
  const photoBase64 = (req.body?.photoBase64 as string | undefined) ?? null;

  if (!title) return res.status(422).json({ error: "emptyTitle" });
  if (participantIds.length === 0) return res.status(422).json({ error: "notEnoughParticipants" });

  const allParticipants = Array.from(new Set([...participantIds, me]));
  const id = crypto.randomUUID();

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query(
      "INSERT INTO chat.conversations (id, kind, title, photo_base64) VALUES ($1, $2, $3, $4)",
      [id, kind, title, photoBase64]
    );
    for (const userId of allParticipants) {
      await client.query(
        "INSERT INTO chat.conversation_participants (conversation_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
        [id, userId]
      );
    }
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }

  const conv = await pool.query("SELECT * FROM chat.conversations WHERE id = $1", [id]);
  res.status(201).json(await toConversationJSON(conv.rows[0]));
}

// De grupos y de actividades se pueden crear tantos como se quiera (a
// diferencia de las individuales, que están limitadas a una por pareja).
app.post("/v1/conversations/group", requireUser, (req, res) => createMultiPartyConversation("group", req, res));
app.post("/v1/conversations/activity", requireUser, (req, res) => createMultiPartyConversation("activity", req, res));

// ---------------------------------------------------------------------------
// Mensajes
// ---------------------------------------------------------------------------

app.get("/v1/conversations/:id/messages", requireUser, async (req, res) => {
  if (!(await isParticipant(req.params.id, (req as any).userId))) return res.status(403).json({ error: "forbidden" });
  const result = await pool.query(
    "SELECT * FROM chat.messages WHERE conversation_id = $1 ORDER BY sent_at ASC",
    [req.params.id]
  );
  res.json(result.rows.map(toMessageJSON));
});

app.post("/v1/conversations/:id/messages", requireUser, async (req, res) => {
  const conversationId = req.params.id;
  const userId = (req as any).userId as string;
  const userName = (req as any).userName as string;
  const text = (req.body?.text as string | undefined)?.trim();

  if (!text) return res.status(422).json({ error: "emptyMessage" });
  if (!(await isParticipant(conversationId, userId))) return res.status(403).json({ error: "forbidden" });

  const id = crypto.randomUUID();
  const inserted = await pool.query(
    `INSERT INTO chat.messages (id, conversation_id, sender_id, sender_name, text)
     VALUES ($1, $2, $3, $4, $5) RETURNING *`,
    [id, conversationId, userId, userName, text]
  );
  await pool.query(
    "UPDATE chat.conversations SET last_message_preview = $2, last_message_at = now() WHERE id = $1",
    [conversationId, text]
  );

  res.status(201).json(toMessageJSON(inserted.rows[0]));
});

// ---------------------------------------------------------------------------
// Eventos (calendario de las salas de tipo "activity")
// ---------------------------------------------------------------------------

app.get("/v1/conversations/:id/events", requireUser, async (req, res) => {
  if (!(await isParticipant(req.params.id, (req as any).userId))) return res.status(403).json({ error: "forbidden" });
  const result = await pool.query(
    "SELECT * FROM chat.events WHERE conversation_id = $1 ORDER BY start_date ASC",
    [req.params.id]
  );
  res.json(await Promise.all(result.rows.map(toEventJSON)));
});

app.post("/v1/events/:id/confirm", requireUser, async (req, res) => {
  const userId = (req as any).userId as string;
  const userName = (req as any).userName as string;

  const event = await pool.query("SELECT * FROM chat.events WHERE id = $1", [req.params.id]);
  if (event.rowCount === 0) return res.status(404).json({ error: "notFound" });
  if (!(await isParticipant(event.rows[0].conversation_id, userId))) return res.status(403).json({ error: "forbidden" });

  await pool.query(
    `INSERT INTO chat.event_attendees (event_id, user_id, name, status)
     VALUES ($1, $2, $3, 'confirmed')
     ON CONFLICT (event_id, user_id) DO UPDATE SET status = 'confirmed'`,
    [req.params.id, userId, userName]
  );

  res.json(await toEventJSON(event.rows[0]));
});

// ---------------------------------------------------------------------------
// Descubrir actividades: a diferencia de GET /v1/conversations (solo las
// tuyas), esto devuelve TODAS las salas de tipo "activity" exista o no ya
// seas participante, para que cualquier socio pueda descubrirlas y pedir
// acceso — ver ActivitiesDirectoryView en la app iOS.
// ---------------------------------------------------------------------------

app.get("/v1/conversations/activities", requireUser, async (req, res) => {
  const userId = (req as any).userId as string;

  const result = await pool.query(
    `SELECT c.*,
            EXISTS(
              SELECT 1 FROM chat.conversation_participants p
              WHERE p.conversation_id = c.id AND p.user_id = $1
            ) AS is_participant,
            (
              SELECT MIN(e.start_date) FROM chat.events e
              WHERE e.conversation_id = c.id AND e.start_date >= now()
            ) AS next_event_date
     FROM chat.conversations c
     WHERE c.kind = 'activity'
     ORDER BY next_event_date ASC NULLS LAST`,
    [userId]
  );

  const summaries: ActivitySummary[] = await Promise.all(
    result.rows.map(async (row) => ({
      conversation: await toConversationJSON(row),
      isParticipant: row.is_participant,
      nextEventDate: row.next_event_date ? new Date(row.next_event_date).toISOString() : null
    }))
  );
  res.json(summaries);
});

/**
 * Solicita acceso a una actividad de la que todavía no eres participante.
 * A diferencia del modo mock de la app iOS (que aprueba al instante para
 * poder verlo funcionar sin backoffice), aquí queda pendiente de
 * aprobación manual — la tabla `chat.activity_join_requests` es lo que
 * consumirá el futuro backoffice para aprobar/rechazar.
 */
app.post("/v1/conversations/:id/request-access", requireUser, async (req, res) => {
  const userId = (req as any).userId as string;
  const conversationId = req.params.id;

  const conversation = await pool.query("SELECT * FROM chat.conversations WHERE id = $1 AND kind = 'activity'", [conversationId]);
  if (conversation.rowCount === 0) return res.status(404).json({ error: "notFound" });
  if (await isParticipant(conversationId, userId)) {
    return res.status(200).json({ status: "alreadyMember" });
  }

  await pool.query(
    `INSERT INTO chat.activity_join_requests (conversation_id, user_id) VALUES ($1, $2)
     ON CONFLICT (conversation_id, user_id) DO NOTHING`,
    [conversationId, userId]
  );
  res.status(201).json({ status: "pending" });
});

// ---------------------------------------------------------------------------
// Administración de eventos (backoffice; fuera del alcance de la app iOS de
// esta entrega, pero el contrato ya existe).
// ---------------------------------------------------------------------------

app.post("/v1/admin/events", requireInternal, async (req, res) => {
  const { conversationId, title, eventDescription, startDate, endDate, location, attendees } = req.body as {
    conversationId: string; title: string; eventDescription?: string;
    startDate: string; endDate?: string | null; location?: string;
    attendees: { id: string; name: string }[];
  };

  if (!conversationId || !title || !startDate) return res.status(422).json({ error: "invalidPayload" });

  const id = crypto.randomUUID();
  const inserted = await pool.query(
    `INSERT INTO chat.events (id, conversation_id, title, event_description, start_date, end_date, location)
     VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
    [id, conversationId, title, eventDescription ?? "", startDate, endDate ?? null, location ?? ""]
  );

  for (const attendee of attendees ?? []) {
    await pool.query(
      "INSERT INTO chat.event_attendees (event_id, user_id, name, status) VALUES ($1, $2, $3, 'invited')",
      [id, attendee.id, attendee.name]
    );
  }

  res.status(201).json(await toEventJSON(inserted.rows[0]));
});

// ---------------------------------------------------------------------------

ensureSchema()
  .then(() => {
    app.listen(PORT, () => console.log(`chat-service escuchando en :${PORT}`));
  })
  .catch((error) => {
    console.error("No se pudo preparar el esquema de chat-service:", error);
    process.exit(1);
  });
