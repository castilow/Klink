import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

abstract class VideoThumbnailHelper {
  /// Generate thumbnail from video file
  static Future<String?> generateThumbnail(String videoPath) async {
    try {
      debugPrint('🎬 [THUMBNAIL] Generando thumbnail para: $videoPath');
      
      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String thumbnailPath = '${tempDir.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Generate thumbnail at 1 second mark
      final String? thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720, // Ancho máximo
        quality: 85,
        timeMs: 1000, // 1 segundo
      );
      
      if (thumbnail != null) {
        debugPrint('✅ [THUMBNAIL] Thumbnail generado: $thumbnail');
        return thumbnail;
      } else {
        debugPrint('⚠️ [THUMBNAIL] No se pudo generar thumbnail');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [THUMBNAIL] Error generando thumbnail: $e');
      return null;
    }
  }
}




















