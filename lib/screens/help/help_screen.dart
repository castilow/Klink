import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/components/custom_appbar.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF17212B) : const Color(0xFFF0F2F5),
      appBar: CustomAppBar(
        title: Text(
          'Preguntas Frecuentes',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // FAQ Items
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF17212B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildFAQItem(
                      context: context,
                      question: '¿Cómo cambio mi foto de perfil?',
                      answer:
                          'Para cambiar tu foto de perfil, ve a Perfil > Mi Perfil. Luego toca tu foto actual y selecciona una nueva imagen de tu galería o toma una foto.',
                      icon: Icons.person,
                      isDarkMode: isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildFAQItem(
                      context: context,
                      question: '¿Cómo bloqueo a un contacto?',
                      answer:
                          'Para bloquear a un contacto, abre el chat con esa persona, toca el ícono de menú (tres puntos) en la esquina superior derecha y selecciona "Bloquear". También puedes hacerlo desde Configuración > Privacidad y Seguridad > Cuentas Bloqueadas.',
                      icon: Icons.block,
                      isDarkMode: isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildFAQItem(
                      context: context,
                      question: '¿Cómo elimino un mensaje?',
                      answer:
                          'Mantén presionado el mensaje que deseas eliminar y selecciona "Eliminar". Puedes elegir eliminar solo para ti o para todos los participantes del chat.',
                      icon: Icons.delete_outline,
                      isDarkMode: isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildFAQItem(
                      context: context,
                      question: '¿Cómo envío una foto o video?',
                      answer:
                          'En cualquier chat, toca el ícono de clip o cámara en la barra de escritura. Puedes seleccionar una imagen o video de tu galería, o tomar una nueva foto o video directamente.',
                      icon: Icons.photo_camera_outlined,
                      isDarkMode: isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildFAQItem(
                      context: context,
                      question: '¿Cómo cambio mi estado o bio?',
                      answer:
                          'Ve a Perfil > Bio para editar tu biografía. Puedes escribir sobre ti, agregar un pensamiento de hasta 80 caracteres, o vincular música de Spotify o Apple Music.',
                      icon: Icons.edit_outlined,
                      isDarkMode: isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildFAQItem(
                      context: context,
                      question: '¿Cómo silencio las notificaciones?',
                      answer:
                          'Puedes silenciar las notificaciones de un chat específico desde el menú del chat (tres puntos) y seleccionando "Silenciar". Para silenciar todas las notificaciones, ve a Configuración > Notificaciones y Sonidos.',
                      icon: Icons.notifications_off_outlined,
                      isDarkMode: isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildFAQItem(
                      context: context,
                      question: '¿Cómo cambio mi nombre de usuario?',
                      answer:
                          'Ve a Perfil > Username para cambiar tu nombre de usuario. Recuerda que solo puedes cambiarlo una vez y debe ser único.',
                      icon: Icons.alternate_email,
                      isDarkMode: isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildFAQItem(
                      context: context,
                      question: '¿Cómo creo un grupo?',
                      answer:
                          'Ve a la pestaña de Chats, toca el ícono de "Nuevo chat" y selecciona "Nuevo grupo". Luego elige los contactos que deseas agregar y dale un nombre al grupo.',
                      icon: Icons.group_add_outlined,
                      isDarkMode: isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildFAQItem(
                      context: context,
                      question: '¿Cómo activo los mensajes temporales?',
                      answer:
                          'Ve a Configuración > Configuración de Chat y activa la opción "Mensajes Temporales". Los mensajes se eliminarán automáticamente después de 24 horas.',
                      icon: Icons.access_time,
                      isDarkMode: isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildFAQItem(
                      context: context,
                      question: '¿Cómo elimino mi cuenta?',
                      answer:
                          'Para eliminar tu cuenta, ve a Configuración > Privacidad y Seguridad. En la parte inferior encontrarás la opción para eliminar tu cuenta. Esta acción es permanente y no se puede deshacer.',
                      icon: Icons.delete_forever_outlined,
                      isDarkMode: isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildFAQItem(
                      context: context,
                      question: '¿Cómo reporto un problema?',
                      answer:
                          'Si encuentras un problema o necesitas ayuda, puedes contactarnos a través de nuestra página web en klink.technology o enviando un mensaje desde Configuración > Ayuda.',
                      icon: Icons.report_problem_outlined,
                      isDarkMode: isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildFAQItem(
                      context: context,
                      question: '¿Cómo cambio el idioma de la aplicación?',
                      answer:
                          'Ve a Configuración > Idioma y selecciona el idioma que prefieras de la lista disponible. La aplicación se actualizará automáticamente.',
                      icon: Icons.language,
                      isDarkMode: isDarkMode,
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

  Widget _buildFAQItem({
    required BuildContext context,
    required String question,
    required String answer,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Icon(
          icon,
          color: isDarkMode ? primaryColor : primaryColor,
          size: 24,
        ),
        title: Text(
          question,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        collapsedIconColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        childrenPadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      indent: 56,
      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
    );
  }
}





