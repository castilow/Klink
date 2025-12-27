import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/user.dart';

import 'submodels/story_text.dart';
import 'submodels/story_image.dart';
import 'submodels/story_video.dart';

enum StoryType { text, video, image }

class Story {
  User? user;
  String id;
  String userId;
  StoryType type;
  List<StoryText> texts;
  List<StoryImage> images;
  List<StoryVideo> videos;
  List<String> viewers;
  List<String> bestFriendsOnly; // Lista de IDs de usuarios que pueden ver (VIP)
  bool isVipOnly; // Si solo es visible para mejores amigos
  DateTime? updatedAt;

  Story({
    this.user,
    this.id = '',
    this.userId = '',
    required this.type,
    this.texts = const [],
    this.videos = const [],
    this.images = const [],
    this.viewers = const [],
    this.bestFriendsOnly = const [],
    this.isVipOnly = false,
    required this.updatedAt,
  });

  bool get isOwner => userId == AuthController.instance.currentUser.userId;

  // Check if any story item is older than 24 hours
  bool get isExpired {
    final now = DateTime.now();
    final duration24Hours = const Duration(hours: 24);

    for (final text in texts) {
      if (now.difference(text.createdAt) < duration24Hours) {
        return false;
      }
    }

    for (final image in images) {
      if (now.difference(image.createdAt) < duration24Hours) {
        return false;
      }
    }

    for (final video in videos) {
      if (now.difference(video.createdAt) < duration24Hours) {
        return false;
      }
    }

    // If all items are older than 24 hours, story is expired
    return (texts.isNotEmpty || images.isNotEmpty || videos.isNotEmpty);
  }

  // Get all valid story items (not older than 24 hours)
  List<StoryText> get validTexts {
    final now = DateTime.now();
    return texts.where((text) {
      return now.difference(text.createdAt) < const Duration(hours: 24);
    }).toList();
  }

  List<StoryImage> get validImages {
    final now = DateTime.now();
    return images.where((image) {
      return now.difference(image.createdAt) < const Duration(hours: 24);
    }).toList();
  }

  List<StoryVideo> get validVideos {
    final now = DateTime.now();
    return videos.where((video) {
      return now.difference(video.createdAt) < const Duration(hours: 24);
    }).toList();
  }

  // Check if story has any valid items
  bool get hasValidItems {
    return validTexts.isNotEmpty ||
        validImages.isNotEmpty ||
        validVideos.isNotEmpty;
  }

  // Create a copy of the story with optional updates
  Story copyWith({
    User? user,
    String? id,
    String? userId,
    StoryType? type,
    List<StoryText>? texts,
    List<StoryImage>? images,
    List<StoryVideo>? videos,
    List<String>? viewers,
    List<String>? bestFriendsOnly,
    bool? isVipOnly,
    DateTime? updatedAt,
  }) {
    return Story(
      user: user ?? this.user,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      texts: texts ?? this.texts,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      viewers: viewers ?? this.viewers,
      bestFriendsOnly: bestFriendsOnly ?? this.bestFriendsOnly,
      isVipOnly: isVipOnly ?? this.isVipOnly,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Story.fromMap({
    required User user,
    required Map<String, dynamic> data,
  }) {
    return Story(
      user: user,
      viewers: List<String>.from(data['viewers'] ?? []),
      id: data['id'] as String,
      userId: data['userId'] as String,
      type: StoryType.values.firstWhere((e) => e.name == data['type']),
      texts: StoryText.textsFrom(data['texts']),
      images: StoryImage.imagesFrom(data['images']),
      videos: StoryVideo.videosFrom(data['videos']),
      bestFriendsOnly: List<String>.from(data['bestFriendsOnly'] ?? []),
      isVipOnly: data['isVipOnly'] == true,
      updatedAt: data['updatedAt'] != null
          ? data['updatedAt']!.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final String userId = AuthController.instance.currentUser.userId;
    return {
      'id': userId,
      'userId': userId,
      'type': type.name,
      'texts': texts.map((text) => text.toMap()).toList(),
      'images': images.map((image) => image.toMap()).toList(),
      'videos': videos.map((video) => video.toMap()).toList(),
      'viewers': [],
      'bestFriendsOnly': bestFriendsOnly,
      'isVipOnly': isVipOnly,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> toUpdateMap({
    required StoryType type,
    required List<Map<String, dynamic>> values,
    List<String>? bestFriendsOnly,
    bool? isVipOnly,
  }) {
    final map = {
      '${type.name}s': values,
      'type': type.name,
      'viewers': [],
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (bestFriendsOnly != null) {
      map['bestFriendsOnly'] = bestFriendsOnly;
    }
    if (isVipOnly != null) {
      map['isVipOnly'] = isVipOnly;
    }
    return map;
  }
  
  // Verificar si el usuario actual puede ver esta historia (VIP)
  bool canView(String currentUserId) {
    if (!isVipOnly) return true; // Si no es VIP, todos pueden ver
    if (userId == currentUserId) return true; // El dueño siempre puede ver
    return bestFriendsOnly.contains(currentUserId); // Solo mejores amigos
  }
  
  // Check if current user has viewed this story
  bool hasUnviewedStories(String currentUserId) {
    // If user is owner, consider it viewed (or handle differently if needed)
    if (userId == currentUserId) return false;
    return !viewers.contains(currentUserId);
  }
}
