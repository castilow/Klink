import 'dart:io';

import 'package:chat_messenger/api/auth_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/api/chat_api.dart';
import 'package:chat_messenger/config/app_config.dart';
import 'package:chat_messenger/models/group.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/services/network_service.dart';

import '../tabs/groups/controllers/group_controller.dart';

abstract class UserApi {
  //
  // UserApi - CRUD Operations
  //

  // Firebase instances
  static final _firestore = FirebaseFirestore.instance;
  static final _realtime = FirebaseDatabase.instance;
  static final _firebaseMsg = FirebaseMessaging.instance;

  // Configure Realtime Database
  static void configureRealtimeDatabase() {
    _realtime.setLoggingEnabled(false);
    _realtime.setPersistenceEnabled(true);
    _realtime.databaseURL = 'https://klink-b0358-default-rtdb.firebaseio.com';
  }

  static Future<dynamic> createAccount({
    File? photoFile,
    required String fullname,
    required String username,
  }) async {
    try {
      final firebaseUser = AuthController.instance.firebaseUser!;

      // Get Firebase User Info:
      final String userId = firebaseUser.uid;
      final String email = firebaseUser.email ?? '';
      
      // Get device token (manejar error si APNS token no está disponible)
      String deviceToken = '';
      try {
        deviceToken = await _firebaseMsg.getToken() ?? '';
        debugPrint('✅ FCM token obtenido durante creación de perfil: ${deviceToken.isNotEmpty ? "OK" : "vacío"}');
      } catch (e) {
        debugPrint('⚠️ Error obteniendo FCM token durante creación de perfil (continuando sin token): $e');
        // Continuar sin token, la app puede funcionar sin él
        deviceToken = '';
      }

      // Upload profile photo
      String photoUrl = '';

      // Check file
      if (photoFile != null) {
        photoUrl = await AppHelper.uploadFile(file: photoFile, userId: userId);
      }

      // Set profile info
      final User user = User(
        userId: userId,
        photoUrl: photoUrl,
        fullname: fullname,
        username: username,
        email: email,
        bio: 'default_bio'.trParams({'appName': AppConfig.appName}),
        deviceToken: deviceToken,
        loginProvider: AuthController.instance.provider,
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
        isOnline: true,
      );

      // Save data
      await _firestore.collection('Users').doc(userId).set(user.toMap());

      // Subscribe for Push Notifications
      _firebaseMsg.subscribeToTopic('NOTIFY_USERS');
      return true;
    } catch (e) {
      return e;
    }
  }

  static Future<dynamic> updateAccount({
    File? photoFile,
    required String fullname,
    required String username,
    required String bio,
  }) async {
    try {
      // Get current user
      final User currentUser = AuthController.instance.currentUser;

      // Update photo
      String photoUrl = currentUser.photoUrl;

      // Check file
      if (photoFile != null) {
        photoUrl = await AppHelper.uploadFile(
          file: photoFile,
          userId: currentUser.userId,
        );
      }

      // Save data
      await _firestore.collection('Users').doc(currentUser.userId).update({
        'photoUrl': photoUrl,
        'fullname': fullname,
        'username': username,
        'bio': bio,
      });

      return true;
    } catch (e) {
      return e;
    }
  }

  static Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('Users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return User.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('UserApi.getUser() -> Error: $e');
      return null;
    }
  }

  static Stream<User> getUserUpdates(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .snapshots()
        .map((event) {
          if (!event.exists || event.data() == null) {
            // Return a default user if document doesn't exist or is null
            return User(
              userId: userId,
              fullname: '',
              username: '',
              photoUrl: '',
              email: '',
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
          return User.fromMap(event.data()!);
        });
  }

  // Check username availability in database
  static Future<bool> checkUsername({
    required String username,
    bool showMsg = true,
  }) async {
    final query = await _firestore
        .collection('Users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    final bool result = query.docs.isEmpty;

    if (result) {
      if (showMsg) {
        DialogHelper.showSnackbarMessage(
          SnackMsgType.success,
          "username_success".tr,
        );
      }
      return true;
    }
    if (showMsg) {
      DialogHelper.showSnackbarMessage(SnackMsgType.error, "username_taken".tr);
    }
    return false;
  }

  // Update user data
  static Future<void> updateUserData({
    required String userId,
    required Map<String, dynamic> data,
    bool isSet = false,
  }) async {
    if (isSet) {
      await _firestore
          .collection('Users')
          .doc(userId)
          .set(data, SetOptions(merge: true));
    } else {
      await _firestore.collection('Users').doc(userId).update(data);
    }
  }

  static Future<void> updateUserInfo(User user) async {
    final firebaseUser = AuthController.instance.firebaseUser!;

    // Get device token (manejar error si APNS token no está disponible)
    String deviceToken = '';
    try {
      deviceToken = await _firebaseMsg.getToken() ?? '';
      debugPrint('✅ FCM token obtenido: ${deviceToken.isNotEmpty ? "OK" : "vacío"}');
    } catch (e) {
      debugPrint('⚠️ Error obteniendo FCM token (continuando sin token): $e');
      // Continuar sin token, la app puede funcionar sin él
      deviceToken = '';
    }

    var data = {
      'deviceToken': deviceToken,
      'lastActive': DateTime.now().millisecondsSinceEpoch,
      'isOnline': true,
    };

    if (user.createdAt == null) {
      final DateTime? creationTime = firebaseUser.metadata.creationTime;
      // Update creation date
      data['createdAt'] = creationTime == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(creationTime);
    }

    // Save data
    await updateUserData(userId: user.userId, data: data, isSet: true);
    // Subscribe for Push Notifications (manejar error si APNS token no está disponible)
    try {
      await _firebaseMsg.subscribeToTopic('NOTIFY_USERS');
      debugPrint('✅ Suscrito al topic NOTIFY_USERS');
    } catch (e) {
      debugPrint('⚠️ Error suscribiéndose al topic (continuando sin suscripción): $e');
      // Continuar sin suscripción, la app puede funcionar sin ella
    }
  }

  /// Update user push token specifically for FCM
  static Future<void> updateUserPushToken(String userId, String token) async {
    try {
      await _firestore.collection('Users').doc(userId).set({
        'pushTokens': FieldValue.arrayUnion([token]),
        'deviceToken': token, // compatibilidad con código legado
        'lastActive': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      debugPrint('updateUserPushToken() -> success for user: $userId');
    } catch (e) {
      debugPrint('updateUserPushToken() -> error: $e');
    }
  }

  /// Remove user push token on logout
  static Future<void> removeUserPushToken(String userId, String token) async {
    try {
      await _firestore.collection('Users').doc(userId).set({
        'pushTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
      debugPrint('removeUserPushToken() -> success for user: $userId');
    } catch (e) {
      debugPrint('removeUserPushToken() -> error: $e');
    }
  }

  // Delete all the files upload by user
  static Future<void> deleteUserStorageFiles() async {
    try {
      final User currentUser = AuthController.instance.currentUser;

      final ListResult listResult = await FirebaseStorage.instance
          .ref('uploads/users/${currentUser.userId}')
          .listAll();
      final List<Future<void>> references = listResult.items
          .map((e) => e.delete())
          .toList();
      // Check result
      if (references.isNotEmpty) {
        await Future.wait(references);
        debugPrint('_deleteUserStorageFiles() -> success');
      } else {
        debugPrint('_deleteUserStorageFiles() -> no files');
      }
    } catch (e) {
      debugPrint('_deleteUserStorageFiles() -> error: $e');
    }
  }

  static Future<void> deleteUserAccount() async {
    try {
      // Get current user model
      final User currentUer = AuthController.instance.currentUser;

      DialogHelper.showProcessingDialog(
        title: 'deleting_profile_account'.tr,
        barrierDismissible: false,
      );

      // Delete all user-uploaded files
      AppHelper.deleteStorageFiles('uploads/${currentUer.userId}');

      // Get User Groups
      final List<Group> userGroups = GroupController.instance.groups
          .where((group) => group.createdBy == currentUer.userId)
          .toList();

      // Delete user's groups
      final groupFutures = userGroups.map(
        (e) => _firestore.collection('Groups').doc(e.groupId).delete(),
      );
      if (groupFutures.isNotEmpty) {
        await Future.wait(groupFutures);
      }

      // Delete profile account data
      await _firestore.collection('Users').doc(currentUer.userId).delete();

      // Close previous dialog
      DialogHelper.closeDialog();

      // Show confirm dialog
      DialogHelper.showAlertDialog(
        icon: const Icon(Icons.check_circle, color: primaryColor),
        title: Text('success'.tr),
        content: Text(
          'profile_account_successfully_deleted'.tr,
          style: const TextStyle(fontSize: 16),
        ),
        actionText: 'sign_out'.tr.toUpperCase(),
        action: () => AuthApi.signOut(),
        showCancelButton: false,
        barrierDismissible: false,
      );
    } catch (e) {
      DialogHelper.closeDialog();
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        "failed_to_delete_user_account".trParams({'error': e.toString()}),
      );
    }
  }

  ///
  /// <-- User Presense features -->
  ///

  static Map<String, dynamic> _isUserOnline(bool value) {
    var data = {
      'isOnline': value,
      'lastActive': Timestamp.now().millisecondsSinceEpoch,
    };
    if (!value) {
      data['isTyping'] = false;
      data['isRecording'] = false;
    }
    return data;
  }

  // Update User Presence in Realtime Database.
  static Future<void> updateUserPresenceInRealtimeDb() async {
    try {
      final firebaseUser = AuthController.instance.firebaseUser;
      if (firebaseUser == null) return;

      // Configure database first
      configureRealtimeDatabase();

      // Get Realtime database reference
      final DatabaseReference connectedRef = _realtime.ref('.info/connected');

      // Listen to updates
      connectedRef.onValue.listen((event) async {
        final isConnected = event.snapshot.value as bool? ?? false;
        if (isConnected) {
          final userStatusRef = _realtime.ref().child(
            'status/${firebaseUser.uid}',
          );

          // Set up onDisconnect first
          await userStatusRef.onDisconnect().update({
            'isOnline': false,
            'lastActive': DateTime.now().millisecondsSinceEpoch,
          });

          // Then update current status
          await userStatusRef.update({
            'isOnline': true,
            'lastActive': DateTime.now().millisecondsSinceEpoch,
            'activeChatId': '', // Inicialmente sin chat activo
          });
        }
      });
    } catch (e) {
      debugPrint('updateUserPresenceInRealtimeDb() -> error: $e');
    }
  }

  // Update User presence
  static Future<void> updateUserPresence(bool isOnline) async {
    final networkService = Get.find<NetworkService>();

    // Check network connectivity before attempting Firebase operations
    if (!networkService.isConnected) {
      debugPrint('updateUserPresence() -> skipped (no network connectivity)');
      return;
    }

    final firebaseUser = AuthController.instance.firebaseUser;
    if (firebaseUser == null) return;

    final data = {
      'isOnline': isOnline,
      'lastActive': DateTime.now().millisecondsSinceEpoch,
    };

    // Update in Firestore with network awareness
    await networkService.executeFirebaseOperation(
      () => _firestore.collection('Users').doc(firebaseUser.uid).update(data),
      operationName: 'updateUserPresence Firestore',
      silent: true, // Don't show user notifications for this operation
    );

    // Update in Realtime Database with network awareness
    await networkService.executeFirebaseOperation(
      () async {
        final userStatusRef = _realtime.ref().child(
          'status/${firebaseUser.uid}',
        );
        await userStatusRef.update(data);
      },
      operationName: 'updateUserPresence Realtime DB',
      silent: true, // Don't show user notifications for this operation
    );

    debugPrint('updateUserPresence($isOnline) -> completed');
  }

  /// Update active chat ID (para notificaciones inteligentes)
  static Future<void> updateActiveChatId(String chatId) async {
    try {
      final firebaseUser = AuthController.instance.firebaseUser;
      if (firebaseUser == null) return;

      configureRealtimeDatabase();
      final userStatusRef = _realtime.ref().child('presence/${firebaseUser.uid}');
      
      await userStatusRef.update({
        'activeChatId': chatId,
        'lastActive': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('updateActiveChatId($chatId) -> completed');
    } catch (e) {
      debugPrint('updateActiveChatId() -> error: $e');
    }
  }

  /// Clear active chat (when leaving chat)
  static Future<void> clearActiveChatId() async {
    try {
      final firebaseUser = AuthController.instance.firebaseUser;
      if (firebaseUser == null) return;

      configureRealtimeDatabase();
      final userStatusRef = _realtime.ref().child('presence/${firebaseUser.uid}');
      
      await userStatusRef.update({
        'activeChatId': '',
        'lastActive': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('clearActiveChatId() -> completed');
    } catch (e) {
      debugPrint('clearActiveChatId() -> error: $e');
    }
  }

  /// Update User typing status
  static Future<void> updateUserTypingStatus(
    bool isTyping,
    String receiverId,
  ) async {
    try {
      final User currentUer = AuthController.instance.currentUser;

      await updateUserData(
        userId: currentUer.userId,
        data: {
          'isTyping': isTyping,
          'typingTo': receiverId,
          'isRecording': false,
        },
        isSet: true,
      );
      // Also update chat node typing status
      await ChatApi.updateChatTypingStatus(isTyping, receiverId);
      debugPrint('updateUserTypingStatus() -> success');
    } catch (e) {
      debugPrint('updateUserTypingStatus() -> error: $e');
    }
  }

  /// Update User recording status
  static Future<void> updateUserRecordingStatus(
    bool isRecording,
    String receiverId,
  ) async {
    try {
      final User currentUer = AuthController.instance.currentUser;

      await updateUserData(
        userId: currentUer.userId,
        data: {
          'isRecording': isRecording,
          'recordingTo': receiverId,
          'isTyping': false,
        },
        isSet: true,
      );
      // Also update chat node recording status
      await ChatApi.updateChatRecordingStatus(isRecording, receiverId);
      debugPrint('updateUserRecordingStatus() -> success');
    } catch (e) {
      debugPrint('updateUserRecordingStatus() -> error: $e');
    }
  }

  /// Close User typing or recording status
  static Future<void> closeTypingOrRecordingStatus() async {
    try {
      final User currentUer = AuthController.instance.currentUser;

      await updateUserData(
        userId: currentUer.userId,
        data: {'isTyping': false, 'isRecording': false},
        isSet: true,
      );
      debugPrint('closeTypingOrRecordingStatus() -> success');
    } catch (e) {
      debugPrint('closeTypingOrRecordingStatus() -> error: $e');
    }
  }

  static Future<void> muteGroup(String groupId, bool isMuted) async {
    try {
      final User currentUer = AuthController.instance.currentUser;

      await UserApi.updateUserData(
        userId: currentUer.userId,
        data: {
          'mutedGroups': isMuted
              ? FieldValue.arrayRemove([groupId])
              : FieldValue.arrayUnion([groupId]),
        },
      );
      debugPrint('muteGroup() -> success');
    } catch (e) {
      debugPrint('muteGroup() -> error: $e');
    }
  }

  /// Get all users from the database
  static Future<List<User>> getAllUsers() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('Users')
          .orderBy('fullname')
          .get();

      final List<User> users = snapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.userId != AuthController.instance.currentUser.userId) // Exclude current user
          .toList();

      debugPrint('getAllUsers() -> found ${users.length} users');
      return users;
    } catch (e) {
      debugPrint('getAllUsers() -> error: $e');
      return [];
    }
  }
}
