import 'dart:io';

import 'package:chat_messenger/api/auth_api.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/components/default_button.dart';
import 'package:chat_messenger/components/custom_appbar.dart';
import 'package:chat_messenger/components/profile_photo_picker.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/screens/auth/signup/controllers/signup_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  SIGN‑UP  (Complete Profile)
/// ─────────────────────────────────────────────────────────────────────────────
class SignUpScreen extends GetView<SignUpController> {
  const SignUpScreen({super.key});

  /// Diálogo para cerrar sesión (por si lo necesitas)
  void _signOut() {
    DialogHelper.showAlertDialog(
      title: Text('sign_out'.tr),
      icon: const Icon(IconlyLight.logout, color: primaryColor),
      content: Text('are_you_sure_you_want_to_sign_out'.tr),
      actionText: 'YES'.tr,
      action: () => AuthApi.signOut(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: const CustomAppBar(
        hideLeading: true,
        title: Text(
          'Complete Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // ─── FONDO CON DEGRADADO ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E2746),
                  const Color(0xFF1B1B1B),
                  const Color(0xFF1B1B1B),
                  const Color(0xFF1E2746).withOpacity(0.5),
                ],
              ),
            ),
          ),
          // ─── CONTENIDO PRINCIPAL ───────────────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Form(
                key: controller.formKey,
                child: Column(
                  children: [
                    const SizedBox(height: defaultPadding),
                    // FOTO DE PERFIL
                    Obx(
                      () => ProfilePhotoPicker(
                        photoFile: controller.photoFile.value,
                        onImageSelected: (File file) =>
                            controller.photoFile.value = file,
                      ),
                    ),
                    const SizedBox(height: defaultPadding * 2),
                    // NOMBRE COMPLETO
                    _buildInputField(
                      controller: controller.nameController,
                      label: 'full_name'.tr,
                      icon: IconlyLight.profile,
                      capitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'please_enter_your_full_name'.tr
                          : null,
                    ),
                    const SizedBox(height: defaultPadding),
                    // USERNAME
                    _buildInputField(
                      controller: controller.usernameController,
                      label: 'username'.tr,
                      icon: IconlyLight.user2,
                      keyboardType: TextInputType.text,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'please_enter_a_username'.tr
                          : null,
                    ),
                    const SizedBox(height: defaultPadding * 2),
                    // BOTÓN  CREAR CUENTA
                    Obx(
                      () => DefaultButton(
                        text: 'create_account'.tr,
                        onPress: controller.isLoading.value
                            ? null
                            : () => controller.signUp(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  HELPER PARA CONSTRUIR CAMPOS DE TEXTO UNIFICADOS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        style: const TextStyle(
          color: Colors.black,      // ← texto negro
          fontSize: 16,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(20),
          border: InputBorder.none,
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.grey[600], // hint gris oscuro
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.grey[600],
            size: 24,
          ),
        ),
        validator: validator,
      ),
    );
  }
}