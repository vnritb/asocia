# FAQ - Sistema de Autenticación

## 🤔 Preguntas Frecuentes

### Generales

#### ¿Qué es este sistema?
Un sistema completo de autenticación con login y registro para la app Asocia. Incluye:
- Microservicio de autenticación (Node.js)
- Pantallas de login y registro (SwiftUI)
- Gestión de tokens JWT
- Almacenamiento seguro en Keychain
- Persistencia de sesión

#### ¿Es seguro?
Para desarrollo local: **Sí, es seguro**.  
Para producción: **Necesita mejoras** (ver sección de seguridad).

#### ¿Funciona sin internet?
No para login/registro inicial. Sí para navegar una vez autenticado (datos en SwiftData local).

---

### Instalación y Configuración

#### ¿Qué necesito instalar?
- Node.js (v14 o superior)
- npm (viene con Node.js)
- Xcode (para la app iOS)

#### ¿Cómo instalo las dependencias?
```bash
cd backend/auth-service
npm install
```

#### ¿Cómo inicio el servidor?
```bash
npm run dev  # Modo desarrollo con auto-reload
# o
npm start    # Modo producción
```

#### ¿En qué puerto corre el servicio?
Puerto 4001 por defecto. Cambiable en `.env`:
```env
PORT=4001
```

#### ¿Cómo cambio la URL en la app iOS?
En `AppEnvironment.swift`:
```swift
case .local:
    return URL(string: "http://localhost:4001")!
```

---

### Uso

#### ¿Cómo registro un usuario nuevo?
1. Ejecutar el microservicio
2. Ejecutar la app
3. En LoginView, pulsar "Crear Cuenta"
4. Completar formulario
5. Pulsar "Enviar"

#### ¿Cómo hago login?
1. En LoginView, introducir email y password
2. Pulsar "Iniciar Sesión"

#### ¿Dónde se guarda el token?
En el Keychain del dispositivo iOS (encriptado automáticamente por el sistema).

#### ¿Dónde se guardan los datos del usuario?
En SwiftData (base de datos local SQLite en el dispositivo).

#### ¿Cuánto dura la sesión?
30 días por defecto. Configurable en el servidor:
```javascript
jwt.sign({ userId, email }, JWT_SECRET, { expiresIn: '30d' })
```

#### ¿Qué pasa si cierro la app?
La sesión persiste. Al volver a abrir, acceso automático.

#### ¿Qué pasa si desinstalo la app?
Se pierden todos los datos locales (token, usuario). Necesitas volver a hacer login.

---

### Errores Comunes

#### Error: "No hay conexión con el servidor"
**Causas:**
- El microservicio no está corriendo
- URL incorrecta en AppEnvironment.swift
- Firewall bloqueando puerto 4001

**Solución:**
```bash
# Verificar que el servicio esté corriendo
curl http://localhost:4001/health

# Si no responde, iniciarlo
cd backend/auth-service
npm run dev
```

#### Error: "Este email ya está registrado"
**Causa:** El email ya existe en la base de datos.

**Solución:**
- Usar otro email, O
- Hacer login con ese email, O
- Reiniciar el microservicio (datos en memoria se pierden)

#### Error: "Email o contraseña incorrectos"
**Causas:**
- Password equivocada
- Usuario no existe
- Typo en el email

**Solución:**
- Verificar credenciales
- Probar con "Crear Cuenta" si es nuevo usuario

#### Error: "Token inválido o expirado"
**Causas:**
- Token expiró (>30 días)
- Servidor reiniciado (JWT_SECRET cambió)
- Token corrupto

**Solución:**
- Volver a hacer login para obtener nuevo token
- Limpiar Keychain y volver a autenticar

#### Error: "Cannot connect to localhost"
**Causa:** Usando dispositivo físico en lugar de simulador.

**Solución:**
Cambiar `localhost` por IP de tu Mac:
```swift
case .local:
    return URL(string: "http://192.168.1.XXX:4001")!
```

Para encontrar tu IP:
```bash
# macOS
ipconfig getifaddr en0

# o ver en: Preferencias → Red → WiFi
```

#### Error: "La contraseña debe tener al menos 6 caracteres"
**Causa:** Password muy corta.

**Solución:** Usar password de 6+ caracteres.

#### App se congela al hacer login/registro
**Causas:**
- Servidor no responde
- URL incorrecta
- Timeout

**Solución:**
- Verificar logs del servidor
- Verificar URL en AppEnvironment
- Verificar conexión de red

---

### Desarrollo

#### ¿Cómo pruebo sin la app?
Usando curl:
```bash
# Registro
curl -X POST http://localhost:4001/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "test@test.com",
    "password": "test123",
    "firstName": "Test",
    "firstSurname": "User"
  }'

# Login
curl -X POST http://localhost:4001/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@test.com",
    "password": "test123"
  }'
```

O ejecutar el script de pruebas:
```bash
cd backend/auth-service
chmod +x test.sh
./test.sh
```

#### ¿Cómo veo los logs?
**Servidor:**
```bash
# En la terminal donde corre npm run dev
# Verás algo como:
[2026-07-26T10:30:00.000Z] POST /v1/auth/register
✅ Usuario registrado: test@test.com
```

**App iOS:**
En Xcode Console (Cmd + Shift + Y):
```
🔐 [AUTH] register - email: test@test.com
   🌐 [POST] http://localhost:4001/v1/auth/register
   ✅ Response: 201 (245ms)
   ✅ Registro exitoso - Token guardado
```

#### ¿Cómo reinicio la base de datos?
```bash
# Detener el servidor (Ctrl + C)
# Volver a iniciar
npm run dev

# Los datos en memoria se pierden
```

#### ¿Cómo limpio el Keychain en la app?
Opción 1: Desinstalar y reinstalar la app
Opción 2: Añadir botón temporal:
```swift
// En LoginView
Button("Limpiar Keychain") {
    KeychainStore.deleteToken()
}
```

#### ¿Cómo veo el contenido del token JWT?
```swift
// En código Swift:
if let token = KeychainStore.loadToken() {
    print("Token: \(token)")
}

// Copiar token y pegar en: https://jwt.io
```

#### ¿Cómo cambio el tiempo de expiración?
En `backend/auth-service/index.js`:
```javascript
// Cambiar de 30d a 7d:
const token = jwt.sign(
  { userId, email }, 
  JWT_SECRET, 
  { expiresIn: '7d' }  // <-- aquí
);
```

---

### Base de Datos

#### ¿Dónde se guardan los usuarios?
Actualmente en memoria (Map). Se pierden al reiniciar el servidor.

#### ¿Cómo migro a base de datos real?
Ver ejemplo con PostgreSQL:

```javascript
// Instalar driver
npm install pg

// Cambiar en index.js
const { Pool } = require('pg');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Reemplazar Map por queries SQL
app.post('/v1/auth/register', async (req, res) => {
  const { id, email, passwordHash, ... } = req.body;
  
  await pool.query(
    'INSERT INTO users (id, email, password_hash, ...) VALUES ($1, $2, $3, ...)',
    [id, email, passwordHash, ...]
  );
  
  // ...
});
```

#### ¿Qué base de datos recomiendan?
Para producción:
- **PostgreSQL**: Robusto, relacional, open-source
- **MongoDB**: NoSQL, flexible, fácil de escalar
- **MySQL**: Popular, estable, buena documentación

Para desarrollo:
- **SQLite**: Simple, local, sin servidor
- **En memoria**: Lo más simple, pero no persiste

---

### Seguridad

#### ¿Es seguro el password?
Sí:
- Nunca se guarda en texto plano
- Se hashea con bcrypt en el servidor (salt rounds: 10)
- Se hashea con SHA256 localmente en iOS (solo para storage, no para comparación)

#### ¿Es seguro el token?
Sí:
- Firmado con JWT_SECRET
- Con expiración (30 días)
- Guardado en Keychain (encriptado por iOS)

**PERO** para producción:
- [ ] Cambiar JWT_SECRET por valor aleatorio
- [ ] Usar HTTPS (no HTTP)
- [ ] Implementar refresh tokens
- [ ] Rate limiting
- [ ] 2FA

#### ¿Qué es JWT_SECRET?
Clave secreta para firmar tokens JWT. **DEBE** ser:
- Aleatorio
- Largo (32+ caracteres)
- Único por entorno
- Nunca en el código fuente

Generar uno nuevo:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Guardarlo en `.env`:
```env
JWT_SECRET=a1b2c3d4e5f6...
```

#### ¿Qué pasa si alguien roba el JWT_SECRET?
Podría generar tokens válidos para cualquier usuario. **Muy peligroso**.

Mitigación:
- No commitear JWT_SECRET al repo
- Rotar regularmente en producción
- Usar gestores de secretos (AWS Secrets Manager, etc.)

#### ¿Debo usar HTTPS?
**SÍ** en producción. Siempre.

En desarrollo local (localhost) HTTP está bien.

#### ¿Qué es bcrypt?
Algoritmo de hash diseñado para passwords:
- Slow (dificulta ataques de fuerza bruta)
- Con salt (previene rainbow tables)
- Configurable (salt rounds)

#### ¿Por qué también SHA256 en iOS?
Para almacenamiento local únicamente. La verificación real ocurre en el servidor con bcrypt.

---

### Producción

#### ¿Está listo para producción?
**No directamente**. Necesita:
- [ ] Base de datos real (PostgreSQL/MongoDB)
- [ ] HTTPS obligatorio
- [ ] JWT_SECRET seguro
- [ ] Rate limiting
- [ ] Logging robusto
- [ ] Monitoring
- [ ] Backups
- [ ] Validación de email
- [ ] Recuperación de contraseña

#### ¿Cómo despliego el backend?
Opciones:
- **Railway**: Simple, $5/mes, buen para empezar
- **Render**: Free tier disponible, fácil setup
- **Heroku**: Clásico, ahora de pago
- **DigitalOcean**: Más control, $5/mes
- **AWS EC2**: Escalable, más complejo

#### ¿Cómo despliego la app iOS?
1. Cambiar scheme a "Asocia (Production)"
2. Product → Archive
3. Distribute → App Store Connect
4. Submit for Review

#### ¿Dónde pongo la URL de producción?
En `AppEnvironment.swift`:
```swift
case .production:
    return URL(string: "https://api.asocia.com")!
```

---

### Otros

#### ¿Puedo tener múltiples usuarios en un dispositivo?
No en la implementación actual. SwiftData guarda un solo `Member`.

Para soportar múltiples cuentas necesitarías:
- Tabla de cuentas en SwiftData
- Selector de cuenta al iniciar
- Token por cuenta

#### ¿Cómo implemento "Olvidé mi contraseña"?
1. Endpoint en servidor: `POST /forgot-password`
2. Generar token temporal (6 dígitos)
3. Enviar email con token
4. Endpoint: `POST /reset-password` con token
5. Pantalla en app para introducir token y nueva password

#### ¿Cómo implemento verificación de email?
1. Al registrar, enviar email con link
2. Link contiene token: `https://app.com/verify?token=abc123`
3. Usuario hace clic
4. App llama: `POST /verify-email` con token
5. Servidor marca usuario como verificado

#### ¿Cómo implemento 2FA?
1. Usuario activa 2FA en ajustes
2. Servidor genera secret (TOTP)
3. Mostrar QR code (Google Authenticator)
4. Al login, pedir código además de password
5. Verificar código con biblioteca TOTP

#### ¿Puedo usar Sign in with Apple?
Sí, Apple lo requiere si ofreces otros métodos sociales.

Ver: [Sign in with Apple Documentation](https://developer.apple.com/documentation/sign_in_with_apple)

#### ¿Funciona con Face ID / Touch ID?
No directamente implementado, pero se puede añadir:

```swift
import LocalAuthentication

func authenticateWithBiometrics() {
    let context = LAContext()
    var error: NSError?
    
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, 
                              localizedReason: "Autenticarse") { success, error in
            if success {
                // Usar token guardado
            }
        }
    }
}
```

---

## 📚 Recursos Adicionales

- [JWT.io](https://jwt.io) - Decodificar tokens JWT
- [bcrypt explained](https://github.com/kelektiv/node.bcrypt.js#a-note-on-rounds) - Entender bcrypt
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html) - Best practices
- [Apple Keychain Services](https://developer.apple.com/documentation/security/keychain_services) - Documentación Keychain
- [Express.js Documentation](https://expressjs.com/) - Framework backend
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata) - Persistencia iOS

---

## 🆘 Soporte

Si tienes problemas:

1. **Revisa esta FAQ**
2. **Lee los logs** (servidor y app)
3. **Ejecuta script de pruebas** (`./test.sh`)
4. **Verifica configuración** (URLs, puertos)
5. **Reinicia todo** (servidor + app)

Si sigue sin funcionar:
- Abre un issue en GitHub
- Incluye logs completos
- Describe pasos para reproducir
