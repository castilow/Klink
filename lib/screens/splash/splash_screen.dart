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

    // Splash siempre en modo oscuro
    return Scaffold(
      backgroundColor: darkThemeBgColor,
      body: Center(
        child: SizedBox(
          width: 160,
          height: 160,
          child: const Image(
            image: AssetImage('assets/images/app_logo.png'),
            fit: BoxFit.contain,
            color: Colors.white, // Tint blanco para modo oscuro
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
