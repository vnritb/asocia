# 🔧 Guía: Ejecutar Asocia en Modo Local

Esta guía te ayudará a ejecutar la app conectándose al **backend real** corriendo en tu Mac con Docker.

---

## 📋 Requisitos Previos

- ✅ **Docker Desktop** instalado y corriendo
- ✅ **Node.js** 18+ instalado
- ✅ **Xcode** con el proyecto abierto
- ✅ **XcodeGen** para generar el proyecto (si no lo tienes: `brew install xcodegen`)

---

## 🚀 Paso 1: Verificar el Backend

### 1.1 Navegar a la carpeta backend

```bash
cd backend
```

### 1.2 Verificar que existe `docker-compose.yml`

```bash
ls -la docker-compose.yml
```

Si no existe, necesitas crearlo o el backend no está configurado aún.

### 1.3 Verificar las variables de entorno

```bash
# Copiar archivos de ejemplo (si no lo has hecho antes)
cp services/api-gateway/.env.example services/api-gateway/.env
cp services/membership-service/.env.example services/membership-service/.env
cp services/chat-service/.env.example services/chat-service/.env
cp services/translation-service/.env.example services/translation-service/.env

# O todo de una vez:
for service in services/*/; do
    if [ -f "${service}.env.example" ]; then
        cp "${service}.env.example" "${service}.env"
        echo "✅ Copiado .env en ${service}"
    fi
done
```

### 1.4 Editar variables de entorno (IMPORTANTE)

Edita cada archivo `.env` y configura:

```bash
# En services/api-gateway/.env
PORT=4000
NODE_ENV=development
MEMBERSHIP_SERVICE_URL=http://membership-service:3001
CHAT_SERVICE_URL=http://chat-service:3002
TRANSLATION_SERVICE_URL=http://translation-service:3003

# En services/membership-service/.env
PORT=3001
NODE_ENV=development
DATABASE_URL=postgresql://postgres:password@postgres:5432/asocia_membership
JWT_SECRET=your-super-secret-key-change-in-production

# En services/chat-service/.env
PORT=3002
NODE_ENV=development
DATABASE_URL=postgresql://postgres:password@postgres:5432/asocia_chat

# En services/translation-service/.env
PORT=3003
NODE_ENV=development
ANTHROPIC_API_KEY=tu-api-key-aqui  # Opcional, solo si quieres traducción real
```

---

## 🐳 Paso 2: Levantar el Backend con Docker

### 2.1 Limpiar contenedores anteriores (si los hay)

```bash
cd backend
docker compose down -v
```

### 2.2 Construir y levantar los servicios

```bash
docker compose up --build
```

**Deberías ver algo como:**

```
✅ postgres         Started
✅ api-gateway      Started (Puerto 4000)
✅ membership-service  Started (Puerto 3001)
✅ chat-service     Started (Puerto 3002)
✅ translation-service Started (Puerto 3003)
```

### 2.3 Verificar que funciona

En **otra terminal**, ejecuta:

```bash
# Verificar que el API Gateway responde
curl http://localhost:4000/health

# Deberías ver:
# {"status":"ok","timestamp":"..."}
```

Si ves un error como "Connection refused", el backend no está levantado correctamente.

---

## 📱 Paso 3: Configurar Xcode para Modo Local

### 3.1 Verificar que existe el scheme "Asocia (Local)"

1. En Xcode, ve a **Product → Scheme → Manage Schemes**
2. Verifica que existe **"Asocia (Local)"**
3. Si **NO existe**, necesitas regenerar el proyecto:

```bash
cd Asocia
xcodegen generate
open Asocia.xcodeproj
```

### 3.2 Seleccionar el scheme correcto

1. En Xcode, en la barra superior, haz clic en el scheme actual
2. Selecciona **"Asocia (Local)"**

### 3.3 Verificar la configuración del scheme (IMPORTANTE)

1. Ve a **Product → Scheme → Edit Scheme...**
2. En la sección **Run**, pestaña **Arguments**
3. En **Environment Variables**, verifica que existe:
   - **Name:** `ASOCIA_ENVIRONMENT`
   - **Value:** `local`
   - ✅ **Checkmark activado**

Si no está, agrégala:
- Haz clic en el **+**
- Name: `ASOCIA_ENVIRONMENT`
- Value: `local`
- ✅ Activa el checkmark

4. Haz clic en **Close**

---

## ▶️ Paso 4: Ejecutar la App

### 4.1 Seleccionar el simulador

En Xcode, selecciona **iPhone 15 Pro** (o cualquier simulador iOS 17+)

### 4.2 Ejecutar

```bash
⌘ + R
```

### 4.3 Verificar la consola de Xcode

Deberías ver:

```
🌍 Asocia arrancada en entorno: Local (Docker) (local)
🌐 API Base URL: http://localhost:4000
⚠️  Usando servicios REALES - El backend debe estar corriendo
🚀 AsociaApp.task iniciado
📊 No hay miembros en la BD. Cargando datos de prueba...
✅ Usuario de prueba agregado: Ana García López
💾 Datos de prueba guardados en SwiftData
   SyncEngine inicializado
```

**Si ves errores:**

```
❌ Error del servidor - Status: 404
📄 Respuesta del servidor: {"error":"Not Found"}
```

Significa que el backend **no está respondiendo** o las rutas no existen.

---

## 🔍 Paso 5: Probar el Registro

### 5.1 En la app, resetear el estado

Para probar el registro desde cero:

```bash
# Detener la app (⌘ + .)
# En el simulador:
# 1. Mantén presionado el ícono de Asocia
# 2. Remove App
# 3. Ejecuta de nuevo en Xcode (⌘ + R)
```

### 5.2 Completar el formulario de registro

1. Toca **"Asocia"** (botón de registro)
2. Completa:
   - **Nombre:** Juan
   - **Primer apellido:** Pérez
   - **Email:** juan@example.com
   - **Contraseña:** 123456
   - **Confirmar:** 123456
3. Toca **"Enviar Solicitud"**

### 5.3 Verificar en la consola de Xcode

```
📡 [API] submitMembershipApplication - Juan Pérez
   🌐 [POST] http://localhost:4000/v1/members/apply
   ✅ Response: 201 (234ms)
   ✅ Application submitted - Token saved
💾 Member guardado localmente en SwiftData
```

### 5.4 Verificar en la consola del backend

En la terminal donde está corriendo `docker compose up`, deberías ver:

```
api-gateway       | POST /v1/members/apply 201 234ms
membership-service| [INFO] New member created: Juan Pérez (juan@example.com)
```

---

## ✅ Verificación Final

Si todo funciona correctamente, deberías poder:

1. ✅ **Registrar usuarios** - La app envía a `http://localhost:4000/v1/members/apply`
2. ✅ **Ver el perfil** - Los datos se guardan localmente y se sincronizan
3. ✅ **Editar datos** - Los cambios se envían al backend
4. ✅ **Ver logs detallados** - Tanto en Xcode como en Docker

---

## 🐛 Solución de Problemas

### Problema 1: "Error del servidor (404)"

**Causa:** El endpoint no existe en el backend

**Solución:**

1. Verifica que el backend tenga el endpoint `/v1/members/apply`
2. Revisa los logs de Docker:
   ```bash
   docker compose logs api-gateway
   docker compose logs membership-service
   ```

3. Verifica que el `api-gateway` está redirigiendo correctamente:
   ```bash
   # En el código del backend, busca:
   # services/api-gateway/src/routes.ts
   # Debería tener algo como:
   # app.post('/v1/members/apply', ...)
   ```

### Problema 2: "No hay conexión con el servidor"

**Causa:** El backend no está corriendo o localhost no resuelve

**Solución:**

```bash
# Verificar que Docker está corriendo
docker ps

# Deberías ver:
# CONTAINER ID   IMAGE                    STATUS
# abc123         asocia-api-gateway       Up 2 minutes
# def456         asocia-membership        Up 2 minutes
# ...

# Si no hay contenedores, levántalos:
cd backend
docker compose up --build
```

### Problema 3: "La app sigue en modo Mock"

**Causa:** El scheme no está configurado correctamente

**Solución:**

1. **Verifica el scheme actual:**
   - Product → Scheme → Debe decir "Asocia (Local)"

2. **Verifica la variable de entorno:**
   - Product → Scheme → Edit Scheme
   - Run → Arguments → Environment Variables
   - Debe tener: `ASOCIA_ENVIRONMENT = local`

3. **Limpia y vuelve a compilar:**
   ```bash
   ⌘ + Shift + K  # Clean
   ⌘ + B          # Build
   ⌘ + R          # Run
   ```

### Problema 4: "El simulador no puede conectarse a localhost"

**Causa:** Estás usando un **dispositivo físico** (iPhone real)

**Solución:**

En un dispositivo físico, `localhost` no resuelve al Mac. Necesitas:

1. **Obtener la IP de tu Mac:**
   ```bash
   ipconfig getifaddr en0  # WiFi
   # O:
   ipconfig getifaddr en1  # Ethernet
   
   # Ejemplo: 192.168.1.100
   ```

2. **Actualizar `AppEnvironment.swift`:**
   ```swift
   case .local:
       // En lugar de localhost:
       return URL(string: "http://192.168.1.100:4000")!
   ```

3. **Recompilar y ejecutar**

### Problema 5: "Error de compilación al usar MockMembershipAPIClient"

**Causa:** El archivo `MockMembershipAPIClientApp.swift` no está en el target correcto

**Solución:**

1. En Xcode, selecciona el archivo `MockMembershipAPIClientApp.swift`
2. En el **File Inspector** (panel derecho), verifica **Target Membership**
3. Asegúrate que **"Asocia"** está ✅ marcado
4. Si no está, márcalo y recompila

---

## 🎯 Checklist Rápido

Antes de ejecutar en modo local, verifica:

- [ ] Docker Desktop está corriendo
- [ ] Backend levantado con `docker compose up --build`
- [ ] API Gateway responde en `http://localhost:4000/health`
- [ ] Scheme "Asocia (Local)" seleccionado en Xcode
- [ ] Variable de entorno `ASOCIA_ENVIRONMENT=local` configurada
- [ ] Simulador seleccionado (no dispositivo físico)
- [ ] La consola muestra: `⚠️ Usando servicios REALES - El backend debe estar corriendo`

---

## 📚 Próximos Pasos

Una vez que el modo local funcione:

1. **Probar sincronización** - Edita datos y verifica que se guardan en el backend
2. **Probar con múltiples usuarios** - Registra varios y verifica la base de datos
3. **Revisar logs** - Familiarízate con los logs de ambos lados (app y backend)
4. **Implementar endpoints faltantes** - Si algún endpoint da 404, impleméntalo en el backend

---

## 🔗 Referencias

- **Arquitectura:** Ver `docs/ARQUITECTURA.md`
- **Backend:** Ver `backend/README.md`
- **App Environment:** Ver `Asocia/App/AppEnvironment.swift`
- **API Client:** Ver `Asocia/Services/APIClient.swift`

---

**Fecha:** 27 de julio de 2026  
**Última actualización:** Hoy  
**Estado:** ✅ Funcional

¡Disfruta desarrollando en modo local! 🚀
