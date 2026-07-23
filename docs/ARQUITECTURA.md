# Asocia — Arquitectura técnica y decisiones de diseño

Víctor Naranjo · versión 4 (redes sociales, búsqueda por similitud, entornos mock/local/staging/producción, actividades públicas, Docker completo, CI/CD) · 23 de julio de 2026

> A partir de esta versión, toda la documentación del proyecto vive en Markdown (`.md`), no en Word. Este archivo sustituye a la antigua `ARQUITECTURA.docx`.

## 1. Objetivo y alcance

Asocia es una app iOS con dos grandes bloques: el alta de socios (splash → botón "Asocia" → formulario de datos → ficha personal con indicador provisional hasta que el equipo gestor confirma el alta a mano) y, una vez confirmada, un Chat entre socios con tres tipos de sala (individual, grupo y actividad con calendario de eventos), más una vista pública de todas las actividades a la que cualquier socio puede pedir acceso.

Novedades de esta versión:

- Redes sociales (Facebook, Instagram, X, TikTok) en los datos del socio.
- Consentimiento explícito para aparecer en la búsqueda del Chat, y los atributos de datos necesarios para el futuro modelo multi-asociación.
- Búsqueda de socios por similitud de texto (no un simple `LIKE`), tolerante a erratas.
- Vista "Todas las actividades" con iconos grandes (foto, título, próximo evento) y solicitud de acceso.
- La capa de microservicios está 100% dockerizada (los 4 servicios + Postgres, con healthchecks).
- La app se puede ejecutar con servicios "mockeados" (sin backend) o contra el backend real, en cuatro entornos: mock, local (Docker), staging y producción.
- Repositorio Git preparado, con GitHub Actions de CI ya funcionando y de despliegue a staging/producción preparados pero comentados (no se despliega nada todavía).
- Roadmap detallado para una futura versión con administradores por asociación, alta masiva por CSV y verificación por SMS.

## 2. Arquitectura de la app iOS

SwiftUI + Swift, patrón MVVM ligero apoyado en `@Observable` (Observation framework). Capas:

- **Views**: `SplashView`, `RootView`, `MembershipButtonView`, `SignupView`, `MemberProfileView`, `SettingsView`, y los paquetes `Views/Chat/` (lista, búsqueda, grupos, actividades, conversación, eventos, directorio de actividades) y `Views/Shared/` (selector de fotografía).
- **Models**: `Member`, `MembershipStatus`, `SyncStatus`, `ChatUser`/`Conversation`/`ChatMessage`/`ActivityEvent`/`EventAttendee`/`ActivitySummary`, `WorldLanguages`.
- **Services**: `APIClient`/`MockMembershipAPIClient` (datos del socio), `SyncEngine` (offline-first), `ChatAPIClient`/`MockChatService` (Chat), `LocalizationManager` + `TranslationAPIClient`/`MockTranslationClient` (idioma), `CalendarExporter` (EventKit), `PersistenceController`, `KeychainStore`, `AppEnvironment`.

`RootView` consulta con `@Query` si existe un `Member` local. Si no existe, muestra el botón "Asocia". Si existe y está pendiente o rechazado, muestra solo la ficha. Si está activo, muestra un `TabView` con "Perfil", "Chat" y "Ajustes".

## 3. Datos del socio

El formulario de alta recoge: nombre, 1er apellido, 2º apellido, email, email 2, móvil, fijo, dirección, CP, ciudad, provincia, fecha de nacimiento, curso/año de entrada, curso/año de salida, promoción, profesión, lugar de trabajo, IBAN, **redes sociales (Facebook, Instagram, X, TikTok)** y fotografía.

**Campos obligatorios**: nombre + 1er apellido, y al menos un contacto (email, móvil o fijo). El resto son opcionales y se pueden completar más adelante desde la ficha (`Member.isValidApplication` centraliza esta regla).

### Consentimiento de búsqueda

`Member.isSearchable` (booleano, por defecto `false`) es el consentimiento explícito para aparecer en la búsqueda de socios del Chat. Se pide como un interruptor tanto en el alta como en la ficha, con el texto: *"Si lo activas, otros socios con el alta confirmada podrán encontrarte al buscar en el Chat."* Solo los socios `active` **y** con `isSearchable = true` aparecen en el directorio del Chat — lo mantiene sincronizado `membership-service` llamando a `chat-service` cada vez que cambia cualquiera de las dos condiciones (ver `syncChatDirectory` en `backend/services/membership-service/src/index.ts`).

### Atributos de asociación (preparados para el roadmap, sección 16)

`Member.associationID` (opcional) y `Member.isVisibleToOtherAssociations` (booleano, por defecto `false`) ya existen en el modelo y en el backend, aunque todavía no tienen UI de selección ni un microservicio de validación de asociaciones — se han añadido ahora para no necesitar una migración de datos cuando se construya esa funcionalidad (ver roadmap).

## 4. Fotografía del socio

`MemberPhotoPicker` (`Views/Shared/PhotoPicker.swift`) permite elegir la foto de dos maneras:

- **Galería**: con `PhotosPicker` (framework PhotosUI, iOS 16+), que se ejecuta fuera de proceso — no requiere `NSPhotoLibraryUsageDescription`.
- **Cámara**: con `UIImagePickerController`, que sí requiere el permiso `NSCameraUsageDescription` (ya incluido en `project.yml`).

La imagen se redimensiona a un máximo de 800 px y se comprime a JPEG (calidad 0,7) antes de guardarla. En SwiftData se guarda con `.externalStorage`. El mismo componente se reutiliza para la foto de las salas de actividad (`NewActivityView`), que se muestra en el listado "Todas las actividades".

Para producción real se recomienda no enviar la imagen como base64 dentro del JSON (como hace este prototipo, por simplicidad), sino subirla a un bucket de objetos (Cloudflare R2 o un bucket S3-compatible) y guardar solo la URL.

## 5. Almacenamiento: base de datos distribuida móvil/servidor

- **Local (offline-first)**: SwiftData con el campo `syncStatus` (`synced` / `pendingUpload` / `pendingDownload` / `conflict` / `syncFailed`). La UI SIEMPRE lee y escribe primero en SwiftData.
- **Remoto**: PostgreSQL, un esquema por microservicio (`membership`, `chat`, `translation`) dentro de la misma instancia.
- **Sincronización**: `SyncEngine` sube lo pendiente y baja el último estado del servidor al arrancar, cada 5 minutos y al recuperar conexión. "Servidor gana" en `membershipStatus`; *last-write-wins* en el resto de campos.

## 6. Backend de microservicios — dockerización

Los 4 microservicios (Node.js + TypeScript, npm workspaces) están **completamente dockerizados**: cada uno tiene su propio `Dockerfile` multi-stage (build con `tsc`, imagen final `node:20-alpine` solo con lo necesario para ejecutar), y `docker-compose.yml` los levanta todos junto con PostgreSQL, con healthchecks reales (`node -e "fetch('http://localhost:PUERTO/healthz')..."`, sin depender de `curl` en la imagen) y dependencias ordenadas (`depends_on: condition: service_healthy`) para que ningún servicio arranque antes de que su dependencia esté lista. No hay ninguna otra pieza de infraestructura fuera de este `docker-compose.yml` — la app iOS es la única parte del proyecto que no se dockeriza (no tiene sentido: es un cliente nativo).

- **api-gateway** (4000): único punto de entrada. Resuelve el Bearer token contra `membership-service`, exige alta confirmada para las rutas de Chat, y proxea el resto.
- **membership-service** (4001): alta, ficha, aprobación/rechazo. Mantiene sincronizado el directorio de `chat-service` cada vez que cambia `membershipStatus` o `isSearchable`.
- **chat-service** (4002): directorio, conversaciones, mensajes, eventos, actividades públicas y solicitudes de acceso.
- **translation-service** (4003): traduce con Claude y cachea en Postgres.

Verificado en este entorno: `npm install && npm run build && npm run typecheck` pasan sin errores en los 5 paquetes (`packages/shared` + los 4 servicios); el `api-gateway` arranca y responde en `/healthz`. No se ha podido probar con una Postgres real en este entorno concreto (sin Docker disponible aquí), pero los servicios fallan de forma controlada (`ECONNREFUSED`) en el punto esperado al no encontrarla, lo que confirma que el resto del código (rutas, tipos, build) es correcto.

### Por qué no CloudKit

CloudKit es exclusivo del ecosistema Apple: no puede recibir fácilmente el flujo de confirmación manual desde un backoffice separado, ni lo consumiría la futura app Android con el mismo contrato. Se mantiene la recomendación de no usarlo como backend principal.

### Hosting gratuito en producción

| Proveedor | Qué ofrece gratis | Limitación principal |
|---|---|---|
| Render | Web service + PostgreSQL gratis, sin tarjeta | El servicio "duerme" tras inactividad; la BD gratuita caduca a los 90 días |
| Railway | 5$/mes en créditos (plan Hobby) | Ya no es "siempre gratis"; se agota con tráfico real |
| Fly.io | Prueba de 2h VM / 7 días | Dejó de tener capa gratuita permanente en 2025 |
| Supabase | PostgreSQL + Auth + Realtime gratis | Pensado como BaaS; menos flexible para microservicios propios en Node |

**Recomendación**: Render para el MVP — cada microservicio como Web Service (build desde su Dockerfile, contexto `backend/`), más una única base de datos PostgreSQL de Render compartida (un esquema por servicio). Pasar a un plan de pago (~7 €/mes por servicio) en cuanto haya socios reales.

## 7. Búsqueda de socios por similitud ("a lo Google")

No se usa un simple `LIKE`/`ILIKE`. `chat-service` usa la extensión `pg_trgm` de PostgreSQL (operador `%` y función `similarity()`) sobre un índice GIN de trigramas, de forma que buscar **"Pedro Gimenez"** encuentra antes a **"Pedro Jiménez"** que a **"Antonio Giménez"**, porque comparte más trigramas con el nombre completo que solo con el apellido:

```sql
SELECT *, similarity(full_name, $2) AS score
FROM chat.directory
WHERE user_id != $1 AND (full_name % $2 OR full_name ILIKE '%' || $2 || '%')
ORDER BY score DESC, full_name ASC
LIMIT 30
```

En el modo mock de la app (sin backend), `StringSimilarity` (`Asocia/Services/ChatService.swift`) implementa el mismo criterio en Swift con el coeficiente de Dice sobre bigramas de caracteres, para que el comportamiento de búsqueda sea el mismo tanto en mock como contra el backend real. Verificado con un test (`ChatServiceTests.searchRanksBySimilarityNotJustSubstring`).

## 8. Chat: individual, grupo y actividad

- **Individual**: solo una conversación por pareja de usuarios, garantizado a nivel de base de datos (tabla `chat.individual_conversation_pairs`, con `user_a < user_b` siempre).
- **Grupo**: se pueden crear tantos como se quiera.
- **Actividad**: como un grupo, pero con un calendario de eventos asociado y una foto propia. La gestión de los eventos (crear, editar, invitar) la hace el equipo administrador desde el backoffice; el socio consulta y confirma asistencia.

## 9. Actividades y calendario de eventos

Dentro de una sala de actividad, un botón "Ver eventos de la actividad" abre `EventsListView`:

- Si solo hay un evento, se muestra directamente su ficha (`EventDetailView`).
- Si hay más de uno, se puede elegir entre lista o calendario con los días marcados (`EventCalendarView`, envoltorio de `UICalendarView`, el mismo componente que usa la app Calendario de Apple).
- Cada evento tiene nombre, descripción, fecha, lugar y lista de asistentes con estado "invitado"/"confirmado"; el socio puede confirmar su asistencia.
- Botón "Añadir al calendario del iPhone": exporta el evento con EventKit (`EKEventStore`), pidiendo permiso con `NSCalendarsFullAccessUsageDescription`.

## 10. Vista "Todas las actividades" y solicitud de acceso

`ActivitiesDirectoryView` (accesible desde un icono en la pestaña Chat) muestra **todas** las actividades que existen, no solo las tuyas, en una cuadrícula de iconos grandes: foto de la actividad, título y fecha del próximo evento (o "Sin próximos eventos"). Si no eres participante, un botón "Solicitar acceso" te permite pedir unirte.

- **Backend real**: la solicitud se guarda en `chat.activity_join_requests`, pendiente de aprobación manual desde el futuro backoffice — no se concede acceso automáticamente.
- **Modo mock de la app**: para poder demostrar el flujo completo sin un backoffice construido todavía, la solicitud se aprueba al instante. Esta diferencia está documentada explícitamente en el código (`MockChatService.requestAccessToActivity`) para que no se confunda con el comportamiento real.

## 11. Idioma dinámico con traducción por IA

Toda la interfaz está en español por defecto (diccionario base en `Asocia/Resources/Localization/es.json`). Desde Ajustes → Idioma, el socio puede elegir cualquier idioma del mundo; si no es uno de los ya empaquetados, la app envía el diccionario completo a `translation-service`, que lo traduce con Claude (Anthropic) y lo guarda en caché — la siguiente persona que elija el mismo idioma lo recibe al instante.

**Orden del selector de idioma**: español, catalán, gallego, euskera, inglés; después los 10 idiomas más hablados del mundo (Ethnologue 2025: chino mandarín, hindi, árabe, francés, bengalí, portugués, ruso, indonesio, urdu y alemán, sin repetir español/inglés); y finalmente el resto de idiomas por orden alfabético. La lista se genera con `Locale.LanguageCode.isoLanguageCodes` (`WorldLanguages.swift`), no es una tabla escrita a mano — verificado con `WorldLanguagesTests`.

En el entorno `.mock`, `MockTranslationClient` simula la traducción anteponiendo el código de idioma al texto (p. ej. `"[fr] Hola"`), sin depender de una clave de Anthropic, para poder probar el flujo sin backend.

## 12. Entornos: mock / local / staging / producción

`AppEnvironment` (`Asocia/App/AppEnvironment.swift`) decide, una única vez al arrancar, qué implementación de cada servicio se usa:

| Entorno | Variable `ASOCIA_ENVIRONMENT` | Implementaciones | Uso |
|---|---|---|---|
| Mock | `mock` | `MockMembershipAPIClient`, `MockChatService`, `MockTranslationClient` | Desarrollar la UI sin backend, ni siquiera con Docker |
| Local | `local` | Clientes reales contra `http://localhost:4000` | Probar contra `docker compose up` en local |
| Staging | `staging` | Clientes reales contra el backend de preproducción | Validar una versión antes de publicarla |
| Producción | `production` | Clientes reales contra el backend de producción | La app publicada |

Cada entorno tiene su propio scheme de Xcode (`Asocia (Mock)`, `Asocia (Local)`, `Asocia (Staging)`, `Asocia (Production)`, definidos en `project.yml`), que fija la variable de entorno del *Run action*. Sin tocar nada (build por defecto), la app cae en `.mock` en Debug y `.production` en Release, para que un build de desarrollo nunca hable por accidente con un backend real.

El modo mock simula además la aprobación del alta (unos segundos después de enviarla, pasa de `pendingApproval` a `active` solo) para poder ver el ciclo completo sin backoffice real.

## 13. Control de versiones y CI/CD

El proyecto está preparado como repositorio Git con GitHub Actions (`.github/workflows/`):

- **`ios-ci.yml`**: build y tests de la app iOS (`xcodebuild`) en cada push/PR — activo.
- **`backend-ci.yml`**: `npm run typecheck` y `npm run build` de los 5 paquetes del backend en cada push/PR — activo.
- **`deploy-staging.yml`** y **`deploy-production.yml`**: despliegue a Render (o al proveedor que se elija) de los 4 microservicios. Están **preparados pero comentados por completo** — no despliegan nada todavía, a la espera de decidir el proveedor definitivo y configurar los secretos (API keys, tokens de despliegue). Descomentarlos y rellenar los secretos de GitHub es el único paso que falta para activarlos.

Ver el `README.md` de la raíz del proyecto para las instrucciones de cómo subir este repositorio a GitHub (no se ha hecho automáticamente: requiere tus credenciales).

## 14. Testing

Swift Testing para tests nuevos de unidad/integración; XCTest (XCUITest) para UI. Ambos conviven sin conflicto.

- **`AsociaTests/`**: `MembershipStatusTests`, `MemberTests` (incluye `isValidApplication`), `SyncEngineTests` (con doble de test `SyncTestMembershipAPIClient`), `ChatServiceTests` (unicidad 1:1, grupos ilimitados, eventos de actividad, confirmación de asistencia, **búsqueda por similitud**, **todas las actividades**, **solicitud de acceso**) y `WorldLanguagesTests` (orden del selector de idioma).
- **`AsociaUITests/`**: botón "Asocia" sin socio, formulario de alta sin pago, activación del botón de enviar.
- **Backend**: `npm run typecheck` / `npm run build` en los 5 paquetes de `backend/`, verificados en esta entrega; `backend-ci.yml` los ejecuta en cada cambio.

## 15. Claude en Xcode

Desde Xcode 26.3, Apple integra de forma nativa el Claude Agent SDK dentro del IDE, con subagentes, tareas en segundo plano y soporte de plugins. No hace falta recurrir a VS Code para trabajar con Claude en este proyecto.

## 16. Roadmap: administradores por asociación, alta masiva y multi-asociación

Esta sección documenta una funcionalidad **todavía no implementada**, pensada para una futura versión.

### 16.1. "Soy administrador"

Un nuevo punto de entrada (p. ej. un enlace discreto en Ajustes) permitiría a un socio solicitar convertirse en administrador:

1. El usuario introduce su número de teléfono.
2. La app lo consulta contra una base de datos de números autorizados (gestionada por un nuevo microservicio, p. ej. `admin-service`, o una tabla dentro de `membership-service`).
3. Si el número está autorizado, se envía un SMS con un enlace de un solo uso (p. ej. vía Twilio o un proveedor equivalente) para confirmar la identidad.
4. Al confirmar, el usuario obtiene un rol de administrador — **de la asociación a la que pertenece** (ver `Member.associationID`), nunca de forma global.

### 16.2. Alta masiva por CSV

Con el rol de administrador activo, se habilitaría una nueva pantalla para cargar un CSV con un formato específico que incluya todos los campos que ya pide el alta individual (nombre, apellidos, contacto, dirección, datos académicos/profesionales, redes sociales, etc.). El backend validaría el formato fila a fila y crearía las altas en estado `pendingApproval`, igual que si cada persona se hubiera dado de alta desde la app.

### 16.3. Selector de asociación en el alta

El formulario de alta (`SignupView`) incorporaría un desplegable para elegir la asociación a la que se pertenece. La lista de asociaciones estaría precargada en el servidor y se validaría contra un microservicio dedicado (p. ej. `associations-service`), en vez de aceptar texto libre — así se garantiza que `Member.associationID` siempre apunta a una asociación real y conocida.

### 16.4. Visibilidad entre asociaciones

Con varias asociaciones conviviendo en el mismo backend:

- Por defecto, cada socio solo ve (en el directorio de búsqueda del Chat) a otros socios **de su misma asociación**.
- Un socio puede activar una opción "ver todas las asociaciones"; al hacerlo, pasa a ver también a socios de otras asociaciones, pero **únicamente a aquellos que también hayan activado** `Member.isVisibleToOtherAssociations` (el atributo ya existe en el modelo desde esta versión — ver sección 3). Es decir: ver-todas-las-asociaciones es una preferencia del que busca; ser-visible-para-otras-asociaciones es un consentimiento independiente del que aparece.
- El administrador de una asociación solo administra (aprueba altas, sube CSV) los socios de su propia asociación.

### 16.5. Piezas técnicas que faltan por construir

- Microservicio (o tabla) de números de teléfono autorizados para ser administrador.
- Integración con un proveedor de SMS.
- Microservicio de asociaciones (catálogo + validación).
- Endpoint de alta masiva por CSV, con validación de formato y manejo de errores fila a fila.
- Filtro de `associationID` (+ `isVisibleToOtherAssociations`) en `GET /v1/directory` de `chat-service`.
- UI de administración (backoffice) para todo lo anterior.

## 17. Próximos pasos sugeridos

- Decidir proveedor de hosting y desplegar el backend en staging (descomentar `deploy-staging.yml`).
- Construir el backoffice de confirmación de altas, gestión del calendario de actividades y aprobación de solicitudes de acceso.
- Configurar `ANTHROPIC_API_KEY` en `translation-service` y probar el flujo completo de traducción desde Ajustes.
- Decidir dónde se suben las fotografías (bucket de objetos) y migrar de `photoBase64` a `photoUrl`.
- Construir el roadmap de la sección 16 (administradores, CSV, multi-asociación).
- Iniciar la app Android sobre el mismo backend.
