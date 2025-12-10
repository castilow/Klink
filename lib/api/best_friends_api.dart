import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:get/get.dart';

abstract class BestFriendsApi {
  //
  // BestFriendsApi - CRUD Operations
  //

  // Firestore instance
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  static CollectionReference<Map<String, dynamic>> _bestFriendsRef(String userId) {
    return _firestore.collection('Users/$userId/BestFriends');
  }

  // Agregar mejor amigo
  static Future<bool> addBestFriend(String friendId) async {
    try {
      final currentUserId = AuthController.instance.currentUser.userId;
      
      await _bestFriendsRef(currentUserId).doc(friendId).set({
        'userId': friendId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'best_friend_added'.tr,
      );
      return true;
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'error_adding_best_friend'.trParams({'error': e.toString()}),
      );
      return false;
    }
  }

  // Remover mejor amigo
  static Future<bool> removeBestFriend(String friendId) async {
    try {
      final currentUserId = AuthController.instance.currentUser.userId;
      
      await _bestFriendsRef(currentUserId).doc(friendId).delete();

      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'best_friend_removed'.tr,
      );
      return true;
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'error_removing_best_friend'.trParams({'error': e.toString()}),
      );
      return false;
    }
  }

  // Verificar si es mejor amigo
  static Future<bool> isBestFriend(String friendId) async {
    try {
      final currentUserId = AuthController.instance.currentUser.userId;
      final doc = await _bestFriendsRef(currentUserId).doc(friendId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Obtener lista de mejores amigos
  static Stream<List<String>> getBestFriends() {
    final currentUserId = AuthController.instance.currentUser.userId;
    return _bestFriendsRef(currentUserId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
    });
  }

  // Obtener lista de mejores amigos (una vez)
  static Future<List<String>> getBestFriendsOnce() async {
    try {
      final currentUserId = AuthController.instance.currentUser.userId;
      final snapshot = await _bestFriendsRef(currentUserId).get();
      return snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
    } catch (e) {
      return [];
    }
  }
}
























