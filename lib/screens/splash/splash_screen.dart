import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/screens/splash/controller/splash_controller.dart';
import 'package:chat_messenger/config/theme_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Init splash controller - esto ejecutará el bootstrap y navegará automáticamente
    Get.put(SplashController());
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla completamente invisible - transición directa sin mostrar logo
    return Scaffold(
      backgroundColor: darkThemeBgColor, // Mismo fondo oscuro para transición suave
      body: const SizedBox.shrink(), // Sin contenido visual
    );
  }
}
