const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 4001;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const SALT_ROUNDS = 10;

// Middleware
app.use(cors());
app.use(express.json());

// Base de datos en memoria (reemplazar con base de datos real)
const users = new Map();

// Logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// MARK: - Rutas de autenticación

/**
 * POST /v1/auth/register
 * Registra un nuevo usuario
 * 
 * Body:
 * {
 *   "id": "uuid",
 *   "email": "user@example.com",
 *   "password": "password123",
 *   "firstName": "Juan",
 *   "firstSurname": "Pérez"
 * }
 * 
 * Response:
 * {
 *   "token": "jwt-token",
 *   "member": { ... }
 * }
 */
app.post('/v1/auth/register', async (req, res) => {
  try {
    const { id, email, password, firstName, firstSurname } = req.body;

    // Validaciones
    if (!id || !email || !password || !firstName || !firstSurname) {
      return res.status(400).json({ 
        error: 'Faltan campos obligatorios: id, email, password, firstName, firstSurname' 
      });
    }

    if (password.length < 6) {
      return res.status(400).json({ 
        error: 'La contraseña debe tener al menos 6 caracteres' 
      });
    }

    // Verificar si el email ya está registrado
    const existingUser = Array.from(users.values()).find(u => u.email === email);
    if (existingUser) {
      return res.status(409).json({ 
        error: 'Este email ya está registrado' 
      });
    }

    // Encriptar contraseña
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    // Crear usuario
    const user = {
      id,
      email,
      passwordHash,
      firstName,
      firstSurname,
      createdAt: new Date().toISOString()
    };

    users.set(id, user);

    // Generar token JWT
    const token = jwt.sign({ userId: id, email }, JWT_SECRET, { expiresIn: '30d' });

    // Crear MemberDTO
    const member = {
      id,
      firstName,
      firstSurname,
      secondSurname: '',
      email,
      secondaryEmail: '',
      mobilePhone: '',
      landlinePhone: '',
      address: '',
      postalCode: '',
      city: '',
      province: '',
      birthDate: null,
      entryYear: '',
      exitYear: '',
      promotion: '',
      profession: '',
      workplace: '',
      iban: '',
      facebookUsername: '',
      instagramUsername: '',
      xUsername: '',
      tiktokUsername: '',
      photoBase64: null,
      isSearchable: false,
      associationID: null,
      isVisibleToOtherAssociations: false,
      membershipStatus: 'pendingApproval',
      joinDate: new Date().toISOString(),
      rejectionReason: null,
      updatedAt: new Date().toISOString()
    };

    console.log(`✅ Usuario registrado: ${email}`);
    
    res.status(201).json({ token, member });
  } catch (error) {
    console.error('Error en registro:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

/**
 * POST /v1/auth/login
 * Autentica un usuario existente
 * 
 * Body:
 * {
 *   "email": "user@example.com",
 *   "password": "password123"
 * }
 * 
 * Response:
 * {
 *   "token": "jwt-token",
 *   "member": { ... }
 * }
 */
app.post('/v1/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validaciones
    if (!email || !password) {
      return res.status(400).json({ 
        error: 'Email y contraseña son obligatorios' 
      });
    }

    // Buscar usuario por email
    const user = Array.from(users.values()).find(u => u.email === email);
    if (!user) {
      return res.status(401).json({ 
        error: 'Email o contraseña incorrectos' 
      });
    }

    // Verificar contraseña
    const passwordMatch = await bcrypt.compare(password, user.passwordHash);
    if (!passwordMatch) {
      return res.status(401).json({ 
        error: 'Email o contraseña incorrectos' 
      });
    }

    // Generar token JWT
    const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '30d' });

    // Crear MemberDTO (en producción, obtener del servicio de members)
    const member = {
      id: user.id,
      firstName: user.firstName,
      firstSurname: user.firstSurname,
      secondSurname: '',
      email: user.email,
      secondaryEmail: '',
      mobilePhone: '',
      landlinePhone: '',
      address: '',
      postalCode: '',
      city: '',
      province: '',
      birthDate: null,
      entryYear: '',
      exitYear: '',
      promotion: '',
      profession: '',
      workplace: '',
      iban: '',
      facebookUsername: '',
      instagramUsername: '',
      xUsername: '',
      tiktokUsername: '',
      photoBase64: null,
      isSearchable: false,
      associationID: null,
      isVisibleToOtherAssociations: false,
      membershipStatus: 'active', // En producción, obtener del backend
      joinDate: user.createdAt,
      rejectionReason: null,
      updatedAt: new Date().toISOString()
    };

    console.log(`✅ Login exitoso: ${email}`);
    
    res.json({ token, member });
  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

/**
 * Middleware para verificar token JWT
 */
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Token no proporcionado' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Token inválido o expirado' });
    }
    req.user = user;
    next();
  });
}

/**
 * GET /v1/auth/verify
 * Verifica si un token es válido
 */
app.get('/v1/auth/verify', authenticateToken, (req, res) => {
  res.json({ 
    valid: true, 
    userId: req.user.userId,
    email: req.user.email 
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'auth-service',
    users: users.size,
    timestamp: new Date().toISOString() 
  });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🔐 Auth Service escuchando en puerto ${PORT}`);
  console.log(`📝 Endpoints disponibles:`);
  console.log(`   POST http://localhost:${PORT}/v1/auth/register`);
  console.log(`   POST http://localhost:${PORT}/v1/auth/login`);
  console.log(`   GET  http://localhost:${PORT}/v1/auth/verify`);
  console.log(`   GET  http://localhost:${PORT}/health`);
});

// Exportar para testing (opcional)
module.exports = { app, authenticateToken };
