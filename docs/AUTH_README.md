# 🔐 Sistema de Autenticación con Login y Registro

> Sistema completo de autenticación JWT para la aplicación Asocia

[![Estado](https://img.shields.io/badge/estado-funcional-success)]()
[![Versión](https://img.shields.io/badge/versión-1.0.0-blue)]()
[![Documentación](https://img.shields.io/badge/docs-completa-green)]()

## 🚀 Inicio Rápido

```bash
# 1. Instalar y ejecutar el microservicio
cd backend/auth-service
npm install
npm run dev

# 2. En Xcode, ejecutar la app (Cmd + R)
```

**¡Listo!** Ahora puedes crear una cuenta y hacer login.

👉 Ver [QUICK_START.md](QUICK_START.md) para instrucciones detalladas.

## 📋 ¿Qué hace este sistema?

- ✅ **Registro de usuarios** con email y contraseña
- ✅ **Login** con credenciales
- ✅ **Tokens JWT** seguros con expiración
- ✅ **Persistencia de sesión** (no requiere login cada vez)
- ✅ **Almacenamiento seguro** en Keychain
- ✅ **Encriptación de contraseñas** con bcrypt
- ✅ **Validación de datos** en cliente y servidor
- ✅ **Manejo de errores** con feedback visual

## 🎯 Flujo de Usuario

```
Splash → LoginView → SignupView → Perfil → Tabs
           ↓           ↓           ↑
         Login      Registro    Token JWT
                                guardado
```

### Primera vez
1. Usuario abre app
2. Ve pantalla de login
3. Pulsa "Crear Cuenta"
4. Completa formulario
5. ¡Registrado! Ve su perfil

### Siguientes veces
1. Usuario abre app
2. **Acceso automático** (token guardado)
3. Ve su perfil directamente

## 🏗️ Arquitectura

```
┌─────────────┐      HTTPS      ┌──────────────┐
│             │ ◀──────────────▶ │              │
│   App iOS   │   JWT Token     │   Backend    │
│  (SwiftUI)  │                 │  (Node.js)   │
│             │                 │              │
└──────┬──────┘                 └──────┬───────┘
       │                               │
       │                               │
   Keychain                         bcrypt
   SwiftData                        JWT
```

## 📁 Estructura del Proyecto

```
.
├── backend/
│   └── auth-service/           # Microservicio de autenticación
│       ├── index.js           # Servidor Express
│       ├── package.json       # Dependencias
│       ├── README.md          # Docs del servicio
│       ├── start.sh          # Script de inicio
│       └── test.sh           # Script de pruebas
│
├── iOS/ (o tu carpeta de código Swift)
│   ├── Member.swift          # Modelo de datos
│   ├── AuthService.swift     # Servicio de auth
│   ├── LoginView.swift       # Pantalla de login
│   ├── SignupView.swift      # Pantalla de registro
│   └── RootView.swift        # Navegación
│
└── docs/
    ├── QUICK_START.md                    # 👈 Empieza aquí
    ├── AUTH_IMPLEMENTATION_SUMMARY.md    # Resumen técnico
    ├── AUTH_USAGE_GUIDE.md              # Guía de uso
    ├── ARCHITECTURE.md                   # Arquitectura detallada
    ├── FAQ.md                           # Preguntas frecuentes
    ├── IMPLEMENTATION_CHECKLIST.md      # Checklist de verificación
    ├── ROADMAP.md                       # Mejoras futuras
    └── EXECUTIVE_SUMMARY.md             # Resumen ejecutivo
```

## 📚 Documentación

| Documento | Para quién | Qué contiene |
|-----------|-----------|--------------|
| [QUICK_START.md](QUICK_START.md) | Todos | Inicio rápido en 5 minutos |
| [EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md) | PMs, Managers | Resumen ejecutivo del proyecto |
| [AUTH_IMPLEMENTATION_SUMMARY.md](AUTH_IMPLEMENTATION_SUMMARY.md) | Desarrolladores | Detalles técnicos completos |
| [AUTH_USAGE_GUIDE.md](AUTH_USAGE_GUIDE.md) | Desarrolladores | Ejemplos de uso y código |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Arquitectos | Diagramas y estructura |
| [FAQ.md](FAQ.md) | Todos | Preguntas frecuentes |
| [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md) | QA, Devs | Verificación de todo |
| [ROADMAP.md](ROADMAP.md) | Product, Devs | Próximas features |

## 🔧 Tecnologías

### Backend
- Node.js + Express
- bcrypt (hash de passwords)
- jsonwebtoken (JWT)
- CORS

### Frontend
- Swift + SwiftUI
- SwiftData (persistencia)
- CryptoKit (hash local)
- Keychain (storage seguro)

## ⚡ Comandos Rápidos

```bash
# Iniciar servidor
cd backend/auth-service && npm run dev

# Probar servidor
curl http://localhost:4001/health

# Ejecutar tests
cd backend/auth-service && ./test.sh

# Ver logs
# (en la terminal donde corre npm run dev)
```

## 🧪 Testing

### Prueba manual rápida

1. **Registro:**
   ```bash
   curl -X POST http://localhost:4001/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{"id":"550e8400-e29b-41d4-a716-446655440000","email":"test@test.com","password":"test123","firstName":"Test","firstSurname":"User"}'
   ```

2. **Login:**
   ```bash
   curl -X POST http://localhost:4001/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@test.com","password":"test123"}'
   ```

### Pruebas automatizadas

```bash
cd backend/auth-service
chmod +x test.sh
./test.sh
```

Deberías ver: `✅ Todas las pruebas completadas`

## 🔐 Seguridad

### ✅ Implementado
- Passwords hasheados con bcrypt
- Tokens JWT firmados
- Almacenamiento en Keychain
- Validación de entrada
- CORS configurado

### ⚠️ Para Producción
- [ ] Usar HTTPS
- [ ] Base de datos real (no en memoria)
- [ ] JWT_SECRET aleatorio
- [ ] Rate limiting
- [ ] Logging robusto
- [ ] Monitoring

Ver [ROADMAP.md](ROADMAP.md) para el plan completo.

## 🐛 Troubleshooting

### Error: "No hay conexión con el servidor"
```bash
# Verificar que el servidor esté corriendo
curl http://localhost:4001/health
# Si no responde, iniciarlo
cd backend/auth-service && npm run dev
```

### Error: "Email ya registrado"
- Normal: el email ya existe
- Usar otro email o hacer login

### Error: "Cannot connect to localhost" (dispositivo físico)
```swift
// En AppEnvironment.swift, cambiar:
case .local:
    return URL(string: "http://192.168.1.XXX:4001")!
    // Usa la IP de tu Mac
```

👉 Ver [FAQ.md](FAQ.md) para más problemas y soluciones.

## 📊 Estado del Proyecto

| Componente | Estado | Siguiente |
|-----------|--------|-----------|
| Backend | ✅ Funcional | BD persistente |
| Frontend | ✅ Funcional | Traducciones |
| Docs | ✅ Completa | - |
| Tests | 🟡 Manual | Automatizar |
| Producción | ⏳ Pendiente | Ver roadmap |

## 🗺️ Roadmap

### v1.1.0 (2 semanas)
- [ ] Base de datos PostgreSQL
- [ ] Variables de entorno
- [ ] Traducciones (ES/CA/EN)
- [ ] Validación de email

### v1.2.0 (1 mes)
- [ ] Recuperación de contraseña
- [ ] Verificación de email
- [ ] Rate limiting
- [ ] HTTPS

### v2.0.0 (2 meses)
- [ ] Refresh tokens
- [ ] Sign in with Apple
- [ ] Tests automatizados
- [ ] Deploy a producción

👉 Ver [ROADMAP.md](ROADMAP.md) completo.

## 🤝 Contribuir

Este es un proyecto interno. Si encuentras bugs o tienes sugerencias:

1. Revisar [FAQ.md](FAQ.md)
2. Revisar [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md)
3. Abrir un issue con:
   - Descripción del problema
   - Pasos para reproducir
   - Logs relevantes

## 📝 Notas Importantes

### ⚠️ Desarrollo Local
- Base de datos en memoria (se pierde al reiniciar)
- JWT_SECRET por defecto (cambiar en producción)
- HTTP sin cifrar (usar HTTPS en producción)

### ✅ Listo para...
- ✅ Desarrollo local
- ✅ Demos
- ✅ Testing
- ⏳ Staging (requiere BD real)
- ❌ Producción (ver roadmap)

## 📞 Soporte

- **Inicio rápido:** [QUICK_START.md](QUICK_START.md)
- **Problemas comunes:** [FAQ.md](FAQ.md)
- **Guía completa:** [AUTH_USAGE_GUIDE.md](AUTH_USAGE_GUIDE.md)
- **Tests:** `./backend/auth-service/test.sh`

## 📜 Licencia

Proyecto interno - Todos los derechos reservados

---

## 🎉 ¡Comienza Ahora!

```bash
# 1. Clonar repo (si aplica)
git clone <repo-url>

# 2. Instalar backend
cd backend/auth-service
npm install

# 3. Iniciar servidor
npm run dev

# 4. Abrir Xcode y ejecutar (Cmd + R)
```

**¿Primera vez?** 👉 Lee [QUICK_START.md](QUICK_START.md)

**¿Tienes preguntas?** 👉 Lee [FAQ.md](FAQ.md)

**¿Quieres profundizar?** 👉 Lee [ARCHITECTURE.md](ARCHITECTURE.md)

---

**Versión:** 1.0.0  
**Última actualización:** Julio 2026  
**Estado:** ✅ Funcional y documentado
