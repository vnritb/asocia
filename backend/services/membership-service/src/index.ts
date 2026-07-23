import express, { NextFunction, Request, Response } from "express";
import cors from "cors";
import crypto from "node:crypto";
import { MEMBER_EDITABLE_FIELDS } from "@asocia/shared";
import type { Member, MembershipApplicationResponse } from "@asocia/shared";
import { pool, ensureSchema } from "./db";

const PORT = Number(process.env.PORT ?? 4001);
const ADMIN_API_KEY = process.env.ADMIN_API_KEY ?? "changeme-admin-key";
const CHAT_SERVICE_URL = process.env.CHAT_SERVICE_URL ?? "http://localhost:4002";
const INTERNAL_API_KEY = process.env.INTERNAL_API_KEY ?? "changeme-internal-key";

const app = express();
app.use(cors());
app.use(express.json({ limit: "10mb" })); // la foto en base64 puede pesar unos cuantos MB

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Convierte una fila de la tabla `members` (snake_case) al `Member` que espera la app. */
function toMemberJSON(row: any): Member {
  return {
    id: row.id,
    firstName: row.first_name,
    firstSurname: row.first_surname,
    secondSurname: row.second_surname,
    email: row.email,
    secondaryEmail: row.secondary_email,
    mobilePhone: row.mobile_phone,
    landlinePhone: row.landline_phone,
    address: row.address,
    postalCode: row.postal_code,
    city: row.city,
    province: row.province,
    birthDate: row.birth_date ? new Date(row.birth_date).toISOString() : null,
    entryYear: row.entry_year,
    exitYear: row.exit_year,
    promotion: row.promotion,
    profession: row.profession,
    workplace: row.workplace,
    iban: row.iban,
    facebookUsername: row.facebook_username,
    instagramUsername: row.instagram_username,
    xUsername: row.x_username,
    tiktokUsername: row.tiktok_username,
    photoBase64: row.photo_base64,
    isSearchable: row.is_searchable,
    associationID: row.association_id,
    isVisibleToOtherAssociations: row.is_visible_to_other_associations,
    membershipStatus: row.membership_status,
    joinDate: row.join_date ? new Date(row.join_date).toISOString() : null,
    rejectionReason: row.rejection_reason,
    updatedAt: new Date(row.updated_at).toISOString()
  };
}

function hasContact(body: Partial<Member>): boolean {
  return Boolean(body.email?.trim() || body.mobilePhone?.trim() || body.landlinePhone?.trim());
}

/**
 * Mantiene chat-service al día de quién es "chateable": un socio solo debe
 * aparecer en la búsqueda del Chat si está `active` Y ha dado su
 * consentimiento (`isSearchable`). Se llama tras cualquier cambio que pueda
 * afectar a esas dos condiciones (confirmación de alta, rechazo, o el
 * propio socio activando/desactivando el interruptor desde su ficha).
 * Falla en silencio (solo log) para no romper la operación principal si
 * chat-service está caído — la sincronización se reintentará en el
 * siguiente cambio.
 */
async function syncChatDirectory(member: Member): Promise<void> {
  const shouldBeListed = member.membershipStatus === "active" && member.isSearchable;
  const fullName = [member.firstName, member.firstSurname, member.secondSurname].filter(Boolean).join(" ");

  try {
    if (shouldBeListed) {
      await fetch(`${CHAT_SERVICE_URL}/internal/directory/upsert`, {
        method: "POST",
        headers: { "content-type": "application/json", "x-internal-key": INTERNAL_API_KEY },
        body: JSON.stringify({ userId: member.id, fullName, photoBase64: member.photoBase64 })
      });
    } else {
      await fetch(`${CHAT_SERVICE_URL}/internal/directory/remove`, {
        method: "POST",
        headers: { "content-type": "application/json", "x-internal-key": INTERNAL_API_KEY },
        body: JSON.stringify({ userId: member.id })
      });
    }
  } catch (error) {
    console.error("No se pudo sincronizar el directorio de chat-service:", error);
  }
}

async function authenticate(req: Request, res: Response, next: NextFunction) {
  const header = req.header("authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: "notAuthenticated" });

  const result = await pool.query("SELECT * FROM membership.members WHERE auth_token = $1", [token]);
  if (result.rowCount === 0) return res.status(401).json({ error: "notAuthenticated" });

  (req as any).memberRow = result.rows[0];
  next();
}

function requireAdmin(req: Request, res: Response, next: NextFunction) {
  const key = req.header("x-admin-key");
  if (key !== ADMIN_API_KEY) return res.status(403).json({ error: "forbidden" });
  next();
}

// ---------------------------------------------------------------------------
// Rutas públicas
// ---------------------------------------------------------------------------

app.get("/healthz", (_req, res) => res.json({ ok: true, service: "membership-service" }));

/**
 * Alta de un nuevo socio. Sin pago (ver docs/ARQUITECTURA.md): solo valida
 * nombre + primer apellido + al menos un contacto, y deja el registro en
 * `pendingApproval` a la espera de que el backoffice lo confirme o rechace.
 */
app.post("/v1/members/apply", async (req, res) => {
  const body = req.body as Partial<Member>;

  if (!body.firstName?.trim() || !body.firstSurname?.trim() || !hasContact(body)) {
    return res.status(422).json({ error: "invalidApplication" });
  }

  const id = body.id && /^[0-9a-f-]{36}$/i.test(body.id) ? body.id : crypto.randomUUID();
  const authToken = crypto.randomBytes(32).toString("hex");

  const result = await pool.query(
    `INSERT INTO membership.members (
       id, first_name, first_surname, second_surname, email, secondary_email,
       mobile_phone, landline_phone, address, postal_code, city, province,
       birth_date, entry_year, exit_year, promotion, profession, workplace,
       iban, facebook_username, instagram_username, x_username, tiktok_username,
       photo_base64, is_searchable, membership_status, auth_token, updated_at
     ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,'pendingApproval',$26, now())
     RETURNING *`,
    [
      id, body.firstName, body.firstSurname, body.secondSurname ?? "",
      body.email ?? "", body.secondaryEmail ?? "", body.mobilePhone ?? "", body.landlinePhone ?? "",
      body.address ?? "", body.postalCode ?? "", body.city ?? "", body.province ?? "",
      body.birthDate ?? null, body.entryYear ?? "", body.exitYear ?? "", body.promotion ?? "",
      body.profession ?? "", body.workplace ?? "", body.iban ?? "",
      body.facebookUsername ?? "", body.instagramUsername ?? "", body.xUsername ?? "", body.tiktokUsername ?? "",
      body.photoBase64 ?? null, body.isSearchable ?? false,
      authToken
    ]
  );

  const response: MembershipApplicationResponse = { authToken, member: toMemberJSON(result.rows[0]) };
  res.status(201).json(response);
});

// ---------------------------------------------------------------------------
// Rutas autenticadas (el propio socio)
// ---------------------------------------------------------------------------

app.get("/v1/members/me", authenticate, (req, res) => {
  res.json(toMemberJSON((req as any).memberRow));
});

const EDITABLE: readonly string[] = MEMBER_EDITABLE_FIELDS;

const FIELD_TO_COLUMN: Record<string, string> = {
  firstName: "first_name", firstSurname: "first_surname", secondSurname: "second_surname",
  email: "email", secondaryEmail: "secondary_email", mobilePhone: "mobile_phone",
  landlinePhone: "landline_phone", address: "address", postalCode: "postal_code",
  city: "city", province: "province", birthDate: "birth_date", entryYear: "entry_year",
  exitYear: "exit_year", promotion: "promotion", profession: "profession",
  workplace: "workplace", iban: "iban",
  facebookUsername: "facebook_username", instagramUsername: "instagram_username",
  xUsername: "x_username", tiktokUsername: "tiktok_username",
  photoBase64: "photo_base64", isSearchable: "is_searchable",
  isVisibleToOtherAssociations: "is_visible_to_other_associations"
};

/**
 * El socio solo puede editar sus propios datos personales; `membershipStatus`,
 * `joinDate` y `rejectionReason` son de solo lectura para él (los cambia el
 * backoffice a través de las rutas /v1/admin/*).
 */
app.patch("/v1/members/me", authenticate, async (req, res) => {
  const body = req.body as Partial<Member>;
  const memberId = (req as any).memberRow.id;

  const sets: string[] = [];
  const values: unknown[] = [];
  for (const field of EDITABLE) {
    if (field in body) {
      values.push((body as any)[field]);
      sets.push(`${FIELD_TO_COLUMN[field]} = $${values.length}`);
    }
  }
  if (sets.length === 0) {
    return res.json(toMemberJSON((req as any).memberRow));
  }
  values.push(memberId);

  const result = await pool.query(
    `UPDATE membership.members SET ${sets.join(", ")}, updated_at = now() WHERE id = $${values.length} RETURNING *`,
    values
  );
  const member = toMemberJSON(result.rows[0]);
  res.json(member);

  if ("isSearchable" in body || "firstName" in body || "firstSurname" in body || "secondSurname" in body || "photoBase64" in body) {
    void syncChatDirectory(member);
  }
});

// ---------------------------------------------------------------------------
// Rutas de administración (usadas por el backoffice; no están en el alcance
// de esta entrega de la app iOS, pero el contrato ya existe para que la
// futura app Android y el backoffice las consuman igual).
// ---------------------------------------------------------------------------

app.get("/v1/admin/members", requireAdmin, async (req, res) => {
  const status = typeof req.query.status === "string" ? req.query.status : null;
  const result = status
    ? await pool.query("SELECT * FROM membership.members WHERE membership_status = $1 ORDER BY updated_at DESC", [status])
    : await pool.query("SELECT * FROM membership.members ORDER BY updated_at DESC");
  res.json(result.rows.map(toMemberJSON));
});

app.post("/v1/admin/members/:id/confirm", requireAdmin, async (req, res) => {
  const result = await pool.query(
    `UPDATE membership.members
     SET membership_status = 'active', join_date = now(), rejection_reason = NULL, updated_at = now()
     WHERE id = $1 RETURNING *`,
    [req.params.id]
  );
  if (result.rowCount === 0) return res.status(404).json({ error: "notFound" });
  const member = toMemberJSON(result.rows[0]);
  res.json(member);
  void syncChatDirectory(member);
});

app.post("/v1/admin/members/:id/reject", requireAdmin, async (req, res) => {
  const reason = typeof req.body?.reason === "string" ? req.body.reason : null;
  const result = await pool.query(
    `UPDATE membership.members
     SET membership_status = 'rejected', rejection_reason = $2, updated_at = now()
     WHERE id = $1 RETURNING *`,
    [req.params.id, reason]
  );
  if (result.rowCount === 0) return res.status(404).json({ error: "notFound" });
  res.json(toMemberJSON(result.rows[0]));
});

// ---------------------------------------------------------------------------

ensureSchema()
  .then(() => {
    app.listen(PORT, () => console.log(`membership-service escuchando en :${PORT}`));
  })
  .catch((error) => {
    console.error("No se pudo preparar el esquema de membership-service:", error);
    process.exit(1);
  });
