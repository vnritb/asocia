# ✅ Checklist de Implementación

## Pre-requisitos

- [ ] Node.js instalado (v14+)
  ```bash
  node --version
  ```
- [ ] npm instalado
  ```bash
  npm --version
  ```
- [ ] Xcode instalado
- [ ] Proyecto iOS abierto en Xcode

## Backend Setup

- [ ] Navegar a directorio del servicio
  ```bash
  cd backend/auth-service
  ```
- [ ] Instalar dependencias
  ```bash
  npm install
  ```
- [ ] Verificar que package.json existe
- [ ] Verificar que index.js existe
- [ ] (Opcional) Copiar .env.example a .env
  ```bash
  cp .env.example .env
  ```
- [ ] (Opcional) Cambiar JWT_SECRET en .env
- [ ] Iniciar servidor
  ```bash
  npm run dev
  ```
- [ ] Verificar que imprime: "🔐 Auth Service escuchando en puerto 4001"
- [ ] Verificar health check
  ```bash
  curl http://localhost:4001/health
  ```
- [ ] Debería responder: `{"status":"ok","service":"auth-service",...}`

## iOS App Setup

- [ ] Archivo `Member.swift` tiene campo `passwordHash`
- [ ] Archivo `AuthService.swift` existe y tiene:
  - [ ] `hashPassword()` método estático
  - [ ] `login()` método
  - [ ] `register()` método
  - [ ] `hasValidToken()` método
- [ ] Archivo `LoginView.swift` existe y tiene:
  - [ ] Campos de email y password
  - [ ] Botón "Crear Cuenta"
  - [ ] Environment key `authService`
- [ ] Archivo `SignupView.swift` actualizado con:
  - [ ] Campos de password y confirmación
  - [ ] Validación mejorada
  - [ ] Callback `onSuccess`
- [ ] Archivo `RootView.swift` actualizado con:
  - [ ] Verificación de token
  - [ ] Muestra LoginView si no hay token
- [ ] `AppEnvironment.swift` configurado:
  - [ ] Caso `.local` apunta a `http://localhost:4001`
  - [ ] (Si usas dispositivo físico) IP de tu Mac en lugar de localhost

## Compilación y Ejecución

- [ ] Proyecto compila sin errores
  ```
  Cmd + B
  ```
- [ ] Scheme seleccionado: "Asocia (Local)"
- [ ] Simulador o dispositivo seleccionado
- [ ] Ejecutar app
  ```
  Cmd + R
  ```
- [ ] App muestra LoginView al iniciar

## Pruebas Funcionales

### Test 1: Registro de Usuario

- [ ] App muestra LoginView
- [ ] Pulsar "Crear Cuenta"
- [ ] SignupView aparece
- [ ] Completar formulario:
  - [ ] Nombre: "Test"
  - [ ] Apellido: "User"
  - [ ] Email: "test@test.com"
  - [ ] Password: "test123"
  - [ ] Confirmar: "test123"
- [ ] Pulsar "Enviar"
- [ ] No hay errores
- [ ] App muestra perfil
- [ ] En Xcode Console ver: "✅ Registro exitoso"
- [ ] En servidor ver: "✅ Usuario registrado: test@test.com"

### Test 2: Persistencia de Sesión

- [ ] Cerrar app (swipe up en simulador)
- [ ] Volver a ejecutar app (Cmd + R)
- [ ] App NO muestra LoginView
- [ ] App va directo a perfil
- [ ] En Xcode Console ver: "Token válido: true"

### Test 3: Login Existente

- [ ] Desinstalar app del simulador
- [ ] Ejecutar app de nuevo (Cmd + R)
- [ ] App muestra LoginView
- [ ] Introducir:
  - [ ] Email: "test@test.com"
  - [ ] Password: "test123"
- [ ] Pulsar "Iniciar Sesión"
- [ ] No hay errores
- [ ] App muestra perfil
- [ ] En Xcode Console ver: "✅ Login exitoso"

### Test 4: Validación de Errores

- [ ] En LoginView, introducir:
  - [ ] Email: "test@test.com"
  - [ ] Password: "wrong"
- [ ] Pulsar "Iniciar Sesión"
- [ ] Ver error: "Email o contraseña incorrectos"

- [ ] Pulsar "Crear Cuenta"
- [ ] Completar con email: "test@test.com"
- [ ] Pulsar "Enviar"
- [ ] Ver error: "Este email ya está registrado"

## Pruebas con cURL

- [ ] Test de registro
  ```bash
  curl -X POST http://localhost:4001/v1/auth/register \
    -H "Content-Type: application/json" \
    -d '{
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "curl@test.com",
      "password": "test123",
      "firstName": "Curl",
      "firstSurname": "Test"
    }'
  ```
- [ ] Respuesta incluye `"token"` y `"member"`

- [ ] Test de login
  ```bash
  curl -X POST http://localhost:4001/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{
      "email": "curl@test.com",
      "password": "test123"
    }'
  ```
- [ ] Respuesta incluye `"token"` y `"member"`

## Pruebas Automatizadas

- [ ] Ejecutar script de pruebas
  ```bash
  cd backend/auth-service
  chmod +x test.sh
  ./test.sh
  ```
- [ ] Todas las pruebas pasan (10/10)
- [ ] Ver mensaje: "✅ Todas las pruebas completadas"

## Verificación de Logs

### En Xcode Console

- [ ] Ver mensajes con emoji 🔐 (AuthService)
- [ ] Ver mensajes con emoji ✅ (éxito)
- [ ] Ver mensajes con emoji ❌ (errores esperados)
- [ ] Ver "Token válido: true" al reabrir app
- [ ] Ver "Miembros encontrados: 1"

### En Terminal del Servidor

- [ ] Ver timestamp de cada request
- [ ] Ver "POST /v1/auth/register"
- [ ] Ver "POST /v1/auth/login"
- [ ] Ver "✅ Usuario registrado: ..."
- [ ] Ver "✅ Login exitoso: ..."

## Seguridad (Desarrollo)

- [ ] Passwords NO visibles en logs
- [ ] Token NO visible en logs (solo primeros caracteres)
- [ ] `.env` en `.gitignore`
- [ ] No hay hardcoded secrets en código
- [ ] Keychain usado para token (no UserDefaults)

## Documentación

- [ ] README principal actualizado
- [ ] `QUICK_START.md` creado
- [ ] `AUTH_IMPLEMENTATION_SUMMARY.md` creado
- [ ] `AUTH_USAGE_GUIDE.md` creado
- [ ] `ARCHITECTURE.md` creado
- [ ] `FAQ.md` creado
- [ ] `SETUP_AUTH_SERVICE.md` creado
- [ ] `backend/auth-service/README.md` creado

## Git

- [ ] Archivos nuevos añadidos al repo
  ```bash
  git status
  ```
- [ ] `.env` NO está en el repo
- [ ] `.env.example` SÍ está en el repo
- [ ] `node_modules/` en `.gitignore`

## Opcional - Mejoras Futuras

- [ ] Añadir claves de localización (ver `LOCALIZATION_KEYS_AUTH.md`)
- [ ] Configurar base de datos real (PostgreSQL/MongoDB)
- [ ] Implementar recuperación de contraseña
- [ ] Añadir validación de formato de email
- [ ] Implementar rate limiting
- [ ] Configurar HTTPS para producción
- [ ] Implementar refresh tokens
- [ ] Añadir 2FA
- [ ] Configurar monitoring (Sentry, DataDog)
- [ ] Implementar backup de base de datos

## Problemas Comunes

Si algo no funciona, verificar:

- [ ] El servidor está corriendo (no cerrado accidentalmente)
- [ ] Puerto 4001 no está ocupado por otro proceso
- [ ] URL correcta en `AppEnvironment.swift`
- [ ] Scheme correcto ("Asocia (Local)")
- [ ] No hay errores de compilación
- [ ] Clean build folder si hay errores raros (Cmd + Shift + K)
- [ ] Simulator reset si hay problemas de Keychain

## ✅ Todo Completo

Si todos los checkboxes están marcados:

🎉 **¡Felicidades! El sistema de autenticación está completamente funcional.**

Siguiente paso: Desplegar a producción o implementar features adicionales.

---

## Notas

Fecha de implementación: _____________

Versión: 1.0.0

Implementado por: _____________

Probado en:
- [ ] Simulador iOS 17.0
- [ ] Simulador iOS 18.0
- [ ] Dispositivo físico
- [ ] macOS (si aplica)

Problemas encontrados:
_____________________________________________________________________________
_____________________________________________________________________________
_____________________________________________________________________________

Soluciones aplicadas:
_____________________________________________________________________________
_____________________________________________________________________________
_____________________________________________________________________________
