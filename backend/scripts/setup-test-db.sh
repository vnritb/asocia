#!/bin/bash

# Script para configurar la base de datos de test

set -e

echo "🔧 Configurando base de datos de test para Asocia..."

# Variables
DB_NAME="asocia_test"
DB_USER="asocia"
DB_PASSWORD="asocia_secret"
DB_HOST="localhost"
DB_PORT="5432"

# Verificar que PostgreSQL está corriendo
if ! pg_isready -h $DB_HOST -p $DB_PORT > /dev/null 2>&1; then
    echo "❌ PostgreSQL no está corriendo en $DB_HOST:$DB_PORT"
    echo "   Inicia PostgreSQL o ejecuta: docker compose up postgres"
    exit 1
fi

echo "✅ PostgreSQL está corriendo"

# Crear base de datos de test si no existe
echo "📦 Creando base de datos de test '$DB_NAME'..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE DATABASE $DB_NAME"

echo "✅ Base de datos '$DB_NAME' lista"

# Aplicar schema (si existe un archivo de schema)
if [ -f "../migrations/schema.sql" ]; then
    echo "📋 Aplicando schema..."
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f ../migrations/schema.sql
    echo "✅ Schema aplicado"
else
    echo "⚠️  No se encontró archivo de schema en ../migrations/schema.sql"
    echo "   Creando tablas básicas..."
    
    # Crear tablas básicas para tests
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME <<SQL
-- Tabla de miembros
CREATE TABLE IF NOT EXISTS members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    dni VARCHAR(10) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address TEXT,
    birth_date DATE,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de mensajes
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL,
    recipient_id UUID NOT NULL,
    content TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'text',
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES members(id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES members(id) ON DELETE CASCADE
);

-- Índices para mejorar rendimiento de queries
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_members_email ON members(email);
CREATE INDEX IF NOT EXISTS idx_members_dni ON members(dni);
CREATE INDEX IF NOT EXISTS idx_members_status ON members(status);

SQL
    
    echo "✅ Tablas básicas creadas"
fi

echo ""
echo "✨ Base de datos de test configurada correctamente"
echo ""
echo "Para ejecutar tests:"
echo "  npm test              # Todos los tests"
echo "  npm run test:unit     # Solo tests unitarios"
echo "  npm run test:integration  # Solo tests de integración"
echo ""
