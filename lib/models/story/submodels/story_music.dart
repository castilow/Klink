import 'seen_by.dart';

class StoryMusic {
  final String trackId;
  final String trackName;
  final String artistName;
  final String albumName;
  final String previewUrl; // URL del preview de 30 segundos (Spotify)
  final String? thumbnailUrl; // URL de la imagen del álbum
  final String? youtubeVideoId; // ID del video de YouTube (opcional)
  final double? startTime; // Tiempo de inicio en segundos (para clips)
  final double? duration; // Duración del clip en segundos
  final bool isCurrentlyPlaying; // Si es música que está escuchando ahora
  List<SeenBy> seenBy;
  final DateTime createdAt;

  StoryMusic({
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.previewUrl,
    this.thumbnailUrl,
    this.youtubeVideoId,
    this.startTime,
    this.duration,
    this.isCurrentlyPlaying = false,
    this.seenBy = const [],
    required this.createdAt,
  });

  factory StoryMusic.fromMap(Map<String, dynamic> data) {
    return StoryMusic(
      trackId: data['trackId'] as String,
      trackName: data['trackName'] as String,
      artistName: data['artistName'] as String,
      albumName: data['albumName'] as String,
      previewUrl: data['previewUrl'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      youtubeVideoId: data['youtubeVideoId'] as String?,
      startTime: data['startTime'] != null ? (data['startTime'] as num).toDouble() : null,
      duration: data['duration'] != null ? (data['duration'] as num).toDouble() : null,
      isCurrentlyPlaying: data['isCurrentlyPlaying'] == true,
      seenBy: SeenBy.seenByFrom(data['seenBy']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackId': trackId,
      'trackName': trackName,
      'artistName': artistName,
      'albumName': albumName,
      'previewUrl': previewUrl,
      'thumbnailUrl': thumbnailUrl,
      'youtubeVideoId': youtubeVideoId,
      'startTime': startTime,
      'duration': duration,
      'isCurrentlyPlaying': isCurrentlyPlaying,
      'seenBy': seenBy.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static List<StoryMusic> musicFrom(List listOfMaps) {
    final music = List<Map<String, dynamic>>.from(listOfMaps);
    return List<StoryMusic>.from(
      music.map((item) => StoryMusic.fromMap(item)),
    );
  }
}
























