# 🌐 Backend - Asocia

Documentación de endpoints y servicios backend.

---

## 📄 Documentos en esta Sección

### [BACKEND_ENDPOINT_IMPLEMENTATION.md](./BACKEND_ENDPOINT_IMPLEMENTATION.md)
**Implementación de Endpoints**

Documentación técnica de todos los endpoints:
- 📡 Especificación de APIs
- 🔌 Métodos HTTP y rutas
- 📝 Request/Response formats
- 🔐 Autenticación y headers
- 🧪 Ejemplos de uso

### [BACKEND_PAGINATION_GUIDE.md](./BACKEND_PAGINATION_GUIDE.md)
**Sistema de Paginación**

Guía del sistema de paginación implementado:
- 📄 Paginación en endpoints
- 🔢 Parámetros `page` y `pageSize`
- ↔️ Response con `hasMore`
- 🔄 Scroll infinito en cliente
- 📊 Optimización de rendimiento

---

## 🎯 Microservicios

### 1. Auth Service (Puerto 4001)

**Endpoints:**
```
POST   /v1/auth/register  - Registrar nuevo usuario
POST   /v1/auth/login     - Iniciar sesión
GET    /v1/auth/verify    - Verificar token
GET    /health            - Health check
```

**Características:**
- JWT para autenticación
- bcrypt para passwords
- Base de datos en memoria (desarrollo)

### 2. Membership Service (Puerto 3000)

**Endpoints:**
```
POST   /v1/members/apply  - Solicitar alta
GET    /v1/members/me     - Obtener perfil actual
PATCH  /v1/members/me     - Actualizar perfil
```

**Características:**
- Estados de membresía
- Sincronización con app
- Gestión de perfiles

### 3. Chat Service (Futuro)

**Endpoints planeados:**
```
GET    /v1/conversations          - Listar conversaciones
POST   /v1/conversations          - Crear conversación
GET    /v1/conversations/:id/messages  - Mensajes
POST   /v1/conversations/:id/messages  - Enviar mensaje
GET    /v1/users/search           - Buscar usuarios (con paginación)
```

---

## 📡 Formato de Respuestas

### Éxito (2xx)
```json
{
  "data": { ... },
  "meta": {
    "page": 0,
    "pageSize": 10,
    "hasMore": true
  }
}
```

### Error (4xx, 5xx)
```json
{
  "error": "Descripción del error"
}
```

---

## 🔐 Autenticación

Todos los endpoints protegidos requieren:

```http
Authorization: Bearer <jwt-token>
```

### Obtener Token

1. **Login:**
```bash
curl -X POST http://localhost:4001/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"pass123"}'
```

2. **Usar token en peticiones:**
```bash
curl http://localhost:3000/v1/members/me \
  -H "Authorization: Bearer eyJhbGc..."
```

---

## 📄 Paginación

### Request
```http
GET /v1/users/search?query=pedro&page=0&pageSize=10
```

### Response
```json
{
  "users": [ ... ],
  "hasMore": true
}
```

### En el Cliente (Swift)
```swift
let response = await chatService.searchDirectory(
    query: "pedro",
    page: 0,
    pageSize: 10
)

print("Usuarios: \(response.users.count)")
print("Hay más: \(response.hasMore)")
```

---

## 🧪 Testing

### Health Check
```bash
curl http://localhost:4001/health
# Respuesta: {"status":"ok"}
```

### Test Completo
```bash
# Ver script en docs/08-scripts/
cd backend/auth-service
./test.sh
```

---

## 🚀 Despliegue

### Desarrollo
```bash
npm run dev  # Auto-reload con nodemon
```

### Producción
```bash
npm start    # Sin auto-reload
```

### Variables de Entorno
```bash
PORT=4001
JWT_SECRET=tu-secret-super-secreto
NODE_ENV=production
DATABASE_URL=postgresql://...
```

---

## 🔗 Enlaces Relacionados

- **Autenticación**: [docs/03-authentication/](../03-authentication/)
- **Chat (paginación)**: [docs/05-chat/](../05-chat/)
- **Scripts**: [docs/08-scripts/](../08-scripts/)

---

**Última actualización:** 27 de julio de 2026
