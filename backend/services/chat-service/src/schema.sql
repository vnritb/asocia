-- Directorio de socios visible para el Chat.
CREATE TABLE IF NOT EXISTS directory (
  user_id CHAR(36) PRIMARY KEY,
  full_name VARCHAR(255) NOT NULL,
  photo_base64 TEXT NULL
);

CREATE INDEX IF NOT EXISTS idx_directory_name ON directory (full_name);

CREATE TABLE IF NOT EXISTS conversations (
  id CHAR(36) PRIMARY KEY,
  kind VARCHAR(30) NOT NULL,
  title VARCHAR(255) NOT NULL DEFAULT '',
  last_message_preview VARCHAR(255) NOT NULL DEFAULT '',
  last_message_at DATETIME NULL,
  photo_base64 TEXT NULL
);

CREATE TABLE IF NOT EXISTS conversation_participants (
  conversation_id CHAR(36) NOT NULL,
  user_id CHAR(36) NOT NULL,
  PRIMARY KEY (conversation_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_participants_user ON conversation_participants (user_id);

CREATE TABLE IF NOT EXISTS individual_conversation_pairs (
  user_a CHAR(36) NOT NULL,
  user_b CHAR(36) NOT NULL,
  conversation_id CHAR(36) NOT NULL,
  PRIMARY KEY (user_a, user_b)
);

CREATE TABLE IF NOT EXISTS messages (
  id CHAR(36) PRIMARY KEY,
  conversation_id CHAR(36) NOT NULL,
  sender_id CHAR(36) NOT NULL,
  sender_name VARCHAR(255) NOT NULL,
  text TEXT NOT NULL,
  sent_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages (conversation_id, sent_at);

CREATE TABLE IF NOT EXISTS events (
  id CHAR(36) PRIMARY KEY,
  conversation_id CHAR(36) NOT NULL,
  title VARCHAR(255) NOT NULL,
  event_description TEXT NOT NULL DEFAULT '',
  start_date DATETIME NOT NULL,
  end_date DATETIME NULL,
  location VARCHAR(255) NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS idx_events_conversation ON events (conversation_id, start_date);

CREATE TABLE IF NOT EXISTS event_attendees (
  event_id CHAR(36) NOT NULL,
  user_id CHAR(36) NOT NULL,
  name VARCHAR(255) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'invited',
  PRIMARY KEY (event_id, user_id)
);

CREATE TABLE IF NOT EXISTS activity_join_requests (
  conversation_id CHAR(36) NOT NULL,
  user_id CHAR(36) NOT NULL,
  requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (conversation_id, user_id)
);
