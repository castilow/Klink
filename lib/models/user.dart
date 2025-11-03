import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

enum LoginProvider { email, google, apple }

class User {
  String userId;
  String fullname;
  String username;
  String photoUrl;
  String email;
  String bio;
  bool isOnline;
  DateTime? lastActive;
  String deviceToken;
  String status;
  LoginProvider loginProvider;
  bool isTyping;
  String typingTo;
  bool isRecording;
  String recordingTo;
  List<String> mutedGroups;
  DateTime? createdAt;

  User({
    this.userId = '',
    this.fullname = '',
    this.username = '',
    this.photoUrl = '',
    this.email = '',
    this.bio = '',
    this.isOnline = false,
    this.lastActive,
    this.deviceToken = '',
    this.status = 'active',
    this.loginProvider = LoginProvider.email,
    this.isTyping = false,
    this.typingTo = '',
    this.isRecording = false,
    this.recordingTo = '',
    this.mutedGroups = const [],
    this.createdAt,
  });

  // Get User first name
  String get firstName => fullname.split(' ').first;

  @override
  String toString() {
    return 'User(userId: $userId, fullname: $fullname, username:$username, photoUrl: $photoUrl, bio: $bio, isOnline: $isOnline, lastActive: $lastActive, deviceToken: $deviceToken, isTyping: $isTyping, typingTo: $typingTo)';
  }

  factory User.fromMap(Map<String, dynamic> data) {
    try {
      // Safe conversion for lastActive
      DateTime? lastActive;
      try {
        final lastActiveValue = data['lastActive'];
        if (lastActiveValue != null) {
          if (lastActiveValue is int) {
            lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveValue);
          } else if (lastActiveValue is Timestamp) {
            lastActive = lastActiveValue.toDate();
          }
        }
      } catch (e) {
        lastActive = null;
      }

      // Safe conversion for mutedGroups
      List<String> mutedGroups = [];
      try {
        final mutedGroupsValue = data['mutedGroups'];
        if (mutedGroupsValue is List) {
          mutedGroups = mutedGroupsValue.whereType<String>().toList();
        }
      } catch (e) {
        mutedGroups = [];
      }

      // Safe conversion for createdAt
      DateTime? createdAt;
      try {
        final createdAtValue = data['createdAt'];
        if (createdAtValue is Timestamp) {
          createdAt = createdAtValue.toDate();
        }
      } catch (e) {
        createdAt = null;
      }

      return User(
        userId: data['userId']?.toString() ?? '',
        fullname: data['fullname']?.toString() ?? '',
        username: data['username']?.toString() ?? '',
        photoUrl: data['photoUrl']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        bio: data['bio']?.toString() ?? '',
        isOnline: data['isOnline'] == true,
        lastActive: lastActive,
        deviceToken: data['deviceToken']?.toString() ?? '',
        status: data['status']?.toString() ?? 'active',
        loginProvider: LoginProvider.values
                .firstWhereOrNull((el) => el.name == data['loginProvider']) ??
            LoginProvider.email,
        isTyping: data['isTyping'] == true,
        typingTo: data['typingTo']?.toString() ?? '',
        isRecording: data['isRecording'] == true,
        recordingTo: data['recordingTo']?.toString() ?? '',
        mutedGroups: mutedGroups,
        createdAt: createdAt,
      );
    } catch (e) {
      // Return a default user if there's any error
      return User(
        userId: data['userId']?.toString() ?? '',
        fullname: data['fullname']?.toString() ?? '',
        username: data['username']?.toString() ?? '',
        photoUrl: data['photoUrl']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        bio: data['bio']?.toString() ?? '',
        isOnline: false,
        lastActive: null,
        deviceToken: '',
        status: 'active',
        loginProvider: LoginProvider.email,
        isTyping: false,
        typingTo: '',
        isRecording: false,
        recordingTo: '',
        mutedGroups: const [],
        createdAt: null,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullname': fullname,
      'username': username,
      'photoUrl': photoUrl,
      'email': email,
      'bio': bio,
      'isOnline': isOnline,
      'lastActive': lastActive?.millisecondsSinceEpoch,
      'deviceToken': deviceToken,
      'status': status,
      'isTyping': isTyping,
      'typingTo': typingTo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
