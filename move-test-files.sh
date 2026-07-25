#!/bin/bash

# Script para mover todos los archivos de tests a la estructura correcta de backend/

echo "🔧 Moviendo archivos de tests a la carpeta backend/..."

# Crear estructura de directorios
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

echo "✅ Estructura de directorios creada"

# Los archivos que se crearon incorrectamente están en la raíz
# Este script los moverá a sus ubicaciones correctas

# Archivos de configuración raíz
if [ -f "backendvitest.config.ts" ]; then
  mv backendvitest.config.ts backend/vitest.config.ts
  echo "✓ Movido vitest.config.ts"
fi

if [ -f "backendpackage.json" ]; then
  mv backendpackage.json backend/package.json
  echo "✓ Movido package.json"
fi

if [ -f "backend.env.test" ]; then
  mv backend.env.test backend/.env.test
  echo "✓ Movido .env.test"
fi

if [ -f "backendREADME.md" ]; then
  mv backendREADME.md backend/README.md
  echo "✓ Movido README.md"
fi

if [ -f "backendTESTS.md" ]; then
  mv backendTESTS.md backend/TESTS.md
  echo "✓ Movido TESTS.md"
fi

# Test helpers
if [ -f "backendtest-helpersdatabase.ts" ]; then
  mv backendtest-helpersdatabase.ts backend/test-helpers/database.ts
  echo "✓ Movido test-helpers/database.ts"
fi

if [ -f "backendtest-helpersserver.ts" ]; then
  mv backendtest-helpersserver.ts backend/test-helpers/server.ts
  echo "✓ Movido test-helpers/server.ts"
fi

# Migrations
if [ -f "backendmigrationstest-schema.sql" ]; then
  mv backendmigrationstest-schema.sql backend/migrations/test-schema.sql
  echo "✓ Movido migrations/test-schema.sql"
fi

# Scripts
if [ -f "backendscriptssetup-test-db.sh" ]; then
  mv backendscriptssetup-test-db.sh backend/scripts/setup-test-db.sh
  chmod +x backend/scripts/setup-test-db.sh
  echo "✓ Movido scripts/setup-test-db.sh"
fi

# Membership tests
if [ -f "backendservicesmembershipsrcvalidatorsmemberValidator.unit.test.ts" ]; then
  mv backendservicesmembershipsrcvalidatorsmemberValidator.unit.test.ts backend/services/membership/src/validators/memberValidator.unit.test.ts
  echo "✓ Movido membership/src/validators/memberValidator.unit.test.ts"
fi

if [ -f "backendservicesmembershipsrcrepositorymemberRepository.unit.test.ts" ]; then
  mv backendservicesmembershipsrcrepositorymemberRepository.unit.test.ts backend/services/membership/src/repository/memberRepository.unit.test.ts
  echo "✓ Movido membership/src/repository/memberRepository.unit.test.ts"
fi

if [ -f "backendservicesmembershiptestsmembership.integration.test.ts" ]; then
  mv backendservicesmembershiptestsmembership.integration.test.ts backend/services/membership/tests/membership.integration.test.ts
  echo "✓ Movido membership/tests/membership.integration.test.ts"
fi

# Chat tests
if [ -f "backendserviceschatsrcvalidatorsmessageValidator.unit.test.ts" ]; then
  mv backendserviceschatsrcvalidatorsmessageValidator.unit.test.ts backend/services/chat/src/validators/messageValidator.unit.test.ts
  echo "✓ Movido chat/src/validators/messageValidator.unit.test.ts"
fi

if [ -f "backendserviceschattestschat.integration.test.ts" ]; then
  mv backendserviceschattestschat.integration.test.ts backend/services/chat/tests/chat.integration.test.ts
  echo "✓ Movido chat/tests/chat.integration.test.ts"
fi

# Translation tests
if [ -f "backendservicestranslationsrctranslationService.unit.test.ts" ]; then
  mv backendservicestranslationsrctranslationService.unit.test.ts backend/services/translation/src/translationService.unit.test.ts
  echo "✓ Movido translation/src/translationService.unit.test.ts"
fi

if [ -f "backendservicestranslationteststranslation.integration.test.ts" ]; then
  mv backendservicestranslationteststranslation.integration.test.ts backend/services/translation/tests/translation.integration.test.ts
  echo "✓ Movido translation/tests/translation.integration.test.ts"
fi

# API Gateway tests
if [ -f "backendservicesapi-gatewaytestsgateway.integration.test.ts" ]; then
  mv backendservicesapi-gatewaytestsgateway.integration.test.ts backend/services/api-gateway/tests/gateway.integration.test.ts
  echo "✓ Movido api-gateway/tests/gateway.integration.test.ts"
fi

echo ""
echo "✨ Archivos movidos correctamente a backend/"
echo ""
echo "Estructura final:"
tree backend/ -I node_modules 2>/dev/null || find backend/ -type f -name "*.ts" -o -name "*.sql" -o -name "*.sh" -o -name "*.json" -o -name "*.md"

echo ""
echo "🚀 Ya puedes ejecutar:"
echo "  cd backend"
echo "  npm install"
echo "  npm test"
