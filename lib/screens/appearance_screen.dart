import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
import 'package:chat_messenger/theme/app_theme.dart';

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
                        // TODO: Implementar configuración de tamaño de texto
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
                        // TODO: Implementar configuración de esquinas
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
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
