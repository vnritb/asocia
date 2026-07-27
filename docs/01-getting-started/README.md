# 🚀 Getting Started - Asocia

Esta sección contiene guías de inicio rápido y recursos para comenzar con el proyecto.

---

## 📄 Documentos en esta Sección

### [FAQ.md](./FAQ.md)
**Preguntas Frecuentes sobre Autenticación y Sistema**

Contiene respuestas a las preguntas más comunes sobre:
- ✅ Sistema de autenticación (login/registro)
- ✅ Instalación y configuración
- ✅ Uso del sistema
- ✅ Errores comunes y soluciones
- ✅ Base de datos y seguridad
- ✅ Despliegue a producción

**Cuándo leer este documento:**
- Eres nuevo en el proyecto
- Tienes problemas con autenticación
- El backend no funciona
- Necesitas entender cómo funciona el sistema

---

## 🎯 Flujo de Inicio Rápido

### 1. Instalación del Backend

```bash
# Ir a la carpeta del servicio de autenticación
cd backend/auth-service

# Instalar dependencias
npm install

# Iniciar el servicio
npm run dev
```

**Resultado esperado:**
```
🚀 Auth service running on http://localhost:4001
```

### 2. Configurar la App iOS

1. Abrir `Asocia.xcodeproj` en Xcode
2. Verificar que el scheme esté en **"Asocia (Local)"**
3. Verificar en `AppEnvironment.swift` que la URL sea `http://localhost:4001`

### 3. Ejecutar la App

```bash
# Desde Xcode
⌘ + R

# O desde terminal
xcodebuild -scheme Asocia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

---

## ❓ Preguntas Frecuentes Rápidas

### ¿Cómo hago login?
1. Ejecutar el backend
2. Ejecutar la app
3. En LoginView, introducir email y password
4. Pulsar "Iniciar Sesión"

### ¿Cómo me registro?
1. En LoginView, pulsar "Crear Cuenta"
2. Completar formulario (mínimo: nombre, apellido, email, contraseña)
3. Pulsar "Enviar"

### Error: "No hay conexión con el servidor"
- Verifica que el backend esté corriendo: `curl http://localhost:4001/health`
- Si no responde, inícialo: `npm run dev` en `backend/auth-service`

### Error: "Este email ya está registrado"
- El email ya existe en la base de datos
- Usa otro email O haz login con ese email
- O reinicia el backend (datos en memoria se pierden)

---

## 📚 Recursos Adicionales

- **Arquitectura**: Ver [docs/02-architecture/](../02-architecture/)
- **Autenticación**: Ver [docs/03-authentication/](../03-authentication/)
- **Backend**: Ver [docs/04-backend/](../04-backend/)
- **Datos de Prueba**: Ver [docs/07-development/SAMPLE_DATA_GUIDE.md](../07-development/SAMPLE_DATA_GUIDE.md)

---

## 🆘 ¿Necesitas más ayuda?

Lee el [FAQ completo](./FAQ.md) que cubre:
- Instalación detallada
- Todos los errores comunes
- Configuración avanzada
- Testing
- Despliegue a producción

---

**Última actualización:** 27 de julio de 2026
