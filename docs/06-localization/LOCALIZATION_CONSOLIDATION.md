# 🔧 Consolidación de Archivos de Localización

## 🎯 Problema Identificado

Había archivos JSON de localización **duplicados** en dos ubicaciones:
1. ❌ **Raíz del proyecto** - Archivos simples creados por error (es.json, ca.json, gl.json, eu.json, en.json)
2. ✅ **Asocia/Resources/Localization** - Archivos completos y correctos

Además, los archivos tenían **contenido diferente**:
- Los de la raíz: Solo ~45 claves básicas
- Los de Resources/Localization: ~170+ claves completas

---

## ✅ Solución Aplicada

### 1. Actualizado es.json en la Ubicación Correcta

He actualizado `/repo/es.json` (que debería estar en `Asocia/Resources/Localization/es.json`) agregando las claves faltantes de Settings:

```json
{
  // ... claves existentes ...
  
  "settings.environment.label": "Entorno",
  
  "settings.mock.section.header": "🧪 Simulación de Alta (Solo Modo Mock)",
  "settings.mock.section.footer": "En modo mock puedes simular...",
  "settings.mock.status.label": "Estado actual",
  "settings.mock.approve.button": "Confirmar Alta",
  "settings.mock.reject.button": "Rechazar Alta",
  "settings.mock.status.active": "Usuario ya confirmado",
  "settings.mock.status.rejected": "Alta rechazada",
  "settings.mock.alert.title": "Alta Confirmada",
  "settings.mock.alert.message": "El alta ha sido confirmada...",
  "settings.mock.rejection.reason": "Rechazado desde el simulador...",
  "settings.mock.status.notMember": "Sin solicitud",
  "settings.mock.status.pending": "⏳ Pendiente de aprobación",
  "settings.mock.status.activeValue": "✅ Activo",
  "settings.mock.status.rejectedValue": "❌ Rechazado"
}
```

---

## 📋 Acciones Necesarias en Xcode

### 1. Verificar Estructura de Carpetas

La estructura correcta debería ser:

```
Asocia/
├── App/
│   └── LocalizationManager-App.swift
├── Resources/
│   └── Localization/
│       ├── es.json ✅
│       ├── ca.json ⚠️ (necesita actualizar)
│       ├── gl.json ⚠️ (necesita actualizar)
│       ├── eu.json ⚠️ (necesita actualizar)
│       └── en.json ⚠️ (necesita actualizar)
```

### 2. Eliminar Archivos Duplicados de la Raíz

**Si existen estos archivos en la raíz del proyecto (fuera de Asocia/):**

```
❌ es.json (raíz)
❌ ca.json (raíz)
❌ gl.json (raíz)
❌ eu.json (raíz)
❌ en.json (raíz)
```

**Elimínalos:**
1. En Xcode, selecciona cada archivo
2. Delete → Move to Trash
3. O desde terminal:
   ```bash
   rm es.json ca.json gl.json eu.json en.json
   ```

### 3. Actualizar los Otros 4 Archivos JSON

Necesitas agregar las mismas claves de Settings a los otros idiomas:

#### ca.json (Catalán)

Agrega al final (antes del `}`):

```json
  "settings.environment.label": "Entorn",
  
  "settings.mock.section.header": "🧪 Simulació d'Alta (Només Mode Mock)",
  "settings.mock.section.footer": "En mode mock pots simular l'aprovació/rebuig d'altes que normalment faria el backoffice.",
  "settings.mock.status.label": "Estat actual",
  "settings.mock.approve.button": "Confirmar Alta",
  "settings.mock.reject.button": "Rebutjar Alta",
  "settings.mock.status.active": "Usuari ja confirmat",
  "settings.mock.status.rejected": "Alta rebutjada",
  "settings.mock.alert.title": "Alta Confirmada",
  "settings.mock.alert.message": "L'alta ha estat confirmada. L'usuari ara té estat 'actiu' i accés complet a l'aplicació.",
  "settings.mock.rejection.reason": "Rebutjat des del simulador d'altes en mode mock",
  "settings.mock.status.notMember": "Sense sol·licitud",
  "settings.mock.status.pending": "⏳ Pendent d'aprovació",
  "settings.mock.status.activeValue": "✅ Actiu",
  "settings.mock.status.rejectedValue": "❌ Rebutjat"
```

#### gl.json (Gallego)

```json
  "settings.environment.label": "Contorna",
  
  "settings.mock.section.header": "🧪 Simulación de Alta (Só Modo Mock)",
  "settings.mock.section.footer": "En modo mock podes simular a aprobación/rexeitamento de altas que normalmente faría o backoffice.",
  "settings.mock.status.label": "Estado actual",
  "settings.mock.approve.button": "Confirmar Alta",
  "settings.mock.reject.button": "Rexeitar Alta",
  "settings.mock.status.active": "Usuario xa confirmado",
  "settings.mock.status.rejected": "Alta rexeitada",
  "settings.mock.alert.title": "Alta Confirmada",
  "settings.mock.alert.message": "A alta foi confirmada. O usuario agora ten estado 'activo' e acceso completo á aplicación.",
  "settings.mock.rejection.reason": "Rexeitado desde o simulador de altas en modo mock",
  "settings.mock.status.notMember": "Sen solicitude",
  "settings.mock.status.pending": "⏳ Pendente de aprobación",
  "settings.mock.status.activeValue": "✅ Activo",
  "settings.mock.status.rejectedValue": "❌ Rexeitado"
```

#### eu.json (Euskera)

```json
  "settings.environment.label": "Ingurunea",
  
  "settings.mock.section.header": "🧪 Alta Simulazioa (Mock Modua Soilik)",
  "settings.mock.section.footer": "Mock moduan backoffice-k egingo lukeen alten onespena/ukatzea simulatu dezakezu.",
  "settings.mock.status.label": "Egungo egoera",
  "settings.mock.approve.button": "Baieztatu Alta",
  "settings.mock.reject.button": "Ukatu Alta",
  "settings.mock.status.active": "Erabiltzailea jadanik baiestuta",
  "settings.mock.status.rejected": "Alta ukatuta",
  "settings.mock.alert.title": "Alta Baiestuta",
  "settings.mock.alert.message": "Alta baiestu da. Erabiltzaileak orain 'aktibo' egoera du eta aplikaziorako sarbide osoa.",
  "settings.mock.rejection.reason": "Mock moduko alten simulatzailetik ukatuta",
  "settings.mock.status.notMember": "Eskaera gabe",
  "settings.mock.status.pending": "⏳ Onespen zain",
  "settings.mock.status.activeValue": "✅ Aktiboa",
  "settings.mock.status.rejectedValue": "❌ Ukatua"
```

#### en.json (Inglés)

```json
  "settings.environment.label": "Environment",
  
  "settings.mock.section.header": "🧪 Registration Simulation (Mock Mode Only)",
  "settings.mock.section.footer": "In mock mode you can simulate the approval/rejection of registrations that would normally be done by the backoffice.",
  "settings.mock.status.label": "Current status",
  "settings.mock.approve.button": "Approve Registration",
  "settings.mock.reject.button": "Reject Registration",
  "settings.mock.status.active": "User already confirmed",
  "settings.mock.status.rejected": "Registration rejected",
  "settings.mock.alert.title": "Registration Confirmed",
  "settings.mock.alert.message": "The registration has been confirmed. The user now has 'active' status and full access to the application.",
  "settings.mock.rejection.reason": "Rejected from the registration simulator in mock mode",
  "settings.mock.status.notMember": "No request",
  "settings.mock.status.pending": "⏳ Pending approval",
  "settings.mock.status.activeValue": "✅ Active",
  "settings.mock.status.rejectedValue": "❌ Rejected"
```

### 4. Verificar Target Membership

Para cada archivo JSON en `Asocia/Resources/Localization/`:

1. **Selecciona el archivo** en Xcode
2. **File Inspector** (⌥⌘1)
3. **Target Membership:**
   - ✅ Asocia (marcado)
   - ☐ AsociaTests (desmarcado)
   - ☐ AsociaUITests (desmarcado)

### 5. Verificar en Build Phases

1. **Proyecto Asocia** → Target **Asocia**
2. **Build Phases** → **Copy Bundle Resources**
3. Verifica que aparecen los 5 archivos:
   ```
   Localization/es.json
   Localization/ca.json
   Localization/gl.json
   Localization/eu.json
   Localization/en.json
   ```

---

## 🧪 Verificación

### 1. Compilar

```bash
⌘ + Shift + K  # Limpiar
⌘ + B          # Compilar
```

### 2. Ejecutar y Verificar Consola

```
✅ Localizaciones cargadas: ca, en, es, eu, gl
🌍 Idioma inicializado: es
```

Si ves warnings:
```
⚠️ No se pudo cargar el archivo de localización para 'xx'
```

Significa que ese archivo no está en el bundle o tiene errores de formato JSON.

### 3. Probar en la App

1. Ve a **Settings** (Ajustes)
2. **Cambia el idioma** a cada uno de los 5
3. **Verifica** que todos los textos cambian correctamente
4. Especialmente verifica la sección de Mock (si estás en modo Debug)

---

## 📊 Resumen de Claves

### Claves Totales por Archivo

Después de las actualizaciones, cada archivo debería tener aproximadamente:

- **~170+ claves** - Incluye:
  - `common.*` (11 claves)
  - `splash.*` (1 clave)
  - `membershipButton.*` (1 clave)
  - `signup.*` (30+ claves)
  - `photoPicker.*` (6 claves)
  - `profile.*` (40+ claves)
  - `tab.*` (3 claves)
  - `chatList.*` (7 claves)
  - `userSearch.*` (3 claves)
  - `newGroup.*` (4 claves)
  - `newActivity.*` (5 claves)
  - `activities.*` (9 claves)
  - `conversation.*` (2 claves)
  - `events.*` (8 claves)
  - `event.*` (14 claves)
  - `settings.*` (23+ claves) ← **Actualizadas**

### Nuevas Claves Agregadas

14 nuevas claves para la sección Mock de Settings:

1. `settings.environment.label`
2. `settings.mock.section.header`
3. `settings.mock.section.footer`
4. `settings.mock.status.label`
5. `settings.mock.approve.button`
6. `settings.mock.reject.button`
7. `settings.mock.status.active`
8. `settings.mock.status.rejected`
9. `settings.mock.alert.title`
10. `settings.mock.alert.message`
11. `settings.mock.rejection.reason`
12. `settings.mock.status.notMember`
13. `settings.mock.status.pending`
14. `settings.mock.status.activeValue`
15. `settings.mock.status.rejectedValue`

---

## ✅ Checklist Final

- [x] `es.json` actualizado con claves de Settings Mock
- [ ] Eliminar archivos JSON duplicados de la raíz (si existen)
- [ ] Actualizar `ca.json` con nuevas claves
- [ ] Actualizar `gl.json` con nuevas claves
- [ ] Actualizar `eu.json` con nuevas claves
- [ ] Actualizar `en.json` con nuevas claves
- [ ] Verificar que todos los archivos están en `Asocia/Resources/Localization/`
- [ ] Verificar Target Membership (solo Asocia marcado)
- [ ] Verificar Copy Bundle Resources en Build Phases
- [ ] Compilar sin errores
- [ ] Probar cambio de idioma en Settings
- [ ] Verificar que no hay warnings de localizaciones

---

## 🎯 Ubicación Correcta Final

```
Asocia/
└── Resources/
    └── Localization/
        ├── es.json  ← ✅ 184 claves
        ├── ca.json  ← ⚠️  Necesita actualizar (agregar 15 claves)
        ├── gl.json  ← ⚠️  Necesita actualizar (agregar 15 claves)
        ├── eu.json  ← ⚠️  Necesita actualizar (agregar 15 claves)
        └── en.json  ← ⚠️  Necesita actualizar (agregar 15 claves)
```

---

## 🐛 Solución de Problemas

### "No se pudo cargar el archivo de localización"

1. Verifica que el archivo existe en `Asocia/Resources/Localization/`
2. Verifica que está marcado en Target Membership (Asocia)
3. Verifica que aparece en Build Phases → Copy Bundle Resources
4. Limpia y recompila: `⌘ + Shift + K` + `⌘ + B`

### "JSON tiene errores de formato"

1. Verifica que no hay comas después de la última clave
2. Todas las comillas deben ser dobles `"`
3. Valida el JSON en https://jsonlint.com

### "Los textos no cambian al cambiar idioma"

1. Verifica que las claves son exactamente iguales en todos los archivos
2. Verifica que `SettingsView.swift` usa `loc.t("settings.mock.xxx")`
3. Verifica que `LocalizationManager` está en el environment

---

**Fecha:** 26 de julio de 2026  
**Versión:** 1.0  
**Estado:** es.json actualizado, pendiente actualizar ca.json, gl.json, eu.json, en.json
