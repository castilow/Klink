import 'dart:async';
import 'dart:io';

import 'package:chat_messenger/api/contact_api.dart';
import 'package:chat_messenger/api/story_api.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/media/helpers/media_helper.dart';
import 'package:chat_messenger/models/story/story.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mime/mime.dart';

class StoryController extends GetxController {
  // Get the current instance
  static StoryController instance = Get.find();

  final RxBool isLoading = RxBool(true);
  final RxList<Story> stories = RxList();
  StreamSubscription<List<Story>>? _stream;

  Story? story;
  dynamic storyItem;

  @override
  void onInit() {
    _getStories();
    super.onInit();
  }

  @override
  void onClose() {
    _stream?.cancel();
    super.onClose();
  }

  Future<void> _getStories() async {
    final List<User> contacts = await ContactApi.getContacts().first;
    _stream = StoryApi.getStories(contacts).listen((event) {
      _updateStoriesList(event);
      isLoading.value = false;
    }, onError: (e) => debugPrint(e.toString()));
  }

  void _updateStoriesList(List<Story> event) {
    final User currentUser = AuthController.instance.currentUser;

    debugPrint('📚 [STORY_CONTROLLER] Actualizando lista de historias');
    debugPrint('📚 [STORY_CONTROLLER] Total de historias recibidas: ${event.length}');

    // Filter out expired stories (older than 24 hours)
    // Solo mostrar historias que tienen items válidos (no expirados)
    final validStories = event.where((story) {
      // Verificar que tenga items válidos (menos de 24 horas)
      final hasValid = story.hasValidItems;
      if (!hasValid) {
        debugPrint('⏰ [STORY_CONTROLLER] Historia expirada para usuario: ${story.userId}');
      }
      return hasValid;
    }).toList();

    debugPrint('✅ [STORY_CONTROLLER] Historias válidas: ${validStories.length}');

    // Solo mostrar usuarios que tienen historias activas
    stories.value = validStories;
    
    // Poner la historia del usuario actual al principio
    final Story? pinned = stories.firstWhereOrNull(
      (e) => e.userId == currentUser.userId,
    );
    if (pinned != null) {
      debugPrint('📌 [STORY_CONTROLLER] Moviendo historia del usuario actual al principio');
      stories.remove(pinned);
      stories.insert(0, pinned);
    }

    debugPrint('📚 [STORY_CONTROLLER] Lista final de historias: ${stories.length}');

    // Auto-cleanup expired story items from database
    // Limpiar items expirados de todas las historias (no solo las completamente expiradas)
    _cleanupExpiredStoryItems(event);
  }

  Future<void> _cleanupExpiredStoryItems(List<Story> allStories) async {
    debugPrint('🧹 [STORY_CONTROLLER] Limpiando items expirados de ${allStories.length} historias');

    for (final story in allStories) {
      try {
        // Verificar si hay items expirados (aunque la historia tenga items válidos)
        final now = DateTime.now();
        final hasExpiredItems = story.texts.any((text) => 
            now.difference(text.createdAt) >= const Duration(hours: 24)) ||
          story.images.any((image) => 
            now.difference(image.createdAt) >= const Duration(hours: 24)) ||
          story.videos.any((video) => 
            now.difference(video.createdAt) >= const Duration(hours: 24));

        if (hasExpiredItems) {
          debugPrint('🧹 [STORY_CONTROLLER] Eliminando items expirados de historia de usuario: ${story.userId}');
          await StoryApi.deleteExpiredStoryItems(story);
          debugPrint('✅ [STORY_CONTROLLER] Items expirados eliminados: ${story.userId}');
        }
      } catch (e) {
        debugPrint('❌ [STORY_CONTROLLER] Error limpiando items expirados: $e');
      }
    }
  }

  // Check if the current user is in the list of viewers
  bool get hasUnviewedStories {
    final User currentUser = AuthController.instance.currentUser;

    if (stories.isEmpty) return false;
    for (var story in stories) {
      bool isViewed = story.viewers.contains(currentUser.userId);
      if (!isViewed && !story.isOwner) {
        return true;
      }
    }
    return false;
  }

  void viewStories() {
    if (hasUnviewedStories) {
      StoryApi.viewStories(stories);
    }
  }

  bool isImage(String path) {
    final mimeType = lookupMimeType(path);
    return mimeType?.startsWith('image/') ?? false;
  }

  Future<void> uploadFileStory() async {
    // Get image from camera
    final File? file = await MediaHelper.getImageFromCamera();
    if (file == null) return;

    // Upload story
    if (isImage(file.path)) {
      await StoryApi.uploadImageStory(file);
    } else {
      await StoryApi.uploadVideoStory(file);
    }
  }
}
