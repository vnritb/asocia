# Sistema de Autenticación con Login y Registro

## 📋 Resumen de Implementación

He implementado un sistema completo de autenticación con las siguientes características:

### ✅ Cambios realizados

#### 1. **Backend - Microservicio de Autenticación**
   - Nuevo servicio Node.js/Express en `backend/auth-service/`
   - Endpoints REST para registro y login
   - Encriptación de contraseñas con bcrypt
   - Generación y verificación de tokens JWT
   - Almacenamiento en memoria (fácil migrar a BD real)
   - Puerto: 4001

#### 2. **Modelo de Datos**
   - Añadido campo `passwordHash` al modelo `Member`
   - El hash se guarda solo localmente en el registro
   - No se sincroniza el password con el backend en updates posteriores

#### 3. **Servicio de Autenticación (iOS)**
   - `AuthService.swift` actualizado con:
     - Método `hashPassword()` para hash local
     - Método `login()` con email/password
     - Método `register()` con todos los datos necesarios
     - Almacenamiento seguro en Keychain
     - DTOs para comunicación con backend

#### 4. **Pantalla de Login**
   - Nueva `LoginView` con:
     - Campos de email y password
     - Validación de campos
     - Botón para ir a registro
     - Manejo de errores
     - Guardado automático en SwiftData

#### 5. **Pantalla de Registro**
   - `SignupView` actualizada con:
     - Campos de password y confirmación
     - Validación mejorada (email + password obligatorios)
     - Integración con AuthService
     - Callback de éxito

#### 6. **Flujo de Navegación**
   - `RootView` actualizado con nuevo flujo:
     1. Verificación de token al iniciar
     2. Si no hay token → LoginView
     3. Si hay token → Verifica Member en BD
     4. Si hay Member → Muestra perfil/tabs según estado

## 🔄 Flujo de Usuario

### Usuario Nuevo (Registro)
```
1. App inicia → LoginView
2. Usuario pulsa "Crear Cuenta"
3. SignupView aparece
4. Usuario completa formulario (nombre, email, password)
5. App llama AuthService.register()
6. Backend:
   - Valida datos
   - Hashea password con bcrypt
   - Crea usuario
   - Genera token JWT
   - Devuelve token + datos básicos
7. App:
   - Guarda token en Keychain
   - Crea Member en SwiftData
   - Cierra SignupView
   - Muestra perfil (estado: pendingApproval)
```

### Usuario Existente (Login)
```
1. App inicia → LoginView
2. Usuario introduce email y password
3. App llama AuthService.login()
4. Backend:
   - Busca usuario por email
   - Verifica password con bcrypt
   - Genera nuevo token JWT
   - Devuelve token + datos actualizados
5. App:
   - Guarda token en Keychain
   - Actualiza/crea Member en SwiftData
   - Muestra perfil/tabs según estado
```

### Siguiente Inicio
```
1. App inicia
2. RootView verifica token en Keychain
3. Si existe token:
   - Busca Member en SwiftData
   - Si existe → Acceso directo a perfil/tabs
   - Si no existe → LoginView
4. Si no hay token → LoginView
```

## 🔐 Seguridad

### En el Cliente (iOS)
- Passwords hasheados con SHA256 localmente
- Token JWT guardado en Keychain (encriptado por iOS)
- Password nunca se guarda en texto plano
- Comunicación HTTPS en producción

### En el Servidor
- Passwords hasheados con bcrypt (salt rounds: 10)
- Tokens JWT con expiración de 30 días
- Validación de longitud mínima de password (6 caracteres)
- CORS habilitado para desarrollo local

### ⚠️ Mejoras para Producción
- [ ] Cambiar JWT_SECRET por valor aleatorio seguro
- [ ] Implementar base de datos real (PostgreSQL/MongoDB)
- [ ] Añadir rate limiting contra fuerza bruta
- [ ] Validar formato de email con regex
- [ ] Implementar recuperación de contraseña
- [ ] Usar refresh tokens
- [ ] Habilitar HTTPS obligatorio
- [ ] Logging de intentos fallidos
- [ ] Expiración de sesión configurable

## 📁 Archivos Modificados

### Nuevos Archivos
- `backend/auth-service/index.js` - Microservicio de autenticación
- `backend/auth-service/package.json` - Dependencias del servicio
- `backend/auth-service/README.md` - Documentación del servicio
- `SETUP_AUTH_SERVICE.md` - Guía de instalación
- `LOCALIZATION_KEYS_AUTH.md` - Nuevas claves de traducción

### Archivos Modificados
- `Member.swift` - Añadido campo `passwordHash`
- `AuthService.swift` - Métodos de login/registro y hash de password
- `LoginView.swift` - Pantalla de login renovada
- `SignupView.swift` - Añadidos campos de password
- `RootView.swift` - Flujo de navegación actualizado

## 🚀 Cómo Ejecutar

### 1. Iniciar el microservicio
```bash
cd backend/auth-service
npm install
npm run dev
```

### 2. Verificar que funciona
```bash
curl http://localhost:4001/health
```

### 3. Ejecutar la app iOS
- Configurar scheme a "Asocia (Local)"
- Asegurarse de que `AppEnvironment.local` apunta a `http://localhost:4001`
- Ejecutar en simulador o dispositivo

### 4. Probar el flujo
1. App muestra LoginView
2. Pulsar "Crear Cuenta"
3. Rellenar formulario con email y password
4. Submit → Usuario registrado
5. Ver perfil con estado "pendingApproval"
6. Cerrar app y volver a abrir
7. Acceso automático (token guardado)

## 🧪 Testing Manual

### Registro
```bash
curl -X POST http://localhost:4001/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "test@test.com",
    "password": "test123",
    "firstName": "Test",
    "firstSurname": "User"
  }'
```

### Login
```bash
curl -X POST http://localhost:4001/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@test.com",
    "password": "test123"
  }'
```

## 📝 Notas Importantes

1. **Base de datos en memoria**: Actualmente el microservicio guarda usuarios en memoria (Map). Al reiniciar el servicio se pierden todos los usuarios. Para producción, integrar con PostgreSQL o MongoDB.

2. **MembershipStatus**: Al registrarse, el usuario recibe estado `pendingApproval`. Al hacer login, recibe estado `active` (simplificación para desarrollo). En producción, esto debería venir de una base de datos real.

3. **Token expiración**: Los tokens JWT expiran a los 30 días. Después de eso, el usuario necesitará volver a hacer login.

4. **Sincronización**: El sistema actual funciona "offline-first". El token se usa solo para autenticación inicial. Los datos del usuario se guardan en SwiftData local.

5. **Migración de datos**: Al añadir `passwordHash` al modelo `Member`, SwiftData manejará automáticamente la migración. Los usuarios existentes tendrán `passwordHash` vacío.

## 🔮 Próximos Pasos

1. **Integrar con API Gateway**: Si tienes un API Gateway, configurar proxy para `/v1/auth/*`
2. **Base de datos persistente**: Migrar de Map en memoria a PostgreSQL/MongoDB
3. **Recuperación de contraseña**: Implementar "Olvidé mi contraseña"
4. **Verificación de email**: Enviar email de confirmación al registrarse
5. **Refresh tokens**: Implementar refresh tokens para mejor seguridad
6. **OAuth/Social login**: Añadir login con Google, Apple, etc.
7. **2FA**: Autenticación de dos factores
8. **Gestión de sesiones**: Panel para ver/cerrar sesiones activas

## ❓ Troubleshooting

### Error: "Connection failed"
- Verifica que el servicio esté corriendo en puerto 4001
- Verifica la URL en `AppEnvironment.swift`

### Error: "Email ya registrado"
- Email ya existe en la base de datos
- Prueba con otro email o haz login

### Error: "Token inválido"
- Token ha expirado
- Vuelve a hacer login

### App no encuentra el servicio
- Si usas dispositivo físico, cambia `localhost` por la IP de tu Mac
- Asegúrate de estar en la misma red WiFi
