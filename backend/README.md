# Asocia — backend de microservicios

Node.js + TypeScript, monorepo con npm workspaces. Cuatro servicios detrás de
un API Gateway, pensados para que tanto la app iOS de este repo como la
futura app Android (fuera del alcance de esta entrega, pero consumiendo
exactamente el mismo API) hablen con el mismo backend sin diferencias.

```
backend/
  packages/shared/         # tipos TypeScript compartidos por todos los servicios
  services/
    api-gateway/            # único punto de entrada público (puerto 4000)
    membership-service/     # alta de socios, ficha, aprobación/rechazo (4001)
    chat-service/           # conversaciones, mensajes, eventos/calendario (4002)
    translation-service/    # traducción de la UI con IA + caché (4003)
  docker-compose.yml        # Postgres + los 4 servicios, para desarrollo local
```

Ya comprobado en este repo: `npm install && npm run build` compila los 5
paquetes sin errores (`npm run typecheck` también). Lo único que no se ha
podido probar en este entorno es una base de datos Postgres real (aquí no
hay Docker disponible) — al arrancar sin Postgres, los servicios fallan de
forma controlada con `ECONNREFUSED`, que es el comportamiento esperado.

## Por qué estos 4 servicios y no otros

- **api-gateway**: único punto de entrada de la app. Traduce el Bearer token
  de sesión del socio en la identidad interna (`X-User-Id`/`X-User-Name`)
  que usan el resto de servicios, y es quien impone la regla "solo socios
  con alta confirmada acceden al Chat" — así ni chat-service ni
  translation-service necesitan saber nada sobre cómo se autentica un socio.
- **membership-service**: dueño de los datos del socio y del ciclo de vida
  del alta (`pendingApproval` -> `active`/`rejected`). Es la única fuente de
  verdad de `membershipStatus`.
- **chat-service**: conversaciones (individuales/grupo/actividad), mensajes
  y el calendario de eventos de las salas de actividad. La unicidad "solo
  una conversación individual por pareja de socios" está garantizada a
  nivel de base de datos (tabla `chat.individual_conversation_pairs`, ver
  `services/chat-service/src/schema.sql`), no solo en el código.
- **translation-service**: recibe el diccionario de textos en español y lo
  traduce a cualquier idioma con IA (Claude), cacheando el resultado en
  Postgres para que la traducción de cada idioma se pague una sola vez,
  la primera vez que alguien lo elige — no una vez por usuario.

## Arrancar en local

```bash
cd backend
cp services/*/.env.example services/*/.env   # y rellena ANTHROPIC_API_KEY
docker compose up --build
```

Esto levanta Postgres (con los 3 esquemas ya creados) y los 4 servicios.
El API Gateway queda en `http://localhost:4000`.

Sin Docker, cada servicio se puede levantar suelto contra un Postgres local
(`npm run dev:gateway`, `npm run dev:membership`, `npm run dev:chat`,
`npm run dev:translation` desde la raíz de `backend/`), siempre que exista
la base de datos `asocia` con los esquemas `membership`, `chat` y
`translation` (ver `scripts/init-schemas.sql`).

## Endpoints principales (vía api-gateway)

| Método | Ruta | Quién la llama | Auth |
|---|---|---|---|
| POST | `/v1/members/apply` | App (alta) | Ninguna |
| GET/PATCH | `/v1/members/me` | App (ficha propia) | Bearer del socio |
| GET | `/v1/admin/members` | Backoffice | `x-admin-key` |
| POST | `/v1/admin/members/:id/confirm` | Backoffice | `x-admin-key` |
| POST | `/v1/admin/members/:id/reject` | Backoffice | `x-admin-key` |
| GET | `/v1/directory` | App (buscar socios) | Bearer + alta activa |
| GET/POST | `/v1/conversations` | App (Chat) | Bearer + alta activa |
| POST | `/v1/conversations/individual` | App (Chat) | Bearer + alta activa |
| POST | `/v1/conversations/group` \| `/activity` | App (Chat) | Bearer + alta activa |
| GET/POST | `/v1/conversations/:id/messages` | App (Chat) | Bearer + alta activa |
| GET | `/v1/conversations/:id/events` | App (Chat) | Bearer + alta activa |
| POST | `/v1/events/:id/confirm` | App (RSVP) | Bearer + alta activa |
| POST | `/v1/admin/events` | Backoffice | `x-internal-key` |
| POST | `/v1/translate` | App (Ajustes > Idioma) | Ninguna |

La app iOS de esta entrega solo usa `/v1/members/*` de verdad (vía
`Asocia/Services/APIClient.swift`) y `/v1/translate` (vía
`TranslationClient.swift`). El Chat de la app usa de momento un backend
**emulado en el propio dispositivo** (`MockChatService`, decisión explícita
para esta fase — ver `docs/ARQUITECTURA.docx`), pero ya habla exactamente el
mismo contrato (`ChatServicing`) que tendría un cliente real contra
`chat-service`; sustituir el mock por un cliente HTTP real es el siguiente
paso natural.

## Backoffice / app Android (fuera de alcance, contrato ya listo)

Ni el backoffice de administración ni la app Android se construyen en esta
entrega. Lo que sí existe ya es el contrato que ambos necesitarán:

- Confirmar/rechazar altas, listar socios pendientes: `/v1/admin/members*`.
- Crear eventos e invitar socios a una actividad: `POST /v1/admin/events`.
- Los tipos compartidos de `packages/shared/src/types.ts` son el contrato
  exacto (nombres de campo incluidos) que espera la app iOS — la app
  Android debería consumir el mismo JSON sin traducciones intermedias.

## Despliegue en producción (Render, capa gratuita)

Cada servicio se despliega como un "Web Service" independiente en Render
(build desde su Dockerfile, contexto = `backend/`), más una base de datos
PostgreSQL de Render compartida por los tres servicios con esquema propio.
Ver `docs/ARQUITECTURA.docx` para la comparativa de proveedores y sus
limitaciones (la capa gratuita de Render "duerme" tras inactividad y la
base de datos gratuita caduca a los 90 días — asumible para el MVP, pero
conviene pasar a un plan de pago en cuanto haya socios reales).

Variables de entorno a configurar en Render para cada servicio: ver los
`.env.example` de cada carpeta en `services/*/`. Los pares `ADMIN_API_KEY` /
`INTERNAL_API_KEY` deben coincidir entre el api-gateway y el servicio que
los verifica (membership-service y chat-service respectivamente).
