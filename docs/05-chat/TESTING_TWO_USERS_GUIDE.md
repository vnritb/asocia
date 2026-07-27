# 📱📱 Guía para Probar el Chat con Dos Usuarios

## 🎯 Objetivo

Probar el sistema de chat con dos usuarios diferentes para verificar que los mensajes se envían y reciben correctamente.

## 🛠️ Opciones de Testing

### Opción 1: Simulador + Dispositivo Físico (RECOMENDADO)

**Ventajas:**
- ✅ Fácil de configurar
- ✅ Dos usuarios reales separados
- ✅ Fácil de debuggear

**Requisitos:**
- 1 Mac con Xcode
- 1 iPhone/iPad físico
- Ambos en la misma red WiFi

**Configuración:**

#### Paso 1: Configurar el Backend
```bash
# Terminal 1 - Iniciar backend
cd backend/auth-service
npm run dev
# Debería mostrar: "Auth Service escuchando en puerto 4001"
```

#### Paso 2: Encontrar la IP de tu Mac
```bash
# En Terminal
ipconfig getifaddr en0
# Ejemplo de salida: 192.168.1.100
```

O visualmente: **Preferencias del Sistema → Red → WiFi → Detalles → IP**

#### Paso 3: Configurar AppEnvironment para dispositivo físico

Crear un nuevo caso en `AppEnvironment.swift`:

```swift
enum AppEnvironment: String, CaseIterable {
    case mock
    case local
    case localPhysical  // 👈 NUEVO
    case staging
    case production
    
    static var current: AppEnvironment {
        if let raw = ProcessInfo.processInfo.environment["ASOCIA_ENVIRONMENT"],
           let value = AppEnvironment(rawValue: raw) {
            return value
        }
        #if DEBUG
        return .mock
        #else
        return .production
        #endif
    }
    
    var apiBaseURL: URL {
        switch self {
        case .mock:
            return URL(string: "http://localhost:0")!
        case .local:
            return URL(string: "http://localhost:4001")!
        case .localPhysical:  // 👈 NUEVO
            return URL(string: "http://192.168.1.100:4001")!  // 👈 Pon tu IP aquí
        case .staging:
            return URL(string: "https://asocia-api-staging.onrender.com")!
        case .production:
            return URL(string: "https://asocia-api.onrender.com")!
        }
    }
    
    // ... resto del código
}
```

#### Paso 4: Crear Schemes en Xcode

**Para Simulador:**
1. Product → Scheme → Edit Scheme
2. Duplicate Scheme actual
3. Nombre: "Asocia (Local - Simulador)"
4. Run → Arguments → Environment Variables:
   - Name: `ASOCIA_ENVIRONMENT`
   - Value: `local`

**Para Dispositivo Físico:**
1. Product → Scheme → Edit Scheme
2. Duplicate Scheme
3. Nombre: "Asocia (Local - Dispositivo)"
4. Run → Arguments → Environment Variables:
   - Name: `ASOCIA_ENVIRONMENT`
   - Value: `localPhysical`

#### Paso 5: Registrar Usuario 1 (Simulador)

1. Xcode → Seleccionar scheme "Asocia (Local - Simulador)"
2. Seleccionar cualquier simulador (ej: iPhone 15 Pro)
3. Cmd + R
4. En LoginView → "Crear Cuenta"
5. Registrar:
   - Nombre: Juan
   - Apellido: Pérez
   - Email: **juan@test.com**
   - Password: test123
   - Confirmar: test123
6. Submit

#### Paso 6: Registrar Usuario 2 (Dispositivo Físico)

1. Conectar iPhone/iPad al Mac
2. Xcode → Seleccionar scheme "Asocia (Local - Dispositivo)"
3. Seleccionar tu dispositivo físico
4. Cmd + R (puede pedir permisos de desarrollador)
5. En LoginView → "Crear Cuenta"
6. Registrar:
   - Nombre: María
   - Apellido: García
   - Email: **maria@test.com**
   - Password: test123
   - Confirmar: test123
7. Submit

#### Paso 7: Probar el Chat

**En Simulador (Juan):**
1. Ir a tab Chat
2. Buscar a María
3. Iniciar conversación
4. Enviar mensaje: "Hola María!"

**En Dispositivo (María):**
1. Debería aparecer notificación o actualización en Chat
2. Abrir conversación con Juan
3. Responder: "Hola Juan, ¿cómo estás?"

**Verificar:**
- ✅ Mensaje de Juan aparece en dispositivo de María
- ✅ Mensaje de María aparece en simulador de Juan
- ✅ Timestamps correctos
- ✅ Estado de lectura (si está implementado)

---

### Opción 2: Dos Simuladores (Más Complejo)

**Ventajas:**
- Todo en el Mac
- No necesita dispositivo físico

**Desventajas:**
- ⚠️ Más lento
- ⚠️ Consume mucha RAM
- ⚠️ Más difícil de debuggear

**Configuración:**

#### Método A: Dos instancias de Xcode (Requiere duplicar el proyecto)

1. Duplicar carpeta del proyecto:
```bash
cp -R Asocia Asocia-User2
```

2. Abrir ambos proyectos en Xcode separadamente

3. Simulador 1:
   - Abrir `Asocia` en Xcode (instancia 1)
   - Seleccionar iPhone 15 Pro
   - Cmd + R
   - Registrar juan@test.com

4. Simulador 2:
   - Abrir `Asocia-User2` en Xcode (instancia 2)
   - Seleccionar iPhone 15 (diferente modelo)
   - Cmd + R
   - Registrar maria@test.com

#### Método B: Ejecutar y cambiar de cuenta (No recomendado para chat)

1. Ejecutar app en Simulador 1
2. Registrar juan@test.com
3. Detener app
4. Cambiar a Simulador 2
5. Ejecutar app
6. Registrar maria@test.com

⚠️ **Problema:** No puedes ver mensajes en tiempo real porque solo una app está activa.

---

### Opción 3: Dos Dispositivos Físicos (Ideal para Testing Real)

**Ventajas:**
- ✅ Testing más realista
- ✅ Cada usuario en su dispositivo
- ✅ Notificaciones push funcionan

**Requisitos:**
- 2 iPhones/iPads
- Ambos en la misma red WiFi
- Ambos con certificados de desarrollo

**Configuración:**

1. Conectar Dispositivo 1 al Mac
2. Xcode → Seleccionar dispositivo 1
3. Cmd + R → Registrar juan@test.com
4. Desconectar dispositivo 1

5. Conectar Dispositivo 2 al Mac
6. Xcode → Seleccionar dispositivo 2
7. Cmd + R → Registrar maria@test.com

8. Ambos dispositivos ya tienen la app instalada
9. Backend sigue corriendo en tu Mac
10. Probar chat entre ambos

---

## 🧪 Script de Pruebas del Chat

### Test 1: Envío Básico de Mensaje

**Usuario 1 (Juan):**
```
1. Abrir tab Chat
2. Buscar "María García"
3. Tap en conversación
4. Escribir: "Hola!"
5. Tap Enviar
```

**Usuario 2 (María):**
```
1. Verificar que aparece notificación
2. Abrir Chat
3. Ver mensaje de Juan: "Hola!"
4. Responder: "Hola Juan!"
```

**Usuario 1 (Juan):**
```
1. Verificar que recibe respuesta: "Hola Juan!"
```

✅ **Éxito:** Mensajes bidireccionales funcionan

---

### Test 2: Múltiples Mensajes

**Usuario 1:**
```
Enviar:
"¿Cómo estás?"
"¿Vienes al evento?"
"Es el sábado"
```

**Usuario 2:**
```
Verificar 3 mensajes recibidos
Responder:
"Bien, gracias"
"Sí, voy"
```

✅ **Éxito:** Múltiples mensajes en orden correcto

---

### Test 3: Estado de Conexión

**Usuario 1:**
```
1. Enviar mensaje
2. Cerrar app (swipe up)
```

**Usuario 2:**
```
1. Enviar mensaje a Usuario 1
2. Verificar estado (¿se muestra como "no entregado"?)
```

**Usuario 1:**
```
1. Reabrir app
2. Verificar que recibe mensaje pendiente
```

✅ **Éxito:** Mensajes se sincronizan al reconectar

---

### Test 4: Búsqueda de Usuarios

**Usuario 1:**
```
1. Tab Chat → Botón "+"
2. Buscar: "María"
3. Verificar que aparece "María García"
4. Buscar: "García"
5. Verificar que aparece
6. Buscar: "XYZ"
7. Verificar que NO aparece
```

✅ **Éxito:** Búsqueda funciona correctamente

---

## 🐛 Troubleshooting

### Error: "Usuario 2 no recibe mensajes"

**Posibles causas:**
1. Backend no está corriendo
2. Dispositivos en diferentes redes
3. Firewall bloqueando puerto
4. WebSocket desconectado

**Solución:**
```bash
# 1. Verificar backend
curl http://192.168.1.100:4001/health

# 2. Verificar que ambos dispositivos están en misma WiFi
# iOS: Ajustes → WiFi → Nombre de red (debe ser igual)

# 3. Verificar logs del servidor
# Deberías ver conexiones WebSocket de ambos usuarios
```

### Error: "Cannot connect to server" en dispositivo físico

**Causa:** IP incorrecta o firewall

**Solución:**
```bash
# 1. Verificar IP del Mac
ipconfig getifaddr en0

# 2. Verificar que AppEnvironment tiene la IP correcta
# En AppEnvironment.swift:
case .localPhysical:
    return URL(string: "http://TU_IP_AQUI:4001")!

# 3. Permitir conexiones entrantes en Firewall
# macOS: Preferencias → Seguridad → Firewall → Opciones
# Permitir "node" o desactivar firewall temporalmente
```

### Error: "Los mensajes aparecen duplicados"

**Causa:** Múltiples conexiones WebSocket

**Solución:**
- Cerrar todas las instancias de la app
- Reiniciar backend
- Volver a abrir apps

### Los mensajes no aparecen en tiempo real

**Solución temporal:**
- Pull to refresh en la lista de chat
- Verificar que WebSocket está conectado
- Revisar logs de conexión

---

## 📋 Checklist de Testing

Antes de considerar el chat funcional, verificar:

- [ ] Dos usuarios pueden registrarse con emails diferentes
- [ ] Usuario 1 puede buscar y encontrar Usuario 2
- [ ] Usuario 1 puede enviar mensaje a Usuario 2
- [ ] Usuario 2 recibe el mensaje en tiempo real
- [ ] Usuario 2 puede responder
- [ ] Usuario 1 recibe la respuesta
- [ ] Múltiples mensajes funcionan
- [ ] Mensajes se guardan localmente (persisten al cerrar app)
- [ ] Mensajes se sincronizan al reconectar
- [ ] Timestamps son correctos
- [ ] Orden de mensajes es correcto
- [ ] Búsqueda de usuarios funciona
- [ ] Cada usuario solo ve sus propias conversaciones
- [ ] No hay mensajes duplicados
- [ ] Performance es buena (< 1 segundo para enviar)

---

## 🔧 Configuración Avanzada

### Simular Red Lenta

Para probar cómo funciona el chat con conexión lenta:

**En Simulator:**
1. Xcode → Debug → Simulate Location → Custom Location
2. Settings → Developer → Network Link Conditioner
3. Enable → 3G / Edge

**En Dispositivo Físico:**
1. Ajustes → Desarrollador → Network Link Conditioner
2. Activar → Perfil 3G

### Simular Pérdida de Conexión

**Método 1 - Modo Avión:**
1. Usuario 1 envía mensaje
2. Usuario 2 activa Modo Avión
3. Usuario 1 envía otro mensaje
4. Usuario 2 desactiva Modo Avión
5. Verificar que recibe ambos mensajes

**Método 2 - Cambiar de WiFi:**
1. Usuario 1 en WiFi A
2. Usuario 2 cambia a WiFi B (sin backend)
3. Enviar mensajes
4. Usuario 2 vuelve a WiFi A
5. Verificar sincronización

---

## 📊 Logs Útiles

### En el Backend (Terminal)

Deberías ver algo como:
```
[2026-07-26T10:30:00] WebSocket connected: juan@test.com
[2026-07-26T10:30:15] WebSocket connected: maria@test.com
[2026-07-26T10:30:30] Message from juan@test.com to maria@test.com
[2026-07-26T10:30:35] Message delivered to maria@test.com
[2026-07-26T10:30:40] Message from maria@test.com to juan@test.com
[2026-07-26T10:30:42] Message delivered to juan@test.com
```

### En Xcode Console

**Usuario 1:**
```
🔐 Login exitoso: juan@test.com
🌐 WebSocket conectado
💬 Enviando mensaje a maria@test.com
✅ Mensaje enviado
📥 Mensaje recibido de maria@test.com
```

**Usuario 2:**
```
🔐 Login exitoso: maria@test.com
🌐 WebSocket conectado
📥 Mensaje recibido de juan@test.com
💬 Enviando mensaje a juan@test.com
✅ Mensaje enviado
```

---

## 🎯 Recomendación Final

Para testing de desarrollo: **Opción 1 (Simulador + Dispositivo)**

Para demos: **Opción 3 (Dos Dispositivos Físicos)**

Para CI/CD: **Tests automatizados con usuarios mock**

---

## 📝 Crear Usuarios de Prueba

Si necesitas múltiples usuarios rápidamente:

```bash
# Script para crear 5 usuarios de prueba
for i in {1..5}; do
  curl -X POST http://localhost:4001/v1/auth/register \
    -H "Content-Type: application/json" \
    -d "{
      \"id\": \"550e8400-e29b-41d4-a716-44665544000$i\",
      \"email\": \"user$i@test.com\",
      \"password\": \"test123\",
      \"firstName\": \"User\",
      \"firstSurname\": \"$i\"
    }"
  echo ""
done
```

Luego puedes hacer login en diferentes dispositivos con:
- user1@test.com / test123
- user2@test.com / test123
- user3@test.com / test123
- etc.

---

¿Necesitas ayuda con alguna configuración específica o tienes problemas con alguno de los métodos?
