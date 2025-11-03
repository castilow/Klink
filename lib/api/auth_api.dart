import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/models/user.dart' hide User;
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/config/theme_config.dart';

abstract class AuthApi {
  static final AuthController _authController = AuthController.instance;
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      DialogHelper.showProcessingDialog();
      
      final UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Send email verification
      await sendEmailVerification(userCredential.user!);
    } catch (e) {
      DialogHelper.closeDialog();
      
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        "failed_to_sign_up_with_email_and_password".trParams(
          {'error': e.toString()},
        ),
      );
    }
  }

  static Future<void> sendEmailVerification(User user) async {
    try {
      // Check status
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        // Go to verify email screen
        Future(() => Get.offAllNamed(AppRoutes.verifyEmail));
        // Sign-out the user to ensure the email is verified first.
        await _firebaseAuth.signOut();
      }
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        "failed_to_send_verification_email".trParams(
          {'error': e.toString()},
        ),
      );
    }
  }

  static Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      DialogHelper.showProcessingDialog();
      
      final UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Get User
      User user = userCredential.user!;

      // Check verification status
      if (!user.emailVerified) {
        // Send email verification if not already sent
        await sendEmailVerification(user);
        DialogHelper.closeDialog();
        return;
      }

      // Set login provider
      _authController.provider = LoginProvider.email;

      // Check account in database
      await _authController.checkUserAccount();
      
      DialogHelper.closeDialog();
    } catch (e) {
      DialogHelper.closeDialog();
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        "failed_to_sign_in_with_email_and_password".trParams(
          {'error': e.toString()},
        ),
      );
    }
  }

  static Future<void> requestPasswordRecovery(String email) async {
    try {
      // Send request
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      // Success message
      DialogHelper.showAlertDialog(
        icon: const Icon(Icons.check_circle, color: primaryColor),
        title: Text('success'.tr),
        content: Text(
          "password_reset_email_sent_successfully".tr,
          style: const TextStyle(fontSize: 16),
        ),
        actionText: 'OKAY'.tr,
        action: () {
          // Close dialog
          Get.back();
          // Close page
          Get.back();
        },
      );
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        "failed_to_send_password_reset_request".trParams(
          {'error': e.toString()},
        ),
      );
    }
  }

  static Future<void> signOut() async {
    try {
      await Get.deleteAll(force: true);
      await _firebaseAuth.signOut();
      Get.offAllNamed(AppRoutes.splash);

      debugPrint('signOut() -> success');
    } catch (e) {
      debugPrint('signOut() -> error: $e');
    }
  }

  // Sign-in con Google eliminado por solicitud
}
