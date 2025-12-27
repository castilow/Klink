import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: _GlassControlButton(
            onTap: () => Get.back(),
            icon: IconlyLight.arrowLeft,
          ),
        ),
        actions: [
          // Music button
          _GlassControlButton(
            onTap: _selectMusic,
            icon: selectedMusic != null ? IconlyBold.volumeUp : IconlyLight.volumeUp,
            child: selectedMusic != null ? const Icon(Icons.music_note, color: Colors.blue) : null,
          ),
          const SizedBox(width: 12),
          // VIP button
          _GlassControlButton(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
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
            icon: isVipOnly ? IconlyBold.star : IconlyLight.star,
            child: isVipOnly ? const Icon(Icons.star, color: Colors.amber) : null,
          ),
          const SizedBox(width: 16),
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
              top: 120, // Moved to top like Instagram
              left: 0,
              right: 0,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.music_note, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${selectedMusic!.trackName} • ${selectedMusic!.artistName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMusic = null;
                              });
                            },
                            child: const Icon(Icons.close, color: Colors.white70, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Upload button area
          Positioned(
            bottom: 30,
            right: 20,
            child: GestureDetector(
              onTap: isUploading ? null : _uploadStory,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isUploading ? 'Subiendo...' : 'Tu historia',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                         if (!isUploading) ...[
                          const SizedBox(width: 8),
                          const Icon(IconlyBold.arrowRightCircle, color: Colors.black),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Save/Download button (Left side)
          Positioned(
            bottom: 30,
            left: 20,
            child: _GlassControlButton(
              onTap: () {
                Get.snackbar('Guardado', 'Imagen guardada en galería (simulado)',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.black.withOpacity(0.7),
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(20),
                );
              },
              icon: IconlyLight.download,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassControlButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? child;
  final double size;

  const _GlassControlButton({
    required this.onTap,
    this.icon,
    this.child,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: child ?? Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}















