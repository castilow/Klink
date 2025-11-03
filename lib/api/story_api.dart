import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/models/story/story.dart';
import 'package:chat_messenger/models/story/submodels/seen_by.dart';
import 'package:chat_messenger/models/story/submodels/story_image.dart';
import 'package:chat_messenger/models/story/submodels/story_text.dart';
import 'package:chat_messenger/models/story/submodels/story_video.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';

abstract class StoryApi {
  //
  // StoryApi - CRUD Operations
  //

  // Stories collection reference
  static final CollectionReference<Map<String, dynamic>> storiesRef =
      FirebaseFirestore.instance.collection('Stories');

  // Get contacts story
  static Stream<List<Story>> getStories(List<User> contacts) {
    final List<Stream<List<Story>>> stories = [];
    stories.add(_getUserStory(AuthController.instance.currentUser));
    for (final contact in contacts) {
      stories.add(_getUserStory(contact));
    }
    return CombineLatestStream(stories, (values) {
      return values.expand((list) => list).toList()
        ..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
    });
  }

  static Stream<List<Story>> _getUserStory(User user) {
    return storiesRef.where('userId', isEqualTo: user.userId).snapshots().map((
      event,
    ) {
      return event.docs
          .map((e) => Story.fromMap(user: user, data: e.data()))
          .toList();
    });
  }

  // Create text story
  static Future<void> uploadTextStory({
    required String text,
    required Color bgColor,
  }) async {
    try {
      final User currentUser = AuthController.instance.currentUser;

      // Check story doc
      final storyDoc = await storiesRef.doc(currentUser.userId).get();

      // New Story Text
      final StoryText storyText = StoryText(
        text: text,
        bgColor: bgColor,
        createdAt: DateTime.now(),
      );

      // Check result
      if (storyDoc.exists) {
        final oldTexts = List<Map<String, dynamic>>.from(storyDoc['texts']);

        // Update existing story
        await storyDoc.reference.update(
          Story.toUpdateMap(
            type: StoryType.text,
            values: [...oldTexts, storyText.toMap()],
          ),
        );
      } else {
        // Create new story
        final Story story = Story(
          type: StoryType.text,
          texts: [storyText],
          updatedAt: null,
        );
        await storyDoc.reference.set(story.toMap());
      }
      // Close the page
      Get.back();
      // Show message
      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'story_created_successfully'.tr,
      );
    } catch (e) {
      DialogHelper.showSnackbarMessage(SnackMsgType.error, e.toString());
    }
  }

  // Create image story
  static Future<void> uploadImageStory(File imageFile) async {
    try {
      final User currentUser = AuthController.instance.currentUser;

      DialogHelper.showProcessingDialog(
        title: 'uploading'.tr,
        barrierDismissible: false,
      );

      // Check story doc
      final storyDoc = await storiesRef.doc(currentUser.userId).get();

      final String imageUrl = await AppHelper.uploadFile(
        file: imageFile,
        userId: currentUser.userId,
      );

      // New Story Image
      final StoryImage storyImage = StoryImage(
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      // Check result
      if (storyDoc.exists) {
        final oldImages = List<Map<String, dynamic>>.from(storyDoc['images']);

        // Update existing story
        await storyDoc.reference.update(
          Story.toUpdateMap(
            type: StoryType.image,
            values: [...oldImages, storyImage.toMap()],
          ),
        );
      } else {
        // Create new story
        final Story story = Story(
          type: StoryType.image,
          images: [storyImage],
          updatedAt: null,
        );
        await storyDoc.reference.set(story.toMap());
      }
      DialogHelper.closeDialog();
      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'story_created_successfully'.tr,
      );
    } catch (e) {
      DialogHelper.closeDialog();
      DialogHelper.showSnackbarMessage(SnackMsgType.error, e.toString());
    }
  }

  // Create video story
  static Future<void> uploadVideoStory(File videoFile) async {
    try {
      final User currentUser = AuthController.instance.currentUser;

      DialogHelper.showProcessingDialog(
        title: 'uploading'.tr,
        barrierDismissible: false,
      );

      // Check story doc
      final storyDoc = await storiesRef.doc(currentUser.userId).get();

      // <-- Upload video -->
      final String videoUrl = await AppHelper.uploadFile(
        file: videoFile,
        userId: currentUser.userId,
      );

      // New Story video
      final StoryVideo storyVideo = StoryVideo(
        videoUrl: videoUrl,
        thumbnailUrl: '', // No thumbnail for now
        createdAt: DateTime.now(),
      );

      // Check result
      if (storyDoc.exists) {
        final oldVideos = List<Map<String, dynamic>>.from(storyDoc['videos']);

        // Update existing story
        await storyDoc.reference.update(
          Story.toUpdateMap(
            type: StoryType.video,
            values: [...oldVideos, storyVideo.toMap()],
          ),
        );
      } else {
        // Create new story
        final Story story = Story(
          type: StoryType.video,
          videos: [storyVideo],
          updatedAt: null,
        );
        await storyDoc.reference.set(story.toMap());
      }
      DialogHelper.closeDialog();
      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'story_created_successfully'.tr,
      );
    } catch (e) {
      DialogHelper.closeDialog();
      DialogHelper.showSnackbarMessage(SnackMsgType.error, e.toString());
    }
  }

  static Future<void> markSeen({
    required Story story,
    required dynamic storyItem,
    required List<SeenBy> seenByList,
  }) async {
    try {
      final User currentUser = AuthController.instance.currentUser;

      // New seen by
      final SeenBy newSeenBy = SeenBy(
        userId: currentUser.userId,
        fullname: currentUser.fullname,
        photoUrl: currentUser.photoUrl,
        time: DateTime.now(),
      );

      // New seen by list
      final List<SeenBy> newSeenByList = [...seenByList, newSeenBy];

      switch (storyItem) {
        case StoryText _:
          // Update story item
          final List<StoryText> texts = story.texts.map((e) {
            if (e == storyItem) {
              e.seenBy = newSeenByList;
            }
            return e;
          }).toList();

          await storiesRef.doc(story.id).update({
            'texts': texts.map((e) => e.toMap()).toList(),
          });
          break;
        case StoryImage _:
          // Update story item
          final List<StoryImage> images = story.images.map((e) {
            if (e == storyItem) {
              e.seenBy = newSeenByList;
            }
            return e;
          }).toList();

          await storiesRef.doc(story.id).update({
            'images': images.map((e) => e.toMap()).toList(),
          });
          break;
        case StoryVideo _:
          // Update story item
          final List<StoryVideo> videos = story.videos.map((e) {
            if (e == storyItem) {
              e.seenBy = newSeenByList;
            }
            return e;
          }).toList();

          await storiesRef.doc(story.id).update({
            'videos': videos.map((e) => e.toMap()).toList(),
          });
          break;
      }
      debugPrint('markSeen() -> success');
    } catch (e) {
      debugPrint('markSeen() -> error: $e');
    }
  }

  static Future<void> _updateStoryData({
    required Story story,
    required Map<Object, Object?> data,
  }) async {
    final int totalItems =
        (story.texts.length + story.images.length + story.videos.length);

    if (totalItems == 0) {
      await storiesRef.doc(story.id).delete();
    } else {
      await storiesRef.doc(story.id).update(data);
    }
  }

  static Future<void> deleteStoryItem({
    required Story story,
    required dynamic storyItem,
  }) async {
    try {
      void success() {
        DialogHelper.showSnackbarMessage(
          SnackMsgType.success,
          'story_deleted_successfully'.tr,
        );
      }

      Map<String, dynamic> updateData = {};
      int totalItems = 0;

      switch (storyItem) {
        case StoryText _:
          final List<StoryText> texts = [...story.texts];
          texts.remove(storyItem);
          updateData['texts'] = texts.map((e) => e.toMap()).toList();
          totalItems = texts.length + story.images.length + story.videos.length;

          success();
          debugPrint('deleteStoryItem -> text: deleted');
          break;

        case StoryImage _:
          final List<StoryImage> images = [...story.images];
          images.remove(storyItem);

          // Delete the image file from storage
          await _deleteFileFromStorage(storyItem.imageUrl);

          updateData['images'] = images.map((e) => e.toMap()).toList();
          totalItems = story.texts.length + images.length + story.videos.length;

          success();
          debugPrint('deleteStoryItem -> image: deleted');
          break;

        case StoryVideo _:
          final List<StoryVideo> videos = [...story.videos];
          videos.remove(storyItem);

          // Delete the video and thumbnail files from storage
          await _deleteFileFromStorage(storyItem.videoUrl);
          await _deleteFileFromStorage(storyItem.thumbnailUrl);

          updateData['videos'] = videos.map((e) => e.toMap()).toList();
          totalItems = story.texts.length + story.images.length + videos.length;

          success();
          debugPrint('deleteStoryItem -> video: deleted');
          break;
      }

      // If no items remain, delete the entire story
      if (totalItems == 0) {
        await deleteStory(story: story);
      } else {
        // Update story with modified data
        await _updateStoryData(story: story, data: updateData);
      }
    } catch (error) {
      debugPrint('deleteStoryItem -> Error: $error');

      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Failed to delete story item. Error: $error',
      );
    }
  }

  // Helper method to delete files from Firebase Storage
  static Future<void> _deleteFileFromStorage(String url) async {
    try {
      if (url.isNotEmpty) {
        final Reference ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
        debugPrint('File deleted from storage: $url');
      }
    } catch (error) {
      debugPrint('Error deleting file from storage: $error');
    }
  }

  // Method to delete entire story
  static Future<void> deleteStory({required Story story}) async {
    try {
      // Delete all files from storage
      for (final image in story.images) {
        await _deleteFileFromStorage(image.imageUrl);
      }
      for (final video in story.videos) {
        await _deleteFileFromStorage(video.videoUrl);
        await _deleteFileFromStorage(video.thumbnailUrl);
      }

      // Delete story document from Firestore
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(story.id)
          .delete();

      // Refresh stories list
      await _refreshStoriesList();

      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'story_deleted_successfully'.tr,
      );

      debugPrint('deleteStory -> story deleted completely');
    } catch (error) {
      debugPrint('deleteStory -> Error: $error');

      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Failed to delete story. Error: $error',
      );
    }
  }

  // Helper method to refresh stories list after deletion
  static Future<void> _refreshStoriesList() async {
    try {
      // The stories will be refreshed automatically by the stream
      debugPrint('Story deleted - list will refresh automatically');
    } catch (error) {
      debugPrint('Error refreshing stories list: $error');
    }
  }

  static Future<void> viewStories(List<Story> stories) async {
    try {
      final User currentUser = AuthController.instance.currentUser;

      final List<Future<void>> futures = stories.map((story) {
        return storiesRef.doc(story.id).update({
          'viewers': FieldValue.arrayUnion([currentUser.userId]),
        });
      }).toList();
      await Future.wait(futures);
      debugPrint('viewStories() -> success');
    } catch (e) {
      debugPrint('viewStories() -> error: $e');
    }
  }

  static Future<void> deleteExpiredStoryItems(Story story) async {
    try {
      final now = DateTime.now();

      // Filter out expired items (older than 24 hours)
      final validTexts = story.texts.where((text) {
        return now.difference(text.createdAt) < const Duration(hours: 24);
      }).toList();

      final validImages = story.images.where((image) {
        return now.difference(image.createdAt) < const Duration(hours: 24);
      }).toList();

      final validVideos = story.videos.where((video) {
        return now.difference(video.createdAt) < const Duration(hours: 24);
      }).toList();

      // Delete expired image and video files from storage
      final expiredImages = story.images.where((image) {
        return now.difference(image.createdAt) >= const Duration(hours: 24);
      }).toList();

      final expiredVideos = story.videos.where((video) {
        return now.difference(video.createdAt) >= const Duration(hours: 24);
      }).toList();

      // Delete files from storage
      for (final image in expiredImages) {
        AppHelper.deleteFile(image.imageUrl);
      }

      for (final video in expiredVideos) {
        Future.wait([
          AppHelper.deleteFile(video.videoUrl),
          AppHelper.deleteFile(video.thumbnailUrl),
        ]);
      }

      // Update story with only valid items
      final totalValidItems =
          validTexts.length + validImages.length + validVideos.length;

      if (totalValidItems == 0) {
        // Delete entire story if no valid items remain
        await storiesRef.doc(story.id).delete();
        debugPrint('deleteExpiredStoryItems -> entire story deleted');
      } else {
        // Update story with only valid items
        await storiesRef.doc(story.id).update({
          'texts': validTexts.map((e) => e.toMap()).toList(),
          'images': validImages.map((e) => e.toMap()).toList(),
          'videos': validVideos.map((e) => e.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint(
          'deleteExpiredStoryItems -> expired items removed, $totalValidItems items remain',
        );
      }
    } catch (e) {
      debugPrint('deleteExpiredStoryItems() -> error: $e');
    }
  }
}
