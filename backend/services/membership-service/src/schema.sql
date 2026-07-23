CREATE TABLE IF NOT EXISTS membership.members (
  id UUID PRIMARY KEY,
  first_name TEXT NOT NULL,
  first_surname TEXT NOT NULL,
  second_surname TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  secondary_email TEXT NOT NULL DEFAULT '',
  mobile_phone TEXT NOT NULL DEFAULT '',
  landline_phone TEXT NOT NULL DEFAULT '',
  address TEXT NOT NULL DEFAULT '',
  postal_code TEXT NOT NULL DEFAULT '',
  city TEXT NOT NULL DEFAULT '',
  province TEXT NOT NULL DEFAULT '',
  birth_date DATE,
  entry_year TEXT NOT NULL DEFAULT '',
  exit_year TEXT NOT NULL DEFAULT '',
  promotion TEXT NOT NULL DEFAULT '',
  profession TEXT NOT NULL DEFAULT '',
  workplace TEXT NOT NULL DEFAULT '',
  iban TEXT NOT NULL DEFAULT '',
  facebook_username TEXT NOT NULL DEFAULT '',
  instagram_username TEXT NOT NULL DEFAULT '',
  x_username TEXT NOT NULL DEFAULT '',
  tiktok_username TEXT NOT NULL DEFAULT '',
  photo_base64 TEXT,
  is_searchable BOOLEAN NOT NULL DEFAULT false,
  -- Roadmap (todavía sin UI ni microservicio de validación de asociaciones,
  -- ver docs/ARQUITECTURA.md): a qué asociación pertenece el socio, y si
  -- permite ser visto por socios de OTRAS asociaciones.
  association_id TEXT,
  is_visible_to_other_associations BOOLEAN NOT NULL DEFAULT false,
  membership_status TEXT NOT NULL DEFAULT 'pendingApproval'
    CHECK (membership_status IN ('pendingApproval', 'active', 'rejected')),
  join_date TIMESTAMPTZ,
  rejection_reason TEXT,
  auth_token TEXT NOT NULL UNIQUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_members_auth_token ON membership.members (auth_token);
CREATE INDEX IF NOT EXISTS idx_members_status ON membership.members (membership_status);
