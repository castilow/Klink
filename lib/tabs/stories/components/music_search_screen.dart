import 'dart:async';
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
  final RxString _selectedSource = 'all'.obs; // 'all', 'spotify', 'youtube'
  Timer? _debounceTimer;
  
  // Audio player para preview
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;
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
      debugPrint('🔍 [MUSIC_SEARCH] Buscando música: "$query" en fuente: ${_selectedSource.value}');
      _isLoading.value = true;
      List<MusicTrack> results = [];
      
      if (_selectedSource.value == 'all') {
        results = await MusicApi.searchAll(query);
      } else if (_selectedSource.value == 'spotify') {
        results = await MusicApi.searchSpotify(query);
      } else if (_selectedSource.value == 'youtube') {
        results = await MusicApi.searchYouTube(query);
      }
      
      debugPrint('✅ [MUSIC_SEARCH] Encontradas ${results.length} canciones');
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
    // Limitar duración a 30 segundos máximo
    double? duration = 30.0; // Por defecto 30 segundos
    
    // Si es Spotify y tiene preview, usar 30 segundos (preview de Spotify es 30s)
    if (track.previewUrl != null && track.previewUrl!.isNotEmpty) {
      duration = 30.0;
    }
    
    return StoryMusic(
      trackId: track.id,
      trackName: track.name,
      artistName: track.artist,
      albumName: track.album,
      previewUrl: track.previewUrl ?? '',
      thumbnailUrl: track.thumbnailUrl,
      duration: duration, // Limitar a 30 segundos
      isCurrentlyPlaying: isCurrentlyPlaying,
      createdAt: DateTime.now(),
    );
  }

  void _selectMusic(MusicTrack track, {bool isCurrentlyPlaying = false}) async {
    debugPrint('✅ [MUSIC_SEARCH] Canción seleccionada: ${track.name} - ${track.artist}');
    debugPrint('🎵 [MUSIC_SEARCH] Preview URL: ${track.previewUrl ?? "No disponible"}');
    
    // Detener preview si está reproduciéndose
    if (_currentlyPlayingId == track.id) {
      _audioPlayer.stop();
      _isPlaying.value = false;
      _currentlyPlayingId = null;
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

  Widget _buildSourceChip(String source, String label, IconData icon) {
    final isSelected = _selectedSource.value == source;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _selectedSource.value = source;
          if (_searchQuery.value.isNotEmpty) {
            _searchMusic(_searchQuery.value);
          }
        }
      },
    );
  }

  Future<void> _playPreview(String trackId, String? previewUrl) async {
    try {
      debugPrint('🎵 [MUSIC_PREVIEW] Reproduciendo preview de: $trackId');
      
      // Si ya está reproduciendo esta canción, pausar
      if (_currentlyPlayingId == trackId && _isPlaying.value) {
        debugPrint('⏸️ [MUSIC_PREVIEW] Pausando preview actual');
        await _audioPlayer.pause();
        _isPlaying.value = false;
        _currentlyPlayingId = null;
        return;
      }
      
      // Si hay otra canción reproduciéndose, detenerla
      if (_currentlyPlayingId != null && _currentlyPlayingId != trackId) {
        debugPrint('⏹️ [MUSIC_PREVIEW] Deteniendo preview anterior');
        await _audioPlayer.stop();
      }
      
      // Solo reproducir si hay preview URL (Spotify tiene preview de 30s)
      if (previewUrl == null || previewUrl.isEmpty) {
        debugPrint('⚠️ [MUSIC_PREVIEW] No hay preview disponible para esta canción');
        Get.snackbar(
          'Sin preview',
          'Esta canción no tiene preview disponible',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return;
      }
      
      // Verificar si es URL de YouTube (no tiene preview directo)
      if (previewUrl.contains('youtube.com') || previewUrl.contains('youtu.be')) {
        debugPrint('⚠️ [MUSIC_PREVIEW] YouTube no proporciona preview directo');
        Get.snackbar(
          'YouTube',
          'Las canciones de YouTube no tienen preview. Selecciona la canción para agregarla.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return;
      }
      
      debugPrint('▶️ [MUSIC_PREVIEW] Cargando preview desde: $previewUrl');
      await _audioPlayer.setUrl(previewUrl);
      await _audioPlayer.play();
      
      _currentlyPlayingId = trackId;
      _isPlaying.value = true;
      
      debugPrint('✅ [MUSIC_PREVIEW] Preview iniciado');
      
      // Escuchar cuando termine el preview
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying.value = false;
          _currentlyPlayingId = null;
          debugPrint('⏹️ [MUSIC_PREVIEW] Preview terminado');
        }
      });
    } catch (e) {
      debugPrint('❌ [MUSIC_PREVIEW] Error reproduciendo preview: $e');
      Get.snackbar(
        'Error',
        'No se pudo reproducir el preview: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Música'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar canciones...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                // Selector de fuente
                Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSourceChip('all', 'Todas', Icons.music_note),
                    _buildSourceChip('spotify', 'Spotify', Icons.library_music),
                    _buildSourceChip('youtube', 'YouTube', Icons.play_circle),
                  ],
                )),
              ],
            ),
          ),
          
          // Opción de música actual (si está permitida)
          if (widget.allowCurrentlyPlaying)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListTile(
                leading: const Icon(Icons.music_note, size: 40),
                title: const Text('Música que estoy escuchando'),
                subtitle: const Text('Agregar música actual'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Por ahora, creamos una música placeholder
                  // En el futuro se puede integrar con Spotify SDK para obtener la canción actual
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
              ),
            ),
          
          const Divider(),
          
          // Lista de resultados
          Expanded(
            child: Obx(() {
              if (_isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (_searchQuery.value.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Busca una canción',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              
              if (_tracks.isEmpty) {
                return Center(
                  child: Text(
                    'No se encontraron resultados',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: _tracks.length,
                itemBuilder: (context, index) {
                  final track = _tracks[index];
                  return ListTile(
                    leading: track.thumbnailUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: track.thumbnailUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.music_note),
                              ),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.music_note),
                          ),
                    title: Text(
                      track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${track.artist} • ${track.album}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Indicador de duración (30 segundos)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '30s',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _selectMusic(track),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

