-- Schema de base de datos para tests
-- Este archivo se usa para configurar la base de datos de test

-- Eliminar tablas existentes (para tests limpios)
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS members CASCADE;

-- Tabla de miembros
CREATE TABLE members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    dni VARCHAR(10) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address TEXT,
    birth_date DATE,
    photo_url TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'rejected')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de mensajes
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL,
    recipient_id UUID NOT NULL,
    content TEXT NOT NULL CHECK (length(content) <= 5000),
    type VARCHAR(20) DEFAULT 'text' CHECK (type IN ('text', 'image', 'file', 'system')),
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para optimizar consultas
CREATE INDEX idx_members_email ON members(email);
CREATE INDEX idx_members_dni ON members(dni);
CREATE INDEX idx_members_status ON members(status);
CREATE INDEX idx_members_created ON members(created_at);

CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_recipient ON messages(recipient_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
CREATE INDEX idx_messages_conversation ON messages(sender_id, recipient_id, created_at);
CREATE INDEX idx_messages_unread ON messages(recipient_id, read) WHERE read = FALSE;

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_members_updated_at
    BEFORE UPDATE ON members
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Datos de ejemplo para tests
INSERT INTO members (id, name, email, dni, phone, address, status) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Test User 1', 'test1@example.com', '12345678Z', '+34600111111', 'Calle Test 1', 'confirmed'),
    ('22222222-2222-2222-2222-222222222222', 'Test User 2', 'test2@example.com', '87654321X', '+34600222222', 'Calle Test 2', 'confirmed'),
    ('33333333-3333-3333-3333-333333333333', 'Test User 3', 'test3@example.com', '11111111H', '+34600333333', 'Calle Test 3', 'pending')
ON CONFLICT (email) DO NOTHING;

-- Mensajes de ejemplo
INSERT INTO messages (sender_id, recipient_id, content, type, read) VALUES
    ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'Hola, ¿cómo estás?', 'text', true),
    ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Muy bien, gracias', 'text', true),
    ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'Bienvenido a la asociación', 'text', false)
ON CONFLICT DO NOTHING;

-- Verificación
SELECT 'Members created: ' || count(*) FROM members;
SELECT 'Messages created: ' || count(*) FROM messages;
