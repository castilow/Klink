import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/helpers/video_thumbnail_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract class VideoApi {
  // Videos collection reference
  static final CollectionReference<Map<String, dynamic>> videosRef =
      FirebaseFirestore.instance.collection('Videos');

  // Upload video
  static Future<void> uploadVideo({
    required File videoFile,
    String? caption,
  }) async {
    try {
      debugPrint('🎥 [VIDEO_API] Iniciando subida de video');
      debugPrint('🎥 [VIDEO_API] Archivo: ${videoFile.path}');
      
      final currentUser = AuthController.instance.currentUser;
      debugPrint('🎥 [VIDEO_API] Usuario: ${currentUser.userId}');

      // Mostrar diálogo de procesamiento
      DialogHelper.showProcessingDialog(
        title: 'Subiendo video...',
        barrierDismissible: false,
      );

      // Generar thumbnail del video
      debugPrint('🎥 [VIDEO_API] Generando thumbnail...');
      String? thumbnailUrl;
      try {
        thumbnailUrl = await VideoThumbnailHelper.generateThumbnail(videoFile.path);
        debugPrint('✅ [VIDEO_API] Thumbnail generado: $thumbnailUrl');
      } catch (e) {
        debugPrint('⚠️ [VIDEO_API] Error generando thumbnail: $e');
        // Continuar sin thumbnail si falla
      }

      // Subir video a Firebase Storage
      debugPrint('📤 [VIDEO_API] Subiendo video a Firebase Storage...');
      final String videoUrl = await AppHelper.uploadFile(
        file: videoFile,
        userId: currentUser.userId,
      );
      debugPrint('✅ [VIDEO_API] Video subido exitosamente: $videoUrl');

      // Subir thumbnail si existe
      if (thumbnailUrl != null) {
        try {
          final thumbnailFile = File(thumbnailUrl);
          if (await thumbnailFile.exists()) {
            final String uploadedThumbnailUrl = await AppHelper.uploadFile(
              file: thumbnailFile,
              userId: currentUser.userId,
            );
            thumbnailUrl = uploadedThumbnailUrl;
            debugPrint('✅ [VIDEO_API] Thumbnail subido: $thumbnailUrl');
          }
        } catch (e) {
          debugPrint('⚠️ [VIDEO_API] Error subiendo thumbnail: $e');
        }
      }

      // Crear documento de video en Firestore
      final String videoId = AppHelper.generateID;
      final now = DateTime.now();
      final videoData = {
        'userId': currentUser.userId,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption ?? '',
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'views': 0,
        'likedBy': <String>[],
        'createdAt': Timestamp.fromDate(now), // Usar timestamp local para que el stream lo detecte inmediatamente
      };

      await videosRef.doc(videoId).set(videoData);
      debugPrint('✅ [VIDEO_API] Video guardado en Firestore: $videoId');
      debugPrint('📊 [VIDEO_API] Datos guardados: $videoData');
      debugPrint('📅 [VIDEO_API] Timestamp: $now');

      // Cerrar diálogo
      Get.back();

      // Mostrar mensaje de éxito
      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'Video subido exitosamente',
      );
    } catch (e) {
      debugPrint('❌ [VIDEO_API] Error al subir video: $e');
      Get.back(); // Cerrar diálogo de procesamiento
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al subir video: ${e.toString()}',
      );
      rethrow;
    }
  }

  // Get videos by user ID
  static Stream<List<Map<String, dynamic>>> getUserVideos(String userId) {
    return videosRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}

