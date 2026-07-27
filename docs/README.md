# 📚 Documentación de Asocia

Bienvenido a la documentación completa del proyecto Asocia.

---

## 🗂️ Índice por Categorías

### [01 - Getting Started](./01-getting-started/)
Guías de inicio rápido y preguntas frecuentes
- **[FAQ](./01-getting-started/FAQ.md)** - Preguntas frecuentes sobre autenticación y el sistema

### [02 - Arquitectura](./02-architecture/)
Documentación de arquitectura del proyecto
- **[ARCHITECTURE (EN)](./02-architecture/ARCHITECTURE.md)** - Architecture overview (English)
- **[ARQUITECTURA (ES)](./02-architecture/ARQUITECTURA.md)** - Visión general de arquitectura (Español)

### [03 - Autenticación](./03-authentication/)
Sistema de login, registro y gestión de tokens
- **[Auth Usage Guide](./03-authentication/AUTH_USAGE_GUIDE.md)** - Guía de uso del sistema de autenticación

### [04 - Backend](./04-backend/)
Documentación de endpoints y servicios backend
- **[Backend Endpoint Implementation](./04-backend/BACKEND_ENDPOINT_IMPLEMENTATION.md)** - Implementación de endpoints
- **[Backend Pagination Guide](./04-backend/BACKEND_PAGINATION_GUIDE.md)** - Sistema de paginación

### [05 - Chat](./05-chat/)
Sistema de mensajería y conversaciones
- **[Chat Users Guide](./05-chat/CHAT_USERS_GUIDE.md)** - Gestión de usuarios en el chat
- **[Infinite Scroll Guide](./05-chat/INFINITE_SCROLL_GUIDE.md)** - Scroll infinito en listas

### [06 - Localización](./06-localization/)
Sistema multiidioma (5 idiomas)
- **[Localization Guide](./06-localization/LOCALIZATION_GUIDE.md)** - Guía completa unificada ✨

### [07 - Desarrollo](./07-development/)
Herramientas y utilidades para desarrollo
- **[Sample Data Guide](./07-development/SAMPLE_DATA_GUIDE.md)** - Datos de prueba
- **[Clean Reset Guide](./07-development/CLEAN_RESET_GUIDE.md)** - Limpiar y resetear el proyecto
- **[Service Logging Guide](./07-development/SERVICE_LOGGING_GUIDE.md)** - Sistema de logging
- **[Logging Summary](./07-development/LOGGING_ADDED_SUMMARY.md)** - Resumen de logging agregado

### [08 - Scripts](./08-scripts/)
Scripts útiles para el desarrollo
- **[start-auth-service.sh](./08-scripts/start-auth-service.sh)** - Iniciar microservicio de autenticación

---

## 🚀 Inicio Rápido

### 1. Instalación

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/asocia.git
cd asocia

# Instalar dependencias del backend
cd backend/auth-service
npm install
```

### 2. Ejecutar el Backend

```bash
# Desde la raíz del proyecto
./docs/08-scripts/start-auth-service.sh
```

### 3. Ejecutar la App iOS

1. Abrir `Asocia.xcodeproj` en Xcode
2. Seleccionar el simulador
3. Presionar `⌘ + R`

---

## 📖 Guías Recomendadas por Flujo

### Para Nuevos Desarrolladores
1. Leer [FAQ](./01-getting-started/FAQ.md)
2. Revisar [ARQUITECTURA](./02-architecture/ARQUITECTURA.md)
3. Configurar [Autenticación](./03-authentication/AUTH_USAGE_GUIDE.md)
4. Cargar [Datos de Prueba](./07-development/SAMPLE_DATA_GUIDE.md)

### Para Implementar Características
1. **Chat**: Ver [Chat Users Guide](./05-chat/CHAT_USERS_GUIDE.md)
2. **Localización**: Ver [Localization Guide](./06-localization/LOCALIZATION_GUIDE.md)
3. **Backend**: Ver [Backend Guides](./04-backend/)

### Para Debugging
1. Activar [Logging](./07-development/SERVICE_LOGGING_GUIDE.md)
2. Si hay problemas: [Clean Reset](./07-development/CLEAN_RESET_GUIDE.md)
3. Revisar [FAQ](./01-getting-started/FAQ.md)

---

## 🏗️ Arquitectura del Proyecto

```
Asocia/
├── App/                    # Punto de entrada
├── Views/                  # Vistas SwiftUI
├── Services/               # Servicios (API, Chat, Auth)
├── Models/                 # Modelos de datos
├── Resources/              # JSON de traducciones
├── Tests/                  # Pruebas unitarias
├── UITests/                # Pruebas de UI
├── backend/                # Microservicios Node.js
│   └── auth-service/       # Servicio de autenticación
└── docs/                   # Documentación (estás aquí)
```

---

## 🌍 Idiomas Soportados

- 🇪🇸 Español (por defecto)
- 🇨🇦 Catalán
- 🇪🇸 Gallego
- 🇪🇸 Euskera
- 🇬🇧 Inglés

Ver [Localization Guide](./06-localization/LOCALIZATION_GUIDE.md) para más detalles.

---

## 🧪 Testing

### Pruebas Unitarias
```bash
xcodebuild test -scheme Asocia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Pruebas de UI
```bash
xcodebuild test -scheme Asocia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:AsociaUITests
```

Ver más en cada guía específica.

---

## 🆘 Obtener Ayuda

1. **Revisa el [FAQ](./01-getting-started/FAQ.md)**
2. **Busca en la documentación** - Usa el índice arriba
3. **Revisa los logs** - Ver [Logging Guide](./07-development/SERVICE_LOGGING_GUIDE.md)
4. **Limpia el proyecto** - Ver [Clean Reset Guide](./07-development/CLEAN_RESET_GUIDE.md)

---

## 🤝 Contribuir

Para contribuir a la documentación:

1. Sigue la estructura de carpetas existente
2. Usa formato Markdown con emojis para claridad
3. Incluye ejemplos de código cuando sea posible
4. Actualiza este índice si agregas nuevas guías

---

## 📝 Notas de Versión

- **v2.0** (27 jul 2026) - Reorganización completa de docs en subcarpetas
- **v1.0** (26 jul 2026) - Documentación inicial

---

**Última actualización:** 27 de julio de 2026  
**Mantenido por:** Equipo de Desarrollo de Asocia

✨ **¡Feliz coding!**
