# ✅ Archivos JSON Creados - Instrucciones Finales

## 📦 Archivos Creados

He creado los 5 archivos JSON completos con todas las traducciones:

1. ✅ `es.json` - Español (45 claves)
2. ✅ `ca.json` - Catalán (45 claves)
3. ✅ `gl.json` - Gallego (45 claves)
4. ✅ `eu.json` - Euskera (45 claves)
5. ✅ `en.json` - Inglés (45 claves)

## 📋 Contenido de los Archivos

Cada archivo JSON incluye:

### Traducciones Comunes (16 claves)
- `app.name`
- `common.accept`, `common.cancel`, `common.ok`
- `common.yes`, `common.no`
- `common.save`, `common.delete`, `common.edit`
- `common.close`, `common.back`
- `common.next`, `common.previous`, `common.done`
- `common.loading`, `common.error`, `common.retry`

### Traducciones de Settings (22 claves)
- `settings.navTitle`
- `settings.language.current`, `settings.language.footer`
- `settings.environment.label`
- `settings.mock.*` (18 claves para la sección de mock)

### Traducciones Adicionales (7 claves)
- `items.count` (con formato %d para pluralización)
- `welcome.message`, `welcome.description`

## 🚀 Próximos Pasos en Xcode

### 1. Mover los Archivos JSON a la Carpeta Resources

**Opción A: Usando Xcode (Recomendado)**
```
1. Abre Xcode
2. En el navegador de proyectos (izquierda), busca la carpeta "Resources"
3. Si no existe, crea una: Click derecho en el proyecto → New Group → "Resources"
4. Arrastra los 5 archivos JSON desde Finder a la carpeta "Resources" en Xcode
5. En el diálogo que aparece, asegúrate de marcar:
   ✅ "Copy items if needed"
   ✅ El target "Asocia" (app principal)
6. Click en "Finish"
```

**Opción B: Manualmente**
```bash
# Desde la terminal, en la raíz del proyecto:
mkdir -p Asocia/Resources
mv es.json ca.json gl.json eu.json en.json Asocia/Resources/

# Luego en Xcode, arrastra los archivos desde Finder
```

### 2. Verificar que los Archivos están en el Target Correcto

Para cada archivo JSON:
```
1. Selecciona el archivo en el navegador de Xcode
2. Abre el File Inspector (⌥⌘1)
3. En "Target Membership", verifica:
   ✅ Asocia (marcado)
   ☐ AsociaTests (desmarcado)
   ☐ AsociaUITests (desmarcado)
```

### 3. Verificar en Build Phases

```
1. Selecciona el proyecto "Asocia" en el navegador
2. Selecciona el target "Asocia"
3. Ve a la pestaña "Build Phases"
4. Expande "Copy Bundle Resources"
5. Verifica que aparecen los 5 archivos JSON:
   - es.json
   - ca.json
   - gl.json
   - eu.json
   - en.json
```

Si no aparecen, haz click en "+" y agrégalos.

### 4. Compilar y Probar

```bash
# Limpiar build anterior
⌘ + Shift + K

# Compilar
⌘ + B

# Ejecutar
⌘ + R
```

### 5. Verificar en la Consola

Al ejecutar la app, deberías ver en la consola:

```
✅ Localizaciones cargadas: ca, en, es, eu, gl
```

Si ves warnings como:
```
⚠️ No se pudo cargar el archivo de localización para 'xx'
```

Significa que ese archivo no está en el bundle. Vuelve al paso 2.

## 🧪 Cómo Probar las Traducciones

### Prueba Manual

1. **Ejecuta la app** (`⌘ + R`)
2. **Ve a Settings/Ajustes**
3. **Cambia el idioma** usando el picker
4. **Verifica que todos los textos cambian:**
   - Título de navegación cambia inmediatamente
   - Footer del selector cambia
   - Si estás en modo Debug/Mock, todos los textos de la sección Mock cambian

### Prueba de Cada Idioma

Cambia a cada idioma y verifica estos textos clave:

| Idioma | Título | Footer (primeras palabras) |
|--------|--------|---------------------------|
| 🇪🇸 Español | "Ajustes" | "Cambia el idioma..." |
| 🇪🇸 Català | "Configuració" | "Canvia l'idioma..." |
| 🇪🇸 Galego | "Axustes" | "Cambia o idioma..." |
| 🇪🇺 Euskara | "Ezarpenak" | "Aldatu aplikazioaren..." |
| 🇬🇧 English | "Settings" | "Change the application..." |

### Prueba de Persistencia

1. **Cambia el idioma** a Catalán
2. **Cierra la app** (swipe up en el simulador)
3. **Vuelve a abrir la app**
4. **Verifica** que sigue en Catalán

## 📊 Estructura Final Esperada

```
Asocia/
├── App/
│   ├── AsociaApp.swift
│   ├── LocalizationManager-App.swift
│   └── ...
├── Resources/
│   ├── es.json ✅
│   ├── ca.json ✅
│   ├── gl.json ✅
│   ├── eu.json ✅
│   └── en.json ✅
├── Views/
│   ├── SettingsView.swift ✅ (internacionalizado)
│   └── ...
├── AsociaTests/
│   ├── LocalizationManagerTests.swift ✅
│   └── ...
└── AsociaUITests/
    ├── LocalizationManagerUITests.swift ✅
    └── ...
```

## ✅ Checklist Final

- [ ] Los 5 archivos JSON están en la carpeta Resources
- [ ] Los archivos están incluidos en el target "Asocia"
- [ ] Los archivos aparecen en Build Phases → Copy Bundle Resources
- [ ] La app compila sin errores (`⌘ + B`)
- [ ] Al ejecutar aparece: "✅ Localizaciones cargadas: ca, en, es, eu, gl"
- [ ] Se puede cambiar el idioma en Settings
- [ ] Todos los textos cambian al cambiar el idioma
- [ ] El idioma persiste al reiniciar la app
- [ ] No hay mensajes de "⚠️ No se pudo cargar..." en la consola

## 🐛 Solución de Problemas

### Error: "No se pudo cargar el archivo de localización"

**Causa:** El archivo no está en el bundle

**Solución:**
1. Verifica que el archivo existe en Resources/
2. Selecciona el archivo en Xcode
3. En File Inspector, marca el checkbox del target "Asocia"
4. Recompila: `⌘ + Shift + K` + `⌘ + B`

### Error: "Invalid JSON"

**Causa:** Formato JSON incorrecto

**Solución:**
1. Verifica que no hay comas al final de la última clave
2. Valida el JSON en https://jsonlint.com
3. Asegúrate de que todas las comillas son dobles `"`, no simples `'`

### Los textos no cambian al cambiar el idioma

**Causa:** LocalizationManager no está notificando cambios

**Solución:**
1. Verifica que `LocalizationManager` tiene `@Observable` y `@MainActor`
2. Verifica que en `AsociaApp.swift` tienes `.environment(localizationManager)`
3. Verifica que en `SettingsView.swift` usas `@Environment(LocalizationManager.self)`

### Aparecen las claves en vez de las traducciones

**Causa:** La clave no existe en el JSON o el JSON no se cargó

**Solución:**
1. Verifica que la clave existe en el archivo JSON
2. Verifica que el archivo está en el bundle (ver consola)
3. Asegúrate de que las comillas están bien escapadas

## 🎉 ¡Listo!

Una vez completados todos los pasos:
- ✅ Tendrás 5 idiomas completos
- ✅ SettingsView totalmente internacionalizado
- ✅ Cambio de idioma en tiempo real
- ✅ Persistencia del idioma seleccionado
- ✅ Fallback a español si falta alguna traducción

---

**Fecha:** 26 de julio de 2026  
**Versión:** 1.0  
**Total de traducciones:** 45 claves × 5 idiomas = 225 traducciones
