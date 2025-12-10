import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
import 'package:chat_messenger/models/story/submodels/story_music.dart';
import 'package:chat_messenger/api/best_friends_api.dart';
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
    final currentUserId = AuthController.instance.currentUser.userId;
    
    debugPrint('📚 [STORY_API] Obteniendo historias para ${contacts.length + 1} usuarios (incluyendo usuario actual)');
    
    final List<Stream<List<Story>>> stories = [];
    stories.add(_getUserStory(AuthController.instance.currentUser));
    for (final contact in contacts) {
      stories.add(_getUserStory(contact));
    }
    
    return CombineLatestStream(stories, (values) {
      final allStories = values.expand((list) => list).toList();
      debugPrint('📚 [STORY_API] Total de historias obtenidas: ${allStories.length}');
      
      // Filtrar historias: solo mostrar historias con items válidos (< 24 horas)
      final validStories = allStories.where((story) {
        // Primero verificar que tenga items válidos (no expirados)
        if (!story.hasValidItems) {
          debugPrint('⏰ [STORY_API] Historia expirada o sin items válidos para usuario: ${story.userId}');
          return false;
        }
        
        // Luego filtrar historias VIP
        // Si no es VIP, todos pueden ver
        if (!story.isVipOnly) {
          debugPrint('👁️ [STORY_API] Historia pública visible para usuario: ${story.userId}');
          return true;
        }
        // Si es el dueño, puede ver
        if (story.userId == currentUserId) {
          debugPrint('👁️ [STORY_API] Historia VIP del usuario actual: ${story.userId}');
          return true;
        }
        // Si el dueño tiene al usuario actual en mejores amigos, puede ver
        final canView = story.bestFriendsOnly.contains(currentUserId);
        debugPrint('👁️ [STORY_API] Historia VIP de ${story.userId}: ${canView ? "Visible (mejor amigo)" : "Oculta"}');
        return canView;
      }).toList();
      
      debugPrint('✅ [STORY_API] Historias válidas después de filtrar: ${validStories.length}');
      
      validStories.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
      return validStories;
    });
  }

  static Stream<List<Story>> _getUserStory(User user) {
    return storiesRef.where('userId', isEqualTo: user.userId).snapshots().map((
      event,
    ) {
      return event.docs
          .map((e) {
            final data = e.data();
            data['id'] = e.id; // Asegurar que el ID del documento esté en los datos
            return Story.fromMap(user: user, data: data);
          })
          .toList();
    });
  }

  // Create text story
  static Future<void> uploadTextStory({
    required String text,
    required Color bgColor,
    StoryMusic? music,
    List<String>? bestFriendsOnly,
    bool isVipOnly = false,
  }) async {
    try {
      debugPrint('📖 [STORY_API] Iniciando subida de historia de texto');
      debugPrint('📖 [STORY_API] Texto: ${text.length} caracteres');
      debugPrint('📖 [STORY_API] Música: ${music != null ? "${music.trackName} - ${music.artistName}" : "Sin música"}');
      debugPrint('📖 [STORY_API] VIP: $isVipOnly, Mejores amigos: ${bestFriendsOnly?.length ?? 0}');
      
      final User currentUser = AuthController.instance.currentUser;
      debugPrint('📖 [STORY_API] Usuario: ${currentUser.userId}');

      // Check story doc
      final storyDoc = await storiesRef.doc(currentUser.userId).get();
      debugPrint('📖 [STORY_API] Documento de historia existe: ${storyDoc.exists}');

      // New Story Text
      final StoryText storyText = StoryText(
        text: text,
        bgColor: bgColor,
        music: music, // Incluir música si existe
        createdAt: DateTime.now(),
      );

      // Check result
      if (storyDoc.exists) {
        final data = storyDoc.data()!;
        final oldTexts = List<Map<String, dynamic>>.from(data['texts'] ?? []);
        final oldImages = List<Map<String, dynamic>>.from(data['images'] ?? []);
        final oldVideos = List<Map<String, dynamic>>.from(data['videos'] ?? []);
        debugPrint('📖 [STORY_API] Actualizando historia existente (${oldTexts.length} textos, ${oldImages.length} imágenes, ${oldVideos.length} videos)');

        // Update existing story - preservar todos los items existentes
        final updateData = {
          'texts': [...oldTexts, storyText.toMap()],
          'images': oldImages, // Preservar imágenes existentes
          'videos': oldVideos, // Preservar videos existentes
          'type': StoryType.text.name,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Actualizar configuración VIP si se proporciona
        if (bestFriendsOnly != null) {
          updateData['bestFriendsOnly'] = bestFriendsOnly;
        }
        if (isVipOnly != null) {
          updateData['isVipOnly'] = isVipOnly;
        }
        
        await storyDoc.reference.update(updateData);
        debugPrint('✅ [STORY_API] Historia de texto actualizada exitosamente');
      } else {
        debugPrint('📖 [STORY_API] Creando nueva historia de texto');
        // Create new story
        final Story story = Story(
          id: currentUser.userId,
          userId: currentUser.userId,
          type: StoryType.text,
          texts: [storyText],
          bestFriendsOnly: bestFriendsOnly ?? [],
          isVipOnly: isVipOnly,
          updatedAt: DateTime.now(),
        );
        await storyDoc.reference.set(story.toMap());
        debugPrint('✅ [STORY_API] Nueva historia de texto creada exitosamente');
      }
      // NO cerrar la pantalla automáticamente - permitir agregar más estados
      // Show message
      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'Estado publicado. Puedes agregar más estados.',
        duration: 2,
      );
    } catch (e) {
      debugPrint('❌ [STORY_API] Error al subir historia de texto: $e');
      DialogHelper.showSnackbarMessage(SnackMsgType.error, e.toString());
    }
  }

  // Create image story
  static Future<void> uploadImageStory(
    File imageFile, {
    StoryMusic? music,
    List<String>? bestFriendsOnly,
    bool isVipOnly = false,
  }) async {
    try {
      debugPrint('🖼️ [STORY_API] Iniciando subida de historia de imagen');
      debugPrint('🖼️ [STORY_API] Archivo: ${imageFile.path}');
      debugPrint('🖼️ [STORY_API] Música: ${music != null ? "${music.trackName} - ${music.artistName}" : "Sin música"}');
      debugPrint('🖼️ [STORY_API] VIP: $isVipOnly, Mejores amigos: ${bestFriendsOnly?.length ?? 0}');
      
      final User currentUser = AuthController.instance.currentUser;
      debugPrint('🖼️ [STORY_API] Usuario: ${currentUser.userId}');

      DialogHelper.showProcessingDialog(
        title: 'uploading'.tr,
        barrierDismissible: false,
      );

      // Check story doc
      final storyDoc = await storiesRef.doc(currentUser.userId).get();
      debugPrint('🖼️ [STORY_API] Documento de historia existe: ${storyDoc.exists}');

      debugPrint('📤 [STORY_API] Subiendo imagen a Firebase Storage...');
      final String imageUrl = await AppHelper.uploadFile(
        file: imageFile,
        userId: currentUser.userId,
      );
      debugPrint('✅ [STORY_API] Imagen subida exitosamente: $imageUrl');

      // New Story Image
      final StoryImage storyImage = StoryImage(
        imageUrl: imageUrl,
        music: music,
        createdAt: DateTime.now(),
      );

      // Check result
      if (storyDoc.exists) {
        final data = storyDoc.data()!;
        final oldTexts = List<Map<String, dynamic>>.from(data['texts'] ?? []);
        final oldImages = List<Map<String, dynamic>>.from(data['images'] ?? []);
        final oldVideos = List<Map<String, dynamic>>.from(data['videos'] ?? []);
        debugPrint('🖼️ [STORY_API] Actualizando historia existente (${oldTexts.length} textos, ${oldImages.length} imágenes, ${oldVideos.length} videos)');

        // Update existing story - preservar todos los items existentes
        final updateData = {
          'texts': oldTexts, // Preservar textos existentes
          'images': [...oldImages, storyImage.toMap()],
          'videos': oldVideos, // Preservar videos existentes
          'type': StoryType.image.name,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Actualizar configuración VIP si se proporciona
        if (bestFriendsOnly != null) {
          updateData['bestFriendsOnly'] = bestFriendsOnly;
        }
        if (isVipOnly != null) {
          updateData['isVipOnly'] = isVipOnly;
        }
        
        await storyDoc.reference.update(updateData);
        debugPrint('✅ [STORY_API] Historia de imagen actualizada exitosamente');
      } else {
        debugPrint('🖼️ [STORY_API] Creando nueva historia de imagen');
        // Create new story
        final Story story = Story(
          id: currentUser.userId,
          userId: currentUser.userId,
          type: StoryType.image,
          images: [storyImage],
          bestFriendsOnly: bestFriendsOnly ?? [],
          isVipOnly: isVipOnly,
          updatedAt: DateTime.now(),
        );
        await storyDoc.reference.set(story.toMap());
        debugPrint('✅ [STORY_API] Nueva historia de imagen creada exitosamente');
      }
      DialogHelper.closeDialog();
      // NO cerrar la pantalla automáticamente - permitir agregar más estados
      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'Estado publicado. Puedes agregar más estados.',
        duration: 2,
      );
    } catch (e) {
      debugPrint('❌ [STORY_API] Error al subir historia de imagen: $e');
      DialogHelper.closeDialog();
      DialogHelper.showSnackbarMessage(SnackMsgType.error, e.toString());
    }
  }

  // Create video story
  static Future<void> uploadVideoStory(
    File videoFile, {
    StoryMusic? music,
    List<String>? bestFriendsOnly,
    bool isVipOnly = false,
  }) async {
    try {
      debugPrint('🎥 [STORY_API] Iniciando subida de historia de video');
      debugPrint('🎥 [STORY_API] Archivo: ${videoFile.path}');
      debugPrint('🎥 [STORY_API] Música: ${music != null ? "${music.trackName} - ${music.artistName}" : "Sin música"}');
      debugPrint('🎥 [STORY_API] VIP: $isVipOnly, Mejores amigos: ${bestFriendsOnly?.length ?? 0}');
      
      final User currentUser = AuthController.instance.currentUser;
      debugPrint('🎥 [STORY_API] Usuario: ${currentUser.userId}');

      DialogHelper.showProcessingDialog(
        title: 'uploading'.tr,
        barrierDismissible: false,
      );

      // Check story doc
      final storyDoc = await storiesRef.doc(currentUser.userId).get();
      debugPrint('🎥 [STORY_API] Documento de historia existe: ${storyDoc.exists}');

      // <-- Upload video -->
      debugPrint('📤 [STORY_API] Subiendo video a Firebase Storage...');
      final String videoUrl = await AppHelper.uploadFile(
        file: videoFile,
        userId: currentUser.userId,
      );
      debugPrint('✅ [STORY_API] Video subido exitosamente: $videoUrl');

      // New Story video
      final StoryVideo storyVideo = StoryVideo(
        videoUrl: videoUrl,
        thumbnailUrl: '', // No thumbnail for now
        music: music,
        createdAt: DateTime.now(),
      );

      // Check result
      if (storyDoc.exists) {
        final data = storyDoc.data()!;
        final oldTexts = List<Map<String, dynamic>>.from(data['texts'] ?? []);
        final oldImages = List<Map<String, dynamic>>.from(data['images'] ?? []);
        final oldVideos = List<Map<String, dynamic>>.from(data['videos'] ?? []);
        debugPrint('🎥 [STORY_API] Actualizando historia existente (${oldTexts.length} textos, ${oldImages.length} imágenes, ${oldVideos.length} videos)');

        // Update existing story - preservar todos los items existentes
        final updateData = {
          'texts': oldTexts, // Preservar textos existentes
          'images': oldImages, // Preservar imágenes existentes
          'videos': [...oldVideos, storyVideo.toMap()],
          'type': StoryType.video.name,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Actualizar configuración VIP si se proporciona
        if (bestFriendsOnly != null) {
          updateData['bestFriendsOnly'] = bestFriendsOnly;
        }
        if (isVipOnly != null) {
          updateData['isVipOnly'] = isVipOnly;
        }
        
        await storyDoc.reference.update(updateData);
        debugPrint('✅ [STORY_API] Historia de video actualizada exitosamente');
      } else {
        debugPrint('🎥 [STORY_API] Creando nueva historia de video');
        // Create new story
        final Story story = Story(
          id: currentUser.userId,
          userId: currentUser.userId,
          type: StoryType.video,
          videos: [storyVideo],
          bestFriendsOnly: bestFriendsOnly ?? [],
          isVipOnly: isVipOnly,
          updatedAt: DateTime.now(),
        );
        await storyDoc.reference.set(story.toMap());
        debugPrint('✅ [STORY_API] Nueva historia de video creada exitosamente');
      }
      DialogHelper.closeDialog();
      // NO cerrar la pantalla automáticamente - permitir agregar más estados
      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'Estado publicado. Puedes agregar más estados.',
        duration: 2,
      );
    } catch (e) {
      debugPrint('❌ [STORY_API] Error al subir historia de video: $e');
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
      debugPrint('👁️ [STORY_API] Marcando historia como vista');
      debugPrint('👁️ [STORY_API] Historia ID: ${story.id}, Usuario: ${story.userId}');
      
      final User currentUser = AuthController.instance.currentUser;

      // New seen by
      final SeenBy newSeenBy = SeenBy(
        userId: currentUser.userId,
        fullname: currentUser.fullname,
        photoUrl: currentUser.photoUrl,
        time: DateTime.now(),
      );

      debugPrint('👁️ [STORY_API] Nuevo visto por: ${currentUser.fullname} (${currentUser.userId})');

      // New seen by list
      final List<SeenBy> newSeenByList = [...seenByList, newSeenBy];
      debugPrint('👁️ [STORY_API] Total de vistos: ${newSeenByList.length}');

      switch (storyItem) {
        case StoryText _:
          debugPrint('👁️ [STORY_API] Actualizando texto de historia');
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
          debugPrint('👁️ [STORY_API] Actualizando imagen de historia');
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
          debugPrint('👁️ [STORY_API] Actualizando video de historia');
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
      debugPrint('✅ [STORY_API] Historia marcada como vista exitosamente');
    } catch (e) {
      debugPrint('❌ [STORY_API] Error marcando historia como vista: $e');
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
      // Verificar que el usuario sea el dueño de la historia
      final currentUserId = AuthController.instance.currentUser.userId;
      if (story.userId != currentUserId) {
        debugPrint('❌ [STORY_API] Usuario no autorizado para eliminar esta historia');
        DialogHelper.showSnackbarMessage(
          SnackMsgType.error,
          'No tienes permiso para eliminar esta historia',
        );
        return;
      }

      debugPrint('🗑️ [STORY_API] Eliminando historia: ${story.id}');
      debugPrint('🗑️ [STORY_API] Usuario: $currentUserId, Dueño: ${story.userId}');

      // Delete all files from storage
      for (final image in story.images) {
        await _deleteFileFromStorage(image.imageUrl);
      }
      for (final video in story.videos) {
        await _deleteFileFromStorage(video.videoUrl);
        await _deleteFileFromStorage(video.thumbnailUrl);
      }

      // Delete story document from Firestore
      await storiesRef.doc(story.id).delete();

      debugPrint('✅ [STORY_API] Historia eliminada exitosamente');

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
      debugPrint('👁️ [STORY_API] Marcando ${stories.length} historias como vistas');
      
      final User currentUser = AuthController.instance.currentUser;
      debugPrint('👁️ [STORY_API] Usuario: ${currentUser.userId}');

      final List<Future<void>> futures = stories.map((story) {
        debugPrint('👁️ [STORY_API] Marcando historia como vista: ${story.id}');
        return storiesRef.doc(story.id).update({
          'viewers': FieldValue.arrayUnion([currentUser.userId]),
        });
      }).toList();
      await Future.wait(futures);
      debugPrint('✅ [STORY_API] ${stories.length} historias marcadas como vistas exitosamente');
    } catch (e) {
      debugPrint('❌ [STORY_API] Error marcando historias como vistas: $e');
    }
  }

  static Future<void> deleteExpiredStoryItems(Story story) async {
    try {
      debugPrint('🧹 [STORY_API] Eliminando items expirados de historia: ${story.id}');
      debugPrint('🧹 [STORY_API] Items actuales - Textos: ${story.texts.length}, Imágenes: ${story.images.length}, Videos: ${story.videos.length}');
      
      final now = DateTime.now();

      // Filter out expired items (older than 24 hours)
      final validTexts = story.texts.where((text) {
        final isExpired = now.difference(text.createdAt) >= const Duration(hours: 24);
        if (isExpired) {
          debugPrint('⏰ [STORY_API] Texto expirado (${now.difference(text.createdAt).inHours}h)');
        }
        return !isExpired;
      }).toList();

      final validImages = story.images.where((image) {
        final isExpired = now.difference(image.createdAt) >= const Duration(hours: 24);
        if (isExpired) {
          debugPrint('⏰ [STORY_API] Imagen expirada (${now.difference(image.createdAt).inHours}h)');
        }
        return !isExpired;
      }).toList();

      final validVideos = story.videos.where((video) {
        final isExpired = now.difference(video.createdAt) >= const Duration(hours: 24);
        if (isExpired) {
          debugPrint('⏰ [STORY_API] Video expirado (${now.difference(video.createdAt).inHours}h)');
        }
        return !isExpired;
      }).toList();

      debugPrint('✅ [STORY_API] Items válidos - Textos: ${validTexts.length}, Imágenes: ${validImages.length}, Videos: ${validVideos.length}');

      // Delete expired image and video files from storage
      final expiredImages = story.images.where((image) {
        return now.difference(image.createdAt) >= const Duration(hours: 24);
      }).toList();

      final expiredVideos = story.videos.where((video) {
        return now.difference(video.createdAt) >= const Duration(hours: 24);
      }).toList();

      debugPrint('🗑️ [STORY_API] Eliminando ${expiredImages.length} imágenes y ${expiredVideos.length} videos expirados del storage');

      // Delete files from storage
      for (final image in expiredImages) {
        debugPrint('🗑️ [STORY_API] Eliminando imagen del storage: ${image.imageUrl}');
        AppHelper.deleteFile(image.imageUrl);
      }

      for (final video in expiredVideos) {
        debugPrint('🗑️ [STORY_API] Eliminando video del storage: ${video.videoUrl}');
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
        debugPrint('🗑️ [STORY_API] Eliminando historia completa (no quedan items válidos)');
        await storiesRef.doc(story.id).delete();
        debugPrint('✅ [STORY_API] Historia completa eliminada');
      } else {
        // Update story with only valid items
        debugPrint('📝 [STORY_API] Actualizando historia con $totalValidItems items válidos');
        await storiesRef.doc(story.id).update({
          'texts': validTexts.map((e) => e.toMap()).toList(),
          'images': validImages.map((e) => e.toMap()).toList(),
          'videos': validVideos.map((e) => e.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ [STORY_API] Historia actualizada: $totalValidItems items válidos restantes');
      }
    } catch (e) {
      debugPrint('❌ [STORY_API] Error eliminando items expirados: $e');
    }
  }
}
