import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messenger/models/user.dart';

enum CallType { audio, video }

enum CallStatus { outgoing, incoming, missed }

class CallHistory {
  final String callId;
  final User receiver;
  final CallType callType;
  final CallStatus callStatus;
  final DateTime createdAt;
  final int duration; // Duration in seconds
  final bool isNew;

  CallHistory({
    required this.callId,
    required this.receiver,
    required this.callType,
    required this.callStatus,
    required this.createdAt,
    this.duration = 0,
    this.isNew = false,
  });

  factory CallHistory.fromMap(Map<String, dynamic> map, User receiver) {
    return CallHistory(
      callId: map['callId'] ?? '',
      receiver: receiver,
      callType: map['callType'] == 'video' ? CallType.video : CallType.audio,
      callStatus: _getCallStatus(map['callStatus']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      duration: map['duration'] ?? 0,
      isNew: map['isNew'] ?? false,
    );
  }

  static CallStatus _getCallStatus(String? status) {
    switch (status) {
      case 'incoming':
        return CallStatus.incoming;
      case 'missed':
        return CallStatus.missed;
      default:
        return CallStatus.outgoing;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'receiverId': receiver.userId,
      'callType': callType == CallType.video ? 'video' : 'audio',
      'callStatus': callStatus == CallStatus.incoming
          ? 'incoming'
          : callStatus == CallStatus.missed
              ? 'missed'
              : 'outgoing',
      'createdAt': Timestamp.fromDate(createdAt),
      'duration': duration,
      'isNew': isNew,
    };
  }
}




