import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/call_history.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:flutter/material.dart';

abstract class CallHistoryApi {
  //
  // CallHistoryApi - CRUD Operations
  //

  // Firebase instances
  static final _firestore = FirebaseFirestore.instance;

  // Get call history for current user
  static Stream<List<CallHistory>> getCallHistory() {
    final User currentUser = AuthController.instance.currentUser;

    return _firestore
        .collection('Users/${currentUser.userId}/CallHistory')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap((event) async {
      List<CallHistory> calls = [];
      for (var doc in event.docs) {
        final data = doc.data();
        final String receiverId = data['receiverId'] ?? '';
        
        // Get receiver user data
        final User? receiver = await UserApi.getUser(receiverId);
        if (receiver != null) {
          calls.add(CallHistory.fromMap(data, receiver));
        }
      }
      return calls;
    });
  }

  // Mark calls as viewed
  static Future<void> viewCalls(List<CallHistory> calls) async {
    try {
      final User currentUser = AuthController.instance.currentUser;
      final batch = _firestore.batch();

      for (var call in calls) {
        if (call.isNew) {
          final docRef = _firestore
              .collection('Users/${currentUser.userId}/CallHistory')
              .doc(call.callId);
          batch.update(docRef, {'isNew': false});
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking calls as viewed: $e');
    }
  }

  // Clear all call history
  static Future<void> clearCallLog(List<CallHistory> calls) async {
    try {
      final User currentUser = AuthController.instance.currentUser;
      final batch = _firestore.batch();

      for (var call in calls) {
        final docRef = _firestore
            .collection('Users/${currentUser.userId}/CallHistory')
            .doc(call.callId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing call log: $e');
    }
  }

  // Add call to history
  static Future<void> addCallToHistory({
    required String receiverId,
    required CallType callType,
    required CallStatus callStatus,
    int duration = 0,
  }) async {
    try {
      final User currentUser = AuthController.instance.currentUser;
      final String callId = _firestore
          .collection('Users/${currentUser.userId}/CallHistory')
          .doc()
          .id;

      await _firestore
          .collection('Users/${currentUser.userId}/CallHistory')
          .doc(callId)
          .set({
        'callId': callId,
        'receiverId': receiverId,
        'callType': callType == CallType.video ? 'video' : 'audio',
        'callStatus': callStatus == CallStatus.incoming
            ? 'incoming'
            : callStatus == CallStatus.missed
                ? 'missed'
                : 'outgoing',
        'createdAt': FieldValue.serverTimestamp(),
        'duration': duration,
        'isNew': false,
      });
    } catch (e) {
      debugPrint('Error adding call to history: $e');
    }
  }
}




