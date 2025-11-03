import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:chat_messenger/services/zego_call_service.dart';

import 'app_controller.dart';

class AuthController extends GetxController {
  // Get the current instance
  static AuthController instance = Get.find();

  // Firebase Auth
  final _firebaseAuth = auth.FirebaseAuth.instance;
  // Firebase User
  auth.User? get firebaseUser => _firebaseAuth.currentUser;

  // Hold login provider
  LoginProvider provider = LoginProvider.email;

  // Current User Model
  final Rxn<User> _currentUser = Rxn();
  StreamSubscription<User>? _stream;

  // <-- GETTERS -->
  User get currentUser {
    try {
      if (_currentUser.value == null) {
        // Return a default user if current user is null
        return User(
          userId: firebaseUser?.uid ?? '',
          fullname: '',
          username: '',
          photoUrl: '',
          email: firebaseUser?.email ?? '',
          bio: '',
          isOnline: false,
          deviceToken: '',
          status: 'active',
          loginProvider: LoginProvider.email,
          isTyping: false,
          typingTo: '',
          isRecording: false,
          recordingTo: '',
          mutedGroups: const [],
        );
      }
      return _currentUser.value!;
    } catch (e) {
      debugPrint('AuthController.currentUser -> Error: $e');
      // Return a default user if there's any error
      return User(
        userId: firebaseUser?.uid ?? '',
        fullname: '',
        username: '',
        photoUrl: '',
        email: firebaseUser?.email ?? '',
        bio: '',
        isOnline: false,
        deviceToken: '',
        status: 'active',
        loginProvider: LoginProvider.email,
        isTyping: false,
        typingTo: '',
        isRecording: false,
        recordingTo: '',
        mutedGroups: const [],
      );
    }
  }

  @override
  void onClose() {
    _stream?.cancel();
    super.onClose();
  }

  // Update Current User Model
  void _updateCurrentUser(User user) {
    _currentUser.value = user;
    // Get user updates
    _stream = UserApi.getUserUpdates(user.userId).listen(
      (event) {
        _currentUser.value = event;
      },
      onError: (e) {
        debugPrint('AuthController._updateCurrentUser() -> Error: $e');
        // Don't update the current user on error to avoid null issues
      },
    );
  }

  // Handle user auth
  Future<void> checkUserAccount() async {
    // Check logged in firebase user
    if (firebaseUser == null) {
      // Go directly to sign in page, skip welcome screen
      Future(() => Get.offAllNamed(AppRoutes.signInOrSignUp));
      return;
    }

    // Check if email is verified
    if (!firebaseUser!.emailVerified) {
      // Reload user to get latest verification status
      await firebaseUser!.reload();
      
      // Check again after reload
      if (!firebaseUser!.emailVerified) {
        // Send email verification
        await firebaseUser!.sendEmailVerification();
        // Go to verify email screen
        Future(() => Get.offAllNamed(AppRoutes.verifyEmail));
        return;
      }
    }

    // Init app controller
    Get.put(AppController(), permanent: true);

    // Check User Account in database
    final user = await UserApi.getUser(firebaseUser!.uid);

    // Check user
    if (user == null) {
      // Go to sign-up page to complete profile
      Future(() => Get.offAllNamed(AppRoutes.signUp));
      return;
    }

    // Check blocked account status
    if (user.status == 'blocked') {
      // Go to blocked account page
      Future(() => Get.offAllNamed(AppRoutes.blockedAccount));
      return;
    }

    // Update the current user model
    _updateCurrentUser(user);

    // Update current user info
    await UserApi.updateUserInfo(user);

    // Inicializar ZEGOCLOUD después de que el usuario esté autenticado
    try {
      final zegoService = Get.find<ZegoCallService>();
      await zegoService.initializeWhenUserAuthenticated();
    } catch (e) {
      debugPrint('AuthController.checkUserAccount() -> Error inicializando ZEGOCLOUD: $e');
    }

    // Go to home page
    Future(() => Get.offAllNamed(AppRoutes.home));
  }

  Future<void> getCurrentUserAndLoadData() async {
    try {
      final user = await UserApi.getUser(firebaseUser!.uid);
      if (user != null) {
        // Update the current user model
        _updateCurrentUser(user);
        // Update current user info
        UserApi.updateUserInfo(user);
        
        // Inicializar ZEGOCLOUD después de cargar los datos del usuario
        try {
          final zegoService = Get.find<ZegoCallService>();
          await zegoService.initializeWhenUserAuthenticated();
        } catch (e) {
          debugPrint('AuthController.getCurrentUserAndLoadData() -> Error inicializando ZEGOCLOUD: $e');
        }
      } else {
        debugPrint('AuthController.getCurrentUserAndLoadData() -> User not found');
      }
    } catch (e) {
      debugPrint('AuthController.getCurrentUserAndLoadData() -> Error: $e');
    }
  }
}
