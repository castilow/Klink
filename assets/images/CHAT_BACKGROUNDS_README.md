# Imágenes de Fondo del Chat

Este directorio debe contener las imágenes predeterminadas para el fondo del chat según el tema.

## Imágenes Requeridas

1. **`chat_background_dark.jpg`** - Imagen de fondo para modo oscuro
   - Debe ser una imagen apropiada para temas oscuros
   - Recomendado: Imagen con tonos oscuros, negros, grises oscuros, etc.
   - Formato: JPG, PNG o cualquier formato soportado por Flutter

2. **`chat_background_light.jpg`** - Imagen de fondo para modo claro
   - Debe ser una imagen apropiada para temas claros
   - Recomendado: Imagen con tonos claros, blancos, grises claros, etc.
   - Formato: JPG, PNG o cualquier formato soportado por Flutter

## Notas

- Si las imágenes no existen, la aplicación usará un color de fondo como fallback:
  - Modo oscuro: Color `#1E1E1E`
  - Modo claro: Color `#F5F5F5`
- El usuario puede cambiar estas imágenes desde la configuración de la app
- Las imágenes se aplican automáticamente según el tema (oscuro/claro) seleccionado

## Cómo Agregar las Imágenes

1. Coloca las imágenes en este directorio: `assets/images/`
2. Asegúrate de que los nombres sean exactamente:
   - `chat_background_dark.jpg` (o `.png`)
   - `chat_background_light.jpg` (o `.png`)
3. Las imágenes ya están declaradas en `pubspec.yaml` (directorio `assets/images/`)



















