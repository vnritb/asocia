# Cómo Probar Chat con Dos Usuarios - Guía Completa

## 🎯 Opción Recomendada: Dos Simuladores Simultáneos

### Setup Inicial (una sola vez)

#### 1. Crear Simuladores

En Xcode:
1. **Window → Devices and Simulators**
2. Click en el **+** (abajo izquierda)
3. Crear dos simuladores:
   - "iPhone 15 - Usuario 1" 
   - "iPhone 15 - Usuario 2"

#### 2. Script para abrir ambos simuladores

Crear archivo `open-two-simulators.sh`:

```bash
#!/bin/bash

echo "🚀 Abriendo dos simuladores para testing de chat..."

# Obtener UDIDs de simuladores disponibles
SIMULATORS=$(xcrun simctl list devices available | grep "iPhone 15" | head -2)

# Extraer UDIDs
SIM1=$(echo "$SIMULATORS" | head -1 | grep -o '\([0-9A-F-]*\)' | tr -d '()')
SIM2=$(echo "$SIMULATORS" | tail -1 | grep -o '\([0-9A-F-]*\)' | tr -d '()')

echo "📱 Simulador 1: $SIM1"
echo "📱 Simulador 2: $SIM2"

# Abrir simuladores
xcrun simctl boot "$SIM1" 2>/dev/null
xcrun simctl boot "$SIM2" 2>/dev/null

open -a Simulator --args -CurrentDeviceUDID "$SIM1"
sleep 2
open -a Simulator --args -CurrentDeviceUDID "$SIM2"

echo "✅ Simuladores abiertos!"
echo ""
echo "Siguiente paso:"
echo "1. En Xcode, seleccionar primer simulador y Cmd+R"
echo "2. En Xcode, seleccionar segundo simulador y Cmd+R"
```

Hacer ejecutable:
```bash
chmod +x open-two-simulators.sh
```

### Flujo de Trabajo Diario

#### 1. Iniciar Backend

```bash
cd backend/auth-service
npm run dev
```

#### 2. Abrir Simuladores

```bash
./open-two-simulators.sh
```

#### 3. Ejecutar App en Ambos

**En Xcode:**

Terminal 1:
```bash
# Ejecutar en primer simulador
xcodebuild -scheme "Asocia (Local)" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  build
```

O manualmente:
1. Xcode → Seleccionar "iPhone 15" en selector de destino
2. `Cmd + R`
3. Esperar a que inicie
4. Xcode → Seleccionar segundo simulador
5. `Cmd + R` de nuevo

#### 4. Registrar Usuarios Diferentes

**Simulador 1:**
```
Email: alice@chat.test
Password: test123
Nombre: Alice
```

**Simulador 2:**
```
Email: bob@chat.test
Password: test123
Nombre: Bob
```

#### 5. Probar Chat

1. En simulador de Alice: buscar "Bob" en chat
2. Enviar mensaje
3. En simulador de Bob: ver mensaje de Alice
4. Responder

### Ventanas Side-by-Side

Para ver ambos simuladores al mismo tiempo:

1. Reduce el tamaño de cada ventana del simulador
2. Ponlos lado a lado
3. Usa **Mission Control** (F3) para organizarlos

O usa esta configuración:
```bash
# Posicionar simuladores automáticamente
osascript -e 'tell application "Simulator" to set bounds of window 1 to {0, 100, 400, 900}'
osascript -e 'tell application "Simulator" to set bounds of window 2 to {410, 100, 810, 900}'
```

---

## 🎯 Opción Alternativa: Simulador + Dispositivo Físico

Si tienes un iPhone/iPad a mano:

### Setup

#### 1. Encontrar IP de tu Mac

```bash
ipconfig getifaddr en0
# Salida: 192.168.1.45 (tu IP local)
```

#### 2. Actualizar AppEnvironment.swift

```swift
enum AppEnvironment: String, CaseIterable {
    case mock
    case local
    case localDevice  // 👈 NUEVO
    case staging
    case production

    var apiBaseURL: URL {
        switch self {
        case .mock:
            return URL(string: "http://localhost:0")!
        case .local:
            return URL(string: "http://localhost:4001")!  // Para simulador
        case .localDevice:
            return URL(string: "http://192.168.1.45:4001")!  // 👈 Tu IP aquí
        case .staging:
            return URL(string: "https://asocia-api-staging.onrender.com")!
        case .production:
            return URL(string: "https://asocia-api.onrender.com")!
        }
    }
}
```

#### 3. Crear Scheme para Dispositivo

En Xcode:
1. **Product → Scheme → Edit Scheme**
2. Duplicar "Asocia (Local)" 
3. Renombrar a "Asocia (Local Device)"
4. En **Arguments → Environment Variables**:
   - Nombre: `ASOCIA_ENVIRONMENT`
   - Valor: `localDevice`

#### 4. Verificar Firewall

Asegurarte de que el puerto 4001 esté accesible:

```bash
# En tu Mac, permitir conexiones entrantes
sudo pfctl -d  # Desactivar firewall temporalmente (solo para testing)

# O añadir regla específica
# System Settings → Network → Firewall → Options
# Permitir Node.js
```

### Uso

1. **Simulador:**
   - Scheme: "Asocia (Local)"
   - Usuario: alice@chat.test

2. **Dispositivo Físico:**
   - Conectar iPhone a Mac
   - Scheme: "Asocia (Local Device)"
   - `Cmd + R`
   - Usuario: bob@chat.test

⚠️ **Importante:** Ambos dispositivos deben estar en la **misma red WiFi**.

---

## 🎯 Opción Avanzada: Múltiples Cuentas en Mismo Dispositivo

Para cambiar entre usuarios sin reinstalar:

### Implementación

#### 1. Crear AccountManager

```swift
// AccountManager.swift
import SwiftUI
import SwiftData

@Observable
class AccountManager {
    var currentAccountEmail: String?
    
    func switchAccount(to email: String) {
        currentAccountEmail = email
        // Recargar datos para esa cuenta
    }
    
    func logout() {
        KeychainStore.deleteToken()
        currentAccountEmail = nil
    }
}
```

#### 2. Añadir Selector de Cuenta en Settings

```swift
// AccountSwitcherView.swift
struct AccountSwitcherView: View {
    @Environment(AccountManager.self) private var accountManager
    @Environment(\.authService) private var authService
    @State private var showAddAccount = false
    
    var body: some View {
        List {
            Section("Cuentas") {
                ForEach(savedAccounts) { account in
                    Button {
                        switchTo(account)
                    } label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                            VStack(alignment: .leading) {
                                Text(account.name)
                                Text(account.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if account.isCurrent {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                
                Button("Añadir Cuenta") {
                    showAddAccount = true
                }
            }
        }
        .sheet(isPresented: $showAddAccount) {
            LoginView(onLoginSuccess: {
                // Nueva cuenta añadida
            })
        }
    }
    
    private func switchTo(_ account: Account) {
        accountManager.switchAccount(to: account.email)
    }
}
```

#### 3. Usar en Settings

```swift
// SettingsView.swift
var body: some View {
    NavigationStack {
        List {
            NavigationLink("Cambiar Cuenta") {
                AccountSwitcherView()
            }
            
            // ... otros settings ...
        }
    }
}
```

Pero esto requiere bastante trabajo. **Para testing, mejor usar dos simuladores.**

---

## 🛠️ Script Completo de Testing

Crear `test-chat-workflow.sh`:

```bash
#!/bin/bash

echo "🚀 Iniciando entorno de testing de chat..."
echo ""

# 1. Verificar que el backend esté corriendo
echo "1️⃣  Verificando backend..."
if ! curl -s http://localhost:4001/health > /dev/null; then
    echo "   ❌ Backend no está corriendo"
    echo "   Iniciando backend..."
    cd backend/auth-service
    npm run dev &
    BACKEND_PID=$!
    sleep 3
    cd ../..
else
    echo "   ✅ Backend corriendo"
fi
echo ""

# 2. Abrir dos simuladores
echo "2️⃣  Abriendo simuladores..."
./open-two-simulators.sh
echo ""

# 3. Instrucciones
echo "3️⃣  Siguiente paso manual:"
echo ""
echo "   En Xcode:"
echo "   1. Seleccionar primer simulador"
echo "   2. Cmd + R"
echo "   3. Registrar usuario: alice@chat.test / test123"
echo ""
echo "   4. Seleccionar segundo simulador"
echo "   5. Cmd + R"
echo "   6. Registrar usuario: bob@chat.test / test123"
echo ""
echo "   ¡Ahora puedes probar el chat!"
echo ""

# 4. Registrar usuarios automáticamente (opcional)
read -p "¿Quieres registrar usuarios automáticamente? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   Registrando alice@chat.test..."
    curl -s -X POST http://localhost:4001/v1/auth/register \
      -H "Content-Type: application/json" \
      -d '{
        "id": "11111111-1111-1111-1111-111111111111",
        "email": "alice@chat.test",
        "password": "test123",
        "firstName": "Alice",
        "firstSurname": "Test"
      }' > /dev/null
    
    echo "   Registrando bob@chat.test..."
    curl -s -X POST http://localhost:4001/v1/auth/register \
      -H "Content-Type: application/json" \
      -d '{
        "id": "22222222-2222-2222-2222-222222222222",
        "email": "bob@chat.test",
        "password": "test123",
        "firstName": "Bob",
        "firstSurname": "Test"
      }' > /dev/null
    
    echo "   ✅ Usuarios registrados"
    echo "   Ahora solo haz login en cada simulador"
fi

echo ""
echo "🎉 ¡Listo para probar el chat!"
```

Hacer ejecutable:
```bash
chmod +x test-chat-workflow.sh
```

### Uso:

```bash
./test-chat-workflow.sh
```

---

## 📋 Checklist de Testing de Chat

### Preparación
- [ ] Backend corriendo
- [ ] Dos simuladores abiertos
- [ ] App instalada en ambos
- [ ] Dos cuentas diferentes creadas

### Casos de Prueba

#### Básico
- [ ] Alice envía mensaje a Bob
- [ ] Bob recibe mensaje de Alice
- [ ] Bob responde a Alice
- [ ] Alice recibe respuesta

#### Avanzado
- [ ] Enviar mensaje mientras el otro está offline
- [ ] Mensaje se entrega al reconectar
- [ ] Marcar como leído
- [ ] Indicador de "escribiendo..."
- [ ] Emojis se muestran correctamente
- [ ] Imágenes se envían correctamente

#### Edge Cases
- [ ] Mensaje muy largo (>1000 caracteres)
- [ ] Muchos mensajes rápidos
- [ ] Enviar sin conexión
- [ ] Reconectar y sincronizar
- [ ] Eliminar conversación
- [ ] Bloquear usuario

---

## 🔍 Debugging en Dos Simuladores

### Ver logs de ambos simultáneamente

En Terminal:

```bash
# Ver logs de todos los simuladores
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Asocia"' --level debug
```

O mejor, dos terminales:

**Terminal 1 (Simulador de Alice):**
```bash
# Encontrar UDID del simulador
xcrun simctl list devices | grep "iPhone 15"

# Ver logs de ese simulador específico
xcrun simctl spawn <UDID-Sim1> log stream --predicate 'processImagePath contains "Asocia"'
```

**Terminal 2 (Simulador de Bob):**
```bash
xcrun simctl spawn <UDID-Sim2> log stream --predicate 'processImagePath contains "Asocia"'
```

### Xcode Console

Puedes ver ambos si usas **filter** en Xcode Console:
- Filter por "Alice" para ver logs del usuario Alice
- Filter por "Bob" para ver logs del usuario Bob

---

## 💡 Tips y Trucos

### 1. Nombres de Usuario Claros

Usa nombres que identifiques fácilmente en logs:

```swift
// En SignupView o donde configures el nombre
firstName = "Alice_SIM1"  // Para simulador 1
firstName = "Bob_SIM2"    // Para simulador 2
```

### 2. Colores Diferentes

Puedes personalizar el tint color para cada "usuario":

```swift
// En RootView o App
.tint(currentUser.email == "alice@chat.test" ? .blue : .green)
```

Así visualmente sabes en qué simulador estás.

### 3. Resetear Simuladores

Si algo va mal:

```bash
# Borrar datos de un simulador específico
xcrun simctl erase <UDID>

# Borrar datos de todos
xcrun simctl erase all
```

### 4. Capturas de Pantalla Sincronizadas

Para documentación:

```bash
# Captura de ambos simuladores a la vez
xcrun simctl io <UDID-1> screenshot alice.png &
xcrun simctl io <UDID-2> screenshot bob.png &
wait
```

---

## 🎯 Recomendación Final

Para desarrollo diario:
**👉 Usa dos simuladores simultáneos**

Pros:
- ✅ Rápido de configurar
- ✅ Fácil de debuggear
- ✅ Consume solo RAM (no batería)
- ✅ Ambos usan mismo backend
- ✅ Puedes ver ambas pantallas a la vez

Solo usa dispositivos físicos cuando necesites probar:
- Notificaciones push reales
- Rendimiento real
- Gestos táctiles específicos
- Cámara/micrófono
- Batería
