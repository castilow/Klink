import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/screens/auth/signup/controllers/signup_with_email_controller.dart';
import 'package:chat_messenger/components/k_auth_background.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
import 'package:chat_messenger/api/auth_api.dart';

class SignUpWithEmailScreen extends GetView<SignUpWithEmailController> {
  const SignUpWithEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Forzar modo oscuro siempre en pantallas de autenticación
    const isDark = true;
    const backgroundColor = darkThemeBgColor;
    const textColor = darkThemeTextColor;
    final secondaryTextColor = Colors.grey[400];
    const fieldBgColor = darkPrimaryContainer;
    final fieldBorderColor = Colors.grey[600];

    // Detectar si es tablet
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    // Para iPad, usar un ancho máximo más grande pero centrado
    final maxWidth = isTablet ? 700.0 : double.infinity;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con imagen de K decorativa (versión revertida solo para registro)
          const KAuthBackground(
            imagePath: 'assets/images/bg_klink_revert3x_1284x2778.jpg',
          ),

          // Main content
          SafeArea(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 48 : 24,
                  vertical: isTablet ? 32 : 0,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: controller.formKey,
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
                          'Registrarse',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Crea tu cuenta',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // ─── EMAIL ──────────────────────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: fieldBgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: fieldBorderColor!,
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            controller: controller.emailController,
                            style: TextStyle(color: textColor, fontSize: 16),
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
                              ),
                              prefixIcon: Icon(
                                IconlyLight.message,
                                color: Colors.grey[400],
                                size: 22,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ─── PASSWORD ─────────────────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: fieldBgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: fieldBorderColor!,
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            controller: controller.passwordController,
                            obscureText: true,
                            style: TextStyle(color: textColor, fontSize: 16),
                            validator: AppHelper.validatePassword,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: fieldBgColor,
                              contentPadding: const EdgeInsets.all(20),
                              hintText: 'Contraseña',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(
                                IconlyLight.lock,
                                color: Colors.grey[400],
                                size: 22,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ─── BOTÓN SIGN‑UP ────────────────────────────────────────
                        Obx(
                          () => Container(
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
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
                                  : controller.signUpWithEmailAndPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: controller.isLoading.value
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      'Registrarse',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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

                        // ─── LINK SIGN‑IN ─────────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿Ya tienes una cuenta?',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Get.offAllNamed(AppRoutes.signIn),
                              child: Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ─── PRIVACY & TERMS ──────────────────────────────────────
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Al registrarte aceptas nuestros',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Política de Privacidad',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              'y',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Términos de Servicio',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
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
          border: Border.all(color: Colors.grey[700]!, width: 1.5),
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
              : SvgPicture.asset(icon, width: 32, height: 32),
        ),
      ),
    );
  }
}
