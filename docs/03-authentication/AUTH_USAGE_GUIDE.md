# Guía de Uso del Sistema de Autenticación

## 📱 Desde la App iOS

### 1. Flujo de Registro

#### Vista del Usuario:
```
1. App inicia → LoginView aparece
2. Usuario pulsa "Crear Cuenta"
3. SignupView aparece en fullscreen
4. Usuario completa:
   - Nombre: "Juan"
   - Primer Apellido: "Pérez"
   - Email: "juan@ejemplo.com"
   - Contraseña: "miclave123"
   - Confirmar Contraseña: "miclave123"
   - (Opcionalmente otros campos...)
5. Pulsa "Enviar"
6. App muestra ProgressView
7. Registro exitoso → Vuelve a LoginView
8. LoginView detecta token → Muestra perfil
```

#### Código involucrado:
```swift
// En SignupView
let response = try await authService.register(
    id: UUID(),
    email: "juan@ejemplo.com",
    password: "miclave123",
    firstName: "Juan",
    firstSurname: "Pérez"
)

// AuthService guarda el token automáticamente
// y crea el Member en SwiftData
```

### 2. Flujo de Login

#### Vista del Usuario:
```
1. App inicia → LoginView aparece
2. Usuario introduce:
   - Email: "juan@ejemplo.com"
   - Contraseña: "miclave123"
3. Pulsa "Iniciar Sesión"
4. App muestra ProgressView
5. Login exitoso → Muestra perfil/tabs
```

#### Código involucrado:
```swift
// En LoginView
let response = try await authService.login(
    email: "juan@ejemplo.com",
    password: "miclave123"
)

// Se recibe:
// - Token JWT (guardado en Keychain)
// - Datos del usuario (guardados en SwiftData)
```

### 3. Persistencia de Sesión

#### Vista del Usuario:
```
1. Usuario cierra la app (swipe up)
2. Usuario vuelve a abrir la app
3. App verifica token → Acceso directo
4. NO se muestra LoginView
5. Usuario ve su perfil directamente
```

#### Código involucrado:
```swift
// En RootView.swift
func checkAuthentication() async {
    hasValidAuth = authService.hasValidToken()
    // Si es true → Busca Member en SwiftData
    // Si existe Member → Muestra perfil
}
```

### 4. Manejo de Errores

#### Email ya registrado:
```swift
// Usuario intenta registrarse con email existente
do {
    let response = try await authService.register(...)
} catch {
    // error.localizedDescription = "Este email ya está registrado"
    errorMessage = error.localizedDescription
}
```

#### Credenciales incorrectas:
```swift
// Usuario introduce password incorrecta
do {
    let response = try await authService.login(...)
} catch {
    // error.localizedDescription = "Email o contraseña incorrectos"
    errorMessage = error.localizedDescription
}
```

#### Sin conexión:
```swift
// No hay conexión con el servidor
do {
    let response = try await authService.login(...)
} catch {
    // error.localizedDescription = "No hay conexión con el servidor"
    errorMessage = error.localizedDescription
}
```

## 🔐 Seguridad en la App

### 1. Almacenamiento del Token

El token JWT se guarda en el Keychain del dispositivo:

```swift
// En AuthService.swift
KeychainStore.saveToken(response.token)

// El Keychain proporciona:
// - Encriptación automática
// - Protección del sistema
// - Persistencia entre reinicios
// - NO se sincroniza con iCloud (más seguro)
```

### 2. Hash de Contraseña Local

```swift
// La contraseña se hashea antes de guardar localmente
let passwordHash = AuthService.hashPassword(password)

// Usa SHA256 (no para comparación, solo para almacenamiento local)
// La verificación real ocurre en el servidor con bcrypt
```

### 3. Password nunca en texto plano

```swift
// ❌ NUNCA se hace esto:
member.password = "mipassword"

// ✅ Siempre hasheado:
member.passwordHash = AuthService.hashPassword("mipassword")
```

## 🌐 Comunicación con el Backend

### Request de Registro

```swift
// Lo que envía la app:
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "juan@ejemplo.com",
  "password": "miclave123",
  "firstName": "Juan",
  "firstSurname": "Pérez"
}

// Lo que recibe:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "member": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "firstName": "Juan",
    "firstSurname": "Pérez",
    "email": "juan@ejemplo.com",
    "membershipStatus": "pendingApproval",
    ...
  }
}
```

### Request de Login

```swift
// Lo que envía la app:
{
  "email": "juan@ejemplo.com",
  "password": "miclave123"
}

// Lo que recibe:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "member": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "firstName": "Juan",
    "firstSurname": "Pérez",
    "email": "juan@ejemplo.com",
    "membershipStatus": "active",
    ...
  }
}
```

### Uso del Token en Requests Futuros

```swift
// En APIClient.swift
// El token se añade automáticamente a los headers:
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

// Ejemplo de request autenticado:
GET /v1/members/me
Headers:
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  Content-Type: application/json
```

## 🧪 Testing en Simulador

### 1. Primera ejecución - Registro
```
Cmd + R → Ejecutar app
App muestra: LoginView
Acción: Pulsar "Crear Cuenta"
Resultado: SignupView aparece

Completar:
  Nombre: Test
  Apellido: User
  Email: test@test.com
  Password: test123
  Confirmar: test123

Acción: Pulsar "Enviar"
Resultado: 
  - App hace POST /v1/auth/register
  - Recibe token
  - Guarda en Keychain
  - Crea Member en SwiftData
  - Muestra perfil
```

### 2. Cerrar y reabrir - Persistencia
```
Cmd + Shift + H → Ir a home
Cmd + Shift + H + H → Ver apps abiertas
Swipe up → Cerrar app

Cmd + R → Ejecutar app de nuevo
Resultado:
  - RootView verifica token
  - Encuentra token en Keychain
  - Encuentra Member en SwiftData
  - NO muestra LoginView
  - Acceso directo al perfil
```

### 3. Eliminar y reinstalar - Fresh start
```
Mantener pulsado icono → Delete App
Cmd + R → Instalar de nuevo
Resultado:
  - NO hay token
  - NO hay Member
  - Muestra LoginView
  - Usuario debe hacer login
```

### 4. Login existente
```
En LoginView:
  Email: test@test.com
  Password: test123
  
Acción: Pulsar "Iniciar Sesión"
Resultado:
  - App hace POST /v1/auth/login
  - Backend verifica credenciales
  - Devuelve nuevo token
  - App actualiza Keychain
  - Acceso al perfil
```

## 🐛 Debug y Logs

### En Xcode Console

#### Registro exitoso:
```
🔐 [AUTH] register - email: test@test.com
   🌐 [POST] http://localhost:4001/v1/auth/register
   🔐 Authenticated: No
   ✅ Response: 201 (245ms)
   ✅ Registro exitoso - Token guardado
   💾 Token guardado en Keychain
```

#### Login exitoso:
```
🔐 [AUTH] login - email: test@test.com
   🌐 [POST] http://localhost:4001/v1/auth/login
   ✅ Response: 200 (156ms)
   ✅ Login exitoso - Token guardado
   💾 Token guardado en Keychain
```

#### Verificación en RootView:
```
✅ RootView - Verificación de autenticación
   Token válido: true
   Miembros encontrados: 1
   Estado del miembro: active
```

### En Terminal del Servidor

#### Usuario registrado:
```
[2026-07-26T10:30:00.000Z] POST /v1/auth/register
✅ Usuario registrado: test@test.com
```

#### Usuario hizo login:
```
[2026-07-26T10:35:00.000Z] POST /v1/auth/login
✅ Login exitoso: test@test.com
```

## 🔄 Ciclo de Vida Completo

```
┌─────────────────────────────────────────────────────────┐
│ 1. INICIO DE APP                                        │
├─────────────────────────────────────────────────────────┤
│ RootView.checkAuthentication()                         │
│  ├─ authService.hasValidToken()                        │
│  │   └─ KeychainStore.loadToken()                      │
│  └─ Query members from SwiftData                       │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
                    ┌─────┴──────┐
                    │ ¿Hay token? │
                    └─────┬──────┘
                          │
           ┌──────────────┴──────────────┐
           │                              │
         NO│                              │SÍ
           ▼                              ▼
    ┌──────────────┐            ┌────────────────┐
    │  LoginView   │            │ ¿Hay Member?   │
    └──────────────┘            └────────────────┘
           │                            │
           │                    ┌───────┴────────┐
           │                    │                 │
           │                   SÍ                NO
           │                    │                 │
           │                    ▼                 ▼
           │           ┌─────────────────┐  ┌──────────┐
           │           │ MemberProfile   │  │LoginView │
           │           │ o MainTabView   │  └──────────┘
           │           └─────────────────┘
           │
           │  Usuario pulsa "Crear Cuenta"
           ▼
    ┌──────────────┐
    │  SignupView  │
    └──────────────┘
           │
           │  Usuario completa formulario
           ▼
    ┌──────────────────────────────────┐
    │ authService.register()           │
    │  ├─ POST /v1/auth/register       │
    │  ├─ Recibe token + member        │
    │  ├─ KeychainStore.saveToken()    │
    │  └─ Insert member en SwiftData   │
    └──────────────────────────────────┘
           │
           │  onSuccess()
           ▼
    ┌──────────────┐
    │  LoginView   │
    └──────────────┘
           │
           │  checkAuth() detecta token
           ▼
    ┌──────────────────┐
    │ MemberProfile    │
    └──────────────────┘
```

## 📱 Estados de la UI

### Estado 1: No autenticado
```
┌─────────────────────────┐
│                         │
│    🔵 Asocia           │
│                         │
│   ┌─────────────────┐  │
│   │ Email           │  │
│   └─────────────────┘  │
│                         │
│   ┌─────────────────┐  │
│   │ Contraseña      │  │
│   └─────────────────┘  │
│                         │
│   ┌─────────────────┐  │
│   │ Iniciar Sesión  │  │
│   └─────────────────┘  │
│                         │
│   ¿No tienes cuenta?    │
│   [Crear Cuenta]        │
│                         │
└─────────────────────────┘
```

### Estado 2: Registro
```
┌─────────────────────────┐
│ ← Cancelar              │
├─────────────────────────┤
│ Crear Cuenta            │
├─────────────────────────┤
│                         │
│ [Foto de perfil]        │
│                         │
│ Nombre:                 │
│ [              ]        │
│                         │
│ Primer apellido:        │
│ [              ]        │
│                         │
│ Email:                  │
│ [              ]        │
│                         │
│ Contraseña:             │
│ [••••••••••••••]        │
│                         │
│ Confirmar:              │
│ [••••••••••••••]        │
│                         │
│ ... más campos ...      │
│                         │
│ [    Enviar    ]        │
│                         │
└─────────────────────────┘
```

### Estado 3: Autenticado - Pending Approval
```
┌─────────────────────────┐
│ Perfil | Chat | Ajustes │ ← Tabs deshabilitados
├─────────────────────────┤
│                         │
│  [Foto]                 │
│                         │
│  Juan Pérez             │
│                         │
│  ⏳ Pendiente de        │
│     aprobación          │
│                         │
│  📧 juan@ejemplo.com    │
│                         │
│  ... datos ...          │
│                         │
└─────────────────────────┘
```

### Estado 4: Autenticado - Active
```
┌─────────────────────────┐
│ Perfil | Chat | Ajustes │ ← Tabs habilitados
├─────────────────────────┤
│                         │
│  [Foto]                 │
│                         │
│  Juan Pérez             │
│  ✅ Socio activo        │
│                         │
│  📧 juan@ejemplo.com    │
│  📱 666123456           │
│                         │
│  [Editar]               │
│                         │
└─────────────────────────┘
```

## 💡 Tips de Desarrollo

1. **Limpiar Keychain entre pruebas:**
   ```swift
   // Añadir botón temporal en LoginView:
   Button("Limpiar Keychain") {
       KeychainStore.deleteToken()
   }
   ```

2. **Ver contenido del token JWT:**
   ```swift
   // En debug:
   if let token = KeychainStore.loadToken() {
       print("Token: \(token)")
       // Copiar y pegar en https://jwt.io para decodificar
   }
   ```

3. **Resetear base de datos local:**
   ```
   - Detener app en Xcode
   - Product > Clean Build Folder
   - Eliminar app del simulador
   - Cmd + R
   ```

4. **Cambiar estado de membership manualmente:**
   ```swift
   // En debug, para testing:
   member.membershipStatus = .active
   try? modelContext.save()
   ```
