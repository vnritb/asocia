# Backend de Asocia

Microservicios Node.js/TypeScript para la app Asocia.

## Estructura

```text
backend/
├── packages/
│   └── shared/                    # Tipos y utilidades compartidas
├── services/
│   ├── api-gateway/              # Gateway principal (puerto 4000)
│   ├── chat-service/             # Mensajería (puerto 4002)
│   ├── membership-service/       # Gestión de socios (puerto 4001)
│   └── translation-service/      # Traducción con IA (puerto 4003)
├── migrations/                   # Scripts SQL
├── scripts/                      # Scripts de utilidad
├── docker-compose.yml            # Orquestación de servicios
├── package.json                  # Workspace raíz
├── vitest.config.ts              # Configuración de tests
└── TESTS.md                      # Documentación de tests

backendTests/
├── services/
│   ├── api-gateway/src/
│   ├── chat-service/src/
│   ├── membership-service/src/
│   └── translation-service/src/
└── test-helpers/                 # Utilidades para tests
```

## Requisitos

- Node.js 20+
- PostgreSQL 15+
- Docker & Docker Compose (recomendado)

## Instalación

```bash
cd backend
npm install
```

## Ejecutar servicios

### Opción 1: Con Docker (recomendado)

```bash
# Copiar variables de entorno
cp services/*/.env.example services/*/.env

# Editar .env si es necesario (especialmente ANTHROPIC_API_KEY para traducción real)

# Levantar todos los servicios
docker compose up --build

# Servicios disponibles:
# - http://localhost:4000 - API Gateway
# - http://localhost:4001 - Membership Service
# - http://localhost:4002 - Chat Service
# - http://localhost:4003 - Translation Service
# - localhost:5432 - PostgreSQL
```

### Opción 2: Sin Docker (desarrollo)

```bash
# Terminal 1: Levantar PostgreSQL
docker compose up postgres

# Aplicar migraciones
psql -h localhost -p 5432 -U asocia -d asocia < migrations/schema.sql

# Terminal 2: API Gateway
npm run dev:gateway

# Terminal 3: Membership Service
npm run dev:membership

# Terminal 4: Chat Service
npm run dev:chat

# Terminal 5: Translation Service
npm run dev:translation
```

## Tests

### Configuración inicial de tests

```bash
# 1. Configurar base de datos de test
chmod +x scripts/setup-test-db.sh
./scripts/setup-test-db.sh

# 2. Copiar variables de entorno para tests
cp .env.test.example .env.test
```

### Ejecutar tests

```bash
# Todos los tests (unitarios + integración)
npm test

# Solo tests unitarios (lógica de negocio, sin red ni BD)
npm run test:unit

# Solo tests de integración (requiere servicios corriendo)
npm run test:integration

# Tests en modo watch (durante desarrollo)
npm run test:watch

# Tests con coverage
npm run test:coverage
```

### Tests unitarios vs integración

- **Tests unitarios** (`*.unit.test.ts`):
  - Prueban la lógica de negocio de forma aislada
  - No requieren servicios externos, BD, ni red
  - Usan mocks para dependencias
  - Muy rápidos (< 1s)
  - Ejemplos:
    - Validación de datos (email, DNI, teléfono)
    - Lógica de dominio (cálculo de edad, permisos)
    - Utilidades y helpers

- **Tests de integración** (`*.integration.test.ts`):
  - Prueban endpoints HTTP completos
  - Requieren servicios corriendo (con Docker o manualmente)
  - Usan base de datos real (asocia_test)
  - Más lentos (varios segundos)
  - Ejemplos:
    - Crear/listar/actualizar miembros
    - Enviar/recibir mensajes
    - Traducir textos
    - Routing del API Gateway

### Ejecutar tests de integración

Los tests de integración requieren que los servicios estén corriendo:

```bash
# Terminal 1: Levantar servicios
docker compose up

# Terminal 2: Ejecutar tests de integración
npm run test:integration
```

O ejecutar todo en un solo comando:

```bash
# Levantar servicios, ejecutar tests, y apagar
docker compose up -d
npm run test:integration
docker compose down
```

## Verificación (sin servicios corriendo)

```bash
# Type checking de TypeScript
npm run typecheck

# Compilar todos los servicios
npm run build

# Todo (typecheck + tests + build)
npm run test:all
```

## Endpoints principales

### API Gateway (`http://localhost:4000`)

**Membership**

- `POST /api/members` - Crear socio
- `GET /api/members` - Listar socios
- `GET /api/members/:id` - Ver socio
- `PATCH /api/members/:id/status` - Confirmar/rechazar socio
- `PUT /api/members/:id` - Actualizar datos
- `DELETE /api/members/:id` - Eliminar socio

**Chat**

- `POST /api/messages` - Enviar mensaje
- `GET /api/messages/:id` - Ver mensaje
- `GET /api/conversations/:userId1/:userId2` - Ver conversación
- `GET /api/conversations/:userId` - Listar conversaciones
- `PATCH /api/messages/:id/read` - Marcar como leído
- `GET /api/messages/unread/:userId` - Contar mensajes sin leer

**Translation**

- `POST /api/translate` - Traducir texto
- `POST /api/detect-language` - Detectar idioma
- `GET /api/supported-languages` - Idiomas soportados
- `POST /api/translate/batch` - Traducir múltiples textos

**Health**

- `GET /health` - Estado de todos los servicios

## Variables de entorno

Cada servicio tiene su propio `.env`:

```text
backend/services/
├── api-gateway/.env
├── chat-service/.env
├── membership-service/.env
└── translation-service/.env
```

Variables importantes:

```env
# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=asocia
POSTGRES_USER=asocia
POSTGRES_PASSWORD=asocia_secret

# Anthropic API (para traducción real)
ANTHROPIC_API_KEY=tu-api-key-aquí

# URLs de servicios (para gateway)
MEMBERSHIP_SERVICE_URL=http://membership:4001
CHAT_SERVICE_URL=http://chat:4002
TRANSLATION_SERVICE_URL=http://translation:4003
```

## Despliegue

Ver `../.github/workflows/deploy-*.yml` para configuración de CI/CD.

Los workflows están preparados pero comentados. Para activarlos:

1. Configura secretos en GitHub:
   - `POSTGRES_CONNECTION_STRING`
   - `ANTHROPIC_API_KEY`
   - Credenciales de despliegue (Render, AWS, etc.)

2. Descomenta los workflows de deploy

3. Haz push a `main` (producción) o `staging`

## Troubleshooting

### Tests fallan con "Connection refused"

Los tests de integración requieren que los servicios estén corriendo:

```bash
docker compose up -d
npm run test:integration
```

### Tests de traducción fallan

Si no tienes `ANTHROPIC_API_KEY` configurada, algunos tests de traducción fallarán. Opciones:

1. Usar solo tests unitarios: `npm run test:unit`
2. Configurar la API key en `.env.test`
3. Los mocks deberían funcionar sin API key (verificar implementación)

### PostgreSQL no se conecta

Verificar que el contenedor esté corriendo:

```bash
docker compose ps
docker compose logs postgres
```

### Puerto ya en uso

Si algún puerto (4000-4003) ya está ocupado:

```bash
# Ver qué está usando el puerto
lsof -i :4000

# Matar el proceso
kill -9 <PID>
```

## Desarrollo

### Añadir un nuevo test unitario

```typescript
// backendTests/services/membership-service/src/validators/myValidator.unit.test.ts
import { describe, it, expect } from 'vitest';

describe('MyValidator', () => {
  it('should validate something', () => {
    expect(validateSomething(input)).toBe(expected);
  });
});
```

### Añadir un nuevo test de integración

```typescript
// backendTests/services/membership-service/src/myFeature.integration.test.ts
import { describe, it, expect } from 'vitest';
import request from 'supertest';

describe('My Feature Integration', () => {
  const baseURL = process.env.MEMBERSHIP_SERVICE_URL || 'http://localhost:4001';

  it('should work end-to-end', async () => {
    const response = await request(baseURL)
      .post('/endpoint')
      .send({ data: 'test' })
      .expect(201);

    expect(response.body).toBeDefined();
  });
});
```

### Ejecutar un solo archivo de test

```bash
npx vitest run backendTests/services/membership-service/src/validators/memberValidator.unit.test.ts
```

### Ver coverage detallado

```bash
npm run test:coverage
open coverage/index.html
```

## Más información

- Documentación de arquitectura: `../docs/ARQUITECTURA.md`
- Tests de la app iOS: `../AsociaTests/` y `../AsociaUITests/`
