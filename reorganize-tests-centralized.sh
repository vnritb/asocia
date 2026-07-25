#!/bin/bash

# Script para reorganizar tests en una estructura centralizada

echo "🔧 Reorganizando tests en estructura centralizada..."
echo ""

# Crear estructura centralizada de tests
mkdir -p backend/tests/unit/membership
mkdir -p backend/tests/unit/chat
mkdir -p backend/tests/unit/translation
mkdir -p backend/tests/integration
mkdir -p backend/test-helpers
mkdir -p backend/migrations
mkdir -p backend/scripts

# Crear directorios de servicios (solo src, sin tests)
mkdir -p backend/services/membership/src
mkdir -p backend/services/chat/src
mkdir -p backend/services/translation/src
mkdir -p backend/services/api-gateway/src

echo "📦 Moviendo archivos de configuración..."

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

echo ""
echo "🧪 Moviendo TESTS UNITARIOS a backend/tests/unit/..."

# Membership unit tests
[ -f "backendservicesmembershipsrcvalidatorsmemberValidator.unit.test.ts" ] && \
  mv backendservicesmembershipsrcvalidatorsmemberValidator.unit.test.ts backend/tests/unit/membership/memberValidator.unit.test.ts && \
  echo "✓ unit/membership/memberValidator.unit.test.ts"

[ -f "backendservicesmembershipsrcrepositorymemberRepository.unit.test.ts" ] && \
  mv backendservicesmembershipsrcrepositorymemberRepository.unit.test.ts backend/tests/unit/membership/memberRepository.unit.test.ts && \
  echo "✓ unit/membership/memberRepository.unit.test.ts"

# Chat unit tests
[ -f "backendserviceschatsrcvalidatorsmessageValidator.unit.test.ts" ] && \
  mv backendserviceschatsrcvalidatorsmessageValidator.unit.test.ts backend/tests/unit/chat/messageValidator.unit.test.ts && \
  echo "✓ unit/chat/messageValidator.unit.test.ts"

# Translation unit tests
[ -f "backendservicestranslationsrctranslationService.unit.test.ts" ] && \
  mv backendservicestranslationsrctranslationService.unit.test.ts backend/tests/unit/translation/translationService.unit.test.ts && \
  echo "✓ unit/translation/translationService.unit.test.ts"

echo ""
echo "🔗 Moviendo TESTS DE INTEGRACIÓN a backend/tests/integration/..."

# Integration tests
[ -f "backendservicesmembershiptestsmembership.integration.test.ts" ] && \
  mv backendservicesmembershiptestsmembership.integration.test.ts backend/tests/integration/membership.integration.test.ts && \
  echo "✓ integration/membership.integration.test.ts"

[ -f "backendserviceschattestschat.integration.test.ts" ] && \
  mv backendserviceschattestschat.integration.test.ts backend/tests/integration/chat.integration.test.ts && \
  echo "✓ integration/chat.integration.test.ts"

[ -f "backendservicestranslationteststranslation.integration.test.ts" ] && \
  mv backendservicestranslationteststranslation.integration.test.ts backend/tests/integration/translation.integration.test.ts && \
  echo "✓ integration/translation.integration.test.ts"

[ -f "backendservicesapi-gatewaytestsgateway.integration.test.ts" ] && \
  mv backendservicesapi-gatewaytestsgateway.integration.test.ts backend/tests/integration/gateway.integration.test.ts && \
  echo "✓ integration/gateway.integration.test.ts"

# Limpiar duplicados
echo ""
echo "🗑️  Limpiando duplicados..."
rm -f backendvitest.config\ *.ts 2>/dev/null
rm -f backendpackage\ *.json 2>/dev/null
rm -f backendREADME\ *.md 2>/dev/null
rm -f backendTESTS\ *.md 2>/dev/null

echo ""
echo "✅ ¡Reorganización completada!"
echo ""
echo "📂 Estructura final:"
echo ""
echo "backend/"
echo "├── tests/                          ← TODOS LOS TESTS AQUÍ"
echo "│   ├── unit/"
echo "│   │   ├── membership/"
echo "│   │   │   ├── memberValidator.unit.test.ts"
echo "│   │   │   └── memberRepository.unit.test.ts"
echo "│   │   ├── chat/"
echo "│   │   │   └── messageValidator.unit.test.ts"
echo "│   │   └── translation/"
echo "│   │       └── translationService.unit.test.ts"
echo "│   └── integration/"
echo "│       ├── membership.integration.test.ts"
echo "│       ├── chat.integration.test.ts"
echo "│       ├── translation.integration.test.ts"
echo "│       └── gateway.integration.test.ts"
echo "├── services/"
echo "│   ├── membership/src/"
echo "│   ├── chat/src/"
echo "│   └── translation/src/"
echo "├── test-helpers/"
echo "├── migrations/"
echo "└── scripts/"
echo ""

# Verificar archivos movidos
echo "🔍 Verificando archivos en backend/tests/:"
echo ""
find backend/tests -type f -name "*.test.ts" 2>/dev/null | sort

echo ""
echo "🚀 Ahora puedes:"
echo "   cd backend"
echo "   npm install"
echo "   npm run test:unit          # Ejecutar solo tests unitarios"
echo "   npm run test:integration   # Ejecutar solo tests de integración"
echo "   npm test                   # Ejecutar todos los tests"
echo ""
