# 🔐 Autenticación - Asocia

Sistema de login, registro y gestión de tokens JWT.

---

## 📄 Documentos en esta Sección

### [AUTH_USAGE_GUIDE.md](./AUTH_USAGE_GUIDE.md)
**Guía de Uso del Sistema de Autenticación**

Guía completa que cubre:
- 🔐 Arquitectura del sistema de auth
- 📝 Login y registro
- 🔑 Gestión de tokens JWT
- 💾 Keychain para almacenamiento seguro
- 🧪 Testing y debugging
- 🚀 Despliegue

---

## 🎯 Conceptos Clave

### Flujo de Autenticación

```
Usuario ingresa credenciales
         ↓
    AuthService
         ↓
Backend (auth-service) - Verifica credenciales
         ↓
    Genera JWT Token
         ↓
KeychainStore - Guarda token localmente
         ↓
SwiftData - Guarda Member local
         ↓
    App autenticada
```

### Componentes

1. **AuthService.swift**
   - Actor que maneja login/registro
   - Comunicación con backend
   - Gestión de tokens

2. **KeychainStore.swift**
   - Almacenamiento seguro de tokens
   - Encriptación nativa de iOS

3. **LoginView.swift**
   - UI de inicio de sesión
   - Validación de formulario

4. **SignupView.swift**
   - UI de registro
   - Formulario completo de alta

5. **backend/auth-service/**
   - Microservicio Node.js
   - Endpoints de auth
   - Validación y bcrypt

---

## 🚀 Inicio Rápido

### 1. Iniciar Backend

```bash
cd backend/auth-service
npm install
npm run dev
```

### 2. Configurar App

En `AppEnvironment.swift`:
```swift
case .local:
    return URL(string: "http://localhost:4001")!
```

### 3. Probar Login

```bash
# Registro
curl -X POST http://localhost:4001/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "test@test.com",
    "password": "test123",
    "firstName": "Test",
    "firstSurname": "User"
  }'

# Login
curl -X POST http://localhost:4001/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@test.com",
    "password": "test123"
  }'
```

---

## 🔒 Seguridad

### En Desarrollo (Local)
- ✅ Passwords hasheados con bcrypt
- ✅ Tokens JWT firmados
- ✅ Almacenamiento en Keychain
- ⚠️ HTTP (no HTTPS) está OK

### En Producción
- ✅ HTTPS obligatorio
- ✅ JWT_SECRET aleatorio y secreto
- ✅ Rate limiting
- ✅ Refresh tokens
- ✅ Validación de email

---

## ❓ Problemas Comunes

### Error: "No hay conexión con el servidor"
```bash
# Verificar que el servicio esté corriendo
curl http://localhost:4001/health

# Si no responde
cd backend/auth-service
npm run dev
```

### Error: "Email ya está registrado"
- Usar otro email
- O hacer login con ese email
- O reiniciar el servicio (datos en memoria se pierden)

### Error: "Token inválido o expirado"
- Volver a hacer login
- El token expira después de 30 días

---

## 🔗 Enlaces Relacionados

- **FAQ**: [docs/01-getting-started/FAQ.md](../01-getting-started/FAQ.md)
- **Backend**: [docs/04-backend/](../04-backend/)
- **Scripts**: [docs/08-scripts/start-auth-service.sh](../08-scripts/start-auth-service.sh)

---

**Última actualización:** 27 de julio de 2026
