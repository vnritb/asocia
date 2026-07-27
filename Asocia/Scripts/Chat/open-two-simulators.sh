#!/bin/bash

echo "🚀 Abriendo dos simuladores para testing de chat..."
echo ""

# Obtener lista de simuladores disponibles
AVAILABLE_SIMS=$(xcrun simctl list devices available | grep "iPhone" | grep -v "unavailable" | head -2)

if [ -z "$AVAILABLE_SIMS" ]; then
    echo "❌ No hay suficientes simuladores disponibles"
    echo "   Crea al menos dos simuladores en Xcode:"
    echo "   Window → Devices and Simulators → Click '+'"
    exit 1
fi

# Extraer nombres y UDIDs
SIM1_LINE=$(echo "$AVAILABLE_SIMS" | head -1)
SIM2_LINE=$(echo "$AVAILABLE_SIMS" | tail -1)

SIM1_NAME=$(echo "$SIM1_LINE" | sed 's/(.*//' | xargs)
SIM2_NAME=$(echo "$SIM2_LINE" | sed 's/(.*//' | xargs)

SIM1_UDID=$(echo "$SIM1_LINE" | grep -o '\([0-9A-F-]*\)' | tr -d '()')
SIM2_UDID=$(echo "$SIM2_LINE" | grep -o '\([0-9A-F-]*\)' | tr -d '()')

echo "📱 Simulador 1: $SIM1_NAME"
echo "   UDID: $SIM1_UDID"
echo ""
echo "📱 Simulador 2: $SIM2_NAME"
echo "   UDID: $SIM2_UDID"
echo ""

# Apagar simuladores que puedan estar corriendo
echo "🔄 Preparando simuladores..."
xcrun simctl shutdown all 2>/dev/null

# Arrancar los dos simuladores seleccionados
xcrun simctl boot "$SIM1_UDID" 2>/dev/null
xcrun simctl boot "$SIM2_UDID" 2>/dev/null

# Abrir Simulator app con el primer simulador
open -a Simulator --args -CurrentDeviceUDID "$SIM1_UDID"

# Esperar un poco para que se abra
sleep 2

# Abrir segundo simulador en nueva ventana
open -a Simulator -n --args -CurrentDeviceUDID "$SIM2_UDID"

echo ""
echo "✅ ¡Simuladores abiertos!"
echo ""
echo "📋 Siguiente paso:"
echo "   1. En Xcode, seleccionar '$SIM1_NAME'"
echo "   2. Cmd + R para ejecutar"
echo "   3. Registrar usuario: alice@chat.test / test123"
echo ""
echo "   4. En Xcode, seleccionar '$SIM2_NAME'"
echo "   5. Cmd + R para ejecutar"
echo "   6. Registrar usuario: bob@chat.test / test123"
echo ""
echo "   ¡Ahora puedes probar el chat entre ambos usuarios!"
echo ""

# Opcional: Posicionar ventanas lado a lado
read -p "¿Quieres posicionar las ventanas lado a lado? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sleep 1
    # Obtener cantidad de ventanas de Simulator
    WINDOW_COUNT=$(osascript -e 'tell application "Simulator" to count windows')
    
    if [ "$WINDOW_COUNT" -ge 2 ]; then
        # Posicionar primera ventana a la izquierda
        osascript -e 'tell application "Simulator" to set bounds of window 1 to {0, 100, 450, 950}'
        # Posicionar segunda ventana a la derecha
        osascript -e 'tell application "Simulator" to set bounds of window 2 to {460, 100, 910, 950}'
        echo "✅ Ventanas posicionadas"
    else
        echo "⚠️  No se pudieron posicionar automáticamente"
    fi
fi

echo ""
echo "💡 Tip: Usa Cmd + Tab para cambiar entre ventanas del Simulator"
echo "💡 Tip: Usa Cmd + K en cada simulador para mostrar/ocultar teclado"
