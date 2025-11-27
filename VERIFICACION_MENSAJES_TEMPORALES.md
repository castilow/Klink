# 🔍 Guía para Verificar Mensajes Temporales de 24 Horas

## ✅ Paso 1: Activar la Funcionalidad

1. Abre la app
2. Ve a **Perfil** → **Chat Settings**
3. Activa el switch **"Mensajes Temporales"**
4. Deberías ver que el switch queda en **ON** (verde/activado)

---

## ✅ Paso 2: Verificar en los Logs al Enviar un Mensaje

1. Abre la consola de Flutter (donde ves los logs)
2. Envía un mensaje de texto a cualquier chat
3. **Busca estos logs en la consola:**

```
📝 Enviando mensaje: isTemporary = true, isViewOnce = false
⏰ Mensaje temporal creado: expiresAt = 2024-XX-XX XX:XX:XX.XXX
```

**✅ Si ves estos logs:** El mensaje se está creando como temporal correctamente.

**❌ Si ves `isTemporary = false`:** La configuración no está activada o no se está leyendo correctamente.

---

## ✅ Paso 3: Verificar en Firestore (Base de Datos)

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto: **klink-b0358**
3. Ve a **Firestore Database**
4. Navega a: `Users` → `[tuUserId]` → `Chats` → `[chatId]` → `Messages`
5. Busca el mensaje que acabas de enviar
6. **Verifica que el mensaje tenga estos campos:**

```json
{
  "isTemporary": true,
  "expiresAt": Timestamp(2024-XX-XX XX:XX:XX)  // 24 horas después de sentAt
}
```

**✅ Si ves estos campos:** El mensaje está guardado correctamente como temporal.

**❌ Si no ves `isTemporary` o `expiresAt`:** Hay un problema al guardar el mensaje.

---

## ✅ Paso 4: Verificar Filtrado de Mensajes Expirados

1. Abre un chat que tenga mensajes temporales
2. En los logs de Flutter, busca:

```
⏰ Mensaje temporal activo: [messageId]
   - expiresAt: 2024-XX-XX XX:XX:XX.XXX
   - Tiempo restante: 23h 59m
```

**✅ Si ves estos logs:** Los mensajes temporales se están cargando y mostrando correctamente.

---

## ✅ Paso 5: Verificar Eliminación Automática (Después de 24 Horas)

### Opción A: Esperar 24 horas (Prueba Real)
- Espera 24 horas después de enviar un mensaje temporal
- El mensaje debería desaparecer automáticamente
- En los logs verás: `⏰ Mensaje expirado eliminado: [messageId]`

### Opción B: Prueba Rápida (Modificar Temporalmente el Código)

Si quieres probar sin esperar 24 horas, puedes modificar temporalmente el código para usar 1 minuto en lugar de 24 horas:

1. Abre: `lib/screens/messages/controllers/message_controller.dart`
2. Busca: `expiresAt = DateTime.now().add(const Duration(hours: 24));`
3. Cámbialo temporalmente a: `expiresAt = DateTime.now().add(const Duration(minutes: 1));`
4. Envía un mensaje
5. Espera 1 minuto
6. El mensaje debería desaparecer automáticamente
7. **IMPORTANTE:** Vuelve a cambiar a `hours: 24` después de probar

---

## ✅ Paso 6: Verificar el Servicio de Limpieza

El servicio `MessageCleanupService` se ejecuta cada hora para limpiar mensajes expirados.

**En los logs deberías ver:**
```
🧹 Iniciando limpieza de mensajes expirados...
✅ Limpieza completada: X mensajes expirados eliminados
```

O si no hay mensajes expirados:
```
✅ Limpieza completada: No hay mensajes expirados
```

---

## 🔧 Solución de Problemas

### ❌ No veo los logs de "Mensaje temporal creado"
- Verifica que el switch esté activado en Chat Settings
- Verifica que estés viendo los logs de Flutter (no solo la consola del dispositivo)
- Reinicia la app después de activar la configuración

### ❌ El mensaje no tiene `isTemporary` en Firestore
- Verifica que la configuración se guardó correctamente
- Revisa los logs para ver si hay errores al guardar
- Verifica que `currentUser.temporaryMessagesEnabled` sea `true`

### ❌ Los mensajes no se eliminan después de 24 horas
- Verifica las reglas de Firestore (ya las actualizamos)
- Verifica que el servicio de limpieza esté corriendo
- Revisa los logs para ver si hay errores de permisos

### ❌ Error de permisos al eliminar
- Las reglas de Firestore ya están actualizadas
- Si aún ves errores, verifica que el usuario esté autenticado
- Revisa que el `userId` y `chatId` sean correctos

---

## 📊 Checklist de Verificación

- [ ] Switch "Mensajes Temporales" activado en Chat Settings
- [ ] Logs muestran `isTemporary = true` al enviar mensaje
- [ ] Logs muestran `expiresAt` con fecha 24 horas después
- [ ] Mensaje en Firestore tiene `isTemporary: true`
- [ ] Mensaje en Firestore tiene `expiresAt` con timestamp correcto
- [ ] Logs muestran "Mensaje temporal activo" al cargar chat
- [ ] Logs muestran tiempo restante correcto
- [ ] Mensajes expirados se eliminan automáticamente (después de 24h)
- [ ] Servicio de limpieza ejecuta correctamente

---

## 🎯 Resultado Esperado

Cuando todo funciona correctamente:

1. ✅ Los mensajes nuevos se crean con `isTemporary: true` y `expiresAt` (24h después)
2. ✅ Los mensajes temporales se muestran normalmente en el chat
3. ✅ Los mensajes expirados se filtran automáticamente y no aparecen
4. ✅ Los mensajes expirados se eliminan de Firestore automáticamente
5. ✅ Los chats vacíos se eliminan automáticamente



