/**
 * Sustituto en memoria del módulo `pg`, usado solo en los tests de
 * integración "mockeados" (ver vitest.integration.mock.config.ts). Cada
 * servicio crea su propio `new Pool(...)` en su `db.ts`, así que cada
 * instancia de FakePool recibe su propio Store: no hay que distinguir qué
 * servicio está preguntando, basta con reconocer las tablas (con su
 * esquema, p.ej. `membership.members`) en el propio texto de la consulta.
 *
 * No es un motor SQL genérico: solo entiende las consultas exactas que usan
 * los servicios reales (ver src/index.ts de cada uno). Si algún servicio
 * cambia sus queries, este fichero debe actualizarse a la vez.
 */

type Row = Record<string, any>;
type Result = { rows: Row[]; rowCount: number };

class Store {
  membershipMembers: Row[] = [];
  chatDirectory: Row[] = [];
  chatConversations: Row[] = [];
  chatParticipants: Row[] = [];
  chatPairs: Row[] = [];
  chatMessages: Row[] = [];
  chatEvents: Row[] = [];
  chatEventAttendees: Row[] = [];
  chatJoinRequests: Row[] = [];
  translations: Row[] = [];
}

function norm(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

function trigrams(s: string): Set<string> {
  const padded = `  ${s}  `;
  const set = new Set<string>();
  for (let i = 0; i < padded.length - 2; i++) set.add(padded.slice(i, i + 3));
  return set;
}

/** Aproximación tosca de `similarity()` de pg_trgm: basta para lo que comprueban los tests. */
function similarity(a: string, b: string): number {
  const ta = trigrams(a.toLowerCase());
  const tb = trigrams(b.toLowerCase());
  let common = 0;
  for (const t of ta) if (tb.has(t)) common++;
  const union = new Set([...ta, ...tb]).size;
  return union === 0 ? 0 : common / union;
}

function sortByDateDesc(rows: Row[], field: string): Row[] {
  return [...rows].sort((a, b) => {
    const av = a[field] ? new Date(a[field]).getTime() : -Infinity;
    const bv = b[field] ? new Date(b[field]).getTime() : -Infinity;
    return bv - av;
  });
}

function run(store: Store, rawText: string, params: any[] = []): Result {
  const text = norm(rawText);

  if (/CREATE (TABLE|SCHEMA|EXTENSION|INDEX)/i.test(text)) return { rows: [], rowCount: 0 };
  if (text === "BEGIN" || text === "COMMIT" || text === "ROLLBACK") return { rows: [], rowCount: 0 };

  // ------------------------------------------------------------- membership
  if (text === "SELECT * FROM membership.members WHERE auth_token = $1") {
    const rows = store.membershipMembers.filter((m) => m.auth_token === params[0]);
    return { rows, rowCount: rows.length };
  }

  if (text.includes("INSERT INTO membership.members")) {
    const row: Row = {
      id: params[0],
      first_name: params[1],
      first_surname: params[2],
      second_surname: params[3],
      email: params[4],
      secondary_email: params[5],
      mobile_phone: params[6],
      landline_phone: params[7],
      address: params[8],
      postal_code: params[9],
      city: params[10],
      province: params[11],
      birth_date: params[12],
      entry_year: params[13],
      exit_year: params[14],
      promotion: params[15],
      profession: params[16],
      workplace: params[17],
      iban: params[18],
      facebook_username: params[19],
      instagram_username: params[20],
      x_username: params[21],
      tiktok_username: params[22],
      photo_base64: params[23],
      is_searchable: params[24],
      association_id: null,
      is_visible_to_other_associations: false,
      membership_status: "pendingApproval",
      join_date: null,
      rejection_reason: null,
      auth_token: params[25],
      updated_at: new Date()
    };
    store.membershipMembers.push(row);
    return { rows: [row], rowCount: 1 };
  }

  if (text === "UPDATE membership.members SET membership_status = 'active', join_date = now(), rejection_reason = NULL, updated_at = now() WHERE id = $1 RETURNING *") {
    const row = store.membershipMembers.find((m) => m.id === params[0]);
    if (!row) return { rows: [], rowCount: 0 };
    row.membership_status = "active";
    row.join_date = new Date();
    row.rejection_reason = null;
    row.updated_at = new Date();
    return { rows: [row], rowCount: 1 };
  }

  if (text === "UPDATE membership.members SET membership_status = 'rejected', rejection_reason = $2, updated_at = now() WHERE id = $1 RETURNING *") {
    const row = store.membershipMembers.find((m) => m.id === params[0]);
    if (!row) return { rows: [], rowCount: 0 };
    row.membership_status = "rejected";
    row.rejection_reason = params[1] ?? null;
    row.updated_at = new Date();
    return { rows: [row], rowCount: 1 };
  }

  if (text.startsWith("UPDATE membership.members SET")) {
    const setPart = text.slice(text.indexOf("SET") + 3, text.indexOf("WHERE"));
    const assignments = [...setPart.matchAll(/(\w+)\s*=\s*\$(\d+)/g)];
    const whereMatch = text.match(/WHERE id = \$(\d+)/);
    const idIndex = whereMatch ? Number(whereMatch[1]) - 1 : -1;
    const row = store.membershipMembers.find((m) => m.id === params[idIndex]);
    if (!row) return { rows: [], rowCount: 0 };
    for (const match of assignments) {
      const [, column, paramIndex] = match;
      row[column] = params[Number(paramIndex) - 1];
    }
    row.updated_at = new Date();
    return { rows: [row], rowCount: 1 };
  }

  if (text === "SELECT * FROM membership.members WHERE membership_status = $1 ORDER BY updated_at DESC") {
    const rows = sortByDateDesc(
      store.membershipMembers.filter((m) => m.membership_status === params[0]),
      "updated_at"
    );
    return { rows, rowCount: rows.length };
  }

  if (text === "SELECT * FROM membership.members ORDER BY updated_at DESC") {
    const rows = sortByDateDesc(store.membershipMembers, "updated_at");
    return { rows, rowCount: rows.length };
  }

  // ------------------------------------------------------------------ chat
  if (text === "SELECT user_id FROM chat.conversation_participants WHERE conversation_id = $1") {
    const rows = store.chatParticipants.filter((p) => p.conversation_id === params[0]);
    return { rows, rowCount: rows.length };
  }

  if (text === "INSERT INTO chat.directory (user_id, full_name, photo_base64) VALUES ($1, $2, $3) ON CONFLICT (user_id) DO UPDATE SET full_name = EXCLUDED.full_name, photo_base64 = EXCLUDED.photo_base64") {
    const existing = store.chatDirectory.find((d) => d.user_id === params[0]);
    if (existing) {
      existing.full_name = params[1];
      existing.photo_base64 = params[2] ?? null;
    } else {
      store.chatDirectory.push({ user_id: params[0], full_name: params[1], photo_base64: params[2] ?? null });
    }
    return { rows: [], rowCount: 1 };
  }

  if (text === "DELETE FROM chat.directory WHERE user_id = $1") {
    const before = store.chatDirectory.length;
    store.chatDirectory = store.chatDirectory.filter((d) => d.user_id !== params[0]);
    return { rows: [], rowCount: before - store.chatDirectory.length };
  }

  if (text.includes("similarity(full_name, $2) AS score FROM chat.directory")) {
    const [userId, query] = params;
    const q = String(query).toLowerCase();
    const rows = store.chatDirectory
      .filter((d) => d.user_id !== userId)
      .map((d) => ({ ...d, score: similarity(d.full_name, query) }))
      .filter((d) => d.score > 0.15 || d.full_name.toLowerCase().includes(q))
      .sort((a, b) => b.score - a.score || a.full_name.localeCompare(b.full_name))
      .slice(0, 30);
    return { rows, rowCount: rows.length };
  }

  if (text.includes("0 AS score FROM chat.directory")) {
    const rows = store.chatDirectory
      .filter((d) => d.user_id !== params[0])
      .map((d) => ({ ...d, score: 0 }))
      .sort((a, b) => a.full_name.localeCompare(b.full_name))
      .slice(0, 100);
    return { rows, rowCount: rows.length };
  }

  if (text === "SELECT c.* FROM chat.conversations c JOIN chat.conversation_participants p ON p.conversation_id = c.id WHERE p.user_id = $1 ORDER BY c.last_message_at DESC NULLS LAST") {
    const conversationIds = new Set(store.chatParticipants.filter((p) => p.user_id === params[0]).map((p) => p.conversation_id));
    const rows = sortByDateDesc(
      store.chatConversations.filter((c) => conversationIds.has(c.id)),
      "last_message_at"
    );
    return { rows, rowCount: rows.length };
  }

  if (text === "SELECT conversation_id FROM chat.individual_conversation_pairs WHERE user_a = $1 AND user_b = $2") {
    const rows = store.chatPairs.filter((p) => p.user_a === params[0] && p.user_b === params[1]);
    return { rows, rowCount: rows.length };
  }

  if (text === "SELECT * FROM chat.conversations WHERE id = $1") {
    const rows = store.chatConversations.filter((c) => c.id === params[0]);
    return { rows, rowCount: rows.length };
  }

  if (text === "SELECT * FROM chat.conversations WHERE id = $1 AND kind = 'activity'") {
    const rows = store.chatConversations.filter((c) => c.id === params[0] && c.kind === "activity");
    return { rows, rowCount: rows.length };
  }

  if (text === "INSERT INTO chat.conversations (id, kind, title) VALUES ($1, 'individual', '')") {
    store.chatConversations.push({ id: params[0], kind: "individual", title: "", last_message_preview: "", last_message_at: null, photo_base64: null });
    return { rows: [], rowCount: 1 };
  }

  if (text === "INSERT INTO chat.conversation_participants (conversation_id, user_id) VALUES ($1, $2), ($1, $3)") {
    store.chatParticipants.push({ conversation_id: params[0], user_id: params[1] }, { conversation_id: params[0], user_id: params[2] });
    return { rows: [], rowCount: 2 };
  }

  if (text === "INSERT INTO chat.individual_conversation_pairs (user_a, user_b, conversation_id) VALUES ($1, $2, $3)") {
    store.chatPairs.push({ user_a: params[0], user_b: params[1], conversation_id: params[2] });
    return { rows: [], rowCount: 1 };
  }

  if (text === "INSERT INTO chat.conversations (id, kind, title, photo_base64) VALUES ($1, $2, $3, $4)") {
    store.chatConversations.push({ id: params[0], kind: params[1], title: params[2], photo_base64: params[3] ?? null, last_message_preview: "", last_message_at: null });
    return { rows: [], rowCount: 1 };
  }

  if (text === "INSERT INTO chat.conversation_participants (conversation_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING") {
    const exists = store.chatParticipants.some((p) => p.conversation_id === params[0] && p.user_id === params[1]);
    if (!exists) store.chatParticipants.push({ conversation_id: params[0], user_id: params[1] });
    return { rows: [], rowCount: exists ? 0 : 1 };
  }

  if (text === "SELECT * FROM chat.messages WHERE conversation_id = $1 ORDER BY sent_at ASC") {
    const rows = [...store.chatMessages.filter((m) => m.conversation_id === params[0])].sort(
      (a, b) => new Date(a.sent_at).getTime() - new Date(b.sent_at).getTime()
    );
    return { rows, rowCount: rows.length };
  }

  if (text === "INSERT INTO chat.messages (id, conversation_id, sender_id, sender_name, text) VALUES ($1, $2, $3, $4, $5) RETURNING *") {
    const row = { id: params[0], conversation_id: params[1], sender_id: params[2], sender_name: params[3], text: params[4], sent_at: new Date() };
    store.chatMessages.push(row);
    return { rows: [row], rowCount: 1 };
  }

  if (text === "UPDATE chat.conversations SET last_message_preview = $2, last_message_at = now() WHERE id = $1") {
    const row = store.chatConversations.find((c) => c.id === params[0]);
    if (row) {
      row.last_message_preview = params[1];
      row.last_message_at = new Date();
    }
    return { rows: [], rowCount: row ? 1 : 0 };
  }

  if (text === "SELECT * FROM chat.events WHERE conversation_id = $1 ORDER BY start_date ASC") {
    const rows = [...store.chatEvents.filter((e) => e.conversation_id === params[0])].sort(
      (a, b) => new Date(a.start_date).getTime() - new Date(b.start_date).getTime()
    );
    return { rows, rowCount: rows.length };
  }

  if (text === "SELECT * FROM chat.events WHERE id = $1") {
    const rows = store.chatEvents.filter((e) => e.id === params[0]);
    return { rows, rowCount: rows.length };
  }

  if (text === "INSERT INTO chat.event_attendees (event_id, user_id, name, status) VALUES ($1, $2, $3, 'confirmed') ON CONFLICT (event_id, user_id) DO UPDATE SET status = 'confirmed'") {
    const existing = store.chatEventAttendees.find((a) => a.event_id === params[0] && a.user_id === params[1]);
    if (existing) {
      existing.status = "confirmed";
    } else {
      store.chatEventAttendees.push({ event_id: params[0], user_id: params[1], name: params[2], status: "confirmed" });
    }
    return { rows: [], rowCount: 1 };
  }

  if (text.includes("FROM chat.conversations c") && text.includes("WHERE c.kind = 'activity'")) {
    const userId = params[0];
    const rows = store.chatConversations
      .filter((c) => c.kind === "activity")
      .map((c) => {
        const isParticipant = store.chatParticipants.some((p) => p.conversation_id === c.id && p.user_id === userId);
        const upcoming = store.chatEvents
          .filter((e) => e.conversation_id === c.id && new Date(e.start_date).getTime() >= Date.now())
          .map((e) => new Date(e.start_date).getTime());
        const nextEventDate = upcoming.length > 0 ? new Date(Math.min(...upcoming)) : null;
        return { ...c, is_participant: isParticipant, next_event_date: nextEventDate };
      })
      .sort((a, b) => {
        if (!a.next_event_date && !b.next_event_date) return 0;
        if (!a.next_event_date) return 1;
        if (!b.next_event_date) return -1;
        return a.next_event_date.getTime() - b.next_event_date.getTime();
      });
    return { rows, rowCount: rows.length };
  }

  if (text === "INSERT INTO chat.activity_join_requests (conversation_id, user_id) VALUES ($1, $2) ON CONFLICT (conversation_id, user_id) DO NOTHING") {
    const exists = store.chatJoinRequests.some((r) => r.conversation_id === params[0] && r.user_id === params[1]);
    if (!exists) store.chatJoinRequests.push({ conversation_id: params[0], user_id: params[1], requested_at: new Date() });
    return { rows: [], rowCount: exists ? 0 : 1 };
  }

  if (text === "INSERT INTO chat.events (id, conversation_id, title, event_description, start_date, end_date, location) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *") {
    const row = {
      id: params[0], conversation_id: params[1], title: params[2], event_description: params[3],
      start_date: params[4], end_date: params[5] ?? null, location: params[6]
    };
    store.chatEvents.push(row);
    return { rows: [row], rowCount: 1 };
  }

  if (text === "INSERT INTO chat.event_attendees (event_id, user_id, name, status) VALUES ($1, $2, $3, 'invited')") {
    store.chatEventAttendees.push({ event_id: params[0], user_id: params[1], name: params[2], status: "invited" });
    return { rows: [], rowCount: 1 };
  }

  if (text === "SELECT user_id, name, status FROM chat.event_attendees WHERE event_id = $1") {
    const rows = store.chatEventAttendees.filter((a) => a.event_id === params[0]);
    return { rows, rowCount: rows.length };
  }

  // --------------------------------------------------------- translation
  if (text === "SELECT key, value FROM translation.translations WHERE language_code = $1 AND key = ANY($2)") {
    const keys: string[] = params[1];
    const rows = store.translations.filter((t) => t.language_code === params[0] && keys.includes(t.key));
    return { rows, rowCount: rows.length };
  }

  if (text === "INSERT INTO translation.translations (language_code, key, value) VALUES ($1, $2, $3) ON CONFLICT (language_code, key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()") {
    const existing = store.translations.find((t) => t.language_code === params[0] && t.key === params[1]);
    if (existing) {
      existing.value = params[2];
      existing.updated_at = new Date();
    } else {
      store.translations.push({ language_code: params[0], key: params[1], value: params[2], updated_at: new Date() });
    }
    return { rows: [], rowCount: 1 };
  }

  throw new Error(`fakePg: consulta no soportada por el mock:\n${rawText}`);
}

class FakeClient {
  constructor(private store: Store) {}
  async query(text: string, params?: any[]): Promise<Result> {
    return run(this.store, text, params ?? []);
  }
  release(): void {}
}

export class Pool {
  private store = new Store();

  constructor(_config?: unknown) {}

  async query(text: string, params?: any[]): Promise<Result> {
    return run(this.store, text, params ?? []);
  }

  async connect(): Promise<FakeClient> {
    return new FakeClient(this.store);
  }

  async end(): Promise<void> {}

  on(): void {}
}

export class Client extends Pool {}

export default { Pool, Client };
