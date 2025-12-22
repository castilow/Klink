# 🎨 Configuración de Filtros Profesionales para Fotos

Esta aplicación soporta múltiples servicios de APIs para aplicar filtros gráficos profesionales a las fotos.

## 📋 Servicios Disponibles

### 1. **Cloudinary** (Recomendado ⭐)

**Ventajas:**
- ✅ Más de 100 filtros y efectos profesionales
- ✅ Plan gratuito generoso (25 créditos/mes)
- ✅ Procesamiento en la nube (rápido)
- ✅ Filtros artísticos avanzados (oil paint, cartoon, etc.)
- ✅ Ajustes automáticos (auto-brightness, auto-contrast)

**Cómo configurar:**

1. Regístrate en [Cloudinary](https://cloudinary.com/users/register/free)
2. Obtén tus credenciales del Dashboard:
   - Cloud Name
   - API Key
   - API Secret

3. Actualiza `lib/config/app_config.dart`:
```dart
static const String cloudinaryCloudName = "tu-cloud-name";
static const String cloudinaryApiKey = "tu-api-key";
static const String cloudinaryApiSecret = "tu-api-secret";
```

**Filtros disponibles con Cloudinary:**
- 🎨 Filtros artísticos: Vintage, Sepia, Oil Paint, Cartoon
- ⚡ Ajustes automáticos: Auto-brightness, Auto-contrast, Auto-color
- 🎭 Efectos especiales: Vignette, Pixelate, Blur, Sharpen
- 🌈 Ajustes de color: Brillo, Contraste, Saturación, Hue

---

### 2. **Imgix** (Alternativa rápida)

**Ventajas:**
- ✅ CDN global (muy rápido)
- ✅ Transformaciones en tiempo real
- ✅ Optimización automática

**Cómo configurar:**

1. Regístrate en [Imgix](https://imgix.com)
2. Crea un source y obtén tu dominio
3. Actualiza `lib/config/app_config.dart`:
```dart
static const String imgixDomain = "tu-dominio.imgix.net";
static const String imgixApiKey = "tu-api-key";
```

**Nota:** Imgix requiere que las imágenes estén en un servicio compatible (S3, Cloud Storage, etc.)

---

### 3. **API Personalizada**

Si tienes tu propio servicio de filtros, puedes conectarlo:

1. Actualiza `lib/config/app_config.dart`:
```dart
static const String customFiltersApiUrl = "https://tu-api.com/filters";
```

2. Tu API debe aceptar:
   - `POST /filters`
   - FormData con:
     - `image`: Archivo de imagen
     - `filter`: Nombre del filtro
     - `intensity`: Intensidad (0.0 a 1.0)

3. Tu API debe retornar:
```json
{
  "url": "https://url-de-imagen-procesada.jpg",
  "image_url": "https://url-alternativa.jpg"
}
```

---

## 🚀 Uso en la Aplicación

### Automático
Si configuras Cloudinary, la app automáticamente usará la API para filtros profesionales.

### Manual
```dart
// Usar API específica
final File? filtered = await FiltersApi.applyFilter(
  imageFile: imageFile,
  filterName: 'vintage',
  intensity: 1.0,
  service: 'cloudinary', // o 'imgix', 'custom'
);

// O usar el helper (elige automáticamente)
final File? filtered = await ImageFiltersHelper.applyFilter(
  imageFile: imageFile,
  filterName: 'oil_paint',
  intensity: 1.0,
);
```

---

## 📊 Comparación de Servicios

| Característica | Cloudinary | Imgix | Local |
|---------------|------------|-------|-------|
| Filtros profesionales | ✅ Muchos | ✅ Varios | ⚠️ Básicos |
| Velocidad | ⚡ Rápido | ⚡⚡ Muy rápido | ⚡⚡⚡ Instantáneo |
| Requiere internet | ✅ Sí | ✅ Sí | ❌ No |
| Plan gratuito | ✅ Sí | ✅ Sí | ✅ Siempre |
| Filtros artísticos | ✅ Sí | ⚠️ Limitados | ❌ No |

---

## 💡 Recomendación

**Para producción:** Usa **Cloudinary** - ofrece la mejor relación calidad/precio con muchos filtros profesionales.

**Para desarrollo/testing:** Usa procesamiento local (ya configurado) - no requiere configuración.

---

## 🔧 Solución de Problemas

### Error: "Cloudinary credentials not configured"
- Verifica que hayas actualizado `app_config.dart` con tus credenciales reales
- Asegúrate de que `cloudinaryCloudName != "your-cloud-name"`

### Error: "API request failed"
- Verifica tu conexión a internet
- Revisa que las credenciales sean correctas
- La app automáticamente usará procesamiento local como fallback

---

## 📚 Recursos

- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Cloudinary Image Transformations](https://cloudinary.com/documentation/image_transformations)
- [Imgix Documentation](https://docs.imgix.com)





















