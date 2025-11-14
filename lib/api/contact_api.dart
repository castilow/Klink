import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:get/get.dart';

import 'user_api.dart';

abstract class ContactApi {
  //
  // ContactApi - CRUD Operations
  //

  // Firebase instances
  static final _firestore = FirebaseFirestore.instance;

  // Create new contact
  static Future<void> addContact({
    required String userId,
    bool showMsg = false,
  }) async {
    try {
      final User currentUser = AuthController.instance.currentUser;

      Future.wait([
        // Save for current user
        _firestore
            .collection('Users/${currentUser.userId}/Contacts')
            .doc(userId)
            .set({
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        }),
        // Save for onother user
        _firestore
            .collection('Users/$userId/Contacts')
            .doc(currentUser.userId)
            .set({
          'userId': currentUser.userId,
          'createdAt': FieldValue.serverTimestamp()
        }),
      ]);
      if (!showMsg) return;
      DialogHelper.showSnackbarMessage(
          SnackMsgType.success, "add_contact_success".tr);
    } catch (e) {
      if (!showMsg) return;
      DialogHelper.showSnackbarMessage(SnackMsgType.error,
          "add_contact_error".trParams({'error': e.toString()}));
    }
  }

  static Future<User?> searchContact(String username) async {
    try {
      // Normalizar: quitar @ opcional, minúsculas y sin espacios
      final String normalizedUsername = AppHelper.sanitizeUsername(
        username.trim().startsWith('@')
            ? username.trim().substring(1)
            : username.trim(),
      );

      if (normalizedUsername.isEmpty) {
        DialogHelper.showSnackbarMessage(
          SnackMsgType.error,
          "enter_username".tr,
        );
        return null;
      }

      final query = await _firestore
          .collection('Users')
          .where('username', isEqualTo: normalizedUsername)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return User.fromMap(query.docs.first.data());
      }

      // Fallback: recorrer usuarios locales para coincidencias flexibles
      final fallbackUsers = await UserApi.getAllUsers();
      final String rawLower = username.trim().toLowerCase();
      User? manualMatch;
      for (final user in fallbackUsers) {
        final unameLower = user.username.toLowerCase();
        final fullnameLower = user.fullname.toLowerCase();
        final emailLower = user.email.toLowerCase();
        final bool matchesUsername =
            unameLower == normalizedUsername || unameLower == rawLower;
        final bool matchesFullName =
            fullnameLower.contains(rawLower) && rawLower.isNotEmpty;
        final bool matchesEmail = emailLower == rawLower && rawLower.isNotEmpty;
        if (matchesUsername || matchesFullName || matchesEmail) {
          manualMatch = user;
          break;
        }
      }

      if (manualMatch != null) return manualMatch;

      return null;
    } catch (e) {
      DialogHelper.showSnackbarMessage(SnackMsgType.error, e.toString());
      return null;
    }
  }

  // Get contacts list
  static Stream<List<User>> getContacts() {
    final User currentUser = AuthController.instance.currentUser;

    return _firestore
        .collection('Users/${currentUser.userId}/Contacts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((event) async {
      List<User> users = [];
      for (var doc in event.docs) {
        final User? user = await UserApi.getUser(doc.id);
        if (user != null) {
          users.add(user);
        }
      }
      return users;
    });
  }

  // Delete contact from the list
  static Future<void> deleteContact(String userId) async {
    try {
      final User currentUser = AuthController.instance.currentUser;

      await _firestore
          .collection('Users/${currentUser.userId}/Contacts')
          .doc(userId)
          .delete();
      DialogHelper.showSnackbarMessage(
          SnackMsgType.success, "delete_contact_success".tr);
    } catch (e) {
      DialogHelper.showSnackbarMessage(SnackMsgType.error,
          "delete_contact_error".trParams({'error': e.toString()}));
    }
  }
}
