# 🏗️ Arquitectura - Asocia

Documentación de la arquitectura general del proyecto.

---

## 📄 Documentos en esta Sección

### [ARCHITECTURE.md](./ARCHITECTURE.md) 🇬🇧
**Architecture Overview (English)**

Comprehensive architecture documentation covering:
- System architecture
- Data flow
- Service structure
- Design patterns
- Technical decisions

### [ARQUITECTURA.md](./ARQUITECTURA.md) 🇪🇸
**Visión General de Arquitectura (Español)**

Documentación completa de arquitectura que cubre:
- Arquitectura del sistema
- Flujo de datos
- Estructura de servicios
- Patrones de diseño
- Decisiones técnicas

---

## 🎯 Conceptos Clave

### Arquitectura Offline-First
```
Usuario → SwiftUI → SwiftData (Local) ⟷ SyncEngine ⟷ Backend
                         ↓
                   Persistencia Local
```

- **UI siempre lee de SwiftData** (instantáneo)
- **SyncEngine sincroniza en segundo plano** (cuando hay red)
- **Backend es la fuente de verdad** (autoridad)

### Microservicios

1. **auth-service** (Puerto 4001)
   - Login / Registro
   - Gestión de tokens JWT
   - Verificación de sesión

2. **membership-service** (Puerto 3000)
   - Gestión de socios
   - Perfiles
   - Estados de membresía

3. **chat-service** (Futuro)
   - Mensajería
   - Conversaciones
   - Notificaciones

### Patrones de Diseño

- **MVVM** - Model-View-ViewModel (SwiftUI)
- **Repository Pattern** - Abstracción de datos
- **Dependency Injection** - Environment values
- **Observable Pattern** - @Observable para reactividad
- **Actor Pattern** - Para servicios concurrentes

---

## 📊 Diagramas

### Flujo de Autenticación
```
LoginView → AuthService → Backend (auth-service)
                ↓
           KeychainStore (guardar token)
                ↓
           SwiftData (guardar Member)
                ↓
           RootView (navegar)
```

### Flujo de Sincronización
```
App Start → SyncEngine.start()
               ↓
         Monitor de Red
               ↓
    ¿Hay conexión? → Sí → pushPendingChanges()
                            pullLatestFromServer()
               ↓
         SwiftData actualizado
               ↓
         UI se actualiza automáticamente
```

---

## 🔗 Enlaces Relacionados

- **Autenticación**: [docs/03-authentication/](../03-authentication/)
- **Backend**: [docs/04-backend/](../04-backend/)
- **Desarrollo**: [docs/07-development/](../07-development/)

---

**Última actualización:** 27 de julio de 2026
