# Instrucciones de configuración del microservicio de autenticación

## 1. Instalación del microservicio

### Navegar al directorio del servicio de autenticación:
```bash
cd backend/auth-service
```

### Instalar dependencias:
```bash
npm install
```

## 2. Ejecutar el servicio

### Modo desarrollo (con auto-reload):
```bash
npm run dev
```

### Modo producción:
```bash
npm start
```

El servicio estará disponible en `http://localhost:4001`

## 3. Verificar que funciona

### Health check:
```bash
curl http://localhost:4001/health
```

Deberías ver:
```json
{
  "status": "ok",
  "service": "auth-service",
  "users": 0,
  "timestamp": "2026-07-26T..."
}
```

## 4. Probar el registro

```bash
curl -X POST http://localhost:4001/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "prueba@test.com",
    "password": "test123",
    "firstName": "Usuario",
    "firstSurname": "Prueba"
  }'
```

## 5. Probar el login

```bash
curl -X POST http://localhost:4001/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "prueba@test.com",
    "password": "test123"
  }'
```

## 6. Configurar la app iOS

Asegúrate de que en tu `AppEnvironment.swift` la URL local apunte a:
- API Gateway: `http://localhost:4000` (si existe)
- Auth Service directo: `http://localhost:4001`

Si usas el simulador de iOS, puedes usar `localhost`.
Si usas un dispositivo físico, necesitas usar la IP de tu Mac:
```swift
case .local:
    return URL(string: "http://192.168.1.XXX:4001")!
```

## 7. Integración con otros microservicios

Si tienes un API Gateway, deberías agregar un proxy en ese gateway:

```javascript
// En tu API Gateway
app.use('/v1/auth', createProxyMiddleware({
  target: 'http://localhost:4001',
  changeOrigin: true
}));
```

Así todas las llamadas a `/v1/auth/*` se redirigen al servicio de autenticación.

## Flujo completo de autenticación

1. **Usuario nuevo:** 
   - Abre la app → Ve LoginView
   - Pulsa "Crear Cuenta" → Ve SignupView
   - Completa formulario con email, password, nombre
   - App llama a `POST /v1/auth/register`
   - Backend crea usuario y devuelve token JWT
   - App guarda token en Keychain y usuario en SwiftData
   - Usuario ve su perfil (estado: pendingApproval)

2. **Usuario existente:**
   - Abre la app → Ve LoginView
   - Introduce email y password
   - App llama a `POST /v1/auth/login`
   - Backend verifica credenciales y devuelve token JWT
   - App guarda token y carga datos del usuario
   - Usuario ve su perfil o tabs según estado

3. **Siguiente inicio:**
   - App verifica token en Keychain
   - Si existe y hay usuario en SwiftData → acceso directo
   - Si no existe → muestra LoginView

## Seguridad

⚠️ **Para producción:**
1. Cambiar `JWT_SECRET` en el servidor
2. Usar HTTPS
3. Implementar refresh tokens
4. Añadir rate limiting
5. Usar base de datos real (PostgreSQL/MongoDB)
6. Validar formato de emails
7. Implementar recuperación de contraseña

## Troubleshooting

### Error de conexión desde la app
- Verifica que el servicio esté ejecutándose: `curl http://localhost:4001/health`
- Verifica la URL en `AppEnvironment.swift`
- Si usas dispositivo físico, usa la IP de tu Mac en lugar de localhost

### Error "Email ya registrado"
- Es correcto, significa que el usuario ya existe
- Prueba con otro email o usa login en lugar de registro

### Error "Token inválido"
- El token puede haber expirado (30 días por defecto)
- Vuelve a hacer login para obtener un nuevo token
