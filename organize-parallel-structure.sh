#!/bin/bash

# Script para reorganizar con estructura paralela src/ y tests/

echo "🔧 Reorganizando con estructura src/ y tests/ paralela..."
echo ""

# Crear estructura paralela para cada servicio
echo "📁 Creando estructura de directorios..."

# Membership
mkdir -p backend/services/membership/src/validators
mkdir -p backend/services/membership/src/repository
mkdir -p backend/services/membership/tests/unit/validators
mkdir -p backend/services/membership/tests/unit/repository
mkdir -p backend/services/membership/tests/integration

# Chat
mkdir -p backend/services/chat/src/validators
mkdir -p backend/services/chat/tests/unit/validators
mkdir -p backend/services/chat/tests/integration

# Translation
mkdir -p backend/services/translation/src
mkdir -p backend/services/translation/tests/unit
mkdir -p backend/services/translation/tests/integration

# API Gateway
mkdir -p backend/services/api-gateway/src
mkdir -p backend/services/api-gateway/tests/integration

# Helpers, migrations, scripts
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

# Helpers
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

# Tests unitarios de membership
[ -f "backendservicesmembershipsrcvalidatorsmemberValidator.unit.test.ts" ] && \
  mv backendservicesmembershipsrcvalidatorsmemberValidator.unit.test.ts backend/services/membership/tests/unit/validators/memberValidator.unit.test.ts && \
  echo "✓ membership/tests/unit/validators/memberValidator.unit.test.ts"

[ -f "backendservicesmembershipsrcrepositorymemberRepository.unit.test.ts" ] && \
  mv backendservicesmembershipsrcrepositorymemberRepository.unit.test.ts backend/services/membership/tests/unit/repository/memberRepository.unit.test.ts && \
  echo "✓ membership/tests/unit/repository/memberRepository.unit.test.ts"

# Test de integración de membership
[ -f "backendservicesmembershiptestsmembership.integration.test.ts" ] && \
  mv backendservicesmembershiptestsmembership.integration.test.ts backend/services/membership/tests/integration/membership.integration.test.ts && \
  echo "✓ membership/tests/integration/membership.integration.test.ts"

# CHAT
echo ""
echo "💬 Moviendo tests de CHAT..."

# Tests unitarios de chat
[ -f "backendserviceschatsrcvalidatorsmessageValidator.unit.test.ts" ] && \
  mv backendserviceschatsrcvalidatorsmessageValidator.unit.test.ts backend/services/chat/tests/unit/validators/messageValidator.unit.test.ts && \
  echo "✓ chat/tests/unit/validators/messageValidator.unit.test.ts"

# Test de integración de chat
[ -f "backendserviceschattestschat.integration.test.ts" ] && \
  mv backendserviceschattestschat.integration.test.ts backend/services/chat/tests/integration/chat.integration.test.ts && \
  echo "✓ chat/tests/integration/chat.integration.test.ts"

# TRANSLATION
echo ""
echo "🌐 Moviendo tests de TRANSLATION..."

# Test unitario de translation
[ -f "backendservicestranslationsrctranslationService.unit.test.ts" ] && \
  mv backendservicestranslationsrctranslationService.unit.test.ts backend/services/translation/tests/unit/translationService.unit.test.ts && \
  echo "✓ translation/tests/unit/translationService.unit.test.ts"

# Test de integración de translation
[ -f "backendservicestranslationteststranslation.integration.test.ts" ] && \
  mv backendservicestranslationteststranslation.integration.test.ts backend/services/translation/tests/integration/translation.integration.test.ts && \
  echo "✓ translation/tests/integration/translation.integration.test.ts"

# API GATEWAY
echo ""
echo "🚪 Moviendo tests de API GATEWAY..."

# Test de integración de gateway
[ -f "backendservicesapi-gatewaytestsgateway.integration.test.ts" ] && \
  mv backendservicesapi-gatewaytestsgateway.integration.test.ts backend/services/api-gateway/tests/integration/gateway.integration.test.ts && \
  echo "✓ api-gateway/tests/integration/gateway.integration.test.ts"

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
echo "📂 Estructura final (src/ y tests/ paralelas):"
echo ""
echo "backend/"
echo "├── services/"
echo "│   ├── membership/"
echo "│   │   ├── src/                         ← Código fuente"
echo "│   │   │   ├── validators/"
echo "│   │   │   │   └── memberValidator.ts"
echo "│   │   │   └── repository/"
echo "│   │   │       └── memberRepository.ts"
echo "│   │   └── tests/                       ← Tests (misma estructura)"
echo "│   │       ├── unit/"
echo "│   │       │   ├── validators/"
echo "│   │       │   │   └── memberValidator.unit.test.ts"
echo "│   │       │   └── repository/"
echo "│   │       │       └── memberRepository.unit.test.ts"
echo "│   │       └── integration/"
echo "│   │           └── membership.integration.test.ts"
echo "│   │"
echo "│   ├── chat/"
echo "│   │   ├── src/"
echo "│   │   │   └── validators/"
echo "│   │   │       └── messageValidator.ts"
echo "│   │   └── tests/"
echo "│   │       ├── unit/"
echo "│   │       │   └── validators/"
echo "│   │       │       └── messageValidator.unit.test.ts"
echo "│   │       └── integration/"
echo "│   │           └── chat.integration.test.ts"
echo "│   │"
echo "│   ├── translation/"
echo "│   │   ├── src/"
echo "│   │   │   └── translationService.ts"
echo "│   │   └── tests/"
echo "│   │       ├── unit/"
echo "│   │       │   └── translationService.unit.test.ts"
echo "│   │       └── integration/"
echo "│   │           └── translation.integration.test.ts"
echo "│   │"
echo "│   └── api-gateway/"
echo "│       ├── src/"
echo "│       └── tests/"
echo "│           └── integration/"
echo "│               └── gateway.integration.test.ts"
echo "│"
echo "├── test-helpers/          ← Helpers compartidos"
echo "├── migrations/            ← SQL schemas"
echo "└── scripts/               ← Setup scripts"
echo ""

# Verificar archivos
echo "🔍 Tests encontrados:"
echo ""
find backend/services -name "*.test.ts" 2>/dev/null | sort | while read file; do
  echo "  ✓ ${file#backend/services/}"
done

echo ""
echo "🚀 Comandos disponibles:"
echo "   cd backend"
echo "   npm install"
echo "   npm run test:unit          # Tests unitarios"
echo "   npm run test:integration   # Tests de integración"
echo "   npm test                   # Todos los tests"
echo ""
