#!/bin/bash

# Script ultra-simple para mover archivos de tests a backend/

echo "🔧 Moviendo archivos de tests a backend/..."
echo ""

# Crear directorios
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

# Listar archivos que empiezan con "backend" en la raíz
echo "📋 Archivos encontrados en la raíz:"
ls -1 backend* 2>/dev/null || echo "  (ninguno)"
echo ""

# Mover cada archivo
echo "📦 Moviendo archivos..."

# Configuración
[ -f "backendvitest.config.ts" ] && mv backendvitest.config.ts backend/vitest.config.ts && echo "✓ vitest.config.ts"
[ -f "backendpackage.json" ] && mv backendpackage.json backend/package.json && echo "✓ package.json"
[ -f "backend.env.test" ] && mv backend.env.test backend/.env.test && echo "✓ .env.test"
[ -f "backendREADME.md" ] && mv backendREADME.md backend/README.md && echo "✓ README.md"
[ -f "backendTESTS.md" ] && mv backendTESTS.md backend/TESTS.md && echo "✓ TESTS.md"

# Helpers
[ -f "backendtest-helpersdatabase.ts" ] && mv backendtest-helpersdatabase.ts backend/test-helpers/database.ts && echo "✓ test-helpers/database.ts"
[ -f "backendtest-helpersserver.ts" ] && mv backendtest-helpersserver.ts backend/test-helpers/server.ts && echo "✓ test-helpers/server.ts"

# Migrations & Scripts
[ -f "backendmigrationstest-schema.sql" ] && mv backendmigrationstest-schema.sql backend/migrations/test-schema.sql && echo "✓ migrations/test-schema.sql"
[ -f "backendscriptssetup-test-db.sh" ] && mv backendscriptssetup-test-db.sh backend/scripts/setup-test-db.sh && chmod +x backend/scripts/setup-test-db.sh && echo "✓ scripts/setup-test-db.sh"

# Membership
[ -f "backendservicesmembershipsrcvalidatorsmemberValidator.unit.test.ts" ] && mv backendservicesmembershipsrcvalidatorsmemberValidator.unit.test.ts backend/services/membership/src/validators/memberValidator.unit.test.ts && echo "✓ membership/validators/memberValidator.unit.test.ts"
[ -f "backendservicesmembershipsrcrepositorymemberRepository.unit.test.ts" ] && mv backendservicesmembershipsrcrepositorymemberRepository.unit.test.ts backend/services/membership/src/repository/memberRepository.unit.test.ts && echo "✓ membership/repository/memberRepository.unit.test.ts"
[ -f "backendservicesmembershiptestsmembership.integration.test.ts" ] && mv backendservicesmembershiptestsmembership.integration.test.ts backend/services/membership/tests/membership.integration.test.ts && echo "✓ membership/tests/membership.integration.test.ts"

# Chat
[ -f "backendserviceschatsrcvalidatorsmessageValidator.unit.test.ts" ] && mv backendserviceschatsrcvalidatorsmessageValidator.unit.test.ts backend/services/chat/src/validators/messageValidator.unit.test.ts && echo "✓ chat/validators/messageValidator.unit.test.ts"
[ -f "backendserviceschattestschat.integration.test.ts" ] && mv backendserviceschattestschat.integration.test.ts backend/services/chat/tests/chat.integration.test.ts && echo "✓ chat/tests/chat.integration.test.ts"

# Translation
[ -f "backendservicestranslationsrctranslationService.unit.test.ts" ] && mv backendservicestranslationsrctranslationService.unit.test.ts backend/services/translation/src/translationService.unit.test.ts && echo "✓ translation/translationService.unit.test.ts"
[ -f "backendservicestranslationteststranslation.integration.test.ts" ] && mv backendservicestranslationteststranslation.integration.test.ts backend/services/translation/tests/translation.integration.test.ts && echo "✓ translation/tests/translation.integration.test.ts"

# Gateway
[ -f "backendservicesapi-gatewaytestsgateway.integration.test.ts" ] && mv backendservicesapi-gatewaytestsgateway.integration.test.ts backend/services/api-gateway/tests/gateway.integration.test.ts && echo "✓ api-gateway/tests/gateway.integration.test.ts"

# Limpiar duplicados
rm -f backendvitest.config\ *.ts
rm -f backendpackage\ *.json
rm -f backendREADME\ *.md
rm -f backendTESTS\ *.md

echo ""
echo "✅ ¡Listo! Archivos movidos a backend/"
echo ""
echo "📂 Verifica la estructura:"
echo ""
ls -la backend/services/membership/tests/ 2>/dev/null
ls -la backend/services/chat/tests/ 2>/dev/null
echo ""
echo "🚀 Ahora puedes:"
echo "   cd backend"
echo "   npm install"
echo "   npm test"
