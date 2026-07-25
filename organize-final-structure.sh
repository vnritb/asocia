#!/bin/bash

# Script para estructura: services/{src,tests}/{membership,chat,translation,api-gateway}

echo "🔧 Reorganizando con estructura services/src/ y services/tests/..."
echo ""

# Crear estructura agrupada
echo "📁 Creando estructura de directorios..."

# SRC - todos los servicios dentro de services/src/
mkdir -p backend/services/src/membership/validators
mkdir -p backend/services/src/membership/repository
mkdir -p backend/services/src/chat/validators
mkdir -p backend/services/src/translation
mkdir -p backend/services/src/api-gateway

# TESTS - todos los tests dentro de services/tests/
mkdir -p backend/services/tests/unit/membership/validators
mkdir -p backend/services/tests/unit/membership/repository
mkdir -p backend/services/tests/unit/chat/validators
mkdir -p backend/services/tests/unit/translation
mkdir -p backend/services/tests/integration/membership
mkdir -p backend/services/tests/integration/chat
mkdir -p backend/services/tests/integration/translation
mkdir -p backend/services/tests/integration/api-gateway

# Carpetas compartidas
mkdir -p backend/test-helpers
mkdir -p backend/migrations
mkdir -p backend/scripts

echo "✓ Estructura creada"
echo ""

# Mover archivos de configuración raíz
echo "📦 Moviendo configuración..."
[ -f "backendvitest.config.ts" ] && mv backendvitest.config.ts backend/vitest.config.ts && echo "✓ vitest.config.ts"
[ -f "backendpackage.json" ] && mv backendpackage.json backend/package.json && echo "✓ package.json"
[ -f "backend.env.test" ] && mv backend.env.test backend/.env.test && echo "✓ .env.test"
[ -f "backendREADME.md" ] && mv backendREADME.md backend/README.md && echo "✓ README.md"
[ -f "backendTESTS.md" ] && mv backendTESTS.md backend/TESTS.md && echo "✓ TESTS.md"

# Helpers compartidos
echo ""
echo "🛠️  Moviendo test-helpers..."
[ -f "backendtest-helpersdatabase.ts" ] && mv backendtest-helpersdatabase.ts backend/test-helpers/database.ts && echo "✓ test-helpers/database.ts"
[ -f "backendtest-helpersserver.ts" ] && mv backendtest-helpersserver.ts backend/test-helpers/server.ts && echo "✓ test-helpers/server.ts"

# Migrations & Scripts
echo ""
echo "🗄️  Moviendo migrations y scripts..."
[ -f "backendmigrationstest-schema.sql" ] && mv backendmigrationstest-schema.sql backend/migrations/test-schema.sql && echo "✓ migrations/test-schema.sql"
[ -f "backendscriptssetup-test-db.sh" ] && mv backendscriptssetup-test-db.sh backend/scripts/setup-test-db.sh && chmod +x backend/scripts/setup-test-db.sh && echo "✓ scripts/setup-test-db.sh"

# MEMBERSHIP
echo ""
echo "👥 Moviendo tests de MEMBERSHIP..."

# Tests unitarios → services/tests/unit/membership/
[ -f "backendservicesmembershipsrcvalidatorsmemberValidator.unit.test.ts" ] && \
  mv backendservicesmembershipsrcvalidatorsmemberValidator.unit.test.ts backend/services/tests/unit/membership/validators/memberValidator.unit.test.ts && \
  echo "✓ services/tests/unit/membership/validators/memberValidator.unit.test.ts"

[ -f "backendservicesmembershipsrcrepositorymemberRepository.unit.test.ts" ] && \
  mv backendservicesmembershipsrcrepositorymemberRepository.unit.test.ts backend/services/tests/unit/membership/repository/memberRepository.unit.test.ts && \
  echo "✓ services/tests/unit/membership/repository/memberRepository.unit.test.ts"

# Test de integración → services/tests/integration/membership/
[ -f "backendservicesmembershiptestsmembership.integration.test.ts" ] && \
  mv backendservicesmembershiptestsmembership.integration.test.ts backend/services/tests/integration/membership/membership.integration.test.ts && \
  echo "✓ services/tests/integration/membership/membership.integration.test.ts"

# CHAT
echo ""
echo "💬 Moviendo tests de CHAT..."

# Test unitario → services/tests/unit/chat/
[ -f "backendserviceschatsrcvalidatorsmessageValidator.unit.test.ts" ] && \
  mv backendserviceschatsrcvalidatorsmessageValidator.unit.test.ts backend/services/tests/unit/chat/validators/messageValidator.unit.test.ts && \
  echo "✓ services/tests/unit/chat/validators/messageValidator.unit.test.ts"

# Test de integración → services/tests/integration/chat/
[ -f "backendserviceschattestschat.integration.test.ts" ] && \
  mv backendserviceschattestschat.integration.test.ts backend/services/tests/integration/chat/chat.integration.test.ts && \
  echo "✓ services/tests/integration/chat/chat.integration.test.ts"

# TRANSLATION
echo ""
echo "🌐 Moviendo tests de TRANSLATION..."

# Test unitario → services/tests/unit/translation/
[ -f "backendservicestranslationsrctranslationService.unit.test.ts" ] && \
  mv backendservicestranslationsrctranslationService.unit.test.ts backend/services/tests/unit/translation/translationService.unit.test.ts && \
  echo "✓ services/tests/unit/translation/translationService.unit.test.ts"

# Test de integración → services/tests/integration/translation/
[ -f "backendservicestranslationteststranslation.integration.test.ts" ] && \
  mv backendservicestranslationteststranslation.integration.test.ts backend/services/tests/integration/translation/translation.integration.test.ts && \
  echo "✓ services/tests/integration/translation/translation.integration.test.ts"

# API GATEWAY
echo ""
echo "🚪 Moviendo tests de API GATEWAY..."

# Test de integración → services/tests/integration/api-gateway/
[ -f "backendservicesapi-gatewaytestsgateway.integration.test.ts" ] && \
  mv backendservicesapi-gatewaytestsgateway.integration.test.ts backend/services/tests/integration/api-gateway/gateway.integration.test.ts && \
  echo "✓ services/tests/integration/api-gateway/gateway.integration.test.ts"

# Limpiar duplicados
echo ""
echo "🗑️  Limpiando duplicados..."
rm -f backendvitest.config\ *.ts 2>/dev/null
rm -f backendpackage\ *.json 2>/dev/null
rm -f backendREADME\ *.md 2>/dev/null
rm -f backendTESTS\ *.md 2>/dev/null
echo "✓ Duplicados eliminados"

# Mostrar estructura final
echo ""
echo "✅ ¡Reorganización completada!"
echo ""
echo "📂 Estructura final:"
echo ""
echo "backend/"
echo "├── services/"
echo "│   ├── src/                                    ← TODO EL CÓDIGO AQUÍ"
echo "│   │   ├── membership/"
echo "│   │   │   ├── validators/"
echo "│   │   │   │   └── memberValidator.ts"
echo "│   │   │   └── repository/"
echo "│   │   │       └── memberRepository.ts"
echo "│   │   ├── chat/"
echo "│   │   │   └── validators/"
echo "│   │   │       └── messageValidator.ts"
echo "│   │   ├── translation/"
echo "│   │   │   └── translationService.ts"
echo "│   │   └── api-gateway/"
echo "│   │       └── routes.ts"
echo "│   │"
echo "│   └── tests/                                  ← TODOS LOS TESTS AQUÍ"
echo "│       ├── unit/"
echo "│       │   ├── membership/"
echo "│       │   │   ├── validators/"
echo "│       │   │   │   └── memberValidator.unit.test.ts"
echo "│       │   │   └── repository/"
echo "│       │   │       └── memberRepository.unit.test.ts"
echo "│       │   ├── chat/"
echo "│       │   │   └── validators/"
echo "│       │   │       └── messageValidator.unit.test.ts"
echo "│       │   └── translation/"
echo "│       │       └── translationService.unit.test.ts"
echo "│       │"
echo "│       └── integration/"
echo "│           ├── membership/"
echo "│           │   └── membership.integration.test.ts"
echo "│           ├── chat/"
echo "│           │   └── chat.integration.test.ts"
echo "│           ├── translation/"
echo "│           │   └── translation.integration.test.ts"
echo "│           └── api-gateway/"
echo "│               └── gateway.integration.test.ts"
echo "│"
echo "├── test-helpers/          ← Helpers compartidos"
echo "├── migrations/            ← SQL schemas"
echo "├── scripts/               ← Setup scripts"
echo "├── vitest.config.ts"
echo "├── package.json"
echo "└── .env.test"
echo ""

# Verificar archivos
echo "🔍 Tests encontrados en services/tests/:"
echo ""
echo "UNIT TESTS:"
find backend/services/tests/unit -name "*.test.ts" 2>/dev/null | sort | while read file; do
  echo "  ✓ ${file#backend/services/tests/}"
done
echo ""
echo "INTEGRATION TESTS:"
find backend/services/tests/integration -name "*.test.ts" 2>/dev/null | sort | while read file; do
  echo "  ✓ ${file#backend/services/tests/}"
done

echo ""
echo "🚀 Comandos disponibles:"
echo "   cd backend"
echo "   npm install"
echo "   npm run test:unit          # Tests unitarios (services/tests/unit/)"
echo "   npm run test:integration   # Tests de integración (services/tests/integration/)"
echo "   npm test                   # Todos los tests"
echo ""
