# Asocia

App SwiftUI (en español, con selector de idioma) para gestionar el alta de
socios y el Chat entre socios confirmados: splash → botón "Asocia" (si no
eres socio) → formulario de alta (sin pago) → ficha de datos personales, con
un indicador provisional mientras el alta no se confirma manualmente desde
el backoffice. Una vez confirmada, aparecen las pestañas de Chat y Ajustes,
más una vista pública de todas las actividades de la asociación.

Toda la documentación técnica y las decisiones de arquitectura están en
[`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).

```
Asocia/                    # proyecto Xcode (app iOS)
backend/                   # microservicios Node.js/TypeScript, dockerizados
docs/ARQUITECTURA.md       # decisiones técnicas y trade-offs
.github/workflows/         # CI (activo) y despliegue a staging/producción (preparado, comentado)
```

## Ejecutar la app: con servicios mockeados o con el backend real

La app tiene 4 **entornos** (`AppEnvironment`, ver `Asocia/App/AppEnvironment.swift`
y `docs/ARQUITECTURA.md` sección 12), cada uno con su propio scheme de Xcode:

| Scheme de Xcode | Entorno | Qué usa |
|---|---|---|
| **Asocia (Mock)** | `mock` | Nada de red: todo son datos e IA "de mentira" en memoria |
| **Asocia (Local)** | `local` | El backend real, corriendo en tu máquina con Docker |
| **Asocia (Staging)** | `staging` | El backend de preproducción (Render) |
| **Asocia (Production)** | `production` | El backend de producción |

### Opción A — Sin backend, con servicios mockeados (la más rápida)

1. En Xcode, selecciona el scheme **Asocia (Mock)** (o simplemente dale a
   Run: por defecto, un build Debug sin scheme especial ya cae en modo mock).
2. Ejecuta la app. El alta, el Chat y la traducción de idioma funcionan con
   datos de ejemplo en memoria — no hace falta nada más.

Útil para desarrollar o probar la interfaz sin depender de que el backend
esté levantado.

### Opción B — Con el backend real, en local con Docker

1. Levanta los microservicios:
   ```bash
   cd backend
   cp services/*/.env.example services/*/.env   # y rellena ANTHROPIC_API_KEY si quieres probar la traducción real
   docker compose up --build
   ```
   Esto arranca PostgreSQL + los 4 microservicios (`api-gateway` en
   `http://localhost:4000`).
2. En Xcode, selecciona el scheme **Asocia (Local)** y ejecuta la app en el
   simulador (para dispositivo físico, `localhost` no resuelve al Mac —
   cambia `AppEnvironment.local.apiBaseURL` por la IP de tu Mac en la red
   local).

### Opción C — Contra staging o producción

Selecciona el scheme **Asocia (Staging)** o **Asocia (Production)**. Antes
de que exista un backend desplegado de verdad, actualiza las URLs en
`AppEnvironment.swift` (`case .staging` / `case .production`) por las
reales.

## Cómo abrir el proyecto iOS en Xcode

Este repo no incluye un `.xcodeproj` (son binarios/XML frágiles y no se
generan bien a mano). Se usa **XcodeGen**, que construye el `.xcodeproj` a
partir de `project.yml`:

```bash
brew install xcodegen
cd Asocia
xcodegen generate
open Asocia.xcodeproj
```

Cada vez que añadas/quites un archivo `.swift`, vuelve a ejecutar
`xcodegen generate`.

### Antes de compilar

1. En `project.yml`, pon tu `DEVELOPMENT_TEAM` y ajusta
   `PRODUCT_BUNDLE_IDENTIFIER` si `org.itb.asocia` ya no está libre.
2. Añade tu icono real en `Assets.xcassets/AppIcon.appiconset` y, si quieres
   un logo propio en el splash, una imagen llamada `AsociaLogo` en
   `Assets.xcassets`.
3. Los permisos de cámara (foto del socio) y calendario (exportar eventos)
   ya están declarados en `project.yml`.

## Backend: arrancarlo, probarlo, desplegarlo

Ver [`backend/README.md`](backend/README.md) para el detalle de endpoints,
variables de entorno y despliegue. Resumen rápido:

```bash
cd backend
docker compose up --build      # todo dockerizado: Postgres + los 4 servicios
# o, sin Docker, servicio a servicio:
npm install
npm run dev:gateway   # y en otras terminales: dev:membership, dev:chat, dev:translation
```

Verificación (sin necesidad de Postgres):

```bash
cd backend
npm install
npm run typecheck   # tipa los 5 paquetes (shared + 4 servicios)
npm run build        # compila todo a dist/
```

## Subir este proyecto a GitHub

Este entorno de trabajo no tiene credenciales de GitHub, así que el
repositorio se ha dejado listo en local (`git init` + commit inicial) pero
**la subida a GitHub la tienes que hacer tú**:

```bash
# Desde la raíz del proyecto (donde está este README):
gh repo create asocia --private --source=. --remote=origin   # con GitHub CLI, o:

git remote add origin https://github.com/<tu-usuario>/asocia.git
git branch -M main
git push -u origin main
```

En cuanto el repo esté en GitHub, `.github/workflows/ios-ci.yml` y
`backend-ci.yml` se ejecutarán automáticamente en cada push/PR (compilan y
testean la app y el backend). Los workflows de despliegue
(`deploy-staging.yml`, `deploy-production.yml`) están **preparados pero
comentados por completo**: no despliegan nada hasta que decidas el
proveedor, configures los secretos en GitHub (Settings → Secrets and
variables → Actions) y descomentes el contenido del archivo.

## Tests

- **Unit**: Swift Testing (`AsociaTests/`). `Cmd+U` o
  `xcodebuild test -scheme "Asocia (Mock)" -only-testing:AsociaTests`.
- **UI**: XCUITest (`AsociaUITests/`), arranca la app con estado limpio
  gracias al launch argument `-UITEST_RESET_STATE`.
- **Backend**: `cd backend && npm install && npm run typecheck && npm run build`.

## Trabajar con Claude en Xcode

Xcode 26.3+ incluye integración nativa con el Claude Agent SDK directamente
en el IDE — no hace falta VS Code para este proyecto. Ver
`docs/ARQUITECTURA.md`, sección "Claude en Xcode".
