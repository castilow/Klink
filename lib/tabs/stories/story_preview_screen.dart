import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/api/story_api.dart';
import 'package:chat_messenger/models/story/submodels/story_music.dart';
import 'package:chat_messenger/tabs/stories/components/music_search_screen.dart';
import 'package:chat_messenger/tabs/stories/components/story_settings_bottom_sheet.dart';
import 'package:chat_messenger/routes/app_routes.dart';

class StoryPreviewScreen extends StatefulWidget {
  final File file;
  final bool isVideo;

  const StoryPreviewScreen({
    super.key,
    required this.file,
    required this.isVideo,
  });

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  StoryMusic? selectedMusic;
  List<String> bestFriendsOnly = [];
  bool isVipOnly = false;
  bool isUploading = false;

  Future<void> _selectMusic() async {
    final music = await Get.to<StoryMusic>(
      () => const MusicSearchScreen(allowCurrentlyPlaying: true),
    );
    if (music != null) {
      setState(() {
        selectedMusic = music;
      });
    }
  }

  void _showAddMoreOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '✅ Estado publicado',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tu estado se ha publicado correctamente. ¿Quieres agregar más estados?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              // Cerrar todas las pantallas de creación de historias
              Get.back(); // Cerrar preview
              // Si venimos de la cámara, cerrar también la cámara
              if (Navigator.canPop(context)) {
                Get.back();
              }
            },
            child: const Text(
              'Finalizar',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              // Cerrar preview y volver a la pantalla de historias para agregar más
              Get.back(); // Cerrar preview
              // Si venimos de la cámara, cerrar también la cámara
              if (Navigator.canPop(context)) {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Agregar más',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadStory() async {
    setState(() {
      isUploading = true;
    });

    try {
      if (widget.isVideo) {
        await StoryApi.uploadVideoStory(
          widget.file,
          music: selectedMusic,
          bestFriendsOnly: bestFriendsOnly,
          isVipOnly: isVipOnly,
        );
      } else {
        await StoryApi.uploadImageStory(
          widget.file,
          music: selectedMusic,
          bestFriendsOnly: bestFriendsOnly,
          isVipOnly: isVipOnly,
        );
      }
      // NO cerrar automáticamente - permitir agregar más estados
      // Mostrar opción para agregar más o cerrar
      _showAddMoreOptions();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al subir la historia: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Vista Previa',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Music button
          IconButton(
            icon: Icon(
              selectedMusic != null ? Icons.music_note : Icons.music_off,
              color: selectedMusic != null ? Colors.blue : Colors.white,
            ),
            onPressed: _selectMusic,
            tooltip: 'Agregar música',
          ),
          // VIP button
          IconButton(
            icon: Icon(
              isVipOnly ? Icons.star : Icons.star_border,
              color: isVipOnly ? Colors.amber : Colors.white,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => StorySettingsBottomSheet(
                  onSave: (friends, vip) {
                    setState(() {
                      bestFriendsOnly = friends;
                      isVipOnly = vip;
                    });
                  },
                  initialBestFriends: bestFriendsOnly,
                  initialIsVipOnly: isVipOnly,
                ),
              );
            },
            tooltip: 'Configuración VIP',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Media preview
          Center(
            child: widget.isVideo
                ? const Icon(Icons.videocam, size: 100, color: Colors.white)
                : Image.file(
                    widget.file,
                    fit: BoxFit.contain,
                  ),
          ),
          
          // Music info overlay
          if (selectedMusic != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedMusic!.trackName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            selectedMusic!.artistName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          selectedMusic = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          
          // Upload button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: isUploading ? null : _uploadStory,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Subir Historia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}















