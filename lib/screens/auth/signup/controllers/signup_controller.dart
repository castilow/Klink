import 'dart:io';

import 'package:flutter/material.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpController extends GetxController {
  final _auth = FirebaseAuth.instance;
  // Variables
  final RxBool isLoading = RxBool(false);
  final RxBool obscurePassword = RxBool(true);
  final RxBool obscureConfirmPassword = RxBool(true);
  // SignUp info
  final Rxn<File> photoFile = Rxn();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void onInit() {
    _setDisplayName();
    super.onInit();
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _setDisplayName() {
    // Get social login name
    final String? displayName =
        AuthController.instance.firebaseUser?.displayName;
    // Check it
    if (displayName != null) {
      nameController.text = displayName;
      usernameController.text = AppHelper.sanitizeUsername(displayName);
    }
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // <-- Create Account -->
  Future<void> signUp() async {
    // Check the form
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    // Show dialog
    DialogHelper.showProcessingDialog(
      title: 'creating_account'.tr,
      barrierDismissible: false,
    );

    try {
      // Create user account
      final result = await UserApi.createAccount(
        photoFile: photoFile.value,
        fullname: nameController.text.trim(),
        username: usernameController.text.trim(),
      );

      // Check result
      if (result is bool && result) {
        // Get current user
        await AuthController.instance.getCurrentUserAndLoadData();

        // Close previous dialog
        DialogHelper.closeDialog();

        // Show confirm dialog
        DialogHelper.showAlertDialog(
          icon: const Icon(Icons.check_circle, color: primaryColor),
          title: Text('success'.tr),
          content: Text(
            'your_profile_account_has_been_successfully_created'.tr,
            style: const TextStyle(fontSize: 16),
          ),
          actionText: 'get_started'.tr.toUpperCase(),
          // Go to home screen
          action: () => Future(() => Get.offAllNamed(AppRoutes.home)),
          showCancelButton: false,
          barrierDismissible: false,
        );
      } else {
        // Close dialog
        DialogHelper.closeDialog();

        // Show error message
        DialogHelper.showSnackbarMessage(
          SnackMsgType.error,
          'failed_to_create_account'.trParams(
            {'error': result.toString()},
          ),
        );
      }
    } catch (e) {
      // Close dialog
      DialogHelper.closeDialog();

      // Show error message
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'failed_to_create_account'.trParams(
          {'error': e.toString()},
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpWithEmailAndPassword() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      
      // Create user account
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Update user profile
      await userCredential.user?.updateDisplayName(nameController.text.trim());
      
      // Notificaciones deshabilitadas
    } catch (e) {
      // Notificaciones deshabilitadas
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
