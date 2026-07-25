#!/bin/bash

# Script mejorado para limpiar duplicados y mover archivos correctamente

echo "🧹 Limpiando archivos duplicados y reorganizando tests..."
echo ""

# Crear estructura de directorios
echo "📁 Creando estructura de directorios..."
mkdir -p backend/test-helpers
mkdir -p backend/migrations
mkdir -p backend/scripts
mkdir -p backend/services/membership/src/validators
mkdir -p backend/services/membership/src/repository
mkdir -p backend/services/membership/tests
mkdir -p backend/services/chat/src/validators
mkdir -p backend/services/chat/tests
mkdir -p backend/services/translation/src
mkdir -p backend/services/translation/tests
mkdir -p backend/services/api-gateway/tests

# PASO 1: Eliminar duplicados (archivos con " 2", " 3", etc.)
echo ""
echo "🗑️  Eliminando archivos duplicados..."
rm -f "backendvitest.config 2.ts" "backendvitest.config 3.ts"
rm -f "backendpackage 2.json" "backendpackage 3.json"
rm -f "backendREADME 2.md" "backendREADME 3.md"
rm -f "backendTESTS 2.md" "backendTESTS 3.md"
echo "✓ Duplicados eliminados"

# PASO 2: Mover archivos de configuración raíz
echo ""
echo "📦 Moviendo archivos de configuración..."

if [ -f "backendvitest.config.ts" ]; then
  mv backendvitest.config.ts backend/vitest.config.ts
  echo "✓ vitest.config.ts → backend/"
fi

if [ -f "backendpackage.json" ]; then
  mv backendpackage.json backend/package.json
  echo "✓ package.json → backend/"
fi

if [ -f "backend.env.test" ]; then
  mv backend.env.test backend/.env.test
  echo "✓ .env.test → backend/"
fi

if [ -f "backendREADME.md" ]; then
  mv backendREADME.md backend/README.md
  echo "✓ README.md → backend/"
fi

if [ -f "backendTESTS.md" ]; then
  mv backendTESTS.md backend/TESTS.md
  echo "✓ TESTS.md → backend/"
fi

# PASO 3: Mover test helpers
echo ""
echo "🛠️  Moviendo test helpers..."

if [ -f "backendtest-helpersdatabase.ts" ]; then
  mv backendtest-helpersdatabase.ts backend/test-helpers/database.ts
  echo "✓ database.ts → backend/test-helpers/"
fi

if [ -f "backendtest-helpersserver.ts" ]; then
  mv backendtest-helpersserver.ts backend/test-helpers/server.ts
  echo "✓ server.ts → backend/test-helpers/"
fi

# PASO 4: Mover migrations
echo ""
echo "🗄️  Moviendo migrations..."

if [ -f "backendmigrationstest-schema.sql" ]; then
  mv backendmigrationstest-schema.sql backend/migrations/test-schema.sql
  echo "✓ test-schema.sql → backend/migrations/"
fi

# PASO 5: Mover scripts
echo ""
echo "📜 Moviendo scripts..."

if [ -f "backendscriptssetup-test-db.sh" ]; then
  mv backendscriptssetup-test-db.sh backend/scripts/setup-test-db.sh
  chmod +x backend/scripts/setup-test-db.sh
  echo "✓ setup-test-db.sh → backend/scripts/"
fi

# PASO 6: Mover tests de Membership
echo ""
echo "👥 Moviendo tests de Membership..."

if [ -f "backendservicesmembershipsrcvalidatorsmemberValidator.unit.test.ts" ]; then
  mv backendservicesmembershipsrcvalidatorsmemberValidator.unit.test.ts backend/services/membership/src/validators/memberValidator.unit.test.ts
  echo "✓ memberValidator.unit.test.ts → backend/services/membership/src/validators/"
fi

if [ -f "backendservicesmembershipsrcrepositorymemberRepository.unit.test.ts" ]; then
  mv backendservicesmembershipsrcrepositorymemberRepository.unit.test.ts backend/services/membership/src/repository/memberRepository.unit.test.ts
  echo "✓ memberRepository.unit.test.ts → backend/services/membership/src/repository/"
fi

if [ -f "backendservicesmembershiptestsmembership.integration.test.ts" ]; then
  mv backendservicesmembershiptestsmembership.integration.test.ts backend/services/membership/tests/membership.integration.test.ts
  echo "✓ membership.integration.test.ts → backend/services/membership/tests/"
fi

# PASO 7: Mover tests de Chat
echo ""
echo "💬 Moviendo tests de Chat..."

if [ -f "backendserviceschatsrcvalidatorsmessageValidator.unit.test.ts" ]; then
  mv backendserviceschatsrcvalidatorsmessageValidator.unit.test.ts backend/services/chat/src/validators/messageValidator.unit.test.ts
  echo "✓ messageValidator.unit.test.ts → backend/services/chat/src/validators/"
fi

if [ -f "backendserviceschattestschat.integration.test.ts" ]; then
  mv backendserviceschattestschat.integration.test.ts backend/services/chat/tests/chat.integration.test.ts
  echo "✓ chat.integration.test.ts → backend/services/chat/tests/"
fi

# PASO 8: Mover tests de Translation
echo ""
echo "🌐 Moviendo tests de Translation..."

if [ -f "backendservicestranslationsrctranslationService.unit.test.ts" ]; then
  mv backendservicestranslationsrctranslationService.unit.test.ts backend/services/translation/src/translationService.unit.test.ts
  echo "✓ translationService.unit.test.ts → backend/services/translation/src/"
fi

if [ -f "backendservicestranslationteststranslation.integration.test.ts" ]; then
  mv backendservicestranslationteststranslation.integration.test.ts backend/services/translation/tests/translation.integration.test.ts
  echo "✓ translation.integration.test.ts → backend/services/translation/tests/"
fi

# PASO 9: Mover tests de API Gateway
echo ""
echo "🚪 Moviendo tests de API Gateway..."

if [ -f "backendservicesapi-gatewaytestsgateway.integration.test.ts" ]; then
  mv backendservicesapi-gatewaytestsgateway.integration.test.ts backend/services/api-gateway/tests/gateway.integration.test.ts
  echo "✓ gateway.integration.test.ts → backend/services/api-gateway/tests/"
fi

# PASO 10: Verificar estructura final
echo ""
echo "✅ ¡Reorganización completada!"
echo ""
echo "📊 Estructura final de backend/:"
echo ""

# Mostrar árbol de archivos (si tree está instalado, sino usar find)
if command -v tree &> /dev/null; then
    tree backend/ -I node_modules -L 4
else
    echo "backend/"
    find backend/ -type f \( -name "*.ts" -o -name "*.sql" -o -name "*.sh" -o -name "*.json" -o -name "*.md" \) | sed 's|backend/|  |' | sort
fi

echo ""
echo "🎯 Próximos pasos:"
echo ""
echo "  cd backend"
echo "  npm install"
echo "  chmod +x scripts/setup-test-db.sh"
echo "  ./scripts/setup-test-db.sh"
echo "  npm test"
echo ""
