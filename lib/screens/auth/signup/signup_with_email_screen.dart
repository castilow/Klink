import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/screens/auth/signup/controllers/signup_with_email_controller.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
 

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
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  
                  Text(
                    'Registrarse',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                      ),
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
                          borderSide: BorderSide(color: Colors.grey[700]!, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white, width: 1.5),
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
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                      ),
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
                          borderSide: BorderSide(color: Colors.grey[700]!, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white, width: 1.5),
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
                  
                  const SizedBox(height: 24),
                  
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
                        onPressed: () => Get.offAllNamed(AppRoutes.signIn),
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
                  Text(
                    'Al registrarte aceptas nuestros',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
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
                          ),
                        ),
                      ),
                      Text(
                        'y',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Términos de Servicio',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w500,
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
    );
  }
}
