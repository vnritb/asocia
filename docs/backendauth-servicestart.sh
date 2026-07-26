#!/bin/bash

# Script de inicio rápido para el microservicio de autenticación

echo "🔐 Iniciando servicio de autenticación..."
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "package.json" ]; then
    echo "❌ Error: Debes ejecutar este script desde backend/auth-service/"
    exit 1
fi

# Verificar si Node.js está instalado
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js no está instalado"
    echo "   Instálalo desde: https://nodejs.org/"
    exit 1
fi

# Verificar si npm está instalado
if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm no está instalado"
    exit 1
fi

# Mostrar versiones
echo "📦 Node version: $(node --version)"
echo "📦 npm version: $(npm --version)"
echo ""

# Verificar si node_modules existe
if [ ! -d "node_modules" ]; then
    echo "📥 Instalando dependencias..."
    npm install
    echo ""
fi

# Verificar si el puerto está ocupado
if lsof -Pi :4001 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  El puerto 4001 está ocupado"
    echo "   Deteniendo proceso anterior..."
    kill -9 $(lsof -t -i:4001)
    sleep 1
fi

echo "✅ Todo listo!"
echo ""
echo "🚀 Iniciando servicio en http://localhost:4001"
echo "   Presiona Ctrl+C para detener el servicio"
echo ""
echo "📡 Endpoints disponibles:"
echo "   POST http://localhost:4001/v1/auth/register"
echo "   POST http://localhost:4001/v1/auth/login"
echo "   GET  http://localhost:4001/v1/auth/verify"
echo "   GET  http://localhost:4001/health"
echo ""

# Iniciar el servicio
npm run dev
