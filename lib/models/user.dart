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
  // Message preferences
  bool temporaryMessagesEnabled; // Si el usuario quiere mensajes temporales (24 horas)
  bool audioViewOnceEnabled; // Si el usuario quiere audios de una sola escucha
  // Bio privacy settings
  bool bioVisibleToAll; // Si la bio es visible para todos
  List<String> bioHiddenFromUsers; // Lista de user IDs a los que se oculta la bio
  // Thoughts (Pensamientos) - estado temporal de 24 horas
  String thought; // Pensamiento de máximo 80 caracteres
  DateTime? thoughtExpiresAt; // Fecha de expiración del pensamiento
  // Music status - música temporal de 24 horas
  Map<String, dynamic>? musicTrack; // {platform: 'spotify'|'apple_music', trackId: String, trackName: String, artist: String, previewUrl: String}
  DateTime? musicExpiresAt; // Fecha de expiración de la música

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
    this.temporaryMessagesEnabled = false,
    this.audioViewOnceEnabled = false,
    this.bioVisibleToAll = true,
    this.bioHiddenFromUsers = const [],
    this.thought = '',
    this.thoughtExpiresAt,
    this.musicTrack,
    this.musicExpiresAt,
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

      // Safe conversion for bioHiddenFromUsers
      List<String> bioHiddenFromUsers = [];
      try {
        final bioHiddenFromUsersValue = data['bioHiddenFromUsers'];
        if (bioHiddenFromUsersValue is List) {
          bioHiddenFromUsers = bioHiddenFromUsersValue.whereType<String>().toList();
        }
      } catch (e) {
        bioHiddenFromUsers = [];
      }

      // Safe conversion for thoughtExpiresAt
      DateTime? thoughtExpiresAt;
      try {
        final thoughtExpiresAtValue = data['thoughtExpiresAt'];
        if (thoughtExpiresAtValue != null) {
          if (thoughtExpiresAtValue is int) {
            thoughtExpiresAt = DateTime.fromMillisecondsSinceEpoch(thoughtExpiresAtValue);
          } else if (thoughtExpiresAtValue is Timestamp) {
            thoughtExpiresAt = thoughtExpiresAtValue.toDate();
          }
        }
      } catch (e) {
        thoughtExpiresAt = null;
      }

      // Safe conversion for musicExpiresAt
      DateTime? musicExpiresAt;
      try {
        final musicExpiresAtValue = data['musicExpiresAt'];
        if (musicExpiresAtValue != null) {
          if (musicExpiresAtValue is int) {
            musicExpiresAt = DateTime.fromMillisecondsSinceEpoch(musicExpiresAtValue);
          } else if (musicExpiresAtValue is Timestamp) {
            musicExpiresAt = musicExpiresAtValue.toDate();
          }
        }
      } catch (e) {
        musicExpiresAt = null;
      }

      // Safe conversion for musicTrack
      Map<String, dynamic>? musicTrack;
      try {
        final musicTrackValue = data['musicTrack'];
        if (musicTrackValue is Map) {
          musicTrack = Map<String, dynamic>.from(musicTrackValue);
        }
      } catch (e) {
        musicTrack = null;
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
        temporaryMessagesEnabled: data['temporaryMessagesEnabled'] ?? false,
        audioViewOnceEnabled: data['audioViewOnceEnabled'] ?? false,
        bioVisibleToAll: data['bioVisibleToAll'] ?? true,
        bioHiddenFromUsers: bioHiddenFromUsers,
        thought: data['thought']?.toString() ?? '',
        thoughtExpiresAt: thoughtExpiresAt,
        musicTrack: musicTrack,
        musicExpiresAt: musicExpiresAt,
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
        temporaryMessagesEnabled: data['temporaryMessagesEnabled'] ?? false,
        audioViewOnceEnabled: data['audioViewOnceEnabled'] ?? false,
        bioVisibleToAll: data['bioVisibleToAll'] ?? true,
        bioHiddenFromUsers: const [],
        thought: data['thought']?.toString() ?? '',
        thoughtExpiresAt: null,
        musicTrack: null,
        musicExpiresAt: null,
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
      'temporaryMessagesEnabled': temporaryMessagesEnabled,
      'audioViewOnceEnabled': audioViewOnceEnabled,
      'bioVisibleToAll': bioVisibleToAll,
      'bioHiddenFromUsers': bioHiddenFromUsers,
      'thought': thought,
      'thoughtExpiresAt': thoughtExpiresAt?.millisecondsSinceEpoch,
      'musicTrack': musicTrack,
      'musicExpiresAt': musicExpiresAt?.millisecondsSinceEpoch,
    };
  }
}
