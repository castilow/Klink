import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/controllers/background_controller.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PreferencesController prefController = Get.find();
    final bool isDarkMode = AppTheme.of(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
        elevation: 0,
        leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      size: 20,
                    ),
                    onPressed: () => Get.back(),
                  ),
        title: Text(
                      'Ajustes',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
        actions: [
                  TextButton(
                    onPressed: () {
                      // TODO: Implementar edición
                    },
                    child: Text(
                      'Editar',
                      style: TextStyle(
                        color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
      body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Chat Preview Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEMA - MODO NOCTURNO AUTOMÁTICO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Chat Preview
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        // Fondo de abajo: chat2.png cubriendo toda la pantalla
                        color: Color(0xFF000000), // Fondo negro base
                        image: DecorationImage(
                          image: AssetImage('assets/images/chat2.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        // Capa superior: patrón chat1.png pequeño y repetido encima
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/chat1.png'),
                            fit: BoxFit.none,
                            repeat: ImageRepeat.repeat,
                            alignment: Alignment.center,
                            scale: 3.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Received message
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                child: Text(
                                  '¡Buenos días! 👋',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Another received message
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¿Sabes qué hora es?',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '7:20 PM',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Sent message
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCF8C6),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Es de mañana en Tokio 😎',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '7:20 PM',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.done_all,
                                          color: Colors.grey[600],
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Theme Options Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Section Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.palette,
                            color: isDarkMode ? Colors.purple[400] : Colors.purple[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Tema de la aplicación',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Theme Options
                    Obx(() {
                      final bool dark = prefController.isDarkMode.value;
                      final bool hasCustomPreference = prefController.hasCustomThemePreference;
                      
                      return Column(
                        children: [
                          // Automático
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: !hasCustomPreference 
                                  ? (isDarkMode ? Colors.green[700] : Colors.green[100])
                                  : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.settings_system_daydream,
                                color: !hasCustomPreference 
                                  ? Colors.white 
                                  : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Automático',
                              style: TextStyle(
                                fontWeight: !hasCustomPreference ? FontWeight.w600 : FontWeight.normal,
                                color: !hasCustomPreference 
                                  ? (isDarkMode ? Colors.green[400] : Colors.green[700])
                                  : (isDarkMode ? Colors.white : Colors.black87),
                              ),
                            ),
                            subtitle: Text(
                              'Seguir configuración del sistema',
                              style: TextStyle(
                                color: !hasCustomPreference 
                                  ? (isDarkMode ? Colors.green[300] : Colors.green[600])
                                  : Colors.grey[400],
                              ),
                            ),
                            trailing: !hasCustomPreference 
                              ? Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.green[400] : Colors.green[600],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              : null,
                            onTap: () => prefController.resetToSystemTheme(),
                          ),
                          
                          Divider(
                            height: 1,
                            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                            indent: 56,
                          ),
                          
                          // Modo Claro
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: hasCustomPreference && !dark
                                  ? (isDarkMode ? Colors.blue[700] : Colors.blue[100])
                                  : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.light_mode,
                                color: hasCustomPreference && !dark
                                  ? Colors.white
                                  : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Modo Claro',
                              style: TextStyle(
                                fontWeight: hasCustomPreference && !dark ? FontWeight.w600 : FontWeight.normal,
                                color: hasCustomPreference && !dark
                                  ? (isDarkMode ? Colors.blue[400] : Colors.blue[700])
                                  : (isDarkMode ? Colors.white : Colors.black87),
                              ),
                            ),
                            subtitle: Text(
                              'Tema claro fijo',
                              style: TextStyle(
                                color: hasCustomPreference && !dark
                                  ? (isDarkMode ? Colors.blue[300] : Colors.blue[600])
                                  : Colors.grey[400],
                              ),
                            ),
                            trailing: hasCustomPreference && !dark
                              ? Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              : null,
                            onTap: () => prefController.setLightTheme(),
                          ),
                          
                          Divider(
                            height: 1,
                            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                            indent: 56,
                          ),
                          
                          // Modo Oscuro
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: hasCustomPreference && dark
                                  ? (isDarkMode ? Colors.purple[700] : Colors.purple[100])
                                  : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.dark_mode,
                                color: hasCustomPreference && dark
                                  ? Colors.white
                                  : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Modo Oscuro',
                              style: TextStyle(
                                fontWeight: hasCustomPreference && dark ? FontWeight.w600 : FontWeight.normal,
                                color: hasCustomPreference && dark
                                  ? (isDarkMode ? Colors.purple[400] : Colors.purple[700])
                                  : (isDarkMode ? Colors.white : Colors.black87),
                              ),
                            ),
                            subtitle: Text(
                              'Tema oscuro fijo',
                              style: TextStyle(
                                color: hasCustomPreference && dark
                                  ? (isDarkMode ? Colors.purple[300] : Colors.purple[600])
                                  : Colors.grey[400],
                              ),
                            ),
                            trailing: hasCustomPreference && dark
                              ? Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.purple[400] : Colors.purple[600],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              : null,
                            onTap: () => prefController.setDarkTheme(),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // Additional Appearance Options
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                          color: isDarkMode ? Colors.blue[700] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                          Icons.text_fields,
                          color: isDarkMode ? Colors.white : Colors.blue[700],
                      size: 20,
                    ),
                  ),
                  title: Text(
                        'Tamaño del texto',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                        'Sistema',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 16,
                  ),
                  onTap: () {
                        _showTextSizePicker(context, isDarkMode, prefController);
                      },
                    ),
                    
                    Divider(
                      height: 1,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      indent: 56,
                  ),
                    
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.green[700] : Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.rounded_corner,
                          color: isDarkMode ? Colors.white : Colors.green[700],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Esquinas de los mensajes',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 16,
                      ),
                      onTap: () {
                        _showBubbleRadiusPicker(context, isDarkMode, prefController);
                      },
                    ),
                    
                    Divider(
                      height: 1,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      indent: 56,
                    ),
                    
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.orange[700] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.animation,
                          color: isDarkMode ? Colors.white : Colors.orange[700],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Animaciones',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 16,
                      ),
                      onTap: () {
                        // TODO: Implementar configuración de animaciones
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Bubble Colors and Background Options
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                    ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.purple[700] : Colors.purple[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.palette,
                          color: isDarkMode ? Colors.white : Colors.purple[700],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Colores de las burbujas',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 16,
                      ),
                      onTap: () {
                        Get.toNamed(AppRoutes.bubbleColorPicker);
                      },
                    ),
                    
                    Divider(
                      height: 1,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      indent: 56,
                    ),
                    
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.indigo[700] : Colors.indigo[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.wallpaper,
                          color: isDarkMode ? Colors.white : Colors.indigo[700],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Fondo del chat',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 16,
                      ),
                      onTap: () {
                        _showChatBackgroundPicker(context, isDarkMode, prefController);
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showBubbleRadiusPicker(BuildContext context, bool isDarkMode, PreferencesController prefController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
          ),
        ),
            
            Padding(
              padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                    'Esquinas de los mensajes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
                    'Ajusta el radio de las esquinas de las burbujas de mensajes',
              style: TextStyle(
                fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
                  const SizedBox(height: 30),
            
                  // Preview section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
              child: Obx(() {
                      final double radius = prefController.customBubbleRadius.value;
                      return Column(
                        children: [
                          // Received message preview
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[800] : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(radius),
                                  bottomLeft: Radius.circular(radius),
                                  bottomRight: Radius.circular(radius),
                                ),
                              ),
                              child: Text(
                                'Mensaje recibido',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          
                          // Sent message preview
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                                color: const Color(0xFFDCF8C6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(radius),
                                  topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(radius),
                      bottomRight: Radius.circular(radius),
                    ),
                              ),
                              child: Text(
                                'Mensaje enviado',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Slider
                  Obx(() {
                    final double currentRadius = prefController.customBubbleRadius.value;
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                              'Radio: ${currentRadius.toStringAsFixed(0)}',
                        style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                prefController.resetBubbleRadius();
                              },
                              child: Text(
                                'Restablecer',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                        ),
                      ),
                            ),
                          ],
                        ),
                        Slider(
                          value: currentRadius,
                          min: 0,
                          max: 30,
                          divisions: 30,
                          activeColor: isDarkMode ? Colors.purple[400] : Colors.purple[600],
                          inactiveColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          onChanged: (value) {
                            prefController.setBubbleRadius(value);
                          },
                        ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '0',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '30',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                          ),
                        ],
                      ),
                    ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatBackgroundPicker(BuildContext context, bool isDarkMode, PreferencesController prefController) {
    BackgroundController bgController;
    if (Get.isRegistered<BackgroundController>()) {
      bgController = Get.find<BackgroundController>();
    } else {
      bgController = Get.put(BackgroundController());
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fondo del chat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Option: Solid Color
                  Obx(() {
                    final bool isSelected = bgController.backgroundType.value == BackgroundType.color;
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(bgController.selectedColorValue.value),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected 
                              ? (isDarkMode ? Colors.purple[400]! : Colors.purple[600]!)
                              : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                      title: Text(
                        'Color sólido',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected 
                        ? Icon(
                            Icons.check_circle,
                            color: isDarkMode ? Colors.purple[400] : Colors.purple[600],
                          )
                        : null,
                      onTap: () {
                        _showColorPicker(context, isDarkMode, bgController);
                      },
                );
              }),
                  
                  Divider(
                    height: 1,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                    indent: 56,
                  ),
                  
                  // Option: Gradients
                  Obx(() {
                    final bool isSelected = bgController.backgroundType.value == BackgroundType.gradient;
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: bgController.gradients[bgController.selectedGradientIndex.value],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected 
                              ? (isDarkMode ? Colors.purple[400]! : Colors.purple[600]!)
                              : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                      title: Text(
                        'Gradientes',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected 
                        ? Icon(
                            Icons.check_circle,
                            color: isDarkMode ? Colors.purple[400] : Colors.purple[600],
                          )
                        : Icon(
                            Icons.arrow_forward_ios,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            size: 16,
                          ),
                      onTap: () {
                        _showGradientPicker(context, isDarkMode, bgController);
                      },
                    );
                  }),
                  
                  Divider(
                    height: 1,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                    indent: 56,
                  ),
                  
                  // Option: Image
            Obx(() {
                    final bool isSelected = bgController.backgroundType.value == BackgroundType.image;
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected 
                              ? (isDarkMode ? Colors.purple[400]! : Colors.purple[600]!)
                              : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: Icon(
                          Icons.image,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Imagen',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected 
                        ? Icon(
                            Icons.check_circle,
                            color: isDarkMode ? Colors.purple[400] : Colors.purple[600],
                          )
                        : Icon(
                            Icons.arrow_forward_ios,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            size: 16,
                          ),
                      onTap: () async {
                        Get.back();
                        // Activar el tipo de fondo como "imagen" primero
                        bgController.backgroundType.value = BackgroundType.image;
                        
                        // Si no hay imagen personalizada, usar la predeterminada
                        if (!bgController.hasCustomImage) {
                          await bgController.resetToDefaultImage();
                        }
                        
                        // Mostrar opciones: usar predeterminada o elegir personalizada
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(
                                    Icons.image,
                                    color: isDarkMode ? Colors.purple[400] : Colors.purple[600],
                                  ),
                                  title: Text(
                                    'Usar imagen predeterminada',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  onTap: () {
                                    Get.back();
                                    bgController.resetToDefaultImage();
                                  },
                                ),
                                ListTile(
                                  leading: Icon(
                                    Icons.photo_library,
                                    color: isDarkMode ? Colors.purple[400] : Colors.purple[600],
                                  ),
                                  title: Text(
                                    'Elegir imagen personalizada',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  onTap: () async {
                                    Get.back();
                                    await bgController.pickImage();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, bool isDarkMode, BackgroundController bgController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Elegir color',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: Color(bgController.selectedColorValue.value),
            onColorChanged: (color) {
              bgController.setSolidColor(color);
            },
            availableColors: [
              Colors.white,
              Colors.black,
              Colors.grey[300]!,
              Colors.grey[600]!,
              Colors.grey[900]!,
              Colors.blue[50]!,
              Colors.blue[100]!,
              Colors.blue[200]!,
              Colors.blue[300]!,
              Colors.blue[400]!,
              Colors.blue[500]!,
              Colors.blue[600]!,
              Colors.blue[700]!,
              Colors.blue[800]!,
              Colors.blue[900]!,
              Colors.green[50]!,
              Colors.green[100]!,
              Colors.green[200]!,
              Colors.green[300]!,
              Colors.green[400]!,
              Colors.green[500]!,
              Colors.green[600]!,
              Colors.green[700]!,
              Colors.green[800]!,
              Colors.green[900]!,
              Colors.purple[50]!,
              Colors.purple[100]!,
              Colors.purple[200]!,
              Colors.purple[300]!,
              Colors.purple[400]!,
              Colors.purple[500]!,
              Colors.purple[600]!,
              Colors.purple[700]!,
              Colors.purple[800]!,
              Colors.purple[900]!,
              Colors.orange[50]!,
              Colors.orange[100]!,
              Colors.orange[200]!,
              Colors.orange[300]!,
              Colors.orange[400]!,
              Colors.orange[500]!,
              Colors.orange[600]!,
              Colors.orange[700]!,
              Colors.orange[800]!,
              Colors.orange[900]!,
              Colors.red[50]!,
              Colors.red[100]!,
              Colors.red[200]!,
              Colors.red[300]!,
              Colors.red[400]!,
              Colors.red[500]!,
              Colors.red[600]!,
              Colors.red[700]!,
              Colors.red[800]!,
              Colors.red[900]!,
              Colors.pink[50]!,
              Colors.pink[100]!,
              Colors.pink[200]!,
              Colors.pink[300]!,
              Colors.pink[400]!,
              Colors.pink[500]!,
              Colors.pink[600]!,
              Colors.pink[700]!,
              Colors.pink[800]!,
              Colors.pink[900]!,
              Colors.teal[50]!,
              Colors.teal[100]!,
              Colors.teal[200]!,
              Colors.teal[300]!,
              Colors.teal[400]!,
              Colors.teal[500]!,
              Colors.teal[600]!,
              Colors.teal[700]!,
              Colors.teal[800]!,
              Colors.teal[900]!,
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Listo',
              style: TextStyle(
                color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGradientPicker(BuildContext context, bool isDarkMode, BackgroundController bgController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
                children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                    'Elegir gradiente',
                        style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: bgController.gradients.length,
                      itemBuilder: (context, index) {
                        final bool isSelected = bgController.backgroundType.value == BackgroundType.gradient &&
                            bgController.selectedGradientIndex.value == index;
                        return GestureDetector(
                          onTap: () {
                            bgController.setGradient(index);
                            Get.back();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: bgController.gradients[index],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                  ? (isDarkMode ? Colors.purple[400]! : Colors.purple[600]!)
                                  : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextSizePicker(BuildContext context, bool isDarkMode, PreferencesController prefController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
                      ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      Text(
                    'Tamaño del texto',
                        style: TextStyle(
                      fontSize: 20,
                          fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                  const SizedBox(height: 8),
                      Text(
                    'Ajusta el tamaño del texto en los mensajes',
                        style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Preview section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Obx(() {
                      final double textSize = prefController.customTextSize.value;
                      final double fontSize = 14 * textSize;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Texto de ejemplo',
                            style: TextStyle(
                              fontSize: fontSize,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Este es un ejemplo de cómo se verá el texto con el tamaño seleccionado.',
                            style: TextStyle(
                              fontSize: fontSize,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Slider
                  Obx(() {
                    final double currentSize = prefController.customTextSize.value;
                    final int percentage = (currentSize * 100).round();
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tamaño: $percentage%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                prefController.resetTextSize();
                              },
                              child: Text(
                                'Restablecer',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                                ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                          value: currentSize,
                          min: 0.7,
                          max: 1.3,
                          divisions: 12,
                          activeColor: isDarkMode ? Colors.purple[400] : Colors.purple[600],
                          inactiveColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    onChanged: (value) {
                            prefController.setTextSize(value);
                    },
                  ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '70%',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '130%',
                  style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
