# 🗺️ Roadmap - Sistema de Autenticación

## ✅ Completado (v1.0.0)

- ✅ Microservicio de autenticación (Node.js/Express)
- ✅ Registro de usuarios con email y password
- ✅ Login con credenciales
- ✅ Tokens JWT con expiración
- ✅ Almacenamiento seguro en Keychain
- ✅ Encriptación de passwords (bcrypt)
- ✅ Pantalla de Login (SwiftUI)
- ✅ Pantalla de Registro (SwiftUI)
- ✅ Persistencia de sesión
- ✅ Flujo de navegación completo
- ✅ Validación de campos
- ✅ Manejo de errores
- ✅ Documentación completa

## 🔜 Próximas Tareas (v1.1.0) - Corto Plazo

### Alta Prioridad

#### 1. Base de Datos Persistente
**Estado:** 🔴 No iniciado  
**Tiempo estimado:** 2-4 horas  
**Descripción:** Migrar de almacenamiento en memoria a PostgreSQL o MongoDB

**Tareas:**
- [ ] Elegir base de datos (PostgreSQL recomendado)
- [ ] Instalar driver (`pg` o `mongodb`)
- [ ] Crear esquema/colección de usuarios
- [ ] Migrar lógica de registro
- [ ] Migrar lógica de login
- [ ] Migrar lógica de verificación
- [ ] Probar con datos reales
- [ ] Documentar schema

**Archivos afectados:**
- `backend/auth-service/index.js`
- `backend/auth-service/package.json`
- Nuevo: `backend/auth-service/database.js`
- Nuevo: `backend/auth-service/schema.sql` (o `models/User.js`)

#### 2. Variables de Entorno
**Estado:** 🟡 Parcial (existe .env.example)  
**Tiempo estimado:** 30 minutos  
**Descripción:** Configurar variables de entorno para diferentes ambientes

**Tareas:**
- [ ] Crear `.env` para desarrollo
- [ ] Crear `.env.staging` para staging
- [ ] Crear `.env.production` para producción
- [ ] Generar JWT_SECRET seguro para cada ambiente
- [ ] Configurar DATABASE_URL
- [ ] Documentar proceso

**Archivos afectados:**
- `.env` (crear)
- `backend/auth-service/index.js` (usar dotenv)

#### 3. Claves de Localización
**Estado:** 🔴 No iniciado  
**Tiempo estimado:** 1 hora  
**Descripción:** Añadir traducciones para textos de login/registro

**Tareas:**
- [ ] Añadir claves en español (`es.json`)
- [ ] Añadir claves en catalán (`ca.json`)
- [ ] Añadir claves en inglés (`en.json`)
- [ ] Actualizar LoginView para usar `loc.t()`
- [ ] Actualizar SignupView para usar `loc.t()`
- [ ] Probar en los 3 idiomas

**Archivos afectados:**
- `Resources/Localization/es.json`
- `Resources/Localization/ca.json`
- `Resources/Localization/en.json`
- `LoginView.swift`
- `SignupView.swift`

### Prioridad Media

#### 4. Validación de Email
**Estado:** 🔴 No iniciado  
**Tiempo estimado:** 1 hora  
**Descripción:** Validar formato de email antes de enviar

**Tareas:**
- [ ] Añadir regex de validación en cliente
- [ ] Añadir regex de validación en servidor
- [ ] Mostrar error si email inválido
- [ ] Añadir tests

**Archivos afectados:**
- `LoginView.swift`
- `SignupView.swift`
- `backend/auth-service/index.js`

#### 5. Recuperación de Contraseña
**Estado:** 🔴 No iniciado  
**Tiempo estimado:** 4-6 horas  
**Descripción:** Implementar "Olvidé mi contraseña"

**Tareas:**
- [ ] Endpoint `POST /forgot-password`
- [ ] Generar token temporal
- [ ] Enviar email con token/link
- [ ] Pantalla en app para introducir token
- [ ] Endpoint `POST /reset-password`
- [ ] Actualizar password en BD
- [ ] Invalidar tokens antiguos
- [ ] Tests

**Archivos nuevos:**
- `ForgotPasswordView.swift`
- `ResetPasswordView.swift`
- `backend/auth-service/email.js`

**Archivos afectados:**
- `LoginView.swift` (botón "Olvidé mi contraseña")
- `backend/auth-service/index.js`

## 🚀 Versión 1.2.0 - Mediano Plazo

### 6. Verificación de Email
**Tiempo estimado:** 3-4 horas

**Tareas:**
- [ ] Email de bienvenida al registrarse
- [ ] Link de verificación
- [ ] Endpoint `POST /verify-email`
- [ ] Estado `emailVerified` en usuario
- [ ] Restricciones según verificación

### 7. Refresh Tokens
**Tiempo estimado:** 4-6 horas

**Tareas:**
- [ ] Tabla de refresh tokens
- [ ] Endpoint `POST /refresh`
- [ ] Access token (1h) + Refresh token (30d)
- [ ] Rotación de refresh tokens
- [ ] Invalidación al logout

### 8. Rate Limiting
**Tiempo estimado:** 2-3 horas

**Tareas:**
- [ ] Instalar `express-rate-limit`
- [ ] Configurar límites (ej: 5 intentos/minuto)
- [ ] Diferentes límites por endpoint
- [ ] Respuesta 429 (Too Many Requests)
- [ ] Tests

### 9. Logging Robusto
**Tiempo estimado:** 2-3 horas

**Tareas:**
- [ ] Instalar Winston o Bunyan
- [ ] Logs estructurados (JSON)
- [ ] Niveles: debug, info, warn, error
- [ ] Rotación de archivos
- [ ] No loguear información sensible

### 10. HTTPS en Producción
**Tiempo estimado:** 2-3 horas

**Tareas:**
- [ ] Configurar certificados SSL
- [ ] Forzar HTTPS en servidor
- [ ] Configurar App Transport Security
- [ ] Probar en staging
- [ ] Desplegar a producción

## 🎯 Versión 2.0.0 - Largo Plazo

### Features Avanzados

#### 11. Sign in with Apple
**Tiempo estimado:** 6-8 horas

**Tareas:**
- [ ] Configurar en Apple Developer
- [ ] Instalar SDK en app
- [ ] Endpoint en servidor
- [ ] Vincular cuenta Apple a usuario
- [ ] Botón en LoginView

#### 12. Autenticación de Dos Factores (2FA)
**Tiempo estimado:** 8-10 horas

**Tareas:**
- [ ] Generar secret TOTP
- [ ] QR code para Google Authenticator
- [ ] Pantalla de configuración 2FA
- [ ] Pantalla de introducir código
- [ ] Backup codes
- [ ] Verificación en login

#### 13. Gestión de Sesiones
**Tiempo estimado:** 4-6 horas

**Tareas:**
- [ ] Tabla de sesiones activas
- [ ] Device fingerprinting
- [ ] Pantalla de sesiones activas
- [ ] Cerrar sesión remota
- [ ] Notificación de nuevo login

#### 14. OAuth con Google/Facebook
**Tiempo estimado:** 6-8 horas cada uno

**Tareas:**
- [ ] Configurar app en Google/Facebook
- [ ] Instalar SDKs
- [ ] Flujo de autorización
- [ ] Endpoint en servidor
- [ ] Vincular cuentas

#### 15. Biométricos (Face ID / Touch ID)
**Tiempo estimado:** 3-4 horas

**Tareas:**
- [ ] Añadir LocalAuthentication framework
- [ ] Solicitar permiso
- [ ] Login con biométricos
- [ ] Fallback a password
- [ ] Configuración en ajustes

## 🔧 Mejoras Técnicas

### 16. Tests Automatizados
**Tiempo estimado:** 10-15 horas

**Backend:**
- [ ] Unit tests (Mocha/Jest)
- [ ] Integration tests
- [ ] Coverage >80%

**iOS:**
- [ ] Unit tests (XCTest)
- [ ] UI tests
- [ ] Coverage >70%

### 17. CI/CD
**Tiempo estimado:** 6-8 horas

**Tareas:**
- [ ] GitHub Actions para backend
- [ ] Tests automáticos en PR
- [ ] Deploy automático a staging
- [ ] GitHub Actions para iOS
- [ ] Build automático
- [ ] TestFlight automático

### 18. Monitoring
**Tiempo estimado:** 4-6 horas

**Tareas:**
- [ ] Integrar Sentry (error tracking)
- [ ] Integrar DataDog o NewRelic (APM)
- [ ] Alertas por email/Slack
- [ ] Dashboard de métricas

### 19. Documentación API
**Tiempo estimado:** 4-6 horas

**Tareas:**
- [ ] Swagger/OpenAPI spec
- [ ] Postman collection
- [ ] Ejemplos de uso
- [ ] Códigos de error documentados

## 📊 Priorización Sugerida

### Fase 1 (Esencial para producción)
1. Base de datos persistente
2. Variables de entorno
3. HTTPS
4. Rate limiting
5. Logging robusto

### Fase 2 (Mejoras de UX)
1. Claves de localización
2. Validación de email
3. Recuperación de contraseña
4. Verificación de email

### Fase 3 (Seguridad avanzada)
1. Refresh tokens
2. 2FA
3. Sign in with Apple

### Fase 4 (Features avanzados)
1. OAuth (Google/Facebook)
2. Biométricos
3. Gestión de sesiones

### Fase 5 (DevOps)
1. Tests automatizados
2. CI/CD
3. Monitoring
4. Documentación API

## 🎯 Objetivos por Versión

### v1.1.0 (1-2 semanas)
- Base de datos real
- Variables de entorno
- Claves de localización
- Validación de email
- **Meta:** Listo para staging

### v1.2.0 (2-3 semanas)
- Recuperación de contraseña
- Verificación de email
- Rate limiting
- Logging robusto
- HTTPS
- **Meta:** Listo para beta

### v2.0.0 (1-2 meses)
- Refresh tokens
- Sign in with Apple
- Tests automatizados
- CI/CD
- Monitoring
- **Meta:** Listo para producción

### v2.1.0 (2-3 meses)
- 2FA
- OAuth
- Biométricos
- Gestión de sesiones
- **Meta:** Feature complete

## 📝 Notas de Desarrollo

### Convenciones de Commit
```
feat: nueva funcionalidad
fix: corrección de bug
docs: cambios en documentación
refactor: refactorización de código
test: añadir o modificar tests
chore: tareas de mantenimiento
```

### Branches
- `main`: producción
- `develop`: desarrollo
- `feature/*`: features nuevos
- `fix/*`: correcciones
- `release/*`: preparación de releases

### Code Review
- Todo PR requiere revisión
- Tests deben pasar
- Coverage no debe bajar

## 🎉 Conclusión

Este roadmap es una guía flexible. Las prioridades pueden cambiar según:
- Feedback de usuarios
- Requerimientos de negocio
- Problemas de seguridad
- Recursos disponibles

**Estado actual:** v1.0.0 completo ✅  
**Próximo milestone:** v1.1.0 (Base de datos + Configuración)  
**Tiempo estimado para v1.1.0:** 1-2 semanas
