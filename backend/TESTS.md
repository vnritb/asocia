# Estructura de tests del backend

Los tests del backend ahora viven fuera de la carpeta `backend`, en la raíz del proyecto, bajo `backendTests/`, mientras que el código de los servicios sigue en `backend/services/`.

## ✅ Estructura actual

```text
backend/
├── services/
│   ├── api-gateway/
│   ├── chat-service/
│   └── membership-service/
├── package.json
├── vitest.config.ts
├── .env.test
├── README.md
└── TESTS.md

backendTests/
├── services/
│   ├── api-gateway/
│   │   └── src/
│   │       └── gateway.integration.test.ts
│   ├── chat-service/
│   │   └── src/
│   │       ├── chat.integration.test.ts
│   │       └── validators/
│   │           └── messageValidator.unit.test.ts
│   ├── membership-service/
│   │   └── src/
│   │       ├── membership.integration.test.ts
│   │       ├── repository/
│   │       │   └── memberRepository.unit.test.ts
│   │       └── validators/
│   │           └── memberValidator.unit.test.ts
└── test-helpers/
    ├── fixtures.ts
    └── integrationTarget.ts
```

## 📊 Resumen

- **6 archivos de tests** en `backendTests/`
- **3 tests de integración**
- **3 tests unitarios**
- **2 helpers compartidos** en `backendTests/test-helpers/`

## 🚀 Cómo ejecutar

```bash
cd backend
npm install
npm test
```

## ✅ Principios de organización

- El código de cada servicio vive en `backend/services/<servicio>/`
- Los tests de cada servicio viven en `backendTests/services/<servicio>/src/`
- Los helpers compartidos van en `backendTests/test-helpers/`
- La estructura está alineada con los servicios reales del backend para que sea más fácil encontrar y mantener los tests
