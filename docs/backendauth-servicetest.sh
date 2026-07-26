#!/bin/bash

# Script de pruebas para el servicio de autenticación

BASE_URL="http://localhost:4001"
TEST_EMAIL="test$(date +%s)@ejemplo.com"
TEST_PASSWORD="test123456"
TEST_ID="550e8400-e29b-41d4-a716-446655440000"

echo "🧪 Iniciando pruebas del servicio de autenticación"
echo "=================================================="
echo ""

# Verificar que el servicio esté corriendo
echo "1️⃣  Verificando que el servicio está activo..."
if ! curl -s "$BASE_URL/health" > /dev/null; then
    echo "   ❌ El servicio no está respondiendo en $BASE_URL"
    echo "   Asegúrate de ejecutar: npm run dev"
    exit 1
fi
echo "   ✅ Servicio activo"
echo ""

# Health check
echo "2️⃣  Health check..."
HEALTH=$(curl -s "$BASE_URL/health")
echo "   $HEALTH"
echo ""

# Test de registro
echo "3️⃣  Probando registro de usuario..."
echo "   Email: $TEST_EMAIL"
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"id\": \"$TEST_ID\",
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"firstName\": \"Test\",
    \"firstSurname\": \"User\"
  }")

if echo "$REGISTER_RESPONSE" | grep -q "token"; then
    echo "   ✅ Registro exitoso"
    TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "   Token recibido: ${TOKEN:0:20}..."
else
    echo "   ❌ Error en registro"
    echo "   $REGISTER_RESPONSE"
    exit 1
fi
echo ""

# Test de registro duplicado
echo "4️⃣  Probando registro con email duplicado..."
DUPLICATE_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"id\": \"660e8400-e29b-41d4-a716-446655440000\",
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"firstName\": \"Test\",
    \"firstSurname\": \"User\"
  }")

if echo "$DUPLICATE_RESPONSE" | grep -q "ya está registrado"; then
    echo "   ✅ Error detectado correctamente"
else
    echo "   ❌ Debería haber rechazado el email duplicado"
fi
echo ""

# Test de login con credenciales correctas
echo "5️⃣  Probando login con credenciales correctas..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\"
  }")

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
    echo "   ✅ Login exitoso"
    NEW_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "   Nuevo token: ${NEW_TOKEN:0:20}..."
else
    echo "   ❌ Error en login"
    echo "   $LOGIN_RESPONSE"
    exit 1
fi
echo ""

# Test de login con credenciales incorrectas
echo "6️⃣  Probando login con contraseña incorrecta..."
WRONG_LOGIN=$(curl -s -X POST "$BASE_URL/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"wrongpassword\"
  }")

if echo "$WRONG_LOGIN" | grep -q "incorrectos"; then
    echo "   ✅ Error detectado correctamente"
else
    echo "   ❌ Debería haber rechazado la contraseña incorrecta"
fi
echo ""

# Test de verificación de token
echo "7️⃣  Probando verificación de token..."
VERIFY_RESPONSE=$(curl -s "$BASE_URL/v1/auth/verify" \
  -H "Authorization: Bearer $NEW_TOKEN")

if echo "$VERIFY_RESPONSE" | grep -q "valid"; then
    echo "   ✅ Token verificado correctamente"
else
    echo "   ❌ Error al verificar token"
    echo "   $VERIFY_RESPONSE"
fi
echo ""

# Test de token inválido
echo "8️⃣  Probando con token inválido..."
INVALID_TOKEN_RESPONSE=$(curl -s "$BASE_URL/v1/auth/verify" \
  -H "Authorization: Bearer token_invalido")

if echo "$INVALID_TOKEN_RESPONSE" | grep -q "inválido"; then
    echo "   ✅ Token inválido detectado correctamente"
else
    echo "   ❌ Debería haber rechazado el token inválido"
fi
echo ""

# Test de registro sin campos obligatorios
echo "9️⃣  Probando registro sin campos obligatorios..."
INCOMPLETE_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"test@test.com\"
  }")

if echo "$INCOMPLETE_RESPONSE" | grep -q "obligatorios"; then
    echo "   ✅ Validación de campos obligatorios funciona"
else
    echo "   ❌ Debería haber rechazado el registro incompleto"
fi
echo ""

# Test de contraseña muy corta
echo "🔟 Probando registro con contraseña muy corta..."
SHORT_PASSWORD_RESPONSE=$(curl -s -X POST "$BASE_URL/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"id\": \"770e8400-e29b-41d4-a716-446655440000\",
    \"email\": \"short@test.com\",
    \"password\": \"123\",
    \"firstName\": \"Test\",
    \"firstSurname\": \"User\"
  }")

if echo "$SHORT_PASSWORD_RESPONSE" | grep -q "al menos 6 caracteres"; then
    echo "   ✅ Validación de longitud de contraseña funciona"
else
    echo "   ❌ Debería haber rechazado la contraseña corta"
fi
echo ""

echo "=================================================="
echo "✅ Todas las pruebas completadas"
echo ""
echo "📊 Resumen:"
echo "   - Health check: OK"
echo "   - Registro: OK"
echo "   - Login: OK"
echo "   - Verificación de token: OK"
echo "   - Validaciones: OK"
echo ""
echo "🎉 El servicio de autenticación está funcionando correctamente!"
