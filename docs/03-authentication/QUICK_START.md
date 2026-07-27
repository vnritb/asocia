# 🚀 Quick Start - Sistema de Autenticación

## TL;DR - Inicio Rápido

```bash
# 1. Instalar dependencias del microservicio
cd backend/auth-service
npm install

# 2. Iniciar el microservicio
npm run dev

# 3. En otra terminal - Probar que funciona
chmod +x test.sh
./test.sh

# 4. Abrir proyecto iOS en Xcode y ejecutar
```

## ✅ Checklist de Verificación

Antes de ejecutar la app, verifica:

- [ ] Node.js instalado (v14 o superior)
- [ ] Microservicio corriendo en puerto 4001
- [ ] `AppEnvironment.swift` configurado para `.local`
- [ ] URL apuntando a `http://localhost:4001` (o IP de tu Mac si usas dispositivo físico)

## 📝 Pasos Detallados

### 1. Configurar el Microservicio

```bash
cd backend/auth-service
npm install
```

### 2. Iniciar el Servicio

```bash
npm run dev
```

Deberías ver:
```
🔐 Auth Service escuchando en puerto 4001
📝 Endpoints disponibles:
   POST http://localhost:4001/v1/auth/register
   POST http://localhost:4001/v1/auth/login
   ...
```

### 3. Verificar que Funciona

```bash
curl http://localhost:4001/health
```

Respuesta esperada:
```json
{
  "status": "ok",
  "service": "auth-service",
  "users": 0,
  "timestamp": "2026-07-26T..."
}
```

### 4. Ejecutar la App iOS

1. Abrir proyecto en Xcode
2. Seleccionar scheme "Asocia (Local)"
3. Seleccionar simulador o dispositivo
4. Cmd + R

### 5. Probar el Flujo

1. **Primera vez - Registro:**
   - App muestra LoginView
   - Pulsar "Crear Cuenta"
   - Completar formulario:
     - Nombre: Test
     - Apellido: User
     - Email: test@test.com
     - Password: test123
     - Confirmar: test123
   - Pulsar "Enviar"
   - Ver perfil (estado: pendingApproval)

2. **Cerrar y reabrir - Persistencia:**
   - Cerrar app (Cmd + Shift + H, swipe up)
   - Volver a ejecutar (Cmd + R)
   - Acceso automático sin login

3. **Login existente:**
   - Eliminar app
   - Reinstalar
   - En LoginView: test@test.com / test123
   - Acceso directo

## 🔧 Troubleshooting Rápido

### ❌ App no conecta con el servidor

**Síntoma:** Error "No hay conexión con el servidor"

**Solución:**
```bash
# 1. Verificar que el servicio esté corriendo
curl http://localhost:4001/health

# 2. Si no responde, iniciarlo
cd backend/auth-service
npm run dev

# 3. Verificar URL en AppEnvironment.swift
# Debe ser: http://localhost:4001
```

### ❌ Email ya registrado

**Síntoma:** Error "Este email ya está registrado"

**Solución:**
- Usar otro email, O
- Hacer login con ese email, O
- Reiniciar el microservicio (los datos están en memoria)

### ❌ Token inválido

**Síntoma:** Error "Token inválido o expirado"

**Solución:**
- Limpiar Keychain y volver a hacer login
- Tokens expiran a los 30 días

### ❌ Simulador no conecta pero funciona en el navegador

**Síntoma:** curl funciona, pero app da error

**Solución:**
- El simulador de iOS bloquea HTTP (no seguro)
- Añadir excepción en Info.plist:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### ❌ Dispositivo físico no conecta

**Síntoma:** Funciona en simulador, no en dispositivo

**Solución:**
- Cambiar `localhost` por IP de tu Mac
- En AppEnvironment.swift:
```swift
case .local:
    return URL(string: "http://192.168.1.XXX:4001")!
```
- Encontrar IP: Preferencias → Red → WiFi → IP

## 📚 Documentación Completa

- `AUTH_IMPLEMENTATION_SUMMARY.md` - Resumen técnico completo
- `AUTH_USAGE_GUIDE.md` - Guía de uso con ejemplos
- `SETUP_AUTH_SERVICE.md` - Configuración detallada del servicio
- `backend/auth-service/README.md` - Documentación del microservicio
- `LOCALIZATION_KEYS_AUTH.md` - Claves de traducción

## 🎯 Próximos Pasos

Una vez que todo funcione:

1. [ ] Añadir claves de traducción (ver `LOCALIZATION_KEYS_AUTH.md`)
2. [ ] Cambiar JWT_SECRET en el servidor
3. [ ] Configurar base de datos real (PostgreSQL/MongoDB)
4. [ ] Implementar recuperación de contraseña
5. [ ] Añadir validación de formato de email
6. [ ] Configurar HTTPS para producción
7. [ ] Implementar refresh tokens

## 💬 Preguntas Frecuentes

**P: ¿Los datos se pierden al reiniciar el servidor?**
R: Sí, actualmente usa almacenamiento en memoria. Para producción, usar base de datos real.

**P: ¿Puedo usar otro puerto?**
R: Sí, cambia `PORT` en el servidor y la URL en `AppEnvironment.swift`

**P: ¿Funciona sin internet?**
R: No para login/registro (necesita servidor). Sí para navegar una vez autenticado (datos en SwiftData).

**P: ¿Es seguro?**
R: Para desarrollo local sí. Para producción necesita HTTPS, base de datos real y JWT_SECRET seguro.

**P: ¿Puedo tener múltiples usuarios?**
R: La app actual solo guarda un Member en SwiftData. Para múltiples cuentas en un dispositivo necesitaría cambios.

## 🎉 ¡Listo!

Si llegaste hasta aquí y todo funciona, ya tienes:

✅ Sistema de autenticación funcional  
✅ Login con email y password  
✅ Registro de nuevos usuarios  
✅ Tokens JWT seguros  
✅ Persistencia de sesión  
✅ Microservicio local  

**¡Buen trabajo!** 🚀
