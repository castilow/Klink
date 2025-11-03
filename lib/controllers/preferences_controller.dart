import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/i18n/app_languages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_messenger/config/theme_config.dart';

class PreferencesController extends GetxController {
  // Get the current instance
  static PreferencesController instance = Get.find();

  final RxBool isDarkMode = false.obs;
  final Rx<Locale> locale = Rx(const Locale('en'));
  final Rxn<String> chatWallpaperPath = Rxn();
  final Rxn<String> groupWallpaperPath = Rxn();
  final String _defaultLocale = 'en';

  late SharedPreferences _prefs;

  // Get current language map
  Map<String, String> get language =>
      AppLanguages().keys[locale.value.toString()] ?? {};

  // Get current language name
  String get langName => language['lang_name'] ?? '';
  
  // Check if user has custom theme preference
  bool get hasCustomThemePreference {
    try {
      return _prefs.getBool(_themeModeKey) != null;
    } catch (e) {
      return false;
    }
  }
  
  // Check if current theme matches system theme
  bool get isFollowingSystemTheme {
    return !hasCustomThemePreference;
  }
  
  // Get current system theme
  bool get currentSystemTheme {
    return _isDeviceDarkMode;
  }
  
  // Check if current theme matches system theme exactly
  bool get isThemeMatchingSystem {
    return isDarkMode.value == _isDeviceDarkMode;
  }
  
  // Get theme status description
  String get themeStatusDescription {
    if (hasCustomThemePreference) {
      return 'Modo personalizado';
    } else {
      return 'Automático (siguiendo sistema)';
    }
  }

  // SharedPreferences key names
  static const String _themeModeKey = 'theme_mode';
  static const String _localeKey = 'locale';
  static const String _chatWallpaperKey = 'chat_wallpaper';
  //static const String _groupWallpaperKey = 'group_wallpaper';

  @override
  void onInit() {
    // Establecer un valor inicial inmediato basado en el tema del sistema
    final Brightness systemBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    final bool platformIsDark = systemBrightness == Brightness.dark;
    isDarkMode.value = platformIsDark;
    Get.changeThemeMode(platformIsDark ? ThemeMode.dark : ThemeMode.light);
    _updateSystemOverlay();
    
    // Escuchar cambios en el tema del sistema en tiempo real
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      final Brightness newBrightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      final bool newIsDark = newBrightness == Brightness.dark;
      
      // Cambiar automáticamente al tema del sistema si no hay preferencia guardada
      try {
        final bool? savedPreference = _prefs.getBool(_themeModeKey);
        if (savedPreference == null) {
          // Modo automático activo - cambiar inmediatamente al tema del sistema
          _changeThemeWithoutSaving(newIsDark);
        }
      } catch (e) {
        // Si hay error, asumir modo automático y cambiar al tema del sistema
        _changeThemeWithoutSaving(newIsDark);
      }
    };
    
    // Listen to language change
    ever(locale, (Locale value) {
      _saveLocale(value);
      Get.updateLocale(value);
    });

    // Listen to theme change
    ever(isDarkMode, (bool value) {
      _changeTheme(value);
    });

    super.onInit();
  }

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Verificar si es la primera vez que se ejecuta la app
      final bool isFirstRun = !_prefs.containsKey('app_initialized');
      if (isFirstRun) {
        // Primera ejecución - asegurar que no hay preferencias de tema guardadas
        await _prefs.remove(_themeModeKey);
        await _prefs.setBool('app_initialized', true);
      }
      
      // Ahora cargar las preferencias guardadas
      _loadThemeMode();
      _loadLocale();
      
      print('✅ Preferences loaded successfully');
    } catch (e) {
      print('❌ Error loading preferences: $e');
      rethrow;
    }
  }

  // Update system overlay when the theme changes
  void _updateSystemOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      getSystemOverlayStyle(isDarkMode.value),
    );
  }

  // Change theme mode
  void _changeTheme(bool isDark) {
    isDarkMode.value = isDark;
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
    _updateSystemOverlay();
    _saveThemeMode(isDark);
  }
  
  // Change theme mode without saving preference (for system changes)
  void _changeThemeWithoutSaving(bool isDark) {
    isDarkMode.value = isDark;
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
    _updateSystemOverlay();
  }

  // Save theme mode to SharedPreferences
  Future<void> _saveThemeMode(bool isDark) async {
    await _prefs.setBool(_themeModeKey, isDark);
  }

  // Get device theme mode
  bool get _isDeviceDarkMode {
    final Brightness brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  // Load theme mode from SharedPreferences
  void _loadThemeMode() {
    try {
      // Por defecto, siempre usar el tema del sistema (modo automático)
      // Solo usar preferencia guardada si el usuario la estableció explícitamente
      final bool? savedIsDark = _prefs.getBool(_themeModeKey);
      
      if (savedIsDark == null) {
        // Modo automático por defecto - usar el tema del sistema
        isDarkMode.value = _isDeviceDarkMode;
      } else {
        // Usuario estableció preferencia manual - usar su elección
        isDarkMode.value = savedIsDark;
      }
      
      Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
      _updateSystemOverlay();
      _updateIconTheme();
    } catch (e) {
      // Si hay error, usar el tema del sistema (modo automático)
      isDarkMode.value = _isDeviceDarkMode;
      Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
      _updateSystemOverlay();
      _updateIconTheme();
    }
  }

  void _updateLocale(String langCode) {
    locale.value = Locale(langCode.split('_').first);
  }

  // Save locale to SharedPreferences
  Future<void> _saveLocale(Locale newLocale) async {
    await _prefs.setString(_localeKey, newLocale.toString());
  }

  bool _isLocaleSupported(String locale) {
    return AppLanguages().keys.containsKey(locale);
  }

  // Load locale from SharedPreferences
  void _loadLocale() {
    String? savedLocale = _prefs.getString(_localeKey);

    // Check result
    if (savedLocale == null) {
      // Get device locale
      final Locale? deviceLocale = Get.deviceLocale;

      // Check device locale
      final bool isSupported = _isLocaleSupported(deviceLocale.toString());
      _updateLocale(isSupported ? deviceLocale.toString() : _defaultLocale);
    } else {
      final bool isSupported = _isLocaleSupported(savedLocale);
      _updateLocale(isSupported ? savedLocale : _defaultLocale);
    }
  }

  ///
  ///  <-- 1-to-1 Chat Wallpaper -->
  ///
  Future<void> setChatWallpaper() async {
    // Pick image from camera/gallery
    final File? wallpaper = await DialogHelper.showPickImageDialog();
    if (wallpaper == null) return;
    // Update wallpaper path
    chatWallpaperPath.value = wallpaper.path;
    await _prefs.setString(_chatWallpaperKey, wallpaper.path);
  }

  Future<void> removeChatWallpaper() async {
    chatWallpaperPath.value = null;
    await _prefs.remove(_chatWallpaperKey);
  }

  Future<void> getChatWallpaperPath() async {
    final path = _prefs.getString(_chatWallpaperKey);

    if (path == null) return;

    // Check the file
    if (File(path).existsSync()) {
      chatWallpaperPath.value = path;
    }
  }
  // END

  ///
  ///  <-- Groups Wallpaper -->
  ///

  Future<void> setGroupWallpaper(String groupId) async {
    // Pick image from camera/gallery
    final File? wallpaper = await DialogHelper.showPickImageDialog();
    if (wallpaper == null) return;
    // Update wallpaper path
    groupWallpaperPath.value = wallpaper.path;
    await _prefs.setString(groupId, wallpaper.path);
  }

  Future<void> removeGroupWallpaper(String groupId) async {
    groupWallpaperPath.value = null;
    await _prefs.remove(groupId);
  }

  Future<void> getGroupWallpaperPath(String groupId) async {
    final path = _prefs.getString(groupId);

    if (path == null) return;

    // Check the file
    if (File(path).existsSync()) {
      groupWallpaperPath.value = path;
    }
    // debugPrint('getWallpaperPath() -> groupId: $groupId, path: $path');
  }

  // END

  Future<void> toggleTheme() async {
    final bool newValue = !isDarkMode.value;
    
    // Cuando el usuario toca el switch, está estableciendo una preferencia manual
    // Esto significa que ya no está en modo automático
    _changeTheme(newValue);
    
    // Mostrar feedback visual (opcional)
    print('🎨 Usuario estableció preferencia manual: ${newValue ? "Dark" : "Light"}');
  }
  
  // Establecer tema claro fijo
  Future<void> setLightTheme() async {
    _changeTheme(false); // false = light theme
    print('☀️ Usuario estableció tema claro fijo');
  }
  
  // Establecer tema oscuro fijo
  Future<void> setDarkTheme() async {
    _changeTheme(true); // true = dark theme
    print('🌙 Usuario estableció tema oscuro fijo');
  }

  // Resetear al tema del sistema
  Future<void> resetToSystemTheme() async {
    try {
      // Eliminar la preferencia guardada para volver al modo automático
      await _prefs.remove(_themeModeKey);
      
      // Usar el tema del sistema
      final bool systemIsDark = _isDeviceDarkMode;
      _changeThemeWithoutSaving(systemIsDark);
      
      print('🔄 Usuario volvió al modo automático');
    } catch (e) {
      // Si hay error, usar el tema del sistema sin guardar
      final bool systemIsDark = _isDeviceDarkMode;
      _changeThemeWithoutSaving(systemIsDark);
      print('🔄 Volvió al modo automático (con error)');
    }
  }
  
  // Forzar actualización del tema del sistema
  void forceSystemThemeUpdate() {
    final bool systemIsDark = _isDeviceDarkMode;
    if (!hasCustomThemePreference) {
      _changeThemeWithoutSaving(systemIsDark);
    }
  }

  // Asegurar que íconos/textos globales respeten el modo actual
  void _updateIconTheme() {
    // Actualmente gestionado por ThemeData en AppTheme.
    // Este hook está disponible por si se requiere lógica adicional específica por plataforma.
  }

  Future<void> updateLocale(String languageCode) async {
    locale.value = Locale(languageCode);
    await _prefs.setString('locale', languageCode);
  }
}
