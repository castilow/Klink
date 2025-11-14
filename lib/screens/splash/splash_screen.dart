import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/screens/splash/controller/splash_controller.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Init splash controller
    Get.put(SplashController());

    // Detectar el tema actual del sistema
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
      body: Center(
        child: SizedBox(
          width: 160,
          height: 160,
          child: Image.asset(
            'assets/images/app_logo.png',
            fit: BoxFit.contain,
            // Sin color forzado - usa el color original de la imagen
            // Se adapta automáticamente al tema
          ),
        ),
      ),
    );
  }
}
