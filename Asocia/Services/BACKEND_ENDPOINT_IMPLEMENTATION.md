# 🚀 Implementación del Endpoint de Paginación - Backend

## 📋 Endpoint a Implementar

```
GET /v1/directory
```

**Query Parameters:**
- `query` (string, opcional): Texto de búsqueda
- `page` (int, default: 0): Número de página (0-indexed)
- `pageSize` (int, default: 10): Elementos por página

**Response:**
```json
{
  "users": [
    {
      "id": "uuid",
      "fullName": "string",
      "photoData": "base64 | null"
    }
  ],
  "hasMore": boolean
}
```

---

## 🟢 Implementación Node.js + Express + PostgreSQL

### 1. Archivo: `routes/directory.js`

```javascript
const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const db = require('../db');

/**
 * GET /v1/directory
 * 
 * Búsqueda de usuarios con paginación y similitud de texto (pg_trgm)
 * Requiere autenticación.
 */
router.get('/v1/directory', authenticateToken, async (req, res) => {
  try {
    const { query = '', page = 0, pageSize = 10 } = req.query;
    
    // Validar parámetros
    const pageNum = Math.max(0, parseInt(page) || 0);
    const pageSizeNum = Math.min(100, Math.max(1, parseInt(pageSize) || 10));
    const offset = pageNum * pageSizeNum;
    
    // Query con búsqueda por similitud (pg_trgm)
    const searchQuery = `
      SELECT 
        id,
        first_name,
        first_surname,
        second_surname,
        CONCAT(first_name, ' ', first_surname, 
               CASE WHEN second_surname != '' THEN ' ' || second_surname ELSE '' END) AS full_name,
        photo_data,
        CASE 
          WHEN $1 = '' THEN 1.0
          ELSE similarity(
            CONCAT(first_name, ' ', first_surname, 
                   CASE WHEN second_surname != '' THEN ' ' || second_surname ELSE '' END),
            $1
          )
        END AS score
      FROM members
      WHERE 
        is_searchable = true
        AND membership_status = 'active'
        AND id != $4  -- Excluir al usuario actual
        AND (
          $1 = ''  -- Si query vacío, devolver todos
          OR similarity(
            CONCAT(first_name, ' ', first_surname, 
                   CASE WHEN second_surname != '' THEN ' ' || second_surname ELSE '' END),
            $1
          ) > 0.15
          OR CONCAT(first_name, ' ', first_surname, 
                    CASE WHEN second_surname != '' THEN ' ' || second_surname ELSE '' END
              ) ILIKE '%' || $1 || '%'
        )
      ORDER BY score DESC, full_name ASC
      LIMIT $2 OFFSET $3
    `;
    
    // Ejecutar búsqueda
    const result = await db.query(searchQuery, [
      query,
      pageSizeNum + 1,  // Pedir uno más para saber si hay más páginas
      offset,
      req.user.id  // ID del usuario autenticado (del token)
    ]);
    
    // Calcular hasMore
    const hasMore = result.rows.length > pageSizeNum;
    const users = result.rows.slice(0, pageSizeNum);
    
    // Formatear respuesta
    const formattedUsers = users.map(user => ({
      id: user.id,
      fullName: user.full_name,
      photoData: user.photo_data ? user.photo_data.toString('base64') : null
    }));
    
    console.log(`📖 Directory search: query="${query}", page=${pageNum}, found=${formattedUsers.length}, hasMore=${hasMore}`);
    
    res.json({
      users: formattedUsers,
      hasMore: hasMore
    });
    
  } catch (error) {
    console.error('❌ Error en /v1/directory:', error);
    res.status(500).json({ 
      error: 'Error interno del servidor',
      message: error.message 
    });
  }
});

module.exports = router;
```

### 2. Archivo: `middleware/auth.js`

```javascript
const jwt = require('jsonwebtoken');

/**
 * Middleware de autenticación
 * Extrae y verifica el token Bearer del header Authorization
 */
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
  
  if (!token) {
    return res.status(401).json({ error: 'Token no proporcionado' });
  }
  
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Token inválido' });
    }
    
    req.user = user;  // { id: 'uuid', ... }
    next();
  });
}

module.exports = { authenticateToken };
```

### 3. Archivo: `index.js` o `app.js` (Registrar ruta)

```javascript
const express = require('express');
const directoryRoutes = require('./routes/directory');

const app = express();

// Middleware
app.use(express.json());

// Rutas
app.use('/api', directoryRoutes);

// ... resto de configuración

app.listen(3000, () => {
  console.log('🚀 Server running on port 3000');
});
```

### 4. Archivo: `db.js` (Conexión PostgreSQL)

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'asocia',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

// Verificar extensión pg_trgm
pool.query('CREATE EXTENSION IF NOT EXISTS pg_trgm;', (err) => {
  if (err) {
    console.error('⚠️  No se pudo crear extensión pg_trgm:', err.message);
  } else {
    console.log('✅ Extensión pg_trgm disponible');
  }
});

module.exports = pool;
```

### 5. Instalación de Dependencias

```bash
npm install express pg jsonwebtoken dotenv
```

### 6. Variables de Entorno (`.env`)

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=asocia
DB_USER=postgres
DB_PASSWORD=postgres

JWT_SECRET=tu-secreto-super-seguro-cambiar-en-produccion
PORT=3000
```

---

## 🔵 Implementación Node.js + Express + MariaDB

### 1. Archivo: `routes/directory.js` (MariaDB)

```javascript
const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const db = require('../db');

router.get('/v1/directory', authenticateToken, async (req, res) => {
  try {
    const { query = '', page = 0, pageSize = 10 } = req.query;
    
    const pageNum = Math.max(0, parseInt(page) || 0);
    const pageSizeNum = Math.min(100, Math.max(1, parseInt(pageSize) || 10));
    const offset = pageNum * pageSizeNum;
    
    // MariaDB no tiene pg_trgm, usamos LIKE con %
    const searchQuery = `
      SELECT 
        id,
        first_name,
        first_surname,
        second_surname,
        CONCAT(first_name, ' ', first_surname, 
               IF(second_surname != '', CONCAT(' ', second_surname), '')) AS full_name,
        photo_data
      FROM members
      WHERE 
        is_searchable = 1
        AND membership_status = 'active'
        AND id != ?
        AND (
          ? = ''
          OR CONCAT(first_name, ' ', first_surname, 
                    IF(second_surname != '', CONCAT(' ', second_surname), '')
              ) LIKE CONCAT('%', ?, '%')
        )
      ORDER BY full_name ASC
      LIMIT ? OFFSET ?
    `;
    
    const [rows] = await db.query(searchQuery, [
      req.user.id,
      query,
      query,
      pageSizeNum + 1,
      offset
    ]);
    
    const hasMore = rows.length > pageSizeNum;
    const users = rows.slice(0, pageSizeNum);
    
    const formattedUsers = users.map(user => ({
      id: user.id,
      fullName: user.full_name,
      photoData: user.photo_data ? user.photo_data.toString('base64') : null
    }));
    
    console.log(`📖 Directory search: query="${query}", page=${pageNum}, found=${formattedUsers.length}, hasMore=${hasMore}`);
    
    res.json({
      users: formattedUsers,
      hasMore: hasMore
    });
    
  } catch (error) {
    console.error('❌ Error en /v1/directory:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
```

### 2. Archivo: `db.js` (MariaDB)

```javascript
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  database: process.env.DB_NAME || 'asocia',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'password',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

module.exports = pool;
```

### 3. Instalación (MariaDB)

```bash
npm install express mysql2 jsonwebtoken dotenv
```

---

## 🗄️ Schema de Base de Datos

### PostgreSQL

```sql
-- Crear extensión para búsqueda por similitud
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Tabla members (simplificada)
CREATE TABLE members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    first_surname VARCHAR(100) NOT NULL,
    second_surname VARCHAR(100) DEFAULT '',
    email VARCHAR(255) NOT NULL UNIQUE,
    photo_data BYTEA,
    is_searchable BOOLEAN DEFAULT false,
    membership_status VARCHAR(20) DEFAULT 'pending_approval',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice para búsquedas rápidas
CREATE INDEX idx_members_searchable ON members(is_searchable, membership_status);

-- Índice GIN para pg_trgm (búsqueda por similitud)
CREATE INDEX idx_members_fullname_trgm ON members 
USING GIN ((first_name || ' ' || first_surname || ' ' || second_surname) gin_trgm_ops);

-- Datos de prueba (20 usuarios)
INSERT INTO members (first_name, first_surname, second_surname, email, is_searchable, membership_status) VALUES
('Marta', 'Puig', '', 'marta.puig@example.com', true, 'active'),
('Jordi', 'Serra', '', 'jordi.serra@example.com', true, 'active'),
('Laia', 'Font', '', 'laia.font@example.com', true, 'active'),
('Pol', 'Vidal', '', 'pol.vidal@example.com', true, 'active'),
('Núria', 'Camps', '', 'nuria.camps@example.com', true, 'active'),
('Àlex', 'Ribas', '', 'alex.ribas@example.com', true, 'active'),
('Clara', 'Soler', '', 'clara.soler@example.com', true, 'active'),
('Bernat', 'Roca', '', 'bernat.roca@example.com', true, 'active'),
('Gemma', 'Vila', '', 'gemma.vila@example.com', true, 'active'),
('Oriol', 'Mas', '', 'oriol.mas@example.com', true, 'active'),
('Pedro', 'Jiménez', '', 'pedro.jimenez@example.com', true, 'active'),
('Antonio', 'Giménez', '', 'antonio.gimenez@example.com', true, 'active'),
('María', 'González', '', 'maria.gonzalez@example.com', true, 'active'),
('Carlos', 'Rodríguez', '', 'carlos.rodriguez@example.com', true, 'active'),
('Laura', 'Martínez', '', 'laura.martinez@example.com', true, 'active'),
('David', 'López', '', 'david.lopez@example.com', true, 'active'),
('Carmen', 'Sánchez', '', 'carmen.sanchez@example.com', true, 'active'),
('Miguel', 'Fernández', '', 'miguel.fernandez@example.com', true, 'active'),
('Elena', 'García', '', 'elena.garcia@example.com', true, 'active'),
('Javier', 'Torres', '', 'javier.torres@example.com', true, 'active');
```

### MariaDB

```sql
-- Tabla members
CREATE TABLE members (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    first_name VARCHAR(100) NOT NULL,
    first_surname VARCHAR(100) NOT NULL,
    second_surname VARCHAR(100) DEFAULT '',
    email VARCHAR(255) NOT NULL UNIQUE,
    photo_data LONGBLOB,
    is_searchable TINYINT(1) DEFAULT 0,
    membership_status VARCHAR(20) DEFAULT 'pending_approval',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_members_searchable ON members(is_searchable, membership_status);
CREATE FULLTEXT INDEX idx_members_fullname ON members(first_name, first_surname, second_surname);

-- Datos de prueba (mismo INSERT que PostgreSQL)
```

---

## 🧪 Pruebas del Endpoint

### Usando cURL

```bash
# 1. Obtener token (asumiendo endpoint de login)
TOKEN=$(curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"tu@email.com","password":"tupassword"}' \
  | jq -r '.token')

# 2. Búsqueda sin filtro, primera página
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/v1/directory?query=&page=0&pageSize=10"

# Respuesta esperada:
# {
#   "users": [ ... 10 usuarios ... ],
#   "hasMore": true
# }

# 3. Segunda página
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/v1/directory?query=&page=1&pageSize=10"

# 4. Búsqueda con filtro
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/v1/directory?query=Maria&page=0&pageSize=10"

# Respuesta esperada:
# {
#   "users": [ 
#     {"id":"...", "fullName":"María González", "photoData":null}
#   ],
#   "hasMore": false
# }
```

### Usando Postman

```
GET http://localhost:3000/v1/directory?query=Maria&page=0&pageSize=10

Headers:
  Authorization: Bearer eyJhbGc...

Response:
{
  "users": [...],
  "hasMore": false
}
```

---

## 🐳 Docker Setup (Opcional)

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
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql

  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: asocia
      DB_USER: postgres
      DB_PASSWORD: postgres
      JWT_SECRET: supersecret
    depends_on:
      - postgres

volumes:
  postgres_data:
```

### Iniciar

```bash
docker-compose up -d
```

---

## ✅ Checklist de Implementación

- [ ] Crear archivo `routes/directory.js` con el endpoint
- [ ] Crear middleware `middleware/auth.js` para autenticación
- [ ] Configurar conexión a base de datos en `db.js`
- [ ] Instalar dependencias npm
- [ ] Configurar variables de entorno (`.env`)
- [ ] Crear schema de base de datos
- [ ] Crear extensión `pg_trgm` (PostgreSQL)
- [ ] Insertar datos de prueba (20 usuarios)
- [ ] Registrar ruta en `app.js`
- [ ] Probar con cURL o Postman
- [ ] Verificar logs en consola del servidor
- [ ] Probar desde la app iOS

---

## 🎯 Verificación

Cuando esté funcionando, en la consola del backend verás:

```
✅ Extensión pg_trgm disponible
🚀 Server running on port 3000

📖 Directory search: query="", page=0, found=10, hasMore=true
📖 Directory search: query="", page=1, found=10, hasMore=false
📖 Directory search: query="Maria", page=0, found=1, hasMore=false
```

Y en la app iOS verás:

```
📡 [CHAT API] searchDirectory - query: '', page: 0, pageSize: 10
   🌐 [GET] http://localhost:3000/v1/directory?query=&page=0&pageSize=10
   ✅ Response: 200 (156ms)
   ✅ Recibidos 10 usuarios, hasMore: true
```

---

**Fecha:** 26 de julio de 2026  
**Versión:** 1.0  
**Tecnologías:** Node.js/Express + PostgreSQL/MariaDB
