# 👥 Usuarios de Chat Agregados para Pruebas

## ✅ Cambios Aplicados

He agregado **15 usuarios adicionales** al directorio de chat del `MockChatService` para que tengas gente con quien chatear cuando pruebes la aplicación.

---

## 📊 Usuarios Disponibles para Chatear

### Total: 25 usuarios

#### Usuarios en Catalán (10 usuarios originales)
1. **Marta Puig**
2. **Jordi Serra**
3. **Laia Font**
4. **Pol Vidal**
5. **Núria Camps**
6. **Àlex Ribas**
7. **Clara Soler**
8. **Bernat Roca**
9. **Gemma Vila**
10. **Oriol Mas**

#### Usuarios en Español (15 usuarios nuevos)
11. **Pedro Jiménez**
12. **Antonio Giménez**
13. **María González**
14. **Carlos Rodríguez**
15. **Laura Martínez**
16. **David López**
17. **Carmen Sánchez**
18. **Miguel Fernández**
19. **Elena García**
20. **Javier Torres**
21. **Patricia Ramírez**
22. **Alberto Díaz**
23. **Ana María Ruiz**
24. **José Luis Moreno**
25. **María José Romero**

---

## 🎯 Cómo Usar

### 1. Buscar Usuarios

1. **Ve a la pestaña Chat**
2. **Tap en la lupa** (buscar)
3. **Escribe un nombre**:
   - `Maria` → Encontrará María González, María José Romero, Ana María Ruiz
   - `Carlos` → Encontrará Carlos Rodríguez
   - `Pedro` → Encontrará Pedro Jiménez
   - etc.

### 2. Iniciar Conversación

1. **Tap en un usuario** de los resultados
2. **Se abre automáticamente** una conversación 1:1
3. **Escribe un mensaje**
4. **El usuario responderá automáticamente** después de 1.5-3 segundos

### 3. Respuestas Automáticas

Los usuarios de prueba responden con mensajes aleatorios:
- "Hola! Com anem?"
- "Perfecte, ens veiem a la propera trobada de l'associació."
- "Gràcies per l'avís!"
- "Apuntat, hi seré."
- "👍"
- "Ho miro i et dic alguna cosa."

---

## 🔍 Características de la Búsqueda

### Búsqueda Inteligente

El buscador usa **similitud de texto** (como Google), no solo coincidencia exacta:

- ✅ `Pedro Gimenez` encuentra **Pedro Jiménez** (sin tilde)
- ✅ `Maria` encuentra **María**, **Ana María**, **María José**
- ✅ `Rodriguez` encuentra **Rodríguez** (sin tilde)
- ✅ Búsqueda insensible a mayúsculas/minúsculas
- ✅ Búsqueda insensible a tildes

### Ordenamiento por Relevancia

Los resultados se ordenan por similitud:
- **Coincidencia exacta** → Primera posición
- **Nombre completo similar** → Antes que solo apellido
- **Solo apellido** → Menos prioridad

**Ejemplo:** Buscar `Pedro Gimenez`:
1. Pedro Jiménez (nombre + apellido similar)
2. Antonio Giménez (solo apellido)

---

## 💬 Funcionalidades Disponibles

### Conversaciones Individuales

- ✅ **Buscar usuario** → Chat 1:1 automático
- ✅ **Enviar mensajes** → Guardados en memoria
- ✅ **Recibir respuestas** → Automáticas después de 1.5-3s
- ✅ **Historial de mensajes** → Se mantiene mientras la app esté abierta
- ✅ **Vista previa** → Último mensaje en la lista de chats

### Crear Grupos

1. **Tap en "Nuevo grupo"** en la lista de chats
2. **Escribe nombre del grupo**: ej. "Promoción 2024"
3. **Selecciona participantes**: Puedes elegir varios usuarios
4. **Crear** → Grupo creado
5. **Chatear con todos** → Los mensajes son del grupo

### Crear Actividades

1. **Tap en "Nueva actividad"**
2. **Nombre**: ej. "Excursión anual"
3. **Participantes**: Selecciona usuarios
4. **Foto** (opcional)
5. **Crear** → Actividad con eventos

---

## 🎭 Comportamiento del Mock

### Al Iniciar la App

```
// El MockChatService crea automáticamente los 25 usuarios
directory = MockChatService.seedDirectory()
```

### Al Buscar

```swift
// Sin filtro → Muestra todos
searchDirectory(query: "") → 25 usuarios

// Con filtro → Búsqueda inteligente
searchDirectory(query: "Maria") → 3 usuarios (María González, Ana María Ruiz, María José Romero)
```

### Al Chatear

```swift
// Tu mensaje
sendMessage(text: "Hola Pedro")

// 1.5-3 segundos después...
// Pedro responde automáticamente con un mensaje aleatorio
```

---

## 📝 Datos Técnicos

### Estructura de ChatUser

Cada usuario tiene:
```swift
ChatUser(
    id: UUID(),              // ID único generado
    fullName: "María González",  // Nombre completo
    photoData: nil           // Sin foto (por ahora)
)
```

### Persistencia

⚠️ **Importante:** Los usuarios de chat están **solo en memoria**:
- ✅ Disponibles mientras la app esté abierta
- ❌ Se pierden al cerrar la app
- ✅ Se recrean al abrir de nuevo

Las **conversaciones y mensajes** también están en memoria:
- Se mantienen durante la sesión
- Se pierden al cerrar la app

---

## 🔧 Personalización

### Agregar Más Usuarios

Edita `ChatService.swift` en el método `seedDirectory()`:

```swift
private static func seedDirectory() -> [ChatUser] {
    [
        // ... usuarios existentes ...
        
        // Tus usuarios personalizados
        "Tu Nombre Aquí",
        "Otro Usuario",
        // ...
    ].map { ChatUser(id: UUID(), fullName: $0, photoData: nil) }
}
```

### Cambiar Respuestas Automáticas

Edita el array `canned` en `MockChatService`:

```swift
private let canned = [
    "Hola! Com anem?",
    "Perfecte!",
    // Agrega tus propios mensajes aquí
    "¡Claro que sí!",
    "Me parece bien",
    "Lo miramos y te digo"
]
```

### Ajustar Tiempo de Respuesta

En el método `scheduleSimulatedReplyIfNeeded`:

```swift
// Cambiar de 1.5-3 segundos a otro rango
try? await Task.sleep(for: .seconds(Double.random(in: 2...5)))  // 2-5 segundos
try? await Task.sleep(for: .seconds(1))  // Siempre 1 segundo
```

---

## 🧪 Escenarios de Prueba

### Prueba 1: Búsqueda Básica

1. Ve a Chat → Buscar
2. Busca "Maria"
3. Deberías ver: María González, Ana María Ruiz, María José Romero
4. Tap en cualquiera
5. Envía un mensaje
6. Espera la respuesta automática

### Prueba 2: Múltiples Conversaciones

1. Busca y abre chat con "Pedro Jiménez"
2. Envía mensaje
3. Vuelve a lista de chats
4. Busca y abre chat con "Carlos Rodríguez"
5. Envía mensaje
6. Verifica que ambas conversaciones aparecen en la lista

### Prueba 3: Crear Grupo

1. Tap "Nuevo grupo"
2. Nombre: "Amigos"
3. Selecciona 3-4 usuarios de la lista
4. Crear
5. Envía un mensaje al grupo
6. Verifica que aparece en la lista de chats

### Prueba 4: Búsqueda con Errores Ortográficos

1. Busca "Jimenez" (sin tilde)
2. Debería encontrar "Pedro Jiménez" y "Antonio Giménez"
3. Busca "Rodriguez" (sin tilde)
4. Debería encontrar "Carlos Rodríguez"

---

## 📊 Resumen de Cambios

### Archivo Modificado
- ✅ `ChatService.swift` → Método `seedDirectory()`

### Usuarios Agregados
- ✅ **+15 nuevos usuarios** (de 10 a 25 total)
- ✅ Mix de nombres en catalán y español
- ✅ Incluye nombres compuestos
- ✅ Variedad de apellidos comunes

### Funcionalidad
- ✅ Búsqueda inteligente con similitud de texto
- ✅ Respuestas automáticas
- ✅ Soporte para conversaciones 1:1
- ✅ Soporte para grupos
- ✅ Soporte para actividades

---

## 🎯 Próximos Pasos

1. **Compila**: `⌘ + B`
2. **Ejecuta**: `⌘ + R`
3. **Asegúrate de tener un usuario activo** (Ana García del ejemplo anterior)
4. **Ve a Chat**
5. **Tap en la lupa**
6. **Busca cualquier nombre** y empieza a chatear

### Verificación en Consola

No hay logging específico para los usuarios de chat, pero cuando inicies una conversación verás los mensajes en la interfaz inmediatamente.

---

## 💡 Consejos

- 🔍 **Prueba la búsqueda** con y sin tildes para ver la similitud de texto
- 💬 **Crea varios chats** para ver cómo se actualiza la lista
- 👥 **Crea un grupo** para probar conversaciones múltiples
- 🎨 **Los usuarios no tienen foto** por ahora (photoData: nil)
- 🔄 **Las respuestas son aleatorias** de la lista predefinida

---

**Fecha:** 26 de julio de 2026  
**Versión:** 1.0  
**Archivo modificado:** ChatService.swift  
**Usuarios totales:** 25 (10 originales + 15 nuevos)
