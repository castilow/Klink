import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/background_controller.dart';
import '../controllers/preferences_controller.dart';

class ChatBackgroundWrapper extends StatelessWidget {
  final Widget child;

  const ChatBackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final BackgroundController controller = Get.put(BackgroundController());
    // Acceder a PreferencesController para hacer el widget reactivo a cambios de tema
    final PreferencesController prefController = Get.find<PreferencesController>();

    return Obx(() {
      // Acceder a isDarkMode y backgroundType para forzar reactividad completa
      final isDark = prefController.isDarkMode.value;
      final bgType = controller.backgroundType.value;
      final customPath = controller.customImagePath.value;
      
      // Esto fuerza la reactividad cuando cambia cualquier cosa relacionada
      final _ = '$isDark-$bgType-$customPath';
      
      return Container(
        decoration: controller.currentDecoration,
        child: child,
      );
    });
  }
}
