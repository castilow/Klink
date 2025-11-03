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

    // Filter out expired stories (older than 24 hours)
    final validStories = event.where((story) => story.hasValidItems).toList();

    stories.value = validStories;
    final Story? pinned = stories.firstWhereOrNull(
      (e) => e.userId == currentUser.userId,
    );
    if (pinned == null) return;
    stories.remove(pinned);
    stories.insert(0, pinned);

    // Auto-cleanup expired stories from database
    _cleanupExpiredStories(event);
  }

  Future<void> _cleanupExpiredStories(List<Story> allStories) async {
    final expiredStories = allStories
        .where((story) => story.isExpired)
        .toList();

    for (final story in expiredStories) {
      try {
        await StoryApi.deleteExpiredStoryItems(story);
        debugPrint('Auto-cleaned expired story for user: ${story.userId}');
      } catch (e) {
        debugPrint('Error cleaning expired story: $e');
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
