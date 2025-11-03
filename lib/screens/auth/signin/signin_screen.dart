import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/components/app_logo.dart';
import 'package:chat_messenger/screens/auth/signin/controller/signin_controller.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
import 'dart:ui';
 

class SignInScreen extends GetView<SignInController> {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Forzar modo oscuro siempre en pantallas de autenticación
    const isDark = true;
    const backgroundColor = darkThemeBgColor;
    const textColor = darkThemeTextColor;
    final secondaryTextColor = Colors.grey[400];
    const fieldBgColor = darkPrimaryContainer;
    final fieldBorderColor = Colors.grey[600];
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    darkThemeBgColor,
                    darkPrimaryContainer,
                    darkPrimaryContainer,
                    darkThemeBgColor,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: controller.emailFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),

                      // Logo without background shadow
                      Container(
                        width: 160,
                        height: 160,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: const AppLogo(width: 160),
                      ),

                      const SizedBox(height: 40),

                      Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Ingresa a tu cuenta',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Email Field
                      Container(
                        decoration: BoxDecoration(
                          color: fieldBgColor,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: fieldBorderColor!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: controller.emailController,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            height: 1.5,
                          ),
                          cursorColor: isDark ? Colors.white : const Color(0xFF2196F3),
                          validator: (String? value) {
                            if (GetUtils.isEmail(value ?? '')) return null;
                            return 'Por favor ingresa un email válido';
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: fieldBgColor,
                            contentPadding: const EdgeInsets.all(20),
                            hintText: 'Email',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                            errorStyle: const TextStyle(
                              color: Color(0xFFFF3B30),
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                            prefixIcon: Icon(
                              IconlyLight.message,
                              color: Colors.grey[400],
                              size: 22,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.grey[700]!, width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      Obx(
                        () => Container(
                          decoration: BoxDecoration(
                            color: fieldBgColor,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: fieldBorderColor!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: controller.passwordController,
                            obscureText: controller.obscurePassword.value,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                              height: 1.5,
                            ),
                            cursorColor: Colors.white,
                            validator: AppHelper.validatePassword,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: fieldBgColor,
                              contentPadding: const EdgeInsets.all(20),
                              hintText: 'Contraseña',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                              errorStyle: const TextStyle(
                                color: Color(0xFFFF3B30),
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                              prefixIcon: Icon(
                                IconlyLight.lock,
                                color: Colors.grey[400],
                                size: 22,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.obscurePassword.value
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey[400],
                                  size: 22,
                                ),
                                onPressed: () =>
                                    controller.togglePasswordVisibility(),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: Colors.grey[700]!, width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Sign in button with gradient
                      Obx(
                        () => Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF000000), Color(0xFF1A1A1A)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : () => controller.signInWithEmailAndPassword(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: controller.isLoading.value
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes una cuenta?',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Get.offAllNamed(AppRoutes.signUpWithEmail),
                             child: Text(
                              'Registrarse',
                              style: TextStyle(
                                 color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Privacy and Terms
                      Text(
                        'Al iniciar sesión aceptas nuestros',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {},
                              child: Text(
                              'Política de Privacidad',
                              style: TextStyle(
                                  color: textColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Text(
                            'y',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                              child: Text(
                              'Términos de Servicio',
                              style: TextStyle(
                                  color: textColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
