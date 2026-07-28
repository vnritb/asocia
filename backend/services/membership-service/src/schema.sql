CREATE TABLE IF NOT EXISTS members (
  id CHAR(36) PRIMARY KEY,
  first_name VARCHAR(255) NOT NULL,
  first_surname VARCHAR(255) NOT NULL,
  second_surname VARCHAR(255) NOT NULL DEFAULT '',
  email VARCHAR(255) NOT NULL DEFAULT '',
  secondary_email VARCHAR(255) NOT NULL DEFAULT '',
  mobile_phone VARCHAR(255) NOT NULL DEFAULT '',
  landline_phone VARCHAR(255) NOT NULL DEFAULT '',
  address VARCHAR(255) NOT NULL DEFAULT '',
  postal_code VARCHAR(50) NOT NULL DEFAULT '',
  city VARCHAR(255) NOT NULL DEFAULT '',
  province VARCHAR(255) NOT NULL DEFAULT '',
  birth_date DATE NULL,
  entry_year VARCHAR(50) NOT NULL DEFAULT '',
  exit_year VARCHAR(50) NOT NULL DEFAULT '',
  promotion VARCHAR(100) NOT NULL DEFAULT '',
  profession VARCHAR(255) NOT NULL DEFAULT '',
  workplace VARCHAR(255) NOT NULL DEFAULT '',
  iban VARCHAR(255) NOT NULL DEFAULT '',
  facebook_username VARCHAR(255) NOT NULL DEFAULT '',
  instagram_username VARCHAR(255) NOT NULL DEFAULT '',
  x_username VARCHAR(255) NOT NULL DEFAULT '',
  tiktok_username VARCHAR(255) NOT NULL DEFAULT '',
  photo_base64 TEXT NULL,
  is_searchable BOOLEAN NOT NULL DEFAULT false,
  association_id VARCHAR(255) NULL,
  is_visible_to_other_associations BOOLEAN NOT NULL DEFAULT false,
  membership_status VARCHAR(50) NOT NULL DEFAULT 'pendingApproval',
  join_date DATETIME NULL,
  rejection_reason TEXT NULL,
  auth_token VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL DEFAULT '',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CREATE TABLE IF NOT EXISTS no toca una tabla ya existente: esta línea
-- añade password_hash a los despliegues que se crearon antes de que
-- existiera el login por email/contraseña (ver POST /v1/members/login).
ALTER TABLE members ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NOT NULL DEFAULT '';

CREATE INDEX IF NOT EXISTS idx_members_auth_token ON members (auth_token);
CREATE INDEX IF NOT EXISTS idx_members_status ON members (membership_status);
CREATE INDEX IF NOT EXISTS idx_members_email ON members (email);
