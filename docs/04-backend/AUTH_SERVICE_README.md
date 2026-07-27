# Servicio de Autenticación JWT

Microservicio de autenticación para la aplicación Asocia.

## Características

- ✅ Registro de usuarios con email y contraseña
- ✅ Login con credenciales
- ✅ Generación de tokens JWT
- ✅ Encriptación de contraseñas con bcrypt
- ✅ Verificación de tokens
- ✅ Almacenamiento en memoria (para desarrollo local)

## Instalación

```bash
cd backend/auth-service
npm install
```

## Ejecución

### Modo desarrollo (con auto-reload):
```bash
npm run dev
```

### Modo producción:
```bash
npm start
```

El servicio se ejecutará en `http://localhost:4001`

## Endpoints

### POST /v1/auth/register
Registra un nuevo usuario.

**Request:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "usuario@ejemplo.com",
  "password": "mipassword123",
  "firstName": "Juan",
  "firstSurname": "Pérez"
}
```

**Response (201):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "member": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "firstName": "Juan",
    "firstSurname": "Pérez",
    "email": "usuario@ejemplo.com",
    "membershipStatus": "pendingApproval",
    ...
  }
}
```

### POST /v1/auth/login
Autentica un usuario existente.

**Request:**
```json
{
  "email": "usuario@ejemplo.com",
  "password": "mipassword123"
}
```

**Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "member": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "firstName": "Juan",
    "firstSurname": "Pérez",
    "email": "usuario@ejemplo.com",
    "membershipStatus": "active",
    ...
  }
}
```

### GET /v1/auth/verify
Verifica si un token JWT es válido.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "valid": true,
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "email": "usuario@ejemplo.com"
}
```

### GET /health
Health check del servicio.

**Response (200):**
```json
{
  "status": "ok",
  "service": "auth-service",
  "users": 5,
  "timestamp": "2026-07-26T10:30:00.000Z"
}
```

## Códigos de error

- `400` - Bad Request (campos faltantes, contraseña muy corta)
- `401` - Unauthorized (credenciales incorrectas)
- `403` - Forbidden (token inválido)
- `409` - Conflict (email ya registrado)
- `500` - Internal Server Error

## Variables de entorno

Crear un archivo `.env`:

```env
PORT=4001
JWT_SECRET=tu-secreto-super-seguro-cambiar-en-produccion
```

## Notas de seguridad

⚠️ **IMPORTANTE para producción:**

1. Cambiar `JWT_SECRET` por un valor aleatorio y seguro
2. Reemplazar el almacenamiento en memoria por una base de datos real (PostgreSQL, MongoDB, etc.)
3. Implementar rate limiting para prevenir ataques de fuerza bruta
4. Añadir validación de formato de email
5. Implementar recuperación de contraseña
6. Considerar refresh tokens para mayor seguridad
7. Habilitar HTTPS en producción

## Integración con la app iOS

La app iOS se conecta a este servicio a través de `AuthService.swift`:

```swift
// Login
let response = try await authService.login(email: email, password: password)

// Registro
let response = try await authService.register(
    id: uuid,
    email: email,
    password: password,
    firstName: firstName,
    firstSurname: firstSurname
)
```

El token JWT se guarda automáticamente en el Keychain del dispositivo.

## Testing con curl

### Registro:
```bash
curl -X POST http://localhost:4001/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "test@ejemplo.com",
    "password": "test123",
    "firstName": "Test",
    "firstSurname": "User"
  }'
```

### Login:
```bash
curl -X POST http://localhost:4001/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@ejemplo.com",
    "password": "test123"
  }'
```

### Verificar token:
```bash
curl -X GET http://localhost:4001/v1/auth/verify \
  -H "Authorization: Bearer <token>"
```
