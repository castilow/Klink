import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_messenger/api/music_api.dart';
import 'package:chat_messenger/config/theme_config.dart';
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
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _selectMusic(MusicTrack track, {bool isCurrentlyPlaying = false}) async {
    debugPrint('✅ [MUSIC_SEARCH] Canción seleccionada: ${track.name} - ${track.artist}');
    
    // Detener preview si está reproduciéndose
    if (_currentlyPlayingId == track.id) {
      _audioPlayer.stop();
      _isPlaying.value = false;
      _currentlyPlayingId = null;
    }
    
    final selectedMusic = await Get.to<StoryMusic>(
      () => MusicSelectionScreen(
        track: track,
        onMusicSelected: widget.onMusicSelected,
      ),
    );
    
    if (selectedMusic != null) {
      widget.onMusicSelected?.call(selectedMusic);
      Get.back(result: selectedMusic);
    }
  }

  Widget _buildSourceChip(String source, String label, IconData icon) {
    return Obx(() {
      final isSelected = _selectedSource.value == source;
      return GestureDetector(
        onTap: () {
          _selectedSource.value = source;
          if (_searchQuery.value.isNotEmpty) {
            _searchMusic(_searchQuery.value);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? primaryGradient : null,
            color: isSelected ? null : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _playPreview(String trackId, String? previewUrl) async {
    try {
      if (_currentlyPlayingId == trackId && _isPlaying.value) {
        await _audioPlayer.pause();
        _isPlaying.value = false;
        _currentlyPlayingId = null;
        return;
      }
      
      if (_currentlyPlayingId != null && _currentlyPlayingId != trackId) {
        await _audioPlayer.stop();
      }
      
      if (previewUrl == null || previewUrl.isEmpty) {
        return;
      }
      
      await _audioPlayer.setUrl(previewUrl);
      await _audioPlayer.play();
      
      _currentlyPlayingId = trackId;
      _isPlaying.value = true;
      
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying.value = false;
          _currentlyPlayingId = null;
        }
      });
    } catch (e) {
      debugPrint('❌ [MUSIC_PREVIEW] Error reproduciendo preview: $e');
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black, // Fallback
      appBar: AppBar(
        title: const Text(
          'Buscar Música',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
          onPressed: () => Get.back(),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A), // Dark Slate
              Color(0xFF000000), // Black
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Barra de búsqueda y filtros
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar canciones...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search, color: primaryColor),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: primaryColor, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSourceChip('all', 'Todas', Icons.music_note),
                        _buildSourceChip('spotify', 'Spotify', Icons.library_music),
                        _buildSourceChip('youtube', 'YouTube', Icons.play_circle),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Opción de música actual
              if (widget.allowCurrentlyPlaying)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
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
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.graphic_eq,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Música que estoy escuchando',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Agregar música actual',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Lista de resultados
              Expanded(
                child: Obx(() {
                  if (_isLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    );
                  }
                  
                  if (_searchQuery.value.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            size: 80,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Busca una canción',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (_tracks.isEmpty) {
                    return Center(
                      child: Text(
                        'No se encontraron resultados',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    );
                  }
                  
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _tracks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final track = _tracks[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _selectMusic(track),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // Thumbnail con botón de play
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Hero(
                                        tag: 'music_${track.id}',
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: track.thumbnailUrl != null
                                              ? CachedNetworkImage(
                                                  imageUrl: track.thumbnailUrl!,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    color: Colors.white.withOpacity(0.1),
                                                  ),
                                                )
                                              : Container(
                                                  width: 56,
                                                  height: 56,
                                                  color: Colors.white.withOpacity(0.1),
                                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                                ),
                                        ),
                                      ),
                                      // Botón de Preview
                                      if (track.previewUrl != null && track.previewUrl!.isNotEmpty && !track.previewUrl!.contains('youtube'))
                                        GestureDetector(
                                          onTap: () => _playPreview(track.id, track.previewUrl),
                                          child: Obx(() {
                                            // Ensure _isPlaying.value is accessed first to register dependency
                                            final isPlaying = _isPlaying.value && _currentlyPlayingId == track.id;
                                            return Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                                              ),
                                              child: Icon(
                                                isPlaying ? Icons.pause : Icons.play_arrow,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            );
                                          }),
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${track.artist} • ${track.album}',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Duración y flecha
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          '30s',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

