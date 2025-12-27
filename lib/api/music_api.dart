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

  /// Obtener el preview URL de Spotify usando el track ID
  static Future<String?> getSpotifyPreviewUrl(String trackId) async {
    try {
      final accessToken = await _getSpotifyAccessToken();
      if (accessToken == null) {
        debugPrint('❌ [MUSIC_API] No se pudo obtener el token de Spotify');
        return null;
      }

      final url = Uri.parse('https://api.spotify.com/v1/tracks/$trackId');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final previewUrl = data['preview_url'] as String?;
        if (previewUrl != null && previewUrl.isNotEmpty) {
          debugPrint('✅ [MUSIC_API] Preview URL obtenido de Spotify: ${previewUrl.substring(0, previewUrl.length > 50 ? 50 : previewUrl.length)}...');
          return previewUrl;
        } else {
          debugPrint('⚠️ [MUSIC_API] No hay preview URL disponible para el track ID: $trackId');
          return null;
        }
      } else {
        debugPrint('❌ [MUSIC_API] Error obteniendo preview de Spotify: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [MUSIC_API] Error obteniendo preview de Spotify: $e');
      return null;
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
  
  /// Buscar música en SoundCloud
  /// Nota: SoundCloud ahora usa HLS (AAC) en lugar de MP3 desde noviembre 2025
  static Future<List<MusicTrack>> searchSoundCloud(String query) async {
    try {
      debugPrint('🎵 [MUSIC_API] Buscando en SoundCloud: $query');
      
      // Lista de client_ids como fallback (algunos pueden estar expirados)
      final clientIds = [
        AppConfig.soundcloudClientId,
        'a3e059563d7fd3372b49b37f00a00bcf', // Client ID público alternativo
        '95f22ed54a5c297b1c41f72d713623ef', // Otro client ID público
      ].where((id) => id.isNotEmpty).toList();
      
      if (clientIds.isEmpty) {
        debugPrint('⚠️ [MUSIC_API] SoundCloud Client ID no configurada');
        return [];
      }

      final encodedQuery = Uri.encodeComponent(query);
      
      // Intentar con cada client_id hasta que uno funcione
      for (final clientId in clientIds) {
        try {
          final url = Uri.parse(
            'https://api.soundcloud.com/tracks?q=$encodedQuery&client_id=$clientId&limit=20',
          );

          debugPrint('🔍 [MUSIC_API] URL de búsqueda SoundCloud: $url');

          final response = await http.get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'KlinkApp/1.0',
            },
          ).timeout(const Duration(seconds: 10));

          debugPrint('📡 [MUSIC_API] Respuesta SoundCloud: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final tracks = data as List? ?? [];

            debugPrint('🎵 [MUSIC_API] Encontradas ${tracks.length} canciones en SoundCloud');

            final results = <MusicTrack>[];
            
            for (final track in tracks) {
              try {
                final trackId = track['id']?.toString() ?? '';
                if (trackId.isEmpty) continue;
                
                final title = track['title'] as String? ?? 'Sin título';
                final user = track['user'] as Map<String, dynamic>? ?? {};
                final artistName = user['username'] as String? ?? 'Desconocido';
                final artworkUrl = track['artwork_url'] as String?;
                final duration = track['duration'] as int?; // en milisegundos
                final isStreamable = track['streamable'] as bool? ?? false;
                
                // Construir URL de streaming usando los nuevos endpoints HLS (AAC)
                // SoundCloud ahora usa HLS en lugar de MP3 desde noviembre 2025
                String? fullStreamUrl;
                
                // Solo intentar obtener stream_url si el track es streamable
                if (isStreamable) {
                  // Primero intentar obtener el track completo para verificar disponibilidad
                  try {
                    final trackUrl = Uri.parse(
                      'https://api.soundcloud.com/tracks/$trackId?client_id=$clientId',
                    );
                    
                    final trackResponse = await http.get(
                      trackUrl,
                      headers: {
                        'Accept': 'application/json',
                        'User-Agent': 'KlinkApp/1.0',
                      },
                    ).timeout(const Duration(seconds: 5));
                    
                    if (trackResponse.statusCode == 200) {
                      final trackData = json.decode(trackResponse.body);
                      
                      // Intentar obtener URL HLS (nuevo formato desde nov 2025)
                      final hlsUrl = trackData['hls_aac_160_url'] as String? ?? 
                                     trackData['hls_aac_96_url'] as String?;
                      
                      if (hlsUrl != null && hlsUrl.isNotEmpty) {
                        // Agregar client_id a la URL HLS
                        final uri = Uri.parse(hlsUrl);
                        fullStreamUrl = uri.replace(queryParameters: {
                          ...uri.queryParameters,
                          'client_id': clientId,
                        }).toString();
                      } else {
                        // Fallback al endpoint de stream tradicional (puede no funcionar)
                        fullStreamUrl = 'https://api.soundcloud.com/tracks/$trackId/stream?client_id=$clientId';
                      }
                    }
                  } catch (e) {
                    debugPrint('⚠️ [MUSIC_API] Error obteniendo detalles del track: $e');
                    // Fallback al endpoint de stream tradicional
                    fullStreamUrl = 'https://api.soundcloud.com/tracks/$trackId/stream?client_id=$clientId';
                  }
                }
                
                debugPrint('🎵 [MUSIC_API] Track SoundCloud: $title - $artistName (ID: $trackId)');
                debugPrint('   Streamable: $isStreamable');
                if (fullStreamUrl != null) {
                  debugPrint('   ✅ Stream URL disponible (música completa): ${fullStreamUrl.substring(0, fullStreamUrl.length > 80 ? 80 : fullStreamUrl.length)}...');
                } else {
                  debugPrint('   ⚠️ Stream URL no disponible (track no streamable)');
                }
                
                // Solo agregar tracks que sean streamables y tengan URL
                if (fullStreamUrl != null && fullStreamUrl.isNotEmpty) {
                  results.add(MusicTrack(
                    id: trackId,
                    name: title,
                    artist: artistName,
                    album: '',
                    previewUrl: fullStreamUrl, // URL de música completa (HLS o stream)
                    thumbnailUrl: artworkUrl,
                    duration: duration,
                  ));
                }
              } catch (e) {
                debugPrint('❌ [MUSIC_API] Error procesando track de SoundCloud: $e');
                continue;
              }
            }

            debugPrint('✅ [MUSIC_API] Retornando ${results.length} tracks válidos de SoundCloud');
            return results; // Éxito, retornar resultados
          } else if (response.statusCode == 401) {
            debugPrint('⚠️ [MUSIC_API] Client ID inválido o expirado: $clientId');
            // Continuar con el siguiente client_id
            continue;
          } else if (response.statusCode == 429) {
            debugPrint('⚠️ [MUSIC_API] Rate limit alcanzado (15,000 requests/24h)');
            return []; // Rate limit, no intentar más
          } else {
            debugPrint('❌ [MUSIC_API] Error en respuesta SoundCloud: ${response.statusCode} - ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
            // Continuar con el siguiente client_id
            continue;
          }
        } catch (e) {
          debugPrint('❌ [MUSIC_API] Error con client_id $clientId: $e');
          // Continuar con el siguiente client_id
          continue;
        }
      }
      
      // Si llegamos aquí, todos los client_ids fallaron
      debugPrint('❌ [MUSIC_API] Todos los client_ids de SoundCloud fallaron');
      return [];
    } catch (e) {
      debugPrint('❌ [MUSIC_API] Error buscando música en SoundCloud: $e');
      return [];
    }
  }
  
  /// Buscar música en Audius (música completa, no solo previews)
  static Future<List<MusicTrack>> searchAudius(String query) async {
    try {
      debugPrint('🎵 [MUSIC_API] Buscando en Audius: $query');
      
      // Audius tiene múltiples hosts, intentar varios
      final hosts = [
        'https://discoveryprovider.audius.co',
        'https://discoveryprovider2.audius.co',
        'https://discoveryprovider3.audius.co',
      ];
      
      for (final host in hosts) {
        try {
          final encodedQuery = Uri.encodeComponent(query);
          final url = Uri.parse('$host/v1/tracks/search?query=$encodedQuery&limit=20');
          
          debugPrint('🔍 [MUSIC_API] URL de búsqueda Audius: $url');
          
          final response = await http.get(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
          );
          
          debugPrint('📡 [MUSIC_API] Respuesta Audius: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final tracks = data['data'] as List? ?? [];
            
            debugPrint('🎵 [MUSIC_API] Encontradas ${tracks.length} canciones en Audius');
            
            final results = tracks.map((track) {
              try {
                final trackId = track['id'] as String? ?? '';
                final title = track['title'] as String? ?? 'Sin título';
                final user = track['user'] as Map<String, dynamic>? ?? {};
                final artistName = user['name'] as String? ?? 'Desconocido';
                final artwork = track['artwork'] as Map<String, dynamic>?;
                final thumbnailUrl = artwork?['150x150'] as String? ?? 
                                   artwork?['480x480'] as String? ?? 
                                   artwork?['1000x1000'] as String;
                final duration = track['duration'] as int?; // en segundos
                
                // Audius requiere construir la URL de stream usando el endpoint específico
                // Formato: https://{host}/v1/tracks/{trackId}/stream
                final fullStreamUrl = '$host/v1/tracks/$trackId/stream';
                
                debugPrint('🎵 [MUSIC_API] Track Audius: $title - $artistName (ID: $trackId)');
                debugPrint('   ✅ Stream URL disponible: $fullStreamUrl');
                
                return MusicTrack(
                  id: trackId,
                  name: title,
                  artist: artistName,
                  album: '',
                  previewUrl: fullStreamUrl, // URL de música completa, no preview
                  thumbnailUrl: thumbnailUrl,
                  duration: duration != null ? duration * 1000 : null, // convertir a milisegundos
                );
              } catch (e) {
                debugPrint('❌ [MUSIC_API] Error procesando track de Audius: $e');
                return null;
              }
            }).whereType<MusicTrack>().toList();
            
            debugPrint('✅ [MUSIC_API] Retornando ${results.length} tracks válidos de Audius');
            return results;
          }
        } catch (e) {
          debugPrint('⚠️ [MUSIC_API] Error con host $host: $e, intentando siguiente...');
          continue;
        }
      }
      
      debugPrint('❌ [MUSIC_API] No se pudo conectar a ningún host de Audius');
      return [];
    } catch (e) {
      debugPrint('❌ [MUSIC_API] Error buscando música en Audius: $e');
      return [];
    }
  }
  
  /// Buscar música en Jamendo (música original gratuita)
  static Future<List<MusicTrack>> searchJamendo(String query) async {
    try {
      debugPrint('🎵 [MUSIC_API] Buscando en Jamendo: $query');
      
      final encodedQuery = Uri.encodeComponent(query);
      // Jamendo API v3.0 - búsqueda de tracks (puede funcionar sin client_id para búsquedas básicas)
      // Si necesitas más límites, regístrate en https://devportal.jamendo.com/ para obtener un client_id
      final url = Uri.parse(
        'https://api.jamendo.com/v3.0/tracks/?'
        'format=json&'
        'limit=20&'
        'search=$encodedQuery&'
        'order=popularity_total&'
        'streamable=1', // Solo tracks que se pueden reproducir
      );
      
      debugPrint('🔍 [MUSIC_API] URL de búsqueda Jamendo: $url');
      
      final response = await http.get(url);
      
      debugPrint('📡 [MUSIC_API] Respuesta Jamendo: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['results'] as List? ?? [];
        
        debugPrint('🎵 [MUSIC_API] Encontradas ${tracks.length} canciones en Jamendo');
        
        final results = tracks.map((track) {
          try {
            final trackId = track['id']?.toString() ?? '';
            final title = track['name'] as String? ?? 'Sin título';
            final artistName = track['artist_name'] as String? ?? 'Desconocido';
            final albumName = track['album_name'] as String? ?? '';
            final artworkUrl = track['image'] as String?;
            final duration = track['duration'] as int?; // en segundos
            final audioUrl = track['audio'] as String?; // URL de streaming directo
            
            debugPrint('🎵 [MUSIC_API] Track Jamendo: $title - $artistName (ID: $trackId)');
            if (audioUrl != null && audioUrl.isNotEmpty) {
              debugPrint('   ✅ Audio URL disponible: ${audioUrl.substring(0, audioUrl.length > 80 ? 80 : audioUrl.length)}...');
            } else {
              debugPrint('   ⚠️ Audio URL no disponible');
            }
            
            return MusicTrack(
              id: trackId,
              name: title,
              artist: artistName,
              album: albumName,
              previewUrl: audioUrl, // URL de música completa
              thumbnailUrl: artworkUrl,
              duration: duration != null ? duration * 1000 : null, // convertir a milisegundos
            );
          } catch (e) {
            debugPrint('❌ [MUSIC_API] Error procesando track de Jamendo: $e');
            return null;
          }
        }).whereType<MusicTrack>().where((t) => 
          t.previewUrl != null && t.previewUrl!.isNotEmpty
        ).toList();
        
        debugPrint('✅ [MUSIC_API] Retornando ${results.length} tracks válidos de Jamendo');
        return results;
      } else {
        debugPrint('❌ [MUSIC_API] Error en respuesta Jamendo: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ [MUSIC_API] Error buscando música en Jamendo: $e');
      return [];
    }
  }

  /// Buscar música en Internet Archive (música libre)
  static Future<List<MusicTrack>> searchInternetArchive(String query) async {
    try {
      debugPrint('🎵 [MUSIC_API] Buscando en Internet Archive: $query');
      
      final encodedQuery = Uri.encodeComponent(query);
      // Internet Archive API - búsqueda de audio
      final url = Uri.parse(
        'https://archive.org/advancedsearch.php?'
        'q=collection:opensource_audio+AND+title:($encodedQuery)&'
        'fl[]=identifier,title,creator,date,downloads,item_size&'
        'sort[]=downloads+desc&'
        'rows=20&'
        'page=1&'
        'output=json',
      );
      
      debugPrint('🔍 [MUSIC_API] URL de búsqueda Internet Archive: $url');
      
      final response = await http.get(url);
      
      debugPrint('📡 [MUSIC_API] Respuesta Internet Archive: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final docs = data['response']?['docs'] as List? ?? [];
        
        debugPrint('🎵 [MUSIC_API] Encontradas ${docs.length} canciones en Internet Archive');
        
        final results = <MusicTrack>[];
        
        for (final doc in docs) {
          try {
            final identifier = doc['identifier'] as String? ?? '';
            if (identifier.isEmpty) continue;
            
            final title = doc['title'] as String? ?? 'Sin título';
            final creator = doc['creator'] is List 
                ? (doc['creator'] as List).join(', ')
                : (doc['creator'] as String? ?? 'Desconocido');
            
            // Construir URL de streaming desde Internet Archive
            // Formato: https://archive.org/download/{identifier}/{identifier}.mp3
            // O usar el endpoint de streaming: https://archive.org/stream/{identifier}
            final streamUrl = 'https://archive.org/download/$identifier/$identifier.mp3';
            final thumbnailUrl = 'https://archive.org/services/img/$identifier';
            
            debugPrint('🎵 [MUSIC_API] Track Internet Archive: $title - $creator (ID: $identifier)');
            debugPrint('   ✅ Stream URL disponible: $streamUrl');
            
            results.add(MusicTrack(
              id: identifier,
              name: title,
              artist: creator,
              album: '',
              previewUrl: streamUrl,
              thumbnailUrl: thumbnailUrl,
              duration: null, // Internet Archive no siempre proporciona duración
            ));
          } catch (e) {
            debugPrint('❌ [MUSIC_API] Error procesando item de Internet Archive: $e');
            continue;
          }
        }
        
        debugPrint('✅ [MUSIC_API] Retornando ${results.length} tracks válidos de Internet Archive');
        return results;
      } else {
        debugPrint('❌ [MUSIC_API] Error en respuesta Internet Archive: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ [MUSIC_API] Error buscando música en Internet Archive: $e');
      return [];
    }
  }

  /// Buscar música en todas las plataformas (Audius, SoundCloud, Jamendo e Internet Archive)
  static Future<List<MusicTrack>> searchAll(String query) async {
    try {
      debugPrint('🎵 [MUSIC_API] Buscando en todas las plataformas: $query');
      
      final results = await Future.wait([
        searchAudius(query).catchError((e) {
          debugPrint('❌ [MUSIC_API] Error en Audius: $e');
          return <MusicTrack>[];
        }),
        searchSoundCloud(query).catchError((e) {
          debugPrint('❌ [MUSIC_API] Error en SoundCloud: $e');
          return <MusicTrack>[];
        }),
        searchJamendo(query).catchError((e) {
          debugPrint('❌ [MUSIC_API] Error en Jamendo: $e');
          return <MusicTrack>[];
        }),
        searchInternetArchive(query).catchError((e) {
          debugPrint('❌ [MUSIC_API] Error en Internet Archive: $e');
          return <MusicTrack>[];
        }),
      ]);
      
      // Combinar todos los resultados
      final combined = [
        ...results[0], // Audius (música completa)
        ...results[1], // SoundCloud (música completa)
        ...results[2], // Jamendo (música original gratuita)
        ...results[3], // Internet Archive (música libre)
      ];
      
      // Priorizar canciones con preview disponible
      combined.sort((a, b) {
        final aHasPreview = a.previewUrl != null && a.previewUrl!.isNotEmpty;
        final bHasPreview = b.previewUrl != null && b.previewUrl!.isNotEmpty;
        
        // Audius primero, luego Jamendo, luego Internet Archive, luego SoundCloud, luego sin preview
        final aIsAudius = a.previewUrl != null && (a.previewUrl!.contains('audius.co') || a.previewUrl!.contains('audius'));
        final bIsAudius = b.previewUrl != null && (b.previewUrl!.contains('audius.co') || b.previewUrl!.contains('audius'));
        final aIsJamendo = a.previewUrl != null && a.previewUrl!.contains('jamendo.com');
        final bIsJamendo = b.previewUrl != null && b.previewUrl!.contains('jamendo.com');
        final aIsArchive = a.previewUrl != null && a.previewUrl!.contains('archive.org');
        final bIsArchive = b.previewUrl != null && b.previewUrl!.contains('archive.org');
        final aIsSoundCloud = a.previewUrl != null && a.previewUrl!.contains('soundcloud.com');
        final bIsSoundCloud = b.previewUrl != null && b.previewUrl!.contains('soundcloud.com');
        
        if (aIsAudius && !bIsAudius) return -1;
        if (!aIsAudius && bIsAudius) return 1;
        if (aIsJamendo && !bIsJamendo && !bIsAudius) return -1;
        if (!aIsJamendo && bIsJamendo && !aIsAudius) return 1;
        if (aIsArchive && !bIsArchive && !bIsAudius && !bIsJamendo) return -1;
        if (!aIsArchive && bIsArchive && !aIsAudius && !aIsJamendo) return 1;
        if (aIsSoundCloud && !bIsSoundCloud && !bIsAudius && !bIsJamendo && !bIsArchive) return -1;
        if (!aIsSoundCloud && bIsSoundCloud && !aIsAudius && !aIsJamendo && !aIsArchive) return 1;
        if (aHasPreview && !bHasPreview) return -1;
        if (!aHasPreview && bHasPreview) return 1;
        return 0;
      });
      
      final audiusCount = results[0].length;
      final soundcloudCount = results[1].length;
      final jamendoCount = results[2].length;
      final archiveCount = results[3].length;
      final withPreview = combined.where((t) => 
        t.previewUrl != null && 
        t.previewUrl!.isNotEmpty
      ).length;
      
      debugPrint('✅ [MUSIC_API] Total de resultados: ${combined.length} (Audius: $audiusCount, SoundCloud: $soundcloudCount, Jamendo: $jamendoCount, Internet Archive: $archiveCount, con preview: $withPreview)');
      
      return combined;
    } catch (e) {
      debugPrint('❌ [MUSIC_API] Error en searchAll: $e');
      return [];
    }
  }
}

