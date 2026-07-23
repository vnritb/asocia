-- pg_trgm habilita búsqueda "a lo Google" por similitud de texto
-- (tolerante a erratas, p.ej. "Gimenez" encuentra "Jiménez"), en vez de un
-- simple LIKE/ILIKE que solo encuentra coincidencias literales. Ver
-- GET /v1/directory en src/index.ts.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Directorio de socios visible para el Chat (se mantiene sincronizado
-- desde membership-service vía POST /internal/directory/upsert cada vez
-- que un socio pasa a "active" + tiene isSearchable=true, o se retira con
-- /internal/directory/remove cuando deja de cumplir alguna de las dos
-- condiciones; ver src/index.ts).
CREATE TABLE IF NOT EXISTS chat.directory (
  user_id UUID PRIMARY KEY,
  full_name TEXT NOT NULL,
  photo_base64 TEXT
);

CREATE INDEX IF NOT EXISTS idx_directory_name_trgm ON chat.directory USING GIN (full_name gin_trgm_ops);

CREATE TABLE IF NOT EXISTS chat.conversations (
  id UUID PRIMARY KEY,
  kind TEXT NOT NULL CHECK (kind IN ('individual', 'group', 'activity')),
  title TEXT NOT NULL DEFAULT '',
  last_message_preview TEXT NOT NULL DEFAULT '',
  last_message_at TIMESTAMPTZ,
  -- Solo se usa en salas "activity", para el listado grande de
  -- "Todas las actividades" (GET /v1/conversations/activities).
  photo_base64 TEXT
);

CREATE TABLE IF NOT EXISTS chat.conversation_participants (
  conversation_id UUID NOT NULL REFERENCES chat.conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  PRIMARY KEY (conversation_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_participants_user ON chat.conversation_participants (user_id);

-- Garantiza a nivel de base de datos que solo puede existir una conversación
-- INDIVIDUAL por pareja de usuarios: user_a/user_b se guardan siempre
-- ordenados (user_a < user_b), así da igual quién empiece la conversación.
CREATE TABLE IF NOT EXISTS chat.individual_conversation_pairs (
  user_a UUID NOT NULL,
  user_b UUID NOT NULL,
  conversation_id UUID NOT NULL REFERENCES chat.conversations(id) ON DELETE CASCADE,
  PRIMARY KEY (user_a, user_b),
  CONSTRAINT ordered_pair CHECK (user_a < user_b)
);

CREATE TABLE IF NOT EXISTS chat.messages (
  id UUID PRIMARY KEY,
  conversation_id UUID NOT NULL REFERENCES chat.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL,
  sender_name TEXT NOT NULL,
  text TEXT NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON chat.messages (conversation_id, sent_at);

-- Eventos de las salas de tipo "activity". Los crea/edita el backoffice
-- (rutas /v1/admin/*); el socio solo lee y confirma asistencia.
CREATE TABLE IF NOT EXISTS chat.events (
  id UUID PRIMARY KEY,
  conversation_id UUID NOT NULL REFERENCES chat.conversations(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  event_description TEXT NOT NULL DEFAULT '',
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  location TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS idx_events_conversation ON chat.events (conversation_id, start_date);

CREATE TABLE IF NOT EXISTS chat.event_attendees (
  event_id UUID NOT NULL REFERENCES chat.events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'invited' CHECK (status IN ('invited', 'confirmed')),
  PRIMARY KEY (event_id, user_id)
);

-- Solicitudes de acceso a una actividad de la que todavía no eres
-- participante (ver GET /v1/conversations/activities y
-- POST /v1/conversations/:id/request-access). A diferencia de la app iOS en
-- modo mock (que las aprueba al instante para poder verlo funcionar sin
-- backoffice), aquí quedan pendientes de aprobación manual — roadmap, ver
-- docs/ARQUITECTURA.md.
CREATE TABLE IF NOT EXISTS chat.activity_join_requests (
  conversation_id UUID NOT NULL REFERENCES chat.conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (conversation_id, user_id)
);
