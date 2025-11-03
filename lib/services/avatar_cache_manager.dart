import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Cache manager dedicado a avatares con expiración larga y mayor capacidad.
class AvatarCacheManager {
  AvatarCacheManager._()
      : manager = CacheManager(
          Config(
            _key,
            stalePeriod: const Duration(days: 60),
            maxNrOfCacheObjects: 1000,
            repo: JsonCacheInfoRepository(databaseName: _dbName),
            fileService: _EtagHttpFileService(),
          ),
        );

  static const String _key = 'avatar_cache_manager';
  static const String _dbName = 'avatar_cache_info';

  static final AvatarCacheManager instance = AvatarCacheManager._();

  final CacheManager manager;

  /// Precarga una lista de URLs en segundo plano.
  Future<void> prefetch(List<String> urls) async {
    for (final url in urls) {
      if (url.isEmpty) continue;
      // No esperamos a que terminen todas; las lanzamos en paralelo.
      unawaited(manager.getSingleFile(url));
    }
  }
}

/// Servicio HTTP que guarda los ETag recibidos en un fichero JSON
/// para inspección/depuración. La lógica de revalidación sigue estando
/// a cargo de flutter_cache_manager internamente.
class _EtagHttpFileService extends HttpFileService {
  static const String _fileName = 'avatar_etags.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode({}));
    }
    return file;
  }

  Future<void> _saveEtag(String url, String etag) async {
    try {
      final file = await _file();
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      map[url] = etag;
      await file.writeAsString(jsonEncode(map), flush: true);
    } catch (_) {}
  }

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String>? headers}) async {
    final response = await super.get(url, headers: headers);
    try {
      final etag = response.eTag;
      if (etag != null && etag.isNotEmpty) {
        unawaited(_saveEtag(url, etag));
      }
    } catch (_) {}
    return response;
  }
}


