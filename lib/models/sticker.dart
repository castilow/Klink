class Sticker {
  final String id;
  final String url;
  final String packId;
  final String? emoji; // Emoji asociado al sticker (opcional)
  final List<String> keywords; // Palabras clave para búsqueda
  
  Sticker({
    required this.id,
    required this.url,
    required this.packId,
    this.emoji,
    this.keywords = const [],
  });
  
  factory Sticker.fromMap(Map<String, dynamic> map) {
    return Sticker(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      packId: map['packId'] ?? '',
      emoji: map['emoji'],
      keywords: List<String>.from(map['keywords'] ?? []),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'packId': packId,
      if (emoji != null) 'emoji': emoji,
      'keywords': keywords,
    };
  }
}

class StickerPack {
  final String id;
  final String name;
  final String publisher;
  final String? trayImageUrl;
  final List<Sticker> stickers;
  final bool isAnimated;
  final bool isPremium;
  final bool isDownloaded;
  
  StickerPack({
    required this.id,
    required this.name,
    required this.publisher,
    this.trayImageUrl,
    required this.stickers,
    this.isAnimated = false,
    this.isPremium = false,
    this.isDownloaded = false,
  });
  
  factory StickerPack.fromMap(Map<String, dynamic> map) {
    return StickerPack(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      publisher: map['publisher'] ?? '',
      trayImageUrl: map['trayImageUrl'],
      stickers: (map['stickers'] as List<dynamic>?)
          ?.map((s) => Sticker.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
      isAnimated: map['isAnimated'] ?? false,
      isPremium: map['isPremium'] ?? false,
      isDownloaded: map['isDownloaded'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'publisher': publisher,
      if (trayImageUrl != null) 'trayImageUrl': trayImageUrl,
      'stickers': stickers.map((s) => s.toMap()).toList(),
      'isAnimated': isAnimated,
      'isPremium': isPremium,
      'isDownloaded': isDownloaded,
    };
  }
}

