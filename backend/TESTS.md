# Estructura de Tests del Backend

Todos los archivos de tests están correctamente organizados en la carpeta `backend/`.

## ✅ Archivos creados:

```
backend/
├── vitest.config.ts                          # Configuración de Vitest
├── package.json                               # Scripts de test
├── .env.test                                  # Variables de entorno para tests
├── README.md                                  # Documentación completa
│
├── test-helpers/                              # Utilidades compartidas
│   ├── database.ts                            # Helpers para BD y generación de datos
│   └── server.ts                              # Mocks de servidor
│
├── migrations/                                # Scripts SQL
│   └── test-schema.sql                        # Schema de BD de test
│
├── scripts/                                   # Scripts de utilidad
│   └── setup-test-db.sh                       # Setup automático de BD
│
└── services/
    ├── membership/
    │   ├── src/
    │   │   ├── validators/
    │   │   │   └── memberValidator.unit.test.ts      # Tests unitarios de validación
    │   │   └── repository/
    │   │       └── memberRepository.unit.test.ts     # Tests unitarios de repositorio
    │   └── tests/
    │       └── membership.integration.test.ts        # Tests de integración HTTP
    │
    ├── chat/
    │   ├── src/
    │   │   └── validators/
    │   │       └── messageValidator.unit.test.ts     # Tests unitarios de validación
    │   └── tests/
    │       └── chat.integration.test.ts              # Tests de integración HTTP
    │
    ├── translation/
    │   ├── src/
    │   │   └── translationService.unit.test.ts       # Tests unitarios
    │   └── tests/
    │       └── translation.integration.test.ts       # Tests de integración HTTP
    │
    └── api-gateway/
        └── tests/
            └── gateway.integration.test.ts            # Tests de integración del gateway
```

## 📊 Resumen:

- **16 archivos** de tests y configuración
- **Tests unitarios**: 4 archivos (lógica de negocio)
- **Tests de integración**: 4 archivos (endpoints HTTP)
- **Helpers y configuración**: 8 archivos

## 🚀 Para ejecutar:

```bash
cd backend

# Instalar dependencias
npm install

# Tests unitarios (no requiere servicios)
npm run test:unit

# Tests de integración (requiere servicios corriendo)
docker compose up -d
npm run test:integration

# Todos los tests
npm test
```

## ✅ Todo está listo!

Todos los archivos están correctamente ubicados en `backend/` y organizados según las mejores prácticas:
- Tests unitarios junto al código que testean (en `src/`)
- Tests de integración en carpetas `tests/` de cada servicio
- Helpers compartidos en `test-helpers/`
- Configuración en la raíz de `backend/`
