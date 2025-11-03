import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:chat_messenger/models/chat.dart';

/// Servicio simple de caché local basado en fichero JSON.
///
/// Guarda y lee la lista de chats para mostrarlos al instante al abrir la app
/// mientras llega el stream de Firestore. No cifra el contenido, sólo se
/// almacena localmente en el dispositivo del usuario.
class LocalCacheService {
  LocalCacheService._();

  static final LocalCacheService instance = LocalCacheService._();

  static const String _chatsCacheFile = 'chats_cache.json';

  Future<File> _resolveFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }

  Future<List<Chat>> readChats() async {
    try {
      final file = await _resolveFile(_chatsCacheFile);
      final raw = await file.readAsString();
      if (raw.isEmpty) return [];
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded.map((e) => Chat.fromCache(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeChats(List<Chat> chats) async {
    try {
      final file = await _resolveFile(_chatsCacheFile);
      final data = chats.map((c) => c.toCacheMap()).toList();
      await file.writeAsString(json.encode(data), flush: true);
    } catch (_) {
      // Silenciar errores de caché: no deben afectar a la UI
    }
  }
}



