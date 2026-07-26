# Arquitectura del Sistema de Autenticación

## 🏗️ Diagrama de Arquitectura

```
┌──────────────────────────────────────────────────────────────────┐
│                         APP iOS (Swift)                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────┐    ┌─────────────┐    ┌──────────────┐         │
│  │ RootView   │───▶│  LoginView  │───▶│  SignupView  │         │
│  └────────────┘    └─────────────┘    └──────────────┘         │
│        │                   │                    │                │
│        │                   │                    │                │
│        ▼                   ▼                    ▼                │
│  ┌──────────────────────────────────────────────────┐           │
│  │           AuthService (actor)                    │           │
│  │  ┌─────────────┐  ┌──────────┐  ┌────────────┐  │           │
│  │  │   login()   │  │register()│  │hasValidTo..│  │           │
│  │  └─────────────┘  └──────────┘  └────────────┘  │           │
│  │  ┌─────────────────────────────────────────┐    │           │
│  │  │      KeychainStore (JWT Token)          │    │           │
│  │  └─────────────────────────────────────────┘    │           │
│  └──────────────────────────────────────────────────┘           │
│        │                                             │            │
│        │ HTTP POST                         SwiftData│            │
│        │ /v1/auth/login                              │            │
│        │ /v1/auth/register                           ▼            │
│        │                              ┌─────────────────────┐    │
│        │                              │  Member (@Model)    │    │
│        │                              │  - id               │    │
│        │                              │  - email            │    │
│        │                              │  - passwordHash     │    │
│        │                              │  - firstName        │    │
│        │                              │  - ...              │    │
│        │                              └─────────────────────┘    │
│        │                                                          │
└────────┼──────────────────────────────────────────────────────────┘
         │
         │ HTTPS (local: HTTP)
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│              BACKEND - Auth Service (Node.js/Express)            │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  POST /v1/auth/register                                │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ 1. Validar email, password                       │  │    │
│  │  │ 2. Verificar email no duplicado                  │  │    │
│  │  │ 3. Hashear password (bcrypt)                     │  │    │
│  │  │ 4. Guardar usuario                               │  │    │
│  │  │ 5. Generar token JWT                             │  │    │
│  │  │ 6. Devolver { token, member }                    │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  POST /v1/auth/login                                   │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ 1. Buscar usuario por email                      │  │    │
│  │  │ 2. Verificar password (bcrypt.compare)           │  │    │
│  │  │ 3. Generar token JWT                             │  │    │
│  │  │ 4. Devolver { token, member }                    │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  GET /v1/auth/verify                                   │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ 1. Extraer token del header Authorization        │  │    │
│  │  │ 2. Verificar firma JWT                           │  │    │
│  │  │ 3. Verificar expiración                          │  │    │
│  │  │ 4. Devolver { valid: true, userId, email }       │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Base de Datos (En memoria - Map)                     │    │
│  │  ┌──────────────────────────────────────────────┐     │    │
│  │  │ users = new Map()                            │     │    │
│  │  │   ├─ id → User                               │     │    │
│  │  │   │   - id: UUID                             │     │    │
│  │  │   │   - email: String                        │     │    │
│  │  │   │   - passwordHash: String (bcrypt)        │     │    │
│  │  │   │   - firstName: String                    │     │    │
│  │  │   │   - firstSurname: String                 │     │    │
│  │  │   │   - createdAt: Date                      │     │    │
│  │  └──────────────────────────────────────────────┘     │    │
│  │                                                        │    │
│  │  ⚠️  PRODUCCIÓN: Reemplazar con PostgreSQL/MongoDB     │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## 🔄 Flujo de Datos - Registro

```
┌─────────┐              ┌──────────┐              ┌──────────┐
│  User   │              │   App    │              │  Server  │
└────┬────┘              └────┬─────┘              └────┬─────┘
     │                        │                         │
     │ Completa formulario    │                         │
     │ ──────────────────────▶│                         │
     │                        │                         │
     │                        │ POST /v1/auth/register  │
     │                        │ ───────────────────────▶│
     │                        │ {                       │
     │                        │   id, email, password,  │
     │                        │   firstName, ...        │
     │                        │ }                       │
     │                        │                         │
     │                        │                         │ Valida datos
     │                        │                         │ Hashea password
     │                        │                         │ Guarda usuario
     │                        │                         │ Genera JWT
     │                        │                         │
     │                        │ { token, member }       │
     │                        │ ◀───────────────────────│
     │                        │                         │
     │                        │ Guarda token (Keychain) │
     │                        │ Guarda member (SwiftData)
     │                        │                         │
     │ Ve perfil              │                         │
     │ ◀──────────────────────│                         │
     │                        │                         │
```

## 🔄 Flujo de Datos - Login

```
┌─────────┐              ┌──────────┐              ┌──────────┐
│  User   │              │   App    │              │  Server  │
└────┬────┘              └────┬─────┘              └────┬─────┘
     │                        │                         │
     │ Introduce credenciales │                         │
     │ ──────────────────────▶│                         │
     │                        │                         │
     │                        │ POST /v1/auth/login     │
     │                        │ ───────────────────────▶│
     │                        │ {                       │
     │                        │   email,                │
     │                        │   password              │
     │                        │ }                       │
     │                        │                         │
     │                        │                         │ Busca usuario
     │                        │                         │ Verifica password
     │                        │                         │ Genera JWT
     │                        │                         │
     │                        │ { token, member }       │
     │                        │ ◀───────────────────────│
     │                        │                         │
     │                        │ Guarda token (Keychain) │
     │                        │ Actualiza member (SwiftData)
     │                        │                         │
     │ Ve perfil/tabs         │                         │
     │ ◀──────────────────────│                         │
     │                        │                         │
```

## 🔄 Flujo de Datos - Persistencia

```
┌─────────┐              ┌──────────┐
│  User   │              │   App    │
└────┬────┘              └────┬─────┘
     │                        │
     │ Abre app               │
     │ ──────────────────────▶│
     │                        │
     │                        │ Lee token (Keychain)
     │                        │ ├─ ¿Existe?
     │                        │ │  SÍ
     │                        │ └─ ¿Válido?
     │                        │    SÍ
     │                        │
     │                        │ Query Member (SwiftData)
     │                        │ ├─ ¿Existe?
     │                        │ └─ SÍ
     │                        │
     │ Acceso directo         │
     │ ◀──────────────────────│
     │ (sin login)            │
     │                        │
```

## 🔐 Seguridad en Capas

```
┌──────────────────────────────────────────────────────────┐
│ CAPA 1: USUARIO                                          │
│ - Password mínimo 6 caracteres                           │
│ - Confirmación de password en registro                   │
│ - Feedback visual de errores                             │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│ CAPA 2: APP iOS                                          │
│ - Password nunca en texto plano                          │
│ - Hash local con SHA256 para storage                     │
│ - Token en Keychain (encriptado por iOS)                 │
│ - HTTPS en producción                                    │
│ - Validación de campos antes de enviar                   │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│ CAPA 3: TRANSPORTE                                       │
│ - HTTPS/TLS en producción                                │
│ - Headers Authorization: Bearer <token>                  │
│ - Timeout de requests                                    │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│ CAPA 4: SERVIDOR                                         │
│ - Validación de entrada                                  │
│ - Password hasheado con bcrypt (salt rounds: 10)         │
│ - JWT con firma secreta                                  │
│ - Expiración de tokens (30 días)                         │
│ - CORS configurado                                       │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│ CAPA 5: BASE DE DATOS                                    │
│ - Passwords nunca en texto plano                         │
│ - Email único (índice)                                   │
│ - Timestamps de creación/modificación                    │
│ - En producción: backup, encriptación                    │
└──────────────────────────────────────────────────────────┘
```

## 📊 Estructura de Datos

### Token JWT Decodificado

```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "email": "juan@ejemplo.com",
    "iat": 1722000000,
    "exp": 1724592000
  },
  "signature": "..."
}
```

### Member en SwiftData

```swift
Member(
  id: UUID
  firstName: "Juan"
  firstSurname: "Pérez"
  secondSurname: ""
  email: "juan@ejemplo.com"
  passwordHash: "5e884898da28047..." // SHA256 local
  mobilePhone: ""
  // ... más campos ...
  membershipStatus: .pendingApproval
  syncStatus: .synced
  localUpdatedAt: Date()
  serverUpdatedAt: Date()
)
```

### Usuario en Servidor

```javascript
{
  id: "550e8400-e29b-41d4-a716-446655440000",
  email: "juan@ejemplo.com",
  passwordHash: "$2b$10$N9qo8uL...", // bcrypt
  firstName: "Juan",
  firstSurname: "Pérez",
  createdAt: "2026-07-26T10:30:00.000Z"
}
```

## 🎯 Endpoints del API

| Método | Endpoint           | Auth | Descripción                |
|--------|-------------------|------|----------------------------|
| POST   | /v1/auth/register | ❌   | Registrar nuevo usuario    |
| POST   | /v1/auth/login    | ❌   | Autenticar usuario         |
| GET    | /v1/auth/verify   | ✅   | Verificar token JWT        |
| GET    | /health           | ❌   | Health check del servicio  |

## 🔄 Estados de MembershipStatus

```
notMember ──register──▶ pendingApproval ──approve──▶ active
                              │
                              │ reject
                              ▼
                          rejected
```

### Acceso según estado:

| Estado            | Perfil | Chat | Tabs |
|-------------------|--------|------|------|
| notMember         | ❌     | ❌   | ❌   |
| pendingApproval   | ✅     | ❌   | ❌   |
| active            | ✅     | ✅   | ✅   |
| rejected          | ✅     | ❌   | ❌   |

## 📦 Dependencias

### Backend (Node.js)

```json
{
  "express": "^4.18.2",     // Framework web
  "bcrypt": "^5.1.1",       // Hash de passwords
  "jsonwebtoken": "^9.0.2", // JWT
  "cors": "^2.8.5",         // CORS
  "uuid": "^9.0.1"          // UUIDs
}
```

### iOS (Swift)

```swift
import SwiftUI        // UI
import SwiftData      // Persistencia local
import CryptoKit      // Hash SHA256
import Foundation     // Networking, JSON
```

## 🚀 Despliegue

### Desarrollo Local

```bash
# Backend
cd backend/auth-service
npm install
npm run dev
# http://localhost:4001

# iOS
Xcode > Product > Run
# Scheme: Asocia (Local)
```

### Producción (Ejemplo)

```bash
# Backend (Railway/Render/Heroku)
git push production main
# https://api.asocia.com

# iOS
Xcode > Product > Archive
# Submit to App Store
# Scheme: Asocia (Production)
```

## 📈 Escalabilidad

### Actual (Desarrollo)

- ✅ 1 servidor
- ✅ Almacenamiento en memoria
- ✅ Sin caché
- ✅ HTTP local

### Producción Básica

- ✅ 1 servidor con PM2/Forever
- ✅ PostgreSQL/MongoDB
- ✅ HTTPS con Let's Encrypt
- ✅ Logs con Winston

### Producción Avanzada

- ✅ Múltiples instancias (Load Balancer)
- ✅ Base de datos con réplicas
- ✅ Redis para caché de sesiones
- ✅ CDN para assets
- ✅ Monitoring (DataDog/NewRelic)
- ✅ Rate limiting por IP
- ✅ Refresh tokens
- ✅ 2FA

## 🔮 Mejoras Futuras

1. **Recuperación de contraseña**
   - Endpoint /forgot-password
   - Email con token temporal
   - Endpoint /reset-password

2. **Verificación de email**
   - Email de bienvenida
   - Link de verificación
   - Estado de cuenta: verified/unverified

3. **OAuth/Social Login**
   - Sign in with Apple
   - Google Sign-In
   - Facebook Login

4. **Refresh Tokens**
   - Access token (corta vida)
   - Refresh token (larga vida)
   - Endpoint /refresh

5. **Sesiones Múltiples**
   - Tabla de sesiones activas
   - Device fingerprinting
   - Cerrar sesión remota

6. **Auditoría**
   - Log de intentos fallidos
   - Notificación de login desde nuevo device
   - Historial de accesos
