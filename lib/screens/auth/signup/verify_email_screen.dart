import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/components/default_button.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/components/custom_appbar.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  Future<void> _checkEmailVerification() async {
    try {
      // Get auth controller
      final authController = AuthController.instance;
      
      // Reload firebase user to get latest status
      await authController.firebaseUser?.reload();
      
      // Check verification status and proceed with account setup
      await authController.checkUserAccount();
    } catch (e) {
      debugPrint('Error checking email verification: $e');
    }
  }

  Future<void> _resendVerification() async {
    try {
      final user = AuthController.instance.firebaseUser;
      if (user != null) {
        await user.sendEmailVerification();
        // Notificaciones deshabilitadas
      }
    } catch (e) {
      debugPrint('Error resending verification: $e');
      // Notificaciones deshabilitadas
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        hideLeading: true,
        title: Text('Verify Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              IconlyBold.message,
              size: 100,
              color: primaryColor,
            ),
            const SizedBox(height: defaultPadding * 2),
            Text(
              'Verify your email',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: defaultPadding),
            Text(
              'We have sent you a verification email. Please check your inbox and verify your email address.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: defaultPadding * 2),
            DefaultButton(
              text: 'I have verified my email',
              onPress: _checkEmailVerification,
            ),
            const SizedBox(height: defaultPadding),
            TextButton(
              onPressed: _resendVerification,
              child: Text(
                'Resend verification email',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
