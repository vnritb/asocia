#!/bin/bash
# Ejecuta los tests unitarios y, contra los servicios reales (docker
# compose), los de integración. Ver backend/README.md.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
cd "$BACKEND_DIR"

echo "== Tests unitarios =="
npm run test:unit

echo
echo "== Levantando servicios (docker compose) para los tests de integración =="
docker compose up -d --wait

echo
echo "== Tests de integración =="
npm run test:integration
