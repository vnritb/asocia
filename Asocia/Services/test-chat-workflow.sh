#!/bin/bash

echo "🚀 Iniciando entorno completo de testing de chat..."
echo "=================================================="
echo ""

BACKEND_PID=""

# Función para limpiar al salir
cleanup() {
    echo ""
    echo "🧹 Limpiando..."
    if [ ! -z "$BACKEND_PID" ]; then
        echo "   Deteniendo backend (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null
    fi
    echo "   ✅ Limpieza completada"
}

trap cleanup EXIT

# 1. Verificar que estamos en el directorio correcto
if [ ! -d "backend/auth-service" ]; then
    echo "❌ Error: Debes ejecutar este script desde la raíz del proyecto"
    echo "   Ejemplo: ./test-chat-workflow.sh"
    exit 1
fi

# 2. Verificar Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js no está instalado"
    echo "   Instálalo desde: https://nodejs.org/"
    exit 1
fi

# 3. Verificar que el backend esté instalado
if [ ! -d "backend/auth-service/node_modules" ]; then
    echo "📦 Instalando dependencias del backend..."
    cd backend/auth-service
    npm install
    cd ../..
fi

# 4. Verificar/Iniciar backend
echo "1️⃣  Verificando backend..."
if ! curl -s http://localhost:4001/health > /dev/null 2>&1; then
    echo "   Backend no está corriendo, iniciando..."
    cd backend/auth-service
    npm run dev > /tmp/auth-service.log 2>&1 &
    BACKEND_PID=$!
    cd ../..
    
    # Esperar a que el backend esté listo
    echo -n "   Esperando a que el backend inicie"
    for i in {1..10}; do
        sleep 1
        echo -n "."
        if curl -s http://localhost:4001/health > /dev/null 2>&1; then
            echo ""
            echo "   ✅ Backend iniciado (PID: $BACKEND_PID)"
            break
        fi
    done
    
    if ! curl -s http://localhost:4001/health > /dev/null 2>&1; then
        echo ""
        echo "   ❌ Backend no se pudo iniciar"
        echo "   Ver logs en: /tmp/auth-service.log"
        exit 1
    fi
else
    echo "   ✅ Backend ya está corriendo"
fi
echo ""

# 5. Abrir simuladores
echo "2️⃣  Abriendo simuladores..."
if [ -f "open-two-simulators.sh" ]; then
    chmod +x open-two-simulators.sh
    ./open-two-simulators.sh
else
    echo "   ⚠️  Script open-two-simulators.sh no encontrado"
    echo "   Abre los simuladores manualmente"
fi
echo ""

# 6. Registrar usuarios de prueba automáticamente
echo "3️⃣  Configurando usuarios de prueba..."
read -p "¿Quieres crear usuarios de prueba automáticamente? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "   Creando alice@chat.test..."
    ALICE_RESULT=$(curl -s -X POST http://localhost:4001/v1/auth/register \
      -H "Content-Type: application/json" \
      -d '{
        "id": "11111111-1111-1111-1111-111111111111",
        "email": "alice@chat.test",
        "password": "test123",
        "firstName": "Alice",
        "firstSurname": "Test"
      }')
    
    if echo "$ALICE_RESULT" | grep -q "token"; then
        echo "   ✅ alice@chat.test creada"
    elif echo "$ALICE_RESULT" | grep -q "ya está registrado"; then
        echo "   ℹ️  alice@chat.test ya existe"
    else
        echo "   ⚠️  Error creando alice@chat.test"
    fi
    
    echo "   Creando bob@chat.test..."
    BOB_RESULT=$(curl -s -X POST http://localhost:4001/v1/auth/register \
      -H "Content-Type: application/json" \
      -d '{
        "id": "22222222-2222-2222-2222-222222222222",
        "email": "bob@chat.test",
        "password": "test123",
        "firstName": "Bob",
        "firstSurname": "Test"
      }')
    
    if echo "$BOB_RESULT" | grep -q "token"; then
        echo "   ✅ bob@chat.test creado"
    elif echo "$BOB_RESULT" | grep -q "ya está registrado"; then
        echo "   ℹ️  bob@chat.test ya existe"
    else
        echo "   ⚠️  Error creando bob@chat.test"
    fi
    
    echo ""
    echo "   📋 Credenciales:"
    echo "   ┌──────────────────────────────┐"
    echo "   │ Usuario 1 (Simulador 1):     │"
    echo "   │ Email: alice@chat.test       │"
    echo "   │ Password: test123            │"
    echo "   ├──────────────────────────────┤"
    echo "   │ Usuario 2 (Simulador 2):     │"
    echo "   │ Email: bob@chat.test         │"
    echo "   │ Password: test123            │"
    echo "   └──────────────────────────────┘"
fi
echo ""

# 7. Instrucciones finales
echo "=================================================="
echo "4️⃣  Siguiente paso (en Xcode):"
echo ""
echo "   A. Ejecutar en Simulador 1:"
echo "      1. Xcode → Seleccionar primer simulador en el selector"
echo "      2. Presionar Cmd + R"
echo "      3. Hacer login con: alice@chat.test / test123"
echo ""
echo "   B. Ejecutar en Simulador 2:"
echo "      4. Xcode → Seleccionar segundo simulador"
echo "      5. Presionar Cmd + R"
echo "      6. Hacer login con: bob@chat.test / test123"
echo ""
echo "   C. Probar Chat:"
echo "      7. En simulador de Alice: buscar 'Bob' y enviar mensaje"
echo "      8. En simulador de Bob: ver mensaje y responder"
echo ""
echo "=================================================="
echo ""
echo "💡 Tips:"
echo "   • Usa Cmd+Tab para cambiar entre simuladores"
echo "   • Usa Cmd+K para mostrar/ocultar teclado"
echo "   • Logs del backend en: /tmp/auth-service.log"
echo "   • Backend corriendo en: http://localhost:4001"
echo ""
echo "🎉 ¡Todo listo para probar el chat!"
echo ""
echo "⚠️  Al cerrar este script, el backend se detendrá automáticamente"
echo "   Para mantenerlo corriendo, presiona Ctrl+Z y luego 'bg'"
echo ""

# Mantener el script vivo para que el backend siga corriendo
if [ ! -z "$BACKEND_PID" ]; then
    echo "⏳ Backend corriendo... Presiona Ctrl+C para detener"
    wait $BACKEND_PID
fi
