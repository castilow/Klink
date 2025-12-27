import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:chat_messenger/models/sticker.dart';
import 'package:chat_messenger/config/app_config.dart';

class StickerController extends GetxController {
  // Lista de packs de stickers disponibles
  final RxList<StickerPack> stickerPacks = RxList<StickerPack>([]);
  
  // Stickers recientes (guardados localmente)
  final RxList<Sticker> recentStickers = RxList<Sticker>([]);
  
  // Stickers creados por el usuario
  final RxList<Sticker> customStickers = RxList<Sticker>([]);
  
  // Estado de carga
  final RxBool isLoading = RxBool(false);
  
  // Búsqueda
  final RxString searchQuery = RxString('');
  final RxList<Sticker> searchResults = RxList<Sticker>([]);
  
  @override
  void onInit() {
    super.onInit();
    _loadStickerPacks(); // Cargar emojis primero (siempre disponibles)
    _loadRecentStickers();
    _loadCustomStickers();
    // Intentar cargar Telegram en segundo plano (no bloquea la UI)
    _loadTelegramStickers().catchError((e) {
      debugPrint('Telegram stickers failed to load: $e');
      // Continuar con emojis si Telegram falla
    });
  }
  
  // Cargar packs de stickers con emojis predeterminados
  void _loadStickerPacks() {
    isLoading.value = true;
    
    // Packs de emojis organizados por categorías
    stickerPacks.value = [
      // Pack 1: Caras y emociones
      StickerPack(
        id: 'faces_pack',
        name: 'Caras',
        publisher: 'Klink',
        stickers: _generateFaceEmojis(),
        isDownloaded: true,
      ),
      // Pack 2: Gestos y personas
      StickerPack(
        id: 'gestures_pack',
        name: 'Gestos',
        publisher: 'Klink',
        stickers: _generateGestureEmojis(),
        isDownloaded: true,
      ),
      // Pack 3: Objetos y símbolos
      StickerPack(
        id: 'objects_pack',
        name: 'Objetos',
        publisher: 'Klink',
        stickers: _generateObjectEmojis(),
        isDownloaded: true,
      ),
      // Pack 4: Animales y naturaleza
      StickerPack(
        id: 'animals_pack',
        name: 'Animales',
        publisher: 'Klink',
        stickers: _generateAnimalEmojis(),
        isDownloaded: true,
      ),
      // Pack 5: Comida y bebida
      StickerPack(
        id: 'food_pack',
        name: 'Comida',
        publisher: 'Klink',
        stickers: _generateFoodEmojis(),
        isDownloaded: true,
      ),
      // Pack 6: Deportes y actividades
      StickerPack(
        id: 'sports_pack',
        name: 'Deportes',
        publisher: 'Klink',
        stickers: _generateSportsEmojis(),
        isDownloaded: true,
      ),
    ];
    
    isLoading.value = false;
  }
  
  // Generar emojis de caras y emociones
  List<Sticker> _generateFaceEmojis() {
    final emojis = [
      '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
      '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
      '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩',
      '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣',
      '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬',
      '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗',
      '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄', '😯',
      '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵', '🤐',
      '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠', '😈',
      '👿', '👹', '👺', '🤡', '💩', '👻', '💀', '☠️', '👽', '👾',
    ];
    return emojis.asMap().entries.map((entry) {
      return Sticker(
        id: 'face_${entry.key}_${entry.value.codeUnits.join('_')}',
        url: entry.value,
        packId: 'faces_pack',
        emoji: entry.value,
      );
    }).toList();
  }
  
  // Generar emojis de gestos y personas
  List<Sticker> _generateGestureEmojis() {
    final emojis = [
      '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏', '✌️', '🤞',
      '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '👍',
      '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝',
      '🙏', '✍️', '💪', '🦾', '🦿', '🦵', '🦶', '👂', '🦻', '👃',
      '👶', '👧', '🧒', '👦', '👩', '🧑', '👨', '👩‍🦱', '👨‍🦱', '👩‍🦰',
      '👨‍🦰', '🧑‍🦰', '👱‍♀️', '👱', '👱‍♂️', '👩‍🦳', '👨‍🦳', '🧑‍🦳', '👩‍🦲', '👨‍🦲',
    ];
    return emojis.asMap().entries.map((entry) {
      return Sticker(
        id: 'gesture_${entry.key}_${entry.value.codeUnits.join('_')}',
        url: entry.value,
        packId: 'gestures_pack',
        emoji: entry.value,
      );
    }).toList();
  }
  
  // Generar emojis de objetos y símbolos
  List<Sticker> _generateObjectEmojis() {
    final emojis = [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
      '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️',
      '✝️', '☪️', '🕉️', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️', '🛐',
      '⛎', '♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐',
      '♑', '♒', '♓', '🆔', '⚛️', '🉑', '☢️', '☣️', '📴', '📳',
      '🈶', '🈚', '🈸', '🈺', '🈷️', '✴️', '🆚', '💮', '🉐', '㊙️',
      '㊗️', '🈴', '🈵', '🈹', '🈲', '🅰️', '🅱️', '🆎', '🆑', '🅾️',
      '🆘', '❌', '⭕', '🛑', '⛔', '📛', '🚫', '💯', '💢', '♨️',
      '🚷', '🚯', '🚳', '🚱', '🔞', '📵', '🚭', '❗', '❓', '❕',
      '❔', '‼️', '⁉️', '🔅', '🔆', '〽️', '⚠️', '🚸', '🔱', '⚜️',
      '🔰', '♻️', '✅', '🈯', '💹', '❇️', '✳️', '❎', '🌐', '💠',
      'Ⓜ️', '🌀', '💤', '🏧', '🚾', '♿', '🅿️', '🈳', '🈂️', '🛂',
      '🛃', '🛄', '🛅', '🚹', '🚺', '🚼', '🚻', '🚮', '🎦', '📶',
      '🈁', '🔣', 'ℹ️', '🔤', '🔡', '🔠', '🔢', '🔟', '🔺', '🔻',
      '🔸', '🔹', '🔶', '🔷', '🔴', '🟠', '🟡', '🟢', '🔵', '🟣',
      '⚫', '⚪', '🟤', '🔶', '🔷', '🔸', '🔹', '🔺', '🔻', '💠',
      '🔘', '🔳', '🔲', '▪️', '▫️', '◾', '◽', '◼️', '◻️', '🟥',
      '🟧', '🟨', '🟩', '🟦', '🟪', '⬛', '⬜', '🟫', '🔈', '🔇',
    ];
    return emojis.asMap().entries.map((entry) {
      return Sticker(
        id: 'object_${entry.key}_${entry.value.codeUnits.join('_')}',
        url: entry.value,
        packId: 'objects_pack',
        emoji: entry.value,
      );
    }).toList();
  }
  
  // Generar emojis de animales y naturaleza
  List<Sticker> _generateAnimalEmojis() {
    final emojis = [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
      '🦁', '🐮', '🐷', '🐽', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒',
      '🐔', '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇',
      '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜',
      '🦟', '🦗', '🕷️', '🦂', '🐢', '🐍', '🦎', '🦖', '🦕', '🐙',
      '🦑', '🦐', '🦞', '🦀', '🐡', '🐠', '🐟', '🐬', '🐳', '🐋',
      '🦈', '🐊', '🐅', '🐆', '🦓', '🦍', '🦧', '🐘', '🦛', '🦏',
      '🐪', '🐫', '🦒', '🦘', '🦡', '🐃', '🐂', '🐄', '🐎', '🐖',
      '🐏', '🐑', '🦙', '🐐', '🦌', '🐕', '🐩', '🐈', '🦝', '🦨',
      '🐓', '🦃', '🦅', '🦆', '🦢', '🦉', '🦚', '🦜', '🐦', '🦩',
      '🦇', '🦉', '🌲', '🌳', '🌴', '🌵', '🌾', '🌿', '☘️', '🍀',
      '🍁', '🍂', '🍃', '🌺', '🌻', '🌹', '🌷', '🌼', '🌸', '🌾',
    ];
    return emojis.asMap().entries.map((entry) {
      return Sticker(
        id: 'animal_${entry.key}_${entry.value.codeUnits.join('_')}',
        url: entry.value,
        packId: 'animals_pack',
        emoji: entry.value,
      );
    }).toList();
  }
  
  // Generar emojis de comida y bebida
  List<Sticker> _generateFoodEmojis() {
    final emojis = [
      '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍈',
      '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🍆', '🥑', '🥦',
      '🥬', '🥒', '🌶️', '🌽', '🥕', '🥔', '🍠', '🥐', '🥯', '🍞',
      '🥖', '🥨', '🧀', '🥚', '🍳', '🥞', '🥓', '🥩', '🍗', '🍖',
      '🦴', '🌭', '🍔', '🍟', '🍕', '🥪', '🥙', '🌮', '🌯', '🥗',
      '🥘', '🥫', '🍝', '🍜', '🍲', '🍛', '🍣', '🍱', '🥟', '🦪',
      '🍤', '🍙', '🍚', '🍘', '🍥', '🥠', '🥮', '🍢', '🍡', '🍧',
      '🍨', '🍦', '🥧', '🍰', '🎂', '🍮', '🍭', '🍬', '🍫', '🍿',
      '🍩', '🍪', '🌰', '🥜', '🍯', '🥛', '🍼', '☕️', '🍵', '🥤',
      '🍶', '🍺', '🍻', '🥂', '🍷', '🥃', '🍸', '🍹', '🧃', '🧉',
      '🧊', '🥄', '🍴', '🍽️', '🥣', '🥡', '🥢', '🧂',
    ];
    return emojis.asMap().entries.map((entry) {
      return Sticker(
        id: 'food_${entry.key}_${entry.value.codeUnits.join('_')}',
        url: entry.value,
        packId: 'food_pack',
        emoji: entry.value,
      );
    }).toList();
  }
  
  // Generar emojis de deportes y actividades
  List<Sticker> _generateSportsEmojis() {
    final emojis = [
      '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱',
      '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🥅', '⛳', '🏹', '🎣',
      '🥊', '🥋', '🎽', '🛹', '🛷', '⛸️', '🥌', '🎿', '⛷️', '🏂',
      '🏋️‍♀️', '🏋️', '🏋️‍♂️', '🤼‍♀️', '🤼', '🤼‍♂️', '🤸‍♀️', '🤸', '🤸‍♂️', '⛹️‍♀️',
      '⛹️', '⛹️‍♂️', '🤺', '🤾‍♀️', '🤾', '🤾‍♂️', '🏌️‍♀️', '🏌️', '🏌️‍♂️', '🏇',
      '🧘‍♀️', '🧘', '🧘‍♂️', '🏄‍♀️', '🏄', '🏄‍♂️', '🏊‍♀️', '🏊', '🏊‍♂️', '🤽‍♀️',
      '🤽', '🤽‍♂️', '🚣‍♀️', '🚣', '🚣‍♂️', '🧗‍♀️', '🧗', '🧗‍♂️', '🚵‍♀️', '🚵',
      '🚵‍♂️', '🚴‍♀️', '🚴', '🚴‍♂️', '🏆', '🥇', '🥈', '🥉', '🏅', '🎖️',
      '🏵️', '🎗️', '🎫', '🎟️', '🎪', '🤹‍♀️', '🤹', '🤹‍♂️', '🎭', '🩰',
      '🎨', '🎬', '🎤', '🎧', '🎼', '🎹', '🥁', '🎷', '🎺', '🎸',
      '🪕', '🎻', '🎲', '♟️', '🎯', '🎳', '🎮', '🎰', '🧩', '🚗',
      '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐', '🚚',
    ];
    return emojis.asMap().entries.map((entry) {
      return Sticker(
        id: 'sport_${entry.key}_${entry.value.codeUnits.join('_')}',
        url: entry.value,
        packId: 'sports_pack',
        emoji: entry.value,
      );
    }).toList();
  }
  
  // Cargar stickers recientes desde SharedPreferences
  Future<void> _loadRecentStickers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentIds = prefs.getStringList('recent_stickers') ?? [];
      
      // Primero cargar los packs y stickers personalizados
      // Luego buscar los stickers recientes
      // Nota: Esto se llama después de _loadStickerPacks y _loadCustomStickers
      for (final id in recentIds) {
        // Buscar en packs
        for (final pack in stickerPacks) {
          try {
            final sticker = pack.stickers.firstWhere((s) => s.id == id);
            if (!recentStickers.any((s) => s.id == id)) {
              recentStickers.add(sticker);
            }
          } catch (_) {
            // Sticker no encontrado en este pack, continuar
          }
        }
        
        // Buscar en stickers personalizados
        try {
          final sticker = customStickers.firstWhere((s) => s.id == id);
          if (!recentStickers.any((s) => s.id == id)) {
            recentStickers.add(sticker);
          }
        } catch (_) {
          // Sticker no encontrado, continuar
        }
      }
      
      // Si no hay recientes pero hay stickers personalizados, agregar algunos
      if (recentStickers.isEmpty && customStickers.isNotEmpty) {
        // Agregar los últimos 10 stickers personalizados a recientes
        final recentCustom = customStickers.take(10).toList();
        recentStickers.addAll(recentCustom);
        debugPrint('✅ Agregados ${recentCustom.length} stickers personalizados a recientes');
      }
    } catch (e) {
      debugPrint('Error loading recent stickers: $e');
    }
  }
  
  // Cargar stickers personalizados del usuario
  Future<void> _loadCustomStickers() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory stickerDir = Directory('${appDir.path}/custom_stickers');
      
      if (await stickerDir.exists()) {
        final files = stickerDir.listSync();
        for (final file in files) {
          if (file is File && (file.path.endsWith('.png') || file.path.endsWith('.jpg') || file.path.endsWith('.webp'))) {
            customStickers.add(Sticker(
              id: 'custom_${file.path.split('/').last}',
              url: file.path,
              packId: 'custom_pack',
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading custom stickers: $e');
    }
  }
  
  // Agregar sticker a recientes
  Future<void> addToRecent(Sticker sticker) async {
    try {
      // Remover si ya existe
      recentStickers.removeWhere((s) => s.id == sticker.id);
      // Agregar al inicio
      recentStickers.insert(0, sticker);
      // Limitar a 30 stickers recientes
      if (recentStickers.length > 30) {
        recentStickers.removeRange(30, recentStickers.length);
      }
      
      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final recentIds = recentStickers.map((s) => s.id).toList();
      await prefs.setStringList('recent_stickers', recentIds);
    } catch (e) {
      debugPrint('Error adding to recent stickers: $e');
    }
  }
  
  // Agregar sticker personalizado
  Future<void> addCustomSticker(File stickerFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory stickerDir = Directory('${appDir.path}/custom_stickers');
      
      if (!await stickerDir.exists()) {
        await stickerDir.create(recursive: true);
      }
      
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.${stickerFile.path.split('.').last}';
      final File newFile = await stickerFile.copy('${stickerDir.path}/$fileName');
      
      final sticker = Sticker(
        id: 'custom_$fileName',
        url: newFile.path,
        packId: 'custom_pack',
      );
      
      customStickers.add(sticker);
      await addToRecent(sticker);
    } catch (e) {
      debugPrint('Error adding custom sticker: $e');
      rethrow;
    }
  }
  
  // Buscar stickers
  void searchStickers(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }
    
    searchResults.value = [];
    final lowerQuery = query.toLowerCase();
    
    // Buscar en todos los packs
    for (final pack in stickerPacks) {
      // Si el nombre del pack coincide, agregar todos sus stickers
      if (pack.name.toLowerCase().contains(lowerQuery)) {
        for (final sticker in pack.stickers) {
          if (!searchResults.any((s) => s.id == sticker.id)) {
            searchResults.add(sticker);
          }
        }
        continue;
      }
      
      // Buscar por emoji
      for (final sticker in pack.stickers) {
        if (sticker.emoji != null) {
          // Para emojis, buscar si el emoji está en el query (comparación directa)
          if (sticker.emoji!.contains(query) || query.contains(sticker.emoji!)) {
            if (!searchResults.any((s) => s.id == sticker.id)) {
              searchResults.add(sticker);
            }
          }
        }
        
        // Si tiene URL y no es emoji, buscar en el nombre del archivo
        if (sticker.url.startsWith('/') || sticker.url.startsWith('http')) {
          final fileName = sticker.url.split('/').last.toLowerCase();
          if (fileName.contains(lowerQuery)) {
            if (!searchResults.any((s) => s.id == sticker.id)) {
              searchResults.add(sticker);
            }
          }
        }
      }
    }
    
    // Buscar en stickers personalizados
    for (final sticker in customStickers) {
      final fileName = sticker.url.split('/').last.toLowerCase();
      if (fileName.contains(lowerQuery)) {
        if (!searchResults.any((s) => s.id == sticker.id)) {
          searchResults.add(sticker);
        }
      }
    }
  }
  
  // Obtener todos los stickers de un pack
  List<Sticker> getStickersByPack(String packId) {
    try {
      final pack = stickerPacks.firstWhere((p) => p.id == packId);
      return pack.stickers;
    } catch (_) {
      return [];
    }
  }
  
  // Obtener todos los stickers (de todos los packs)
  List<Sticker> getAllStickers() {
    final List<Sticker> all = [];
    for (final pack in stickerPacks) {
      all.addAll(pack.stickers);
    }
    all.addAll(customStickers);
    return all;
  }
  
  // Cargar stickers desde múltiples APIs (TODAS las disponibles)
  Future<void> _loadTelegramStickers() async {
    try {
      isLoading.value = true;
      
      int loadedCount = 0;
      
      // Cargar desde TODAS las APIs disponibles (no solo una)
      // 1. OpenMoji (SVG transparente)
      try {
        await _loadOpenMojiStickers().timeout(const Duration(seconds: 5));
        loadedCount++;
        debugPrint('✅ Stickers cargados desde OpenMoji');
      } catch (e) {
        debugPrint('⚠️ OpenMoji no disponible: $e');
      }
      
      // 2. Giphy (PNG transparente)
      try {
        await _loadGiphyStickers().timeout(const Duration(seconds: 5));
        loadedCount++;
        debugPrint('✅ Stickers cargados desde Giphy');
      } catch (e) {
        debugPrint('⚠️ Giphy no disponible: $e');
      }
      
      // 3. Tenor (GIF/PNG)
      try {
        await _loadTenorStickers().timeout(const Duration(seconds: 5));
        loadedCount++;
        debugPrint('✅ Stickers cargados desde Tenor');
      } catch (e) {
        debugPrint('⚠️ Tenor no disponible: $e');
      }
      
      if (loadedCount == 0) {
        debugPrint('⚠️ Ninguna API de stickers disponible - usando emojis por defecto');
      } else {
        debugPrint('✅ Total: $loadedCount APIs cargadas exitosamente');
      }
      
      isLoading.value = false;
    } catch (e) {
      debugPrint('❌ Error loading stickers: $e');
      isLoading.value = false;
    }
  }
  
  // Cargar un pack específico de Telegram desde tstickers-api
  // Retorna true si se cargó exitosamente
  Future<bool> _loadTelegramPack(String packName) async {
    try {
      // Intentar con diferentes URLs base y formatos de endpoint
      final List<Map<String, String>> endpoints = [
        {'url': 'https://stickers.horner.tj/api/pack/$packName', 'base': 'https://stickers.horner.tj'},
        {'url': 'https://tstickers-api.herokuapp.com/api/pack/$packName', 'base': 'https://tstickers-api.herokuapp.com'},
      ];
      
      Map<String, dynamic>? packData;
      String? baseUrl;
      
      for (final endpoint in endpoints) {
        try {
          final response = await http.get(
            Uri.parse(endpoint['url']!),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'Klink/1.0',
            },
          ).timeout(const Duration(seconds: 3)); // Timeout muy corto para no bloquear
          
          if (response.statusCode == 200) {
            try {
              packData = json.decode(response.body);
              baseUrl = endpoint['base'];
              debugPrint('✅ Loaded Telegram pack: $packName');
              break;
            } catch (e) {
              // Error parsing, continuar con siguiente endpoint
              continue;
            }
          }
        } catch (e) {
          // Timeout o error de red, continuar silenciosamente
          continue;
        }
      }
      
      if (packData == null || baseUrl == null) {
        return false;
      }
      
      // Parsear los stickers del pack (diferentes formatos posibles)
      List<dynamic> stickersData = [];
      
      if (packData['stickers'] != null) {
        stickersData = packData['stickers'] as List<dynamic>;
      } else if (packData['data'] != null && packData['data'] is List) {
        stickersData = packData['data'] as List<dynamic>;
      }
      
      if (stickersData.isEmpty) {
        return false;
      }
      
      final List<Sticker> telegramStickers = [];
      
      for (final stickerData in stickersData) {
        try {
          // Intentar diferentes formatos de respuesta
          String? fileId;
          String? emoji;
          
          if (stickerData is Map) {
            fileId = stickerData['file_id']?.toString() ?? 
                     stickerData['id']?.toString() ??
                     stickerData['fileId']?.toString();
            emoji = stickerData['emoji']?.toString();
          } else if (stickerData is String) {
            fileId = stickerData;
          }
          
          if (fileId != null && fileId.isNotEmpty) {
            // La API convierte WebP a PNG automáticamente (TRANSPARENTE)
            final String stickerUrl = '$baseUrl/api/sticker/$fileId.png';
            
            telegramStickers.add(Sticker(
              id: 'telegram_${packName}_$fileId',
              url: stickerUrl,
              packId: 'telegram_$packName',
              emoji: emoji,
            ));
          }
        } catch (e) {
          debugPrint('Error parsing sticker: $e');
          continue;
        }
      }
      
      if (telegramStickers.isNotEmpty) {
        final pack = StickerPack(
          id: 'telegram_$packName',
          name: packData['title']?.toString() ?? 
                packData['name']?.toString() ?? 
                packName,
          publisher: 'Telegram',
          trayImageUrl: packData['tray_image'] != null 
              ? '$baseUrl/api/sticker/${packData['tray_image']}.png'
              : null,
          stickers: telegramStickers,
          isDownloaded: true,
          isAnimated: false, // PNG estático transparente (convertido de WebP)
        );
        
        // Agregar al inicio de la lista
        stickerPacks.insert(0, pack);
        debugPrint('✅ Loaded Telegram pack: $packName (${telegramStickers.length} transparent PNG stickers)');
        return true;
      }
      
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading Telegram pack $packName: $e');
      return false;
    }
  }
  
  // Cargar stickers desde OpenMoji (SVG transparente garantizado)
  Future<void> _loadOpenMojiStickers() async {
    try {
      // OpenMoji CDN - más stickers populares con SVG transparente
      final List<Map<String, String>> openMojiStickers = [
        {'name': 'Happy', 'url': 'https://openmoji.org/data/color/svg/1F600.svg', 'keywords': 'feliz, sonrisa, happy'},
        {'name': 'Laugh', 'url': 'https://openmoji.org/data/color/svg/1F602.svg', 'keywords': 'risa, reír, laugh'},
        {'name': 'Love', 'url': 'https://openmoji.org/data/color/svg/1F60D.svg', 'keywords': 'amor, enamorado, love'},
        {'name': 'Cool', 'url': 'https://openmoji.org/data/color/svg/1F60E.svg', 'keywords': 'cool, genial, gafas'},
        {'name': 'Wink', 'url': 'https://openmoji.org/data/color/svg/1F609.svg', 'keywords': 'guiño, wink'},
        {'name': 'Kiss', 'url': 'https://openmoji.org/data/color/svg/1F618.svg', 'keywords': 'beso, kiss'},
        {'name': 'Heart Eyes', 'url': 'https://openmoji.org/data/color/svg/1F60D.svg', 'keywords': 'ojos corazón, heart'},
        {'name': 'Thumbs Up', 'url': 'https://openmoji.org/data/color/svg/1F44D.svg', 'keywords': 'pulgar arriba, ok'},
        {'name': 'Clap', 'url': 'https://openmoji.org/data/color/svg/1F44F.svg', 'keywords': 'aplauso, clap'},
        {'name': 'Fire', 'url': 'https://openmoji.org/data/color/svg/1F525.svg', 'keywords': 'fuego, fire'},
        {'name': 'Heart', 'url': 'https://openmoji.org/data/color/svg/2764.svg', 'keywords': 'corazón, heart'},
        {'name': 'Star', 'url': 'https://openmoji.org/data/color/svg/2B50.svg', 'keywords': 'estrella, star'},
        {'name': 'Party', 'url': 'https://openmoji.org/data/color/svg/1F389.svg', 'keywords': 'fiesta, party'},
        {'name': 'Rocket', 'url': 'https://openmoji.org/data/color/svg/1F680.svg', 'keywords': 'cohete, rocket'},
        {'name': 'Diamond', 'url': 'https://openmoji.org/data/color/svg/1F48E.svg', 'keywords': 'diamante, diamond'},
        {'name': 'Thumbs Down', 'url': 'https://openmoji.org/data/color/svg/1F44E.svg', 'keywords': 'pulgar abajo, no'},
        {'name': 'OK', 'url': 'https://openmoji.org/data/color/svg/1F44C.svg', 'keywords': 'ok, perfecto'},
        {'name': 'Pray', 'url': 'https://openmoji.org/data/color/svg/1F64F.svg', 'keywords': 'rezar, gracias'},
        {'name': 'Muscle', 'url': 'https://openmoji.org/data/color/svg/1F4AA.svg', 'keywords': 'fuerza, músculo'},
        {'name': 'Wave', 'url': 'https://openmoji.org/data/color/svg/1F44B.svg', 'keywords': 'hola, adiós'},
        {'name': 'Peace', 'url': 'https://openmoji.org/data/color/svg/270C.svg', 'keywords': 'paz, victoria'},
        {'name': 'Point Right', 'url': 'https://openmoji.org/data/color/svg/1F449.svg', 'keywords': 'señalar, derecha'},
        {'name': 'Point Left', 'url': 'https://openmoji.org/data/color/svg/1F448.svg', 'keywords': 'señalar, izquierda'},
        {'name': 'Raised Hand', 'url': 'https://openmoji.org/data/color/svg/270B.svg', 'keywords': 'mano arriba'},
        {'name': 'Fist', 'url': 'https://openmoji.org/data/color/svg/270A.svg', 'keywords': 'puño, fuerza'},
      ];
      
      final List<Sticker> stickers = openMojiStickers.map((item) {
        return Sticker(
          id: 'openmoji_${item['name']!.toLowerCase()}',
          url: item['url']!,
          packId: 'openmoji',
          keywords: item['keywords']!.split(', '),
        );
      }).toList();
      
      if (stickers.isNotEmpty) {
        final pack = StickerPack(
          id: 'openmoji',
          name: 'OpenMoji',
          publisher: 'OpenMoji',
          stickers: stickers,
          isDownloaded: true,
          isAnimated: false,
        );
        
        stickerPacks.insert(0, pack);
        debugPrint('✅ Loaded OpenMoji pack: ${stickers.length} SVG stickers');
      }
    } catch (e) {
      debugPrint('❌ Error loading OpenMoji: $e');
      rethrow;
    }
  }
  
  // Cargar stickers desde Giphy (PNG transparente)
  Future<void> _loadGiphyStickers() async {
    try {
      // Más categorías populares para más variedad
      final List<String> categories = [
        'love', 'happy', 'celebration', 'funny', 'cute', 
        'excited', 'sad', 'angry', 'surprised', 'cool',
        'thumbs up', 'clap', 'fire', 'party', 'dance'
      ];
      final List<Sticker> allStickers = [];
      
      for (final category in categories) {
        try {
          final uri = Uri.parse(
            'https://api.giphy.com/v1/stickers/search?api_key=${AppConfig.giphyApiKey}&q=$category&limit=15&rating=g'
          );
          
          final response = await http.get(uri).timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final List<dynamic> items = data['data'] ?? [];
            
            for (final item in items) {
              final images = item['images'] ?? {};
              
              // Priorizar PNG estático de mayor resolución para mejor calidad
              String? url;
              // Primero intentar original_still (mayor resolución)
              if (images['original_still'] != null && images['original_still']['url'] != null) {
                url = images['original_still']['url'] as String;
              } else if (images['fixed_height_still'] != null && images['fixed_height_still']['url'] != null) {
                url = images['fixed_height_still']['url'] as String;
              } else if (images['original'] != null && images['original']['url'] != null) {
                // Fallback a original si no hay still
                url = images['original']['url'] as String;
              }
              
              if (url != null && url.isNotEmpty) {
                allStickers.add(Sticker(
                  id: 'giphy_${item['id']}',
                  url: url,
                  packId: 'giphy_$category',
                  keywords: [category, item['title']?.toString() ?? ''],
                ));
              }
            }
          }
          
          // Pequeña pausa entre requests
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          debugPrint('Error loading Giphy category $category: $e');
          continue;
        }
      }
      
      if (allStickers.isNotEmpty) {
        final pack = StickerPack(
          id: 'giphy',
          name: 'Giphy',
          publisher: 'Giphy',
          stickers: allStickers,
          isDownloaded: true,
          isAnimated: false,
        );
        
        stickerPacks.insert(0, pack);
        debugPrint('✅ Loaded Giphy pack: ${allStickers.length} PNG stickers');
      }
    } catch (e) {
      debugPrint('❌ Error loading Giphy: $e');
      rethrow;
    }
  }
  
  // Cargar stickers desde Tenor
  Future<void> _loadTenorStickers() async {
    try {
      // Tenor API - más categorías para más variedad
      final List<String> categories = [
        'love', 'happy', 'celebration', 'funny', 'cute',
        'excited', 'sad', 'angry', 'surprised', 'cool',
        'thumbs up', 'clap', 'fire', 'party', 'dance'
      ];
      final List<Sticker> allStickers = [];
      
      for (final category in categories) {
        try {
          // Tenor API key pública (demo key)
          final uri = Uri.parse(
            'https://g.tenor.com/v1/search?q=$category&key=LIVDSRZULELA&limit=15&media_filter=sticker'
          );
          
          final response = await http.get(uri).timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final List<dynamic> results = data['results'] ?? [];
            
            for (final result in results) {
              final media = result['media'] as List<dynamic>?;
              if (media != null && media.isNotEmpty) {
                // Priorizar PNG transparente si está disponible
                final sticker = media[0];
                String? url;
                
                // Buscar PNG transparente primero
                if (sticker['png_transparent'] != null && sticker['png_transparent']['url'] != null) {
                  url = sticker['png_transparent']['url']?.toString();
                } else if (sticker['url'] != null) {
                  url = sticker['url']?.toString();
                }
                
                if (url != null && url.isNotEmpty) {
                  allStickers.add(Sticker(
                    id: 'tenor_${result['id']}',
                    url: url,
                    packId: 'tenor_$category',
                    keywords: [category, ...(result['tags'] as List<dynamic>? ?? []).map((t) => t.toString())],
                  ));
                }
              }
            }
          }
          
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          debugPrint('Error loading Tenor category $category: $e');
          continue;
        }
      }
      
      if (allStickers.isNotEmpty) {
        final pack = StickerPack(
          id: 'tenor',
          name: 'Tenor',
          publisher: 'Tenor',
          stickers: allStickers,
          isDownloaded: true,
          isAnimated: false,
        );
        
        stickerPacks.insert(0, pack);
        debugPrint('✅ Loaded Tenor pack: ${allStickers.length} stickers');
      }
    } catch (e) {
      debugPrint('❌ Error loading Tenor: $e');
      rethrow;
    }
  }
  
}

