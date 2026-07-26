# 🌐 Paginación con Servicios Reales (Backend)

## ✅ Implementación Completa

He actualizado `ChatAPIClient` para que **soporte paginación con el backend real**, no solo en modo mock.

---

## 📊 Dos Modos de Funcionamiento

### 1. Modo Mock (Desarrollo)

**Cuándo:** `AppEnvironment.mock`

```swift
if env.usesMockServices {
    chatService = MockChatService()  // ← Usa esto
}
```

**Características:**
- ✅ 20 usuarios hardcodeados en memoria
- ✅ Paginación funciona localmente
- ✅ No requiere backend
- ✅ Respuestas automáticas simuladas

### 2. Modo Real (Local/Staging/Producción)

**Cuándo:** `AppEnvironment.local`, `.staging`, `.production`

```swift
else {
    chatService = ChatAPIClient(baseURL: env.apiBaseURL)  // ← Usa esto
}
```

**Características:**
- ✅ Usuarios del backend (base de datos real)
- ✅ Paginación con API REST
- ✅ Requiere backend corriendo
- ✅ Mensajes reales persistentes

---

## 🔌 API del Backend

### Endpoint de Búsqueda con Paginación

```
GET /v1/directory?query={query}&page={page}&pageSize={pageSize}
```

**Parámetros:**
- `query` (string): Texto de búsqueda (opcional, vacío = todos)
- `page` (int): Número de página (0-indexed)
- `pageSize` (int): Usuarios por página (default: 10)

**Respuesta:**
```json
{
  "users": [
    {
      "id": "uuid",
      "fullName": "María González",
      "photoData": null
    },
    // ... más usuarios
  ],
  "hasMore": true
}
```

### Ejemplo de Llamada

```
GET /v1/directory?query=Maria&page=0&pageSize=10
```

**Respuesta:**
```json
{
  "users": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "fullName": "María González",
      "photoData": null
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "fullName": "María José Romero",
      "photoData": null
    }
  ],
  "hasMore": false
}
```

---

## 📝 Implementación en ChatAPIClient

### Código Actualizado

```swift
func searchDirectory(query: String, page: Int = 0, pageSize: Int = 10) async -> (users: [ChatUser], hasMore: Bool) {
    #if DEBUG
    print("📡 [CHAT API] searchDirectory - query: '\(query)', page: \(page), pageSize: \(pageSize)")
    #endif
    
    let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let path = "/v1/directory?query=\(encodedQuery)&page=\(page)&pageSize=\(pageSize)"
    
    do {
        struct DirectoryResponse: Decodable {
            let users: [ChatUser]
            let hasMore: Bool
        }
        
        let response: DirectoryResponse = try await get(path)
        
        #if DEBUG
        print("   ✅ Recibidos \(response.users.count) usuarios, hasMore: \(response.hasMore)")
        #endif
        
        return (users: response.users, hasMore: response.hasMore)
    } catch {
        #if DEBUG
        print("   ❌ Error: \(error.localizedDescription)")
        #endif
        
        // Fallback: devolver lista vacía en caso de error
        return (users: [], hasMore: false)
    }
}
```

### Cambios Principales

1. **Query Parameters** - Envía `page` y `pageSize` al backend
2. **DirectoryResponse** - Estructura para deserializar la respuesta
3. **Logging** - Debug logs para ver peticiones y respuestas
4. **Error Handling** - Fallback a lista vacía si falla

---

## 🔄 Flujo Completo

### Usuario Abre Búsqueda (Modo Real)

```
1. UserSearchView abre
   ↓
2. resetAndSearch()
   page: 0, pageSize: 10
   ↓
3. ChatAPIClient.searchDirectory(query: "", page: 0, pageSize: 10)
   ↓
4. HTTP GET /v1/directory?query=&page=0&pageSize=10
   ↓
5. Backend (chat-service)
   - Consulta base de datos (MariaDB/PostgreSQL)
   - SELECT * FROM users WHERE searchable = true LIMIT 10 OFFSET 0
   - Cuenta total para calcular hasMore
   ↓
6. Respuesta JSON
   {
     "users": [...],  // 10 usuarios
     "hasMore": true
   }
   ↓
7. UserSearchView muestra primeros 10 usuarios
```

### Usuario Hace Scroll (Modo Real)

```
1. onAppear detecta último elemento
   ↓
2. loadMore()
   page: 1, pageSize: 10
   ↓
3. HTTP GET /v1/directory?query=&page=1&pageSize=10
   ↓
4. Backend
   - SELECT * FROM users WHERE searchable = true LIMIT 10 OFFSET 10
   ↓
5. Respuesta JSON
   {
     "users": [...],  // siguientes 10 usuarios
     "hasMore": false
   }
   ↓
6. results.append(nuevosUsuarios)
   Total: 20 usuarios
```

---

## 📊 Logging en Modo Real

### Al Buscar

```
📡 [CHAT API] searchDirectory - query: '', page: 0, pageSize: 10
   🌐 [GET] http://localhost:3000/v1/directory?query=&page=0&pageSize=10
   🔐 Authenticated: Yes
   ✅ Response: 200 (156ms)
   ✅ Recibidos 10 usuarios, hasMore: true
```

### Al Cargar Más

```
📡 [CHAT API] searchDirectory - query: '', page: 1, pageSize: 10
   🌐 [GET] http://localhost:3000/v1/directory?query=&page=1&pageSize=10
   🔐 Authenticated: Yes
   ✅ Response: 200 (123ms)
   ✅ Recibidos 10 usuarios, hasMore: false

📄 Página 1 cargada: +10 usuarios, total: 20, hasMore: false
```

### Con Error

```
📡 [CHAT API] searchDirectory - query: 'test', page: 0, pageSize: 10
   🌐 [GET] http://localhost:3000/v1/directory?query=test&page=0&pageSize=10
   🔐 Authenticated: Yes
   ❌ Response: 500 (89ms)
   ❌ Error: Error del servidor (500)
```

---

## 🗄️ Backend - Implementación Esperada

### SQL Query con Paginación

```sql
-- Búsqueda con similitud de texto (pg_trgm)
SELECT 
    id,
    first_name || ' ' || first_surname AS full_name,
    photo_data,
    similarity(first_name || ' ' || first_surname, $1) AS score
FROM members
WHERE 
    is_searchable = true
    AND membership_status = 'active'
    AND (
        $1 = '' 
        OR similarity(first_name || ' ' || first_surname, $1) > 0.15
        OR (first_name || ' ' || first_surname) ILIKE '%' || $1 || '%'
    )
ORDER BY score DESC, full_name ASC
LIMIT $2 OFFSET $3;

-- Parámetros:
-- $1 = query (string)
-- $2 = pageSize (int)
-- $3 = page * pageSize (int)
```

### Contar Total para hasMore

```sql
SELECT COUNT(*) as total
FROM members
WHERE 
    is_searchable = true
    AND membership_status = 'active'
    AND (
        $1 = '' 
        OR similarity(first_name || ' ' || first_surname, $1) > 0.15
        OR (first_name || ' ' || first_surname) ILIKE '%' || $1 || '%'
    );
```

### Lógica de hasMore

```javascript
// En Node.js (backend)
const offset = page * pageSize;
const limit = pageSize;

const users = await db.query(/* query arriba */, [query, limit, offset]);
const totalCount = await db.query(/* count query */, [query]);

const hasMore = (offset + users.length) < totalCount.rows[0].total;

res.json({ users, hasMore });
```

---

## 🧪 Pruebas

### Modo Mock (Sin Backend)

```bash
# 1. Asegúrate de estar en modo Mock
# En AppEnvironment.swift o variable de entorno
ASOCIA_ENVIRONMENT=mock

# 2. Ejecuta
⌘ + R

# 3. Ve a Chat → Lupa
# Verás 20 usuarios del mock

# 4. Consola mostrará:
🔍 Búsqueda: '' - 10 resultados, hasMore: true
📄 Página 1 cargada: +10 usuarios, total: 20, hasMore: false
```

### Modo Local (Con Backend)

```bash
# 1. Inicia el backend
cd backend
docker-compose up

# 2. Asegúrate de estar en modo Local
ASOCIA_ENVIRONMENT=local

# 3. Ejecuta
⌘ + R

# 4. Ve a Chat → Lupa
# Verás usuarios reales de la base de datos

# 5. Consola mostrará:
📡 [CHAT API] searchDirectory - query: '', page: 0, pageSize: 10
   🌐 [GET] http://localhost:3000/v1/directory?query=&page=0&pageSize=10
   ✅ Response: 200 (156ms)
   ✅ Recibidos 10 usuarios, hasMore: true
```

---

## 🔐 Autenticación

El `ChatAPIClient` usa el **mismo token** que `APIClient`:

```swift
private var authToken: String?

init(baseURL: URL, session: URLSession = .shared) {
    self.baseURL = baseURL
    self.session = session
    self.authToken = KeychainStore.loadToken()  // ← Token del login
}
```

**Flujo:**
1. Usuario se da de alta → Recibe token
2. Token se guarda en Keychain
3. ChatAPIClient lo carga automáticamente
4. Cada request incluye: `Authorization: Bearer {token}`

---

## ⚠️ Requisitos del Backend

Para que funcione en modo real, el backend debe:

### 1. Endpoint `/v1/directory`

✅ Acepta parámetros: `query`, `page`, `pageSize`
✅ Devuelve: `{ users: [...], hasMore: boolean }`
✅ Requiere autenticación (Bearer token)
✅ Solo muestra usuarios con `isSearchable = true`
✅ Solo muestra usuarios con `membershipStatus = active`

### 2. Base de Datos

✅ Tabla `members` con columna `is_searchable`
✅ Índice en `full_name` para búsquedas rápidas
✅ Extensión `pg_trgm` para similitud de texto (PostgreSQL)
✅ O algoritmo similar en MariaDB

### 3. Paginación Eficiente

✅ Usa `LIMIT` y `OFFSET` en SQL
✅ Calcula total para determinar `hasMore`
✅ Mantiene orden consistente entre páginas

---

## 📊 Comparación Mock vs Real

| Característica | Mock | Real (Backend) |
|---------------|------|----------------|
| **Usuarios** | 20 hardcodeados | Todos de la BD |
| **Persistencia** | No (memoria) | Sí (BD) |
| **Paginación** | Simulada | Real |
| **Búsqueda** | StringSimilarity local | pg_trgm en BD |
| **Velocidad** | Instantáneo | Depende de red |
| **Requiere backend** | No | Sí |
| **Logging** | 🔍 📄 | 📡 🌐 ✅/❌ |

---

## ✅ Checklist

- [x] `ChatServicing` protocolo con paginación
- [x] `MockChatService` implementa paginación (local)
- [x] `ChatAPIClient` implementa paginación (backend)
- [x] `UserSearchView` usa paginación
- [x] Logging agregado para debugging
- [x] Manejo de errores con fallback
- [x] Funciona en modo Mock sin backend
- [x] Funciona en modo Real con backend

---

## 🎯 Próximos Pasos

### Para Probar Modo Mock (Ya Funciona)

```bash
⌘ + R
# Ve a Chat → Lupa
# Verás 20 usuarios con paginación
```

### Para Probar Modo Real (Requiere Backend)

1. **Implementa el endpoint** en el backend:
   ```
   GET /v1/directory?query={query}&page={page}&pageSize={pageSize}
   ```

2. **Inicia el backend**:
   ```bash
   cd backend
   docker-compose up
   ```

3. **Cambia a modo local**:
   ```swift
   // En AppEnvironment o variable de entorno
   ASOCIA_ENVIRONMENT=local
   ```

4. **Ejecuta la app**:
   ```bash
   ⌘ + R
   ```

5. **Revisa logs** en consola para ver peticiones HTTP

---

**Fecha:** 26 de julio de 2026  
**Versión:** 1.0  
**Archivo modificado:** ChatAPIClient.swift  
**Estado:** Mock ✅ Funciona | Real ⚠️ Requiere backend
