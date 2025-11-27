import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:chat_messenger/controllers/preferences_controller.dart';

enum BackgroundType {
  color,
  gradient,
  image,
}

class BackgroundController extends GetxController {
  static BackgroundController get to => Get.find();

  final Rx<BackgroundType> backgroundType = BackgroundType.image.obs; // Cambiado a image por defecto
  final RxInt selectedColorValue = 0xFFFFFFFF.obs; // Default white
  final RxInt selectedGradientIndex = 0.obs;
  final RxString customImagePath = ''.obs;
  
  // Imágenes predeterminadas según el tema
  // Usar las imágenes existentes como predeterminadas
  static const String defaultDarkImage = 'assets/images/chat2.png';
  static const String defaultLightImage = 'assets/images/chat1.png';

  // Predefined gradients
  final List<LinearGradient> gradients = [
    const LinearGradient(colors: [Color(0xFF74ebd5), Color(0xFFACB6E5)]),
    const LinearGradient(colors: [Color(0xFFff9a9e), Color(0xFFfecfef)]),
    const LinearGradient(colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)]),
    const LinearGradient(colors: [Color(0xFF84fab0), Color(0xFF8fd3f4)]),
    const LinearGradient(colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)]),
    const LinearGradient(colors: [Color(0xFF43e97b), Color(0xFF38f9d7)]),
    const LinearGradient(colors: [Color(0xFFfa709a), Color(0xFFfee140)]),
    const LinearGradient(colors: [Color(0xFF30cfd0), Color(0xFF330867)]),
    const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]), // Dark Premium
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _listenToThemeChanges();
  }

  void _listenToThemeChanges() {
    // Escuchar cambios en el tema para actualizar la imagen predeterminada
    try {
      final PreferencesController prefController = Get.find<PreferencesController>();
      ever(prefController.isDarkMode, (bool isDark) {
        // Solo actualizar si no hay imagen personalizada
        if (customImagePath.value.isEmpty && backgroundType.value == BackgroundType.image) {
          // Forzar actualización del decoration
          update();
        }
      });
    } catch (e) {
      // Si no se encuentra PreferencesController, continuar sin escuchar
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final typeIndex = prefs.getInt('bg_type');
    final savedImagePath = prefs.getString('bg_image_path') ?? '';
    
    // Si no hay configuración guardada, usar imagen predeterminada según el tema
    if (typeIndex == null) {
      backgroundType.value = BackgroundType.image;
      customImagePath.value = ''; // Vacío = usar predeterminada
      // Guardar la configuración inicial
      await _saveSettings();
    } else {
      backgroundType.value = BackgroundType.values[typeIndex];
      selectedColorValue.value = prefs.getInt('bg_color') ?? 0xFFFFFFFF;
      selectedGradientIndex.value = prefs.getInt('bg_gradient_index') ?? 0;
      customImagePath.value = savedImagePath;
      
      // Si el tipo es image pero no hay imagen personalizada, asegurar que use predeterminada
      if (backgroundType.value == BackgroundType.image && savedImagePath.isEmpty) {
        customImagePath.value = ''; // Asegurar que esté vacío para usar predeterminada
      }
    }
    
    // Forzar actualización después de cargar
    update();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bg_type', backgroundType.value.index);
    await prefs.setInt('bg_color', selectedColorValue.value);
    await prefs.setInt('bg_gradient_index', selectedGradientIndex.value);
    await prefs.setString('bg_image_path', customImagePath.value);
  }

  void setSolidColor(Color color) {
    backgroundType.value = BackgroundType.color;
    selectedColorValue.value = color.value;
    _saveSettings();
  }

  void setGradient(int index) {
    backgroundType.value = BackgroundType.gradient;
    selectedGradientIndex.value = index;
    _saveSettings();
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      backgroundType.value = BackgroundType.image;
      customImagePath.value = image.path;
      _saveSettings();
      update(); // Forzar actualización
    } else {
      // Si el usuario cancela, pero no hay imagen personalizada, usar predeterminada
      if (customImagePath.value.isEmpty) {
        await resetToDefaultImage();
      }
    }
  }
  
  // Restablecer a la imagen predeterminada según el tema
  Future<void> resetToDefaultImage() async {
    backgroundType.value = BackgroundType.image;
    customImagePath.value = ''; // Vacío = usar predeterminada
    
    // Limpiar cualquier configuración de imagen personalizada guardada
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bg_image_path');
    
    _saveSettings();
    update(); // Forzar actualización
  }
  
  // Verificar si tiene imagen personalizada
  bool get hasCustomImage {
    return customImagePath.value.isNotEmpty && 
           File(customImagePath.value).existsSync();
  }

  // Hacer que currentDecoration sea reactivo accediendo a isDarkMode
  BoxDecoration get currentDecoration {
    // Acceder a isDarkMode para hacerlo reactivo
    try {
      final PreferencesController prefController = Get.find<PreferencesController>();
      final bool isDark = prefController.isDarkMode.value; // Esto hace que sea reactivo
      
      switch (backgroundType.value) {
        case BackgroundType.color:
          return BoxDecoration(color: Color(selectedColorValue.value));
        case BackgroundType.gradient:
          if (selectedGradientIndex.value < gradients.length) {
            return BoxDecoration(gradient: gradients[selectedGradientIndex.value]);
          }
          return BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5));
        case BackgroundType.image:
          // Si hay imagen personalizada Y el archivo existe, usarla
          if (customImagePath.value.isNotEmpty) {
            final file = File(customImagePath.value);
            if (file.existsSync()) {
              return BoxDecoration(
                image: DecorationImage(
                  image: FileImage(file),
                  fit: BoxFit.cover,
                ),
              );
            } else {
              // Si el archivo no existe, limpiar la ruta y usar predeterminada
              customImagePath.value = '';
              _saveSettings();
            }
          }
          
          // Si no hay imagen personalizada, usar la imagen predeterminada según el tema
          final String defaultImage = isDark ? defaultDarkImage : defaultLightImage;
          
          return BoxDecoration(
            // Color de fondo como fallback si la imagen no carga
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            image: DecorationImage(
              image: AssetImage(defaultImage),
              fit: BoxFit.cover,
              opacity: isDark ? 0.8 : 0.3, // Más visible para que se note el cambio
            ),
          );
      }
    } catch (e) {
      // Fallback si no se puede obtener el tema
      return const BoxDecoration(color: Color(0xFFF5F5F5));
    }
  }
  
  // Obtener la ruta de la imagen predeterminada actual según el tema
  String get currentDefaultImagePath {
    try {
      final PreferencesController prefController = Get.find<PreferencesController>();
      final bool isDark = prefController.isDarkMode.value;
      return isDark ? defaultDarkImage : defaultLightImage;
    } catch (e) {
      return defaultLightImage;
    }
  }
  
  // Verificar si está usando imagen predeterminada
  bool get isUsingDefaultImage {
    return backgroundType.value == BackgroundType.image && 
           (customImagePath.value.isEmpty || !File(customImagePath.value).existsSync());
  }
}

