import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/components/app_logo.dart';
import 'package:chat_messenger/components/k_auth_background.dart';
import 'package:chat_messenger/screens/auth/signin/controller/signin_controller.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
import 'package:chat_messenger/api/auth_api.dart';
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
      body: Stack(
        children: [
          // Fondo con K decorativa (versión full bright solo para login)
          const KAuthBackground(
            imagePath: 'assets/images/k_full_bright_iphone_1284x2778.png',
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
                      const SizedBox(height: 40),

                      // Logo integrado con alta calidad
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[600],
                                  size: 60,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        'Iniciar Sesión',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
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

                      const SizedBox(height: 32),

                      // Divider with "O"
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[600],
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'O',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[600],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Social Sign In Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google Sign In
                          _buildSocialButton(
                            onTap: () => AuthApi.signInWithGoogle(),
                            icon: 'assets/icons/google.svg',
                            label: 'Google',
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

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
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Al iniciar sesión aceptas nuestros',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
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
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
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

  /// Build social sign-in button
  Widget _buildSocialButton({
    required VoidCallback onTap,
    required String icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: darkPrimaryContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey[700]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: icon.contains('apple')
              ? SvgPicture.asset(
                  icon,
                  width: 32,
                  height: 32,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                )
              : SvgPicture.asset(
                  icon,
                  width: 32,
                  height: 32,
                ),
        ),
      ),
    );
  }
}
