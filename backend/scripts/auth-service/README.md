# 🚀 Scripts - Asocia

Scripts útiles para desarrollo.

---

## 📄 Scripts en esta Sección

### [start-auth-service.sh](./start-auth-service.sh)
**Iniciar Microservicio de Autenticación**

Script para iniciar rápidamente el backend de autenticación:
- ✅ Verifica Node.js y npm
- ✅ Instala dependencias si faltan
- ✅ Mata procesos en puerto 4001 si están ocupados
- ✅ Inicia el servicio en modo desarrollo
- 📡 Muestra endpoints disponibles

---

## 🚀 Uso

### 1. Desde la Raíz del Proyecto

```bash
# Dar permisos de ejecución (solo la primera vez)
chmod +x docs/08-scripts/start-auth-service.sh

# Ejecutar
./docs/08-scripts/start-auth-service.sh
```

### 2. Desde backend/auth-service

```bash
cd backend/auth-service

# Copiar script
cp ../../docs/08-scripts/start-auth-service.sh .

# Ejecutar
./start-auth-service.sh
```

---

## 📋 Lo que Hace el Script

```
1. 🔍 Verificar ubicación correcta (backend/auth-service)
2. 📦 Verificar Node.js y npm instalados
3. 📥 Instalar dependencias si faltan (npm install)
4. 🔌 Verificar puerto 4001
5. 🛑 Matar proceso anterior si existe
6. ✅ Mostrar información del servicio
7. 🚀 Iniciar npm run dev
```

---

## 🖥️ Salida Esperada

```bash
🔐 Iniciando servicio de autenticación...

📦 Node version: v20.10.0
📦 npm version: 10.2.3

✅ Todo listo!

🚀 Iniciando servicio en http://localhost:4001
   Presiona Ctrl+C para detener el servicio

📡 Endpoints disponibles:
   POST http://localhost:4001/v1/auth/register
   POST http://localhost:4001/v1/auth/login
   GET  http://localhost:4001/v1/auth/verify
   GET  http://localhost:4001/health

> auth-service@1.0.0 dev
> nodemon index.js

[nodemon] 3.0.2
[nodemon] watching: *.*
[nodemon] starting `node index.js`
🚀 Auth service running on http://localhost:4001
```

---

## 🔧 Solución de Problemas

### Error: "Node.js no está instalado"

```bash
# macOS (con Homebrew)
brew install node

# O descarga desde: https://nodejs.org/
```

### Error: "El puerto 4001 está ocupado"

El script automáticamente mata el proceso anterior.

Si persiste:
```bash
# Buscar proceso
lsof -i :4001

# Matar manualmente
kill -9 <PID>
```

### Error: "Debes ejecutar desde backend/auth-service"

```bash
# Ir a la carpeta correcta
cd backend/auth-service

# Ejecutar de nuevo
./start-auth-service.sh
```

---

## 📝 Otros Scripts Útiles

### Crear Script de Test

```bash
#!/bin/bash
# test-auth.sh

echo "🧪 Testing auth service..."

# Register
echo "1️⃣ Registrando usuario..."
curl -X POST http://localhost:4001/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "test@test.com",
    "password": "test123",
    "firstName": "Test",
    "firstSurname": "User"
  }'

echo ""
echo ""

# Login
echo "2️⃣ Haciendo login..."
curl -X POST http://localhost:4001/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@test.com",
    "password": "test123"
  }'

echo ""
echo ""
echo "✅ Tests completados"
```

### Crear Script de Reset

```bash
#!/bin/bash
# reset-all.sh

echo "🗑️ Limpiando proyecto completo..."

# Limpiar build
echo "1️⃣ Limpiando build..."
xcodebuild clean -scheme Asocia

# Limpiar derived data
echo "2️⃣ Limpiando derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Asocia-*

# Resetear simuladores
echo "3️⃣ Reseteando simuladores..."
xcrun simctl shutdown all
xcrun simctl erase all

echo "✅ Limpieza completada"
```

---

## 🔗 Enlaces Relacionados

- **Autenticación**: [docs/03-authentication/](../03-authentication/)
- **Backend**: [docs/04-backend/](../04-backend/)
- **FAQ**: [docs/01-getting-started/FAQ.md](../01-getting-started/FAQ.md)

---

## 💡 Crear tus Propios Scripts

### Template Básico

```bash
#!/bin/bash

# Nombre del script
# Descripción
# Autor y fecha

echo "🚀 Iniciando script..."

# Verificar condiciones previas
if [ ! -f "archivo.txt" ]; then
    echo "❌ Error: archivo.txt no encontrado"
    exit 1
fi

# Hacer algo
echo "✅ Procesando..."

# Resultado
echo "✨ Script completado exitosamente"
```

### Dar Permisos

```bash
chmod +x mi-script.sh
```

### Ejecutar

```bash
./mi-script.sh
```

---

**Última actualización:** 27 de julio de 2026
