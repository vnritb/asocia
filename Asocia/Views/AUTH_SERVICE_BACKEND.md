# 🔐 Auth Service - Microservicio de Autenticación

## Implementación Completa del Backend

Este microservicio maneja login, registro y autenticación con JWT.

---

## 📁 Estructura del Proyecto

```
auth-service/
├── src/
│   ├── index.js          # Servidor principal
│   ├── routes/
│   │   └── auth.js       # Rutas de autenticación
│   ├── middleware/
│   │   └── auth.js       # Middleware de verificación JWT
│   └── db.js             # Conexión a base de datos
├── package.json
├── .env
└── Dockerfile
```

---

## 📄 Archivos del Backend

### 1. `package.json`

```json
{
  "name": "auth-service",
  "version": "1.0.0",
  "description": "Servicio de autenticación para Asocia",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "pg": "^8.11.3",
    "dotenv": "^16.3.1",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
```

### 2. `src/index.js`

```javascript
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Rutas
app.use('/v1/auth', authRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'auth-service' });
});

app.listen(PORT, () => {
  console.log(`🔐 Auth Service running on port ${PORT}`);
});
```

### 3. `src/routes/auth.js`

```javascript
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');

const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'tu-secreto-super-seguro-cambiar-en-produccion';
const JWT_EXPIRES_IN = '30d'; // Token válido por 30 días

/**
 * POST /v1/auth/register
 * Registra un nuevo usuario (sin datos completos, solo credenciales)
 */
router.post('/register', async (req, res) => {
  try {
    const { email, password, firstName, firstSurname } = req.body;
    
    // Validaciones básicas
    if (!email || !password || !firstName || !firstSurname) {
      return res.status(400).json({ 
        error: 'Email, contraseña, nombre y apellido son obligatorios' 
      });
    }
    
    if (password.length < 6) {
      return res.status(400).json({ 
        error: 'La contraseña debe tener al menos 6 caracteres' 
      });
    }
    
    // Verificar si el email ya existe
    const existingUser = await db.query(
      'SELECT id FROM members WHERE email = $1',
      [email]
    );
    
    if (existingUser.rows.length > 0) {
      return res.status(409).json({ 
        error: 'Este email ya está registrado' 
      });
    }
    
    // Hashear contraseña
    const passwordHash = await bcrypt.hash(password, 10);
    
    // Crear usuario
    const result = await db.query(
      `INSERT INTO members (
        email, password_hash, first_name, first_surname, 
        is_searchable, membership_status
      ) VALUES ($1, $2, $3, $4, false, 'pending_approval')
      RETURNING id, email, first_name, first_surname, membership_status, created_at`,
      [email, passwordHash, firstName, firstSurname]
    );
    
    const user = result.rows[0];
    
    // Generar token JWT
    const token = jwt.sign(
      { 
        id: user.id, 
        email: user.email 
      }, 
      JWT_SECRET, 
      { expiresIn: JWT_EXPIRES_IN }
    );
    
    console.log(`✅ [AUTH] Usuario registrado: ${email}`);
    
    // Devolver token y datos básicos del usuario
    res.status(201).json({
      token,
      member: formatMemberDTO(user)
    });
    
  } catch (error) {
    console.error('❌ Error en registro:', error);
    res.status(500).json({ error: 'Error al registrar usuario' });
  }
});

/**
 * POST /v1/auth/login
 * Autentica un usuario existente
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ 
        error: 'Email y contraseña son obligatorios' 
      });
    }
    
    // Buscar usuario por email
    const result = await db.query(
      `SELECT 
        id, email, password_hash, first_name, first_surname, second_surname,
        secondary_email, mobile_phone, landline_phone, address, postal_code,
        city, province, birth_date, entry_year, exit_year, promotion,
        profession, workplace, iban, facebook_username, instagram_username,
        x_username, tiktok_username, photo_data, is_searchable,
        association_id, is_visible_to_other_associations, membership_status,
        join_date, rejection_reason, updated_at
      FROM members 
      WHERE email = $1`,
      [email]
    );
    
    if (result.rows.length === 0) {
      return res.status(401).json({ 
        error: 'Email o contraseña incorrectos' 
      });
    }
    
    const user = result.rows[0];
    
    // Verificar contraseña
    const passwordMatch = await bcrypt.compare(password, user.password_hash);
    
    if (!passwordMatch) {
      return res.status(401).json({ 
        error: 'Email o contraseña incorrectos' 
      });
    }
    
    // Generar token JWT
    const token = jwt.sign(
      { 
        id: user.id, 
        email: user.email 
      }, 
      JWT_SECRET, 
      { expiresIn: JWT_EXPIRES_IN }
    );
    
    console.log(`✅ [AUTH] Login exitoso: ${email}`);
    
    // Devolver token y datos completos del usuario
    res.json({
      token,
      member: formatMemberDTO(user)
    });
    
  } catch (error) {
    console.error('❌ Error en login:', error);
    res.status(500).json({ error: 'Error al iniciar sesión' });
  }
});

/**
 * Formatea un usuario de la BD al DTO esperado por la app
 */
function formatMemberDTO(user) {
  return {
    id: user.id,
    firstName: user.first_name || '',
    firstSurname: user.first_surname || '',
    secondSurname: user.second_surname || '',
    email: user.email,
    secondaryEmail: user.secondary_email || '',
    mobilePhone: user.mobile_phone || '',
    landlinePhone: user.landline_phone || '',
    address: user.address || '',
    postalCode: user.postal_code || '',
    city: user.city || '',
    province: user.province || '',
    birthDate: user.birth_date,
    entryYear: user.entry_year || '',
    exitYear: user.exit_year || '',
    promotion: user.promotion || '',
    profession: user.profession || '',
    workplace: user.workplace || '',
    iban: user.iban || '',
    facebookUsername: user.facebook_username || '',
    instagramUsername: user.instagram_username || '',
    xUsername: user.x_username || '',
    tiktokUsername: user.tiktok_username || '',
    photoBase64: user.photo_data ? user.photo_data.toString('base64') : null,
    isSearchable: user.is_searchable || false,
    associationID: user.association_id,
    isVisibleToOtherAssociations: user.is_visible_to_other_associations || false,
    membershipStatus: user.membership_status || 'pending_approval',
    joinDate: user.join_date,
    rejectionReason: user.rejection_reason,
    updatedAt: user.updated_at || user.created_at
  };
}

module.exports = router;
```

### 4. `src/db.js`

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'asocia',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

pool.on('connect', () => {
  console.log('✅ Conectado a PostgreSQL');
});

pool.on('error', (err) => {
  console.error('❌ Error inesperado en PostgreSQL:', err);
});

module.exports = pool;
```

### 5. `.env`

```env
PORT=3001
DB_HOST=localhost
DB_PORT=5432
DB_NAME=asocia
DB_USER=postgres
DB_PASSWORD=postgres
JWT_SECRET=tu-secreto-super-seguro-cambiar-en-produccion-123456789
```

---

## 🗄️ Schema de Base de Datos

### Actualizar tabla `members`

```sql
-- Agregar columna para contraseña hasheada
ALTER TABLE members 
ADD COLUMN password_hash VARCHAR(255);

-- Índice para búsquedas rápidas por email
CREATE INDEX idx_members_email ON members(email);

-- Datos de prueba con contraseñas
-- Contraseña para todos: "password123"
-- Hash generado con bcrypt.hash('password123', 10)

UPDATE members SET password_hash = '$2a$10$YourHashedPasswordHere' 
WHERE email = 'ana.garcia@example.com';

-- O insertar usuario nuevo con contraseña
-- Primero genera el hash en Node.js:
-- const bcrypt = require('bcryptjs');
-- const hash = await bcrypt.hash('password123', 10);
-- console.log(hash);
```

---

## 🚀 Instalación y Ejecución

### 1. Instalar Dependencias

```bash
cd auth-service
npm install
```

### 2. Configurar Base de Datos

```bash
# Asegúrate de tener PostgreSQL corriendo
psql -U postgres -d asocia -f schema.sql
```

### 3. Ejecutar en Desarrollo

```bash
npm run dev
```

### 4. Ejecutar en Producción

```bash
npm start
```

---

## 🧪 Pruebas

### Usando cURL

```bash
# 1. Registrar nuevo usuario
curl -X POST http://localhost:3001/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "nuevo@example.com",
    "password": "password123",
    "firstName": "Nuevo",
    "firstSurname": "Usuario"
  }'

# Respuesta:
# {
#   "token": "eyJhbGc...",
#   "member": { ... }
# }

# 2. Login
curl -X POST http://localhost:3001/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "nuevo@example.com",
    "password": "password123"
  }'

# Respuesta:
# {
#   "token": "eyJhbGc...",
#   "member": { ... }
# }
```

---

## 🐳 Docker

### `Dockerfile`

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY src ./src

EXPOSE 3001

CMD ["node", "src/index.js"]
```

### `docker-compose.yml`

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: asocia
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  auth-service:
    build: ./auth-service
    ports:
      - "3001:3001"
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: asocia
      DB_USER: postgres
      DB_PASSWORD: postgres
      JWT_SECRET: supersecret123456789
    depends_on:
      - postgres

volumes:
  postgres_data:
```

### Ejecutar con Docker

```bash
docker-compose up -d
```

---

## 📊 Logging Esperado

### En el servidor

```
✅ Conectado a PostgreSQL
🔐 Auth Service running on port 3001

✅ [AUTH] Usuario registrado: nuevo@example.com
✅ [AUTH] Login exitoso: ana.garcia@example.com
```

### En la app iOS

```
🔐 [AUTH] login - email: ana.garcia@example.com
   🌐 [POST] http://localhost:3001/v1/auth/login
   ✅ Response: 200 (234ms)
   ✅ Login exitoso - Token guardado
   💾 Token guardado en Keychain

✅ RootView - Verificación de autenticación
   Token válido: true
   Miembros encontrados: 1
   Estado del miembro: active
```

---

## 🔒 Seguridad

### Buenas Prácticas Implementadas

✅ Contraseñas hasheadas con bcrypt (10 rounds)
✅ Tokens JWT con expiración
✅ Validación de entrada
✅ Manejo seguro de errores (sin revelar info sensible)
✅ Almacenamiento en Keychain (iOS)

### Para Producción

⚠️ Cambiar `JWT_SECRET` a un valor aleatorio y seguro
⚠️ Usar HTTPS en producción
⚠️ Implementar rate limiting
⚠️ Agregar refresh tokens
⚠️ Implementar logout en servidor (lista negra de tokens)

---

## ✅ Checklist

- [ ] Crear carpeta `auth-service`
- [ ] Crear `package.json`
- [ ] Crear `src/index.js`
- [ ] Crear `src/routes/auth.js`
- [ ] Crear `src/db.js`
- [ ] Crear `.env`
- [ ] Ejecutar `npm install`
- [ ] Agregar columna `password_hash` a tabla `members`
- [ ] Iniciar servidor: `npm run dev`
- [ ] Probar endpoint `/v1/auth/register`
- [ ] Probar endpoint `/v1/auth/login`
- [ ] Verificar que el token se guarda en Keychain

---

**Fecha:** 26 de julio de 2026  
**Versión:** 1.0  
**Puerto:** 3001  
**Endpoints:** /v1/auth/login, /v1/auth/register
