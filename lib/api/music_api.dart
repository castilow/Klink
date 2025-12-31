import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:chat_messenger/config/app_config.dart';

class MusicTrack {
  final String id;
  final String name;
  final String artist;
  final String album;
  final String? previewUrl;
  final String? thumbnailUrl;
  final int? duration; // en milisegundos

  MusicTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    this.previewUrl,
    this.thumbnailUrl,
    this.duration,
  });
}

abstract class MusicApi {
  static String? _spotifyAccessToken;
  static DateTime? _tokenExpiry;

  /// Buscar canciones en Spotify
  static Future<List<MusicTrack>> searchSpotify(String query) async {
    try {
      debugPrint('🎵 [MUSIC_API] Buscando en Spotify: $query');
      
      // Obtener token de acceso
      final accessToken = await _getSpotifyAccessToken();
      if (accessToken == null) {
        debugPrint('❌ [MUSIC_API] No se pudo obtener el token de Spotify');
        throw Exception('No se pudo obtener el token de Spotify');
      }

      debugPrint('✅ [MUSIC_API] Token de Spotify obtenido');

      // Buscar canciones (aumentar límite para tener más opciones con preview)
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://api.spotify.com/v1/search?q=$encodedQuery&type=track&limit=50&market=US',
      );

      debugPrint('🔍 [MUSIC_API] URL de búsqueda Spotify: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📡 [MUSIC_API] Respuesta Spotify: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']?['items'] as List? ?? [];

        debugPrint('🎵 [MUSIC_API] Encontradas ${tracks.length} canciones en Spotify');

        final results = tracks.map((track) {
          try {
            final album = track['album'] as Map<String, dynamic>? ?? {};
            final artists = track['artists'] as List? ?? [];
            final artistNames = artists
                .map((a) => (a as Map<String, dynamic>?)?['name'] as String? ?? '')
                .where((name) => name.isNotEmpty)
                .join(', ');

            final trackName = track['name'] as String? ?? 'Sin título';
            final trackId = track['id'] as String? ?? '';
            final previewUrl = track['preview_url'] as String?;
            final images = album['images'] as List? ?? [];
            final thumbnailUrl = images.isNotEmpty && images[0] != null
                ? ((images[0] as Map<String, dynamic>?)?['url'] as String?)
                : null;
            final duration = track['duration_ms'] as int?;

            // Log detallado del preview
            if (previewUrl != null && previewUrl.isNotEmpty) {
              debugPrint('🎵 [MUSIC_API] Track Spotify: $trackName - $artistNames');
              debugPrint('   ✅ Preview URL disponible: ${previewUrl.substring(0, previewUrl.length > 50 ? 50 : previewUrl.length)}...');
            } else {
              debugPrint('🎵 [MUSIC_API] Track Spotify: $trackName - $artistNames');
              debugPrint('   ⚠️ Preview URL no disponible para esta canción');
            }

            return MusicTrack(
              id: trackId,
              name: trackName,
              artist: artistNames.isNotEmpty ? artistNames : 'Desconocido',
              album: album['name'] as String? ?? '',
              previewUrl: previewUrl,
              thumbnailUrl: thumbnailUrl,
              duration: duration,
            );
          } catch (e) {
            debugPrint('❌ [MUSIC_API] Error procesando track de Spotify: $e');
            return null;
          }
        }).whereType<MusicTrack>().toList();

        // Priorizar canciones con preview (ponerlas primero)
        results.sort((a, b) {
          final aHasPreview = a.previewUrl != null && a.previewUrl!.isNotEmpty;
          final bHasPreview = b.previewUrl != null && b.previewUrl!.isNotEmpty;
          if (aHasPreview && !bHasPreview) return -1;
          if (!aHasPreview && bHasPreview) return 1;
          return 0;
        });

        final withPreview = results.where((t) => t.previewUrl != null && t.previewUrl!.isNotEmpty).length;
        debugPrint('✅ [MUSIC_API] Retornando ${results.length} tracks válidos de Spotify (${withPreview} con preview)');
        return results;
      } else {
        debugPrint('❌ [MUSIC_API] Error en respuesta Spotify: ${response.statusCode} - ${response.body}');
        throw Exception('Error al buscar en Spotify: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [MUSIC_API] Error buscando música en Spotify: $e');
      throw Exception('Error buscando música: $e');
    }
  }

  /// Obtener las canciones más populares de Spotify
  static Future<List<MusicTrack>> getPopularTracks() async {
    try {
      final accessToken = await _getSpotifyAccessToken();
      if (accessToken == null) {
        throw Exception('No se pudo obtener el token de Spotify');
      }

      // Obtener playlists populares
      final url = Uri.parse(
        'https://api.spotify.com/v1/browse/featured-playlists?limit=1',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Por ahora retornamos lista vacía, se puede mejorar
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Obtener token de acceso de Spotify (Client Credentials Flow)
  static Future<String?> _getSpotifyAccessToken() async {
    try {
      // Verificar si el token aún es válido (válido por 1 hora)
      if (_spotifyAccessToken != null && 
          _tokenExpiry != null && 
          DateTime.now().isBefore(_tokenExpiry!)) {
        return _spotifyAccessToken;
      }

      final credentials = base64Encode(
        utf8.encode('${AppConfig.spotifyClientId}:${AppConfig.spotifyClientSecret}'),
      );

      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _spotifyAccessToken = data['access_token'] as String;
        // El token expira en 1 hora, guardamos la hora de expiración
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
        return _spotifyAccessToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtener stream URL de Audius usando el track ID
  /// Audius requiere usar el endpoint /stream para reproducir música
  static Future<String?> getAudiusStreamUrl(String trackId) async {
    try {
      // Lista de gateways de Audius para intentar
      final gateways = [
        'https://audius-discovery-1.cultur3stake.com',
        'https://audius-discovery-2.cultur3stake.com',
        'https://discoveryprovider.audius.co',
        'https://audius-metadata-1.figment.io',
        'https://audius-metadata-2.figment.io',
      ];
      
      // Intentar obtener el track primero para verificar que existe y obtener stream_url si está disponible
      for (final gateway in gateways) {
        try {
          final trackUrl = Uri.parse('$gateway/v1/tracks/$trackId?app_name=Klink');
          final trackResponse = await http.get(trackUrl).timeout(const Duration(seconds: 5));
          
          if (trackResponse.statusCode == 200) {
            final data = json.decode(trackResponse.body);
            final track = data['data'] as Map<String, dynamic>?;
            
            if (track != null) {
              // Intentar obtener stream_url del track (a veces viene en la respuesta)
              var streamUrl = track['stream_url'] as String?;
              
              if (streamUrl != null && streamUrl.isNotEmpty) {
                if (streamUrl.startsWith('http')) {
                  debugPrint('✅ [MUSIC_API] Stream URL obtenido del track: $gateway');
                  return streamUrl;
                } else {
                  // Construir URL completa si es relativa
                  final fullUrl = '$gateway$streamUrl';
                  debugPrint('✅ [MUSIC_API] Stream URL construido: $gateway');
                  return fullUrl;
                }
              }
              
              // Si no hay stream_url en el track, usar el endpoint /stream directamente
              // Este es el método estándar de Audius
              final streamEndpoint = '$gateway/v1/tracks/$trackId/stream?app_name=Klink';
              debugPrint('✅ [MUSIC_API] Usando endpoint /stream en gateway: $gateway');
              return streamEndpoint;
            }
          }
        } catch (e) {
          // Continuar con el siguiente gateway
          debugPrint('⚠️ [MUSIC_API] Gateway $gateway falló: $e');
          continue;
        }
      }
      
      debugPrint('❌ [MUSIC_API] No se pudo obtener stream URL de ningún gateway');
      return null;
    } catch (e) {
      debugPrint('❌ [MUSIC_API] Error obteniendo stream URL de Audius: $e');
      return null;
    }
  }

  /// Buscar música en Audius (API gratuita)
  static Future<List<MusicTrack>> searchAudius(String query) async {
    try {
      debugPrint('🎵 [MUSIC_API] Buscando en Audius: $query');
      
      // Audius API endpoint - completamente gratuito, sin API key requerida
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://discoveryprovider.audius.co/v1/tracks/search?query=$encodedQuery&app_name=Klink',
      );

      debugPrint('🔍 [MUSIC_API] URL de búsqueda Audius: $url');

      final response = await http.get(url);

      debugPrint('📡 [MUSIC_API] Respuesta Audius: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['data'] as List? ?? [];

        debugPrint('🎵 [MUSIC_API] Encontradas ${tracks.length} pistas en Audius');

        final results = <MusicTrack>[];
        
        for (final track in tracks) {
          try {
            final trackId = track['id'] as String? ?? '';
            final title = track['title'] as String? ?? 'Sin título';
            final artistName = track['user']?['name'] as String? ?? 'Desconocido';
            final artwork = track['artwork'] as Map<String, dynamic>?;
            final artworkUrl = artwork?['150x150'] as String?;
            
            // Para Audius, siempre necesitamos obtener el stream URL usando el track ID
            // porque la búsqueda no siempre incluye stream_url
            String? fullStreamUrl;
            
            if (trackId.isNotEmpty) {
              // Siempre obtener el stream URL usando el track ID para asegurar que funcione
              debugPrint('🔍 [MUSIC_API] Obteniendo stream URL para track ID: $trackId');
              fullStreamUrl = await getAudiusStreamUrl(trackId);
              
              // Si getAudiusStreamUrl no funcionó, intentar con stream_url de la búsqueda como fallback
              if (fullStreamUrl == null || fullStreamUrl.isEmpty) {
                var streamUrl = track['stream_url'] as String?;
                if (streamUrl != null && streamUrl.isNotEmpty) {
                  if (streamUrl.startsWith('http')) {
                    fullStreamUrl = streamUrl;
                  } else {
                    // Si es relativa, construir URL completa usando un gateway
                    fullStreamUrl = 'https://discoveryprovider.audius.co$streamUrl';
                  }
                }
              }
            }
            
            debugPrint('🎵 [MUSIC_API] Track Audius: $title - $artistName (ID: $trackId)');
            if (fullStreamUrl != null && fullStreamUrl.isNotEmpty) {
              debugPrint('   ✅ Stream URL disponible: ${fullStreamUrl.substring(0, fullStreamUrl.length > 50 ? 50 : fullStreamUrl.length)}...');
              results.add(MusicTrack(
                id: trackId,
                name: title,
                artist: artistName,
                album: '',
                previewUrl: fullStreamUrl, // URL completa para reproducir
                thumbnailUrl: artworkUrl,
              ));
            } else {
              debugPrint('   ⚠️ Stream URL no disponible para este track');
            }
          } catch (e) {
            debugPrint('❌ [MUSIC_API] Error procesando track de Audius: $e');
          }
        }

        debugPrint('✅ [MUSIC_API] Retornando ${results.length} tracks válidos de Audius (con stream URL)');
        return results;
      } else {
        debugPrint('❌ [MUSIC_API] Error en respuesta Audius: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ [MUSIC_API] Error buscando música en Audius: $e');
      return [];
    }
  }

  /// Buscar música en YouTube
  static Future<List<MusicTrack>> searchYouTube(String query) async {
    try {
      debugPrint('🎵 [MUSIC_API] Buscando en YouTube: $query');
      
      if (AppConfig.youtubeApiKey.isEmpty) {
        debugPrint('⚠️ [MUSIC_API] YouTube API Key no configurada');
        return [];
      }

      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?'
        'part=snippet&'
        'q=$encodedQuery&'
        'type=video&'
        'videoCategoryId=10&' // Categoría de música
        'maxResults=20&'
        'key=${AppConfig.youtubeApiKey}',
      );

      debugPrint('🔍 [MUSIC_API] URL de búsqueda YouTube: $url');

      final response = await http.get(url);

      debugPrint('📡 [MUSIC_API] Respuesta YouTube: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];

        debugPrint('🎵 [MUSIC_API] Encontrados ${items.length} videos en YouTube');

        final results = items.map((item) {
          try {
            final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
            final idData = item['id'] as Map<String, dynamic>? ?? {};
            final videoId = idData['videoId'] as String? ?? '';
            final title = snippet['title'] as String? ?? 'Sin título';
            final channelTitle = snippet['channelTitle'] as String? ?? 'Desconocido';
            final thumbnails = snippet['thumbnails'] as Map<String, dynamic>?;
            final highThumbnail = thumbnails?['high'] as Map<String, dynamic>?;
            final thumbnailUrl = highThumbnail?['url'] as String?;
            
            debugPrint('🎵 [MUSIC_API] Track YouTube: $title - $channelTitle (ID: $videoId)');
            
            return MusicTrack(
              id: videoId,
              name: title,
              artist: channelTitle,
              album: '',
              thumbnailUrl: thumbnailUrl,
              // YouTube no proporciona preview URL directamente, pero podemos usar el video ID
              previewUrl: videoId.isNotEmpty ? 'https://www.youtube.com/watch?v=$videoId' : null,
            );
          } catch (e) {
            debugPrint('❌ [MUSIC_API] Error procesando item de YouTube: $e');
            return null;
          }
        }).whereType<MusicTrack>().toList();

        debugPrint('✅ [MUSIC_API] Retornando ${results.length} tracks válidos de YouTube');
        return results;
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMsg = errorData['error']?['message'] as String? ?? response.statusCode.toString();
          debugPrint('❌ [MUSIC_API] Error en respuesta YouTube: ${response.statusCode} - $errorMsg');
        } catch (_) {
          debugPrint('❌ [MUSIC_API] Error en respuesta YouTube: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      // Si hay error, retornar lista vacía en lugar de lanzar excepción
      debugPrint('❌ [MUSIC_API] Error buscando música en YouTube: $e');
      return [];
    }
  }
  
  /// Buscar música solo en Audius (API gratuita)
  /// NO usar Spotify como lo solicitó el usuario
  static Future<List<MusicTrack>> searchAll(String query) async {
    try {
      debugPrint('🎵 [MUSIC_API] Buscando solo en Audius (API gratuita): $query');
      
      // Solo buscar en Audius (gratuita y música completa)
      final audiusResults = await searchAudius(query).catchError((e) {
        debugPrint('❌ [MUSIC_API] Error en Audius: $e');
        return <MusicTrack>[];
      });
      
      // También buscar en YouTube como respaldo si Audius no tiene resultados
      List<MusicTrack> youtubeResults = [];
      if (audiusResults.isEmpty) {
        debugPrint('⚠️ [MUSIC_API] No hay resultados en Audius, buscando en YouTube como respaldo...');
        youtubeResults = await searchYouTube(query).catchError((e) {
          debugPrint('❌ [MUSIC_API] Error en YouTube: $e');
          return <MusicTrack>[];
        });
      }
      
      // Combinar resultados, Audius primero
      final combined = [
        ...audiusResults,
        ...youtubeResults,
      ];
      
      debugPrint('✅ [MUSIC_API] Total de resultados: ${combined.length} (Audius: ${audiusResults.length}, YouTube: ${youtubeResults.length})');
      
      return combined;
    } catch (e) {
      debugPrint('❌ [MUSIC_API] Error en searchAll: $e');
      return [];
    }
  }
  
  /// Buscar música solo en Audius (gratuita)
  static Future<List<MusicTrack>> searchAudiusOnly(String query) async {
    return searchAudius(query);
  }
}

