import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio de caché para videos similar a TikTok
/// Descarga y guarda videos localmente para reproducción instantánea
class VideoCacheService {
  VideoCacheService._();
  static final VideoCacheService instance = VideoCacheService._();

  // Directorio de caché
  Directory? _cacheDir;
  
  // Tamaño máximo del caché (500 MB)
  static const int maxCacheSize = 500 * 1024 * 1024; // 500 MB
  
  // Tamaño máximo por video (50 MB)
  static const int maxVideoSize = 50 * 1024 * 1024; // 50 MB

  /// Inicializar el directorio de caché
  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/video_cache');
    
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    
    return _cacheDir!;
  }

  /// Generar nombre de archivo único basado en la URL
  String _getCacheFileName(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}.mp4';
  }

  /// Obtener ruta del archivo en caché
  Future<File?> getCachedFile(String videoUrl) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = _getCacheFileName(videoUrl);
      final file = File('${cacheDir.path}/$fileName');
      
      if (await file.exists()) {
        // Actualizar fecha de acceso para LRU
        await file.setLastModified(DateTime.now());
        debugPrint('✅ [VIDEO_CACHE] Video encontrado en caché: $fileName');
        return file;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [VIDEO_CACHE] Error obteniendo archivo en caché: $e');
      return null;
    }
  }

  /// Descargar y guardar video en caché
  Future<File?> cacheVideo(String videoUrl) async {
    try {
      // Verificar si ya está en caché
      final cachedFile = await getCachedFile(videoUrl);
      if (cachedFile != null) {
        return cachedFile;
      }

      debugPrint('📥 [VIDEO_CACHE] Descargando video: $videoUrl');
      
      // Verificar tamaño del caché y limpiar si es necesario
      await _cleanCacheIfNeeded();

      // Descargar video
      final response = await http.get(
        Uri.parse(videoUrl),
        headers: {
          'Connection': 'keep-alive',
        },
      ).timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception('Timeout descargando video');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error descargando video: ${response.statusCode}');
      }

      // Verificar tamaño del video
      if (response.bodyBytes.length > maxVideoSize) {
        debugPrint('⚠️ [VIDEO_CACHE] Video muy grande, no se guardará en caché');
        return null;
      }

      // Guardar en caché
      final cacheDir = await _getCacheDirectory();
      final fileName = _getCacheFileName(videoUrl);
      final file = File('${cacheDir.path}/$fileName');
      
      await file.writeAsBytes(response.bodyBytes, flush: true);
      debugPrint('✅ [VIDEO_CACHE] Video guardado en caché: $fileName (${(response.bodyBytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');
      
      return file;
    } catch (e) {
      debugPrint('❌ [VIDEO_CACHE] Error descargando video: $e');
      return null;
    }
  }

  /// Obtener o descargar video (retorna archivo local o null)
  Future<File?> getOrCacheVideo(String videoUrl) async {
    // Primero intentar obtener del caché
    final cachedFile = await getCachedFile(videoUrl);
    if (cachedFile != null) {
      return cachedFile;
    }

    // Si no está en caché, descargar en segundo plano (no bloquear)
    cacheVideo(videoUrl);
    
    // Retornar null para usar la URL original mientras se descarga
    return null;
  }

  /// Limpiar caché si es necesario (LRU - Least Recently Used)
  Future<void> _cleanCacheIfNeeded() async {
    try {
      final cacheDir = await _getCacheDirectory();
      final files = await cacheDir.list().toList();
      
      // Calcular tamaño total
      int totalSize = 0;
      final fileInfos = <MapEntry<File, int>>[];
      
      for (var file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
          fileInfos.add(MapEntry(file, stat.size));
        }
      }

      // Si el tamaño es menor al máximo, no hacer nada
      if (totalSize < maxCacheSize) {
        return;
      }

      debugPrint('🧹 [VIDEO_CACHE] Limpiando caché. Tamaño actual: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Ordenar por fecha de modificación (más antiguos primero)
      fileInfos.sort((a, b) {
        final aStat = a.key.statSync();
        final bStat = b.key.statSync();
        return aStat.modified.compareTo(bStat.modified);
      });

      // Eliminar archivos más antiguos hasta que el tamaño sea menor al máximo
      int deletedSize = 0;
      for (var entry in fileInfos) {
        if (totalSize - deletedSize < maxCacheSize) {
          break;
        }
        
        try {
          await entry.key.delete();
          deletedSize += entry.value;
          debugPrint('🗑️ [VIDEO_CACHE] Eliminado: ${entry.key.path}');
        } catch (e) {
          debugPrint('❌ [VIDEO_CACHE] Error eliminando archivo: $e');
        }
      }

      debugPrint('✅ [VIDEO_CACHE] Caché limpiado. Espacio liberado: ${(deletedSize / 1024 / 1024).toStringAsFixed(2)} MB');
    } catch (e) {
      debugPrint('❌ [VIDEO_CACHE] Error limpiando caché: $e');
    }
  }

  /// Limpiar todo el caché manualmente
  Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
        debugPrint('✅ [VIDEO_CACHE] Caché limpiado completamente');
      }
    } catch (e) {
      debugPrint('❌ [VIDEO_CACHE] Error limpiando caché: $e');
    }
  }

  /// Obtener tamaño del caché
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) return 0;

      int totalSize = 0;
      await for (var entity in cacheDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('❌ [VIDEO_CACHE] Error calculando tamaño del caché: $e');
      return 0;
    }
  }

  /// Precargar video en segundo plano
  Future<void> preloadVideo(String videoUrl) async {
    // Verificar si ya está en caché
    final cachedFile = await getCachedFile(videoUrl);
    if (cachedFile != null) {
      return; // Ya está en caché
    }

    // Descargar en segundo plano
    cacheVideo(videoUrl);
  }
}

