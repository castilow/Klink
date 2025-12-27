import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_messenger/api/music_api.dart';
import 'package:chat_messenger/models/story/submodels/story_music.dart';
import 'package:just_audio/just_audio.dart';
import 'package:chat_messenger/tabs/stories/components/music_selection_screen.dart';

class MusicSearchScreen extends StatefulWidget {
  final Function(StoryMusic)? onMusicSelected;
  final bool allowCurrentlyPlaying;

  const MusicSearchScreen({
    super.key,
    this.onMusicSelected,
    this.allowCurrentlyPlaying = true,
  });

  @override
  State<MusicSearchScreen> createState() => _MusicSearchScreenState();
}

class _MusicSearchScreenState extends State<MusicSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxList<MusicTrack> _tracks = RxList();
  final RxBool _isLoading = false.obs;
  final RxString _searchQuery = ''.obs;
  Timer? _debounceTimer;
  
  // Audio player para preview
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Rxn<String> _currentlyPlayingId = Rxn<String>();
  final RxBool _isPlaying = false.obs;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchQuery.value = _searchController.text;
      if (_searchQuery.value.isNotEmpty) {
        _searchMusic(_searchQuery.value);
      } else {
        _tracks.clear();
      }
    });
  }

  Future<void> _searchMusic(String query) async {
    try {
      debugPrint('🔍 [MUSIC_SEARCH] Buscando música en Audius y SoundCloud: "$query"');
      _isLoading.value = true;
      
      // Buscar en Audius y SoundCloud (música completa, gratuita)
      final results = await MusicApi.searchAll(query);
      
      debugPrint('✅ [MUSIC_SEARCH] Encontradas ${results.length} canciones (Audius + SoundCloud)');
      _tracks.value = results;
    } catch (e) {
      debugPrint('❌ [MUSIC_SEARCH] Error buscando música: $e');
      Get.snackbar(
        'Error',
        'No se pudo buscar música: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  StoryMusic _convertToStoryMusic(MusicTrack track, {bool isCurrentlyPlaying = false}) {
    // Audius proporciona música completa, usar la duración real si está disponible
    double? duration = 30.0; // Por defecto 30 segundos para historias
    
    // Si es Audius y tiene duración, usar la duración real (pero limitar a 30s para historias)
    if (track.duration != null && track.duration! > 0) {
      // Convertir de milisegundos a segundos y limitar a 30s para historias
      duration = (track.duration! / 1000.0).clamp(0.0, 30.0);
    }
    
    return StoryMusic(
      trackId: track.id,
      trackName: track.name,
      artistName: track.artist,
      albumName: track.album,
      previewUrl: track.previewUrl ?? '',
      thumbnailUrl: track.thumbnailUrl,
      duration: duration, // Máximo 30 segundos para historias
      isCurrentlyPlaying: isCurrentlyPlaying,
      createdAt: DateTime.now(),
    );
  }

  void _selectMusic(MusicTrack track, {bool isCurrentlyPlaying = false}) async {
    debugPrint('✅ [MUSIC_SEARCH] Canción seleccionada: ${track.name} - ${track.artist}');
    debugPrint('🎵 [MUSIC_SEARCH] Preview URL: ${track.previewUrl ?? "No disponible"}');
    
    // Detener preview si está reproduciéndose
    if (_currentlyPlayingId.value == track.id) {
      _audioPlayer.stop();
      _isPlaying.value = false;
      _currentlyPlayingId.value = null;
    }
    
    // Abrir pantalla de selección de música y esperar el resultado
    final selectedMusic = await Get.to<StoryMusic>(
      () => MusicSelectionScreen(
        track: track,
        onMusicSelected: widget.onMusicSelected,
      ),
    );
    
    // Si se seleccionó música, retornar el resultado
    if (selectedMusic != null) {
      widget.onMusicSelected?.call(selectedMusic);
      Get.back(result: selectedMusic);
    }
  }

  Future<void> _playPreview(String trackId, String? previewUrl) async {
    try {
      debugPrint('🎵 [MUSIC_PREVIEW] Reproduciendo preview de: $trackId');
      
      // Si ya está reproduciendo esta canción, pausar
      if (_currentlyPlayingId.value == trackId && _isPlaying.value) {
        debugPrint('⏸️ [MUSIC_PREVIEW] Pausando preview actual');
        await _audioPlayer.pause();
        _isPlaying.value = false;
        _currentlyPlayingId.value = null;
        return;
      }
      
      // Si hay otra canción reproduciéndose, detenerla
      if (_currentlyPlayingId.value != null && _currentlyPlayingId.value != trackId) {
        debugPrint('⏹️ [MUSIC_PREVIEW] Deteniendo preview anterior');
        await _audioPlayer.stop();
      }
      
      // Solo reproducir si hay preview URL
      if (previewUrl == null || previewUrl.isEmpty) {
        debugPrint('⚠️ [MUSIC_PREVIEW] No hay preview disponible para esta canción');
        return;
      }
      
      // Audius proporciona música completa
      debugPrint('✅ [MUSIC_PREVIEW] URL de Audius detectada (música completa)');
      
      debugPrint('▶️ [MUSIC_PREVIEW] Cargando audio desde: $previewUrl');
      await _audioPlayer.setUrl(previewUrl);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();
      
      _currentlyPlayingId.value = trackId;
      _isPlaying.value = true;
      
      debugPrint('✅ [MUSIC_PREVIEW] Audio iniciado');
      
      // Escuchar cuando termine el audio
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying.value = false;
          _currentlyPlayingId.value = null;
          debugPrint('⏹️ [MUSIC_PREVIEW] Audio terminado');
        }
      });
    } catch (e) {
      debugPrint('❌ [MUSIC_PREVIEW] Error reproduciendo preview: $e');
      _isPlaying.value = false;
      _currentlyPlayingId.value = null;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme Constants
    const Color premiumBlack = Color(0xFF0F172A);
    const Color cyanColor = Color(0xFF00E5FF);
    
    return Scaffold(
      backgroundColor: premiumBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Buscar Música',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: premiumBlack.withOpacity(0.7),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              premiumBlack,
              Color(0xFF001518), // Deepest cyan/black
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 10),
            
            // Search Bar V3 (Darker, Sleeker)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: cyanColor,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B), // Explicitly force dark background
                      hintText: 'Buscar canciones...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.4)),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery.value = '';
                              _tracks.clear();
                            },
                          )
                        : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)), // Subtle border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: cyanColor.withOpacity(0.5), width: 1.5), // Valid cyan focus
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    autofocus: true,
                    onChanged: (val) {
                      setState(() {}); 
                    },
                  ),
                ),
            ),
            
            // Current Music Card V3
            if (widget.allowCurrentlyPlaying && _searchQuery.value.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                         final currentMusic = StoryMusic(
                          trackId: 'current_${DateTime.now().millisecondsSinceEpoch}',
                          trackName: 'Música actual',
                          artistName: 'Artista',
                          albumName: 'Álbum',
                          previewUrl: '',
                          isCurrentlyPlaying: true,
                          createdAt: DateTime.now(),
                        );
                        widget.onMusicSelected?.call(currentMusic);
                        Get.back();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF006064),
                              Color(0xFF0F172A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cyanColor.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: cyanColor.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildPulsingIcon(cyanColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Música que estoy escuchando',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Usar audio actual del dispositivo',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
            // Results List
             Expanded(
              child: Obx(() {
                if (_isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: cyanColor));
                }
                
                // TRENDING SECTION (Empty State) with Animations
                if (_searchQuery.value.isEmpty) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          'Tendencias',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8), // Reduced from 16
                        GridView.count(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero, // Explicitly remove padding
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.6,
                          children: [
                            _buildTrendCard('Pop Hits', Icons.star, [Colors.pinkAccent, Colors.purpleAccent], 0),
                            _buildTrendCard('Latino', Icons.music_note, [Colors.orangeAccent, Colors.deepOrange], 1),
                            _buildTrendCard('Electronic', Icons.flash_on, [Colors.purpleAccent, Colors.deepPurple], 2),
                            _buildTrendCard('Chill & Lo-Fi', Icons.nightlight_round, [Colors.indigoAccent, Colors.blueAccent], 3),
                            _buildTrendCard('Rock', Icons.graphic_eq, [Colors.redAccent, Colors.red], 4),
                             _buildTrendCard('Hip Hop', Icons.mic, [Colors.blueAccent, Colors.cyan], 5),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                
                if (_tracks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron canciones',
                          style: TextStyle(color: Colors.white.withOpacity(0.4)),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    final hasPreview = track.previewUrl != null && track.previewUrl!.isNotEmpty;
                    
                    return Obx(() {
                      final isCurrentlyPlaying = _currentlyPlayingId.value == track.id && _isPlaying.value;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (_currentlyPlayingId.value != null && _isPlaying.value) {
                                _audioPlayer.stop();
                                _isPlaying.value = false;
                                _currentlyPlayingId.value = null;
                              }
                              _selectMusic(track);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCurrentlyPlaying 
                                    ? cyanColor.withOpacity(0.15) 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: isCurrentlyPlaying 
                                  ? Border.all(color: cyanColor.withOpacity(0.5), width: 1)
                                  : Border.all(color: Colors.transparent),
                              ),
                              child: Row(
                                children: [
                                  // Album Art
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: track.thumbnailUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl: track.thumbnailUrl!,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(color: Colors.white.withOpacity(0.1)),
                                                errorWidget: (context, url, error) => Container(color: Colors.white.withOpacity(0.1)),
                                              )
                                            : Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.white.withOpacity(0.1),
                                                child: const Icon(Icons.music_note, color: Colors.white),
                                              ),
                                      ),
                                      if (isCurrentlyPlaying)
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.graphic_eq, color: cyanColor),
                                        ),
                                    ],
                                  ),
                                  
                                  const SizedBox(width: 16),
                                  
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          track.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isCurrentlyPlaying ? cyanColor : Colors.white.withOpacity(0.95),
                                            fontSize: 16,
                                            fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${track.artist}${track.album.isNotEmpty ? ' • ${track.album}' : ''}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.6),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Action
                                  if (hasPreview)
                                    IconButton(
                                      onPressed: () {
                                          if (isCurrentlyPlaying) {
                                            _audioPlayer.stop();
                                            _isPlaying.value = false;
                                            _currentlyPlayingId.value = null;
                                          } else {
                                            _playPreview(track.id, track.previewUrl);
                                          }
                                      },
                                      icon: Icon(
                                        isCurrentlyPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill,
                                        color: isCurrentlyPlaying ? cyanColor : Colors.white.withOpacity(0.3),
                                        size: 36,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para tarjeta de tendencia V3 con gradientes y animación
  Widget _buildTrendCard(String title, IconData icon, List<Color> gradientColors, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      // Staggered delay logic simulated with curve tweak or just simple delay if using Future, but TweenAnimationBuilder starts immediately. 
      // For simple staggered, we can't easily wait here without StatefulWidget wrapper. 
      // BUT we can use a FutureBuilder delay or just let them all animate in slightly.
      // Better approach for pure widget: simple entry animation.
      builder: (context, value, child) {
         // Apply a small delay based on index by clamping or modifying curve? 
         // Easiest is just to let them animate together or use a key.
         // Let's keep it simple: nice fade/slide up.
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _searchController.text = title;
          _searchMusic(title);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradientColors.first.withOpacity(0.2),
                gradientColors.last.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gradientColors.first.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
               Positioned(
                 bottom: -15,
                 right: -15,
                 child: Icon(
                   icon,
                   size: 80,
                   color: gradientColors.last.withOpacity(0.15),
                 ),
               ),
               Padding(
                 padding: const EdgeInsets.all(16),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         color: gradientColors.first.withOpacity(0.2),
                         shape: BoxShape.circle,
                       ),
                       child: Icon(icon, color: gradientColors.first, size: 20),
                     ),
                     Text(
                       title,
                       style: const TextStyle(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                         fontSize: 16,
                       ),
                     ),
                   ],
                 ),
               ),
            ],
          ),
        ),
      ),
    ),
    );
  }
  
  // Widget para icono pulsante simple
  Widget _buildPulsingIcon(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.1),
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10 * value,
                  spreadRadius: 2 * (value - 1.0),
                ),
              ],
            ),
            child: Icon(Icons.graphic_eq, color: color, size: 24),
          ),
        );
      },
      onEnd: () {}, // Loop se manejaría mejor con AnimationController en Stateful, pero para efecto sutil esto funciona una vez. 
      // Para loop infinito simple en build:
    );
  }
}

