import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:chat_messenger/api/story_api.dart';
import 'package:chat_messenger/models/story/submodels/story_music.dart';
import 'package:chat_messenger/models/story/story_overlay.dart';
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
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  StoryMusic? selectedMusic;
  List<String> bestFriendsOnly = [];
  bool isVipOnly = false;
  bool isUploading = false;
  bool isEditingText = false; 
  bool isDraggingOverlay = false; // State for Drag-to-Delete
  bool isDeleteZoneActive = false; // State for collision detection 
  
  // Overlay State
  List<StoryOverlay> overlays = [];
  final Uuid _uuid = const Uuid();

  // Tools
  final ImagePicker _picker = ImagePicker();

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

  // --- Overlay Methods ---

  void _addTextOverlay({StoryOverlay? existingOverlay}) {
    setState(() => isEditingText = true); 

    String text = existingOverlay?.text ?? '';
    Color color = existingOverlay?.color ?? Colors.white;
    TextAlign textAlign = existingOverlay?.textAlign ?? TextAlign.center;
    bool showBackground = existingOverlay?.showBackground ?? false;
    double fontSize = existingOverlay?.fontSize ?? 28.0;

    // Enhanced fonts with Neon options
    List<TextStyle> fontStyles = [
      const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold), // Classic
      const TextStyle(fontFamily: 'Serif', fontStyle: FontStyle.italic, fontWeight: FontWeight.w900), // Elegant
      const TextStyle(fontFamily: 'Monospace', fontWeight: FontWeight.bold, letterSpacing: -1.0), // Modern
      const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, height: 1.1), // Strong
      TextStyle(
        fontFamily: 'Cursive', 
        fontWeight: FontWeight.bold,
        shadows: [
           Shadow(blurRadius: 15, color: color == Colors.black ? Colors.white.withOpacity(0.8) : color.withOpacity(0.8), offset: Offset.zero),
           Shadow(blurRadius: 30, color: color == Colors.black ? Colors.white.withOpacity(0.6) : color.withOpacity(0.6), offset: Offset.zero),
        ]
      ), // Neon
    ];
    List<String> fontNames = ['Clásica', 'Elegante', 'Moderna', 'Fuerte', 'Neón'];
    
    int selectedFontIndex = 0;
    
    if (existingOverlay?.textStyle != null) {
      for (int i = 0; i < fontStyles.length; i++) {
        if (existingOverlay!.textStyle!.fontFamily == fontStyles[i].fontFamily) {
          selectedFontIndex = i;
          break;
        }
      }
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            bool isNeon = selectedFontIndex == 4;
            
            TextStyle currentStyle = fontStyles[selectedFontIndex].copyWith(
               color: showBackground 
                  ? (color == Colors.white ? Colors.black : Colors.white) 
                  : (isNeon ? Colors.white : color),
               fontSize: fontSize,
               shadows: isNeon 
                 ? [
                     Shadow(blurRadius: 10, color: color, offset: Offset.zero),
                     Shadow(blurRadius: 20, color: color, offset: Offset.zero),
                   ] 
                 : (showBackground ? [] : [
                    Shadow(blurRadius: 10, color: Colors.black.withOpacity(0.5), offset: const Offset(0, 2))
                 ]),
                fontFamily: fontStyles[selectedFontIndex].fontFamily, 
             );

             InputDecoration inputDecoration = InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  hintText: '...',
                  hintStyle: fontStyles[selectedFontIndex].copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: fontSize,
                    shadows: [] 
                  ),
                  filled: showBackground,
                  fillColor: showBackground ? color : Colors.transparent, 
              );

            return Scaffold(
              backgroundColor: Colors.transparent, 
              resizeToAvoidBottomInset: true, // Allow layout to adjust for keyboard
              body: Stack(
                children: [
                   // Main Text Input Area
                   Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        autofocus: true,
                        controller: TextEditingController(text: text),
                        style: currentStyle,
                        textAlign: textAlign,
                        decoration: inputDecoration,
                        cursorColor: showBackground ? (color == Colors.white ? Colors.black : Colors.white) : color,
                        showCursor: true,
                        onChanged: (val) {
                          text = val;
                        },
                        maxLines: null,
                      ),
                    ),
                  ),

                  // --- FONT SIZE SLIDER (LEFT) ---
                  Positioned(
                    left: 10,
                    top: 150,
                    bottom: 250, 
                    child: Center(
                       child: SizedBox(
                         height: 250, 
                         width: 40,
                         child: RotatedBox(
                           quarterTurns: 3, 
                           child: SliderTheme(
                             data: SliderTheme.of(context).copyWith(
                               trackHeight: 4, 
                               thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 5),
                               overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                               activeTrackColor: Colors.white,
                               inactiveTrackColor: Colors.white.withOpacity(0.3),
                               thumbColor: Colors.white,
                               overlayColor: Colors.white.withOpacity(0.1),
                               valueIndicatorColor: Colors.white,
                             ),
                             child: Slider(
                               value: fontSize,
                               min: 14.0,
                               max: 80.0,
                               onChanged: (val) {
                                 setStateDialog(() => fontSize = val);
                               },
                             ),
                           ),
                         ),
                       ),
                    ),
                  ),
                  
                  // Gesture Detector for Pinch to Resize (Invisible layer)
                  Positioned.fill(
                    child: GestureDetector(
                      onScaleUpdate: (details) {
                        if (details.scale != 1.0) {
                          // Simple scaling logic: adjust font size by the scale factor
                          // We use a sensitivity factor to make it feel natural
                          double newSize = fontSize * details.scale;
                          if (newSize < 14.0) newSize = 14.0;
                          if (newSize > 120.0) newSize = 120.0; // Increased max size
                          setStateDialog(() => fontSize = newSize);
                        }
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Container(),
                    ),
                  ),
                  
                  // --- TOP RIGHT: "LISTO" ---
                  Positioned(
                    top: 50,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Listo', 
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))
                          ]
                        )
                      ),
                    ),
                  ),

                  // -- BOTTOM CONTROLS STACK (Anchored to keyboard) --
                  Positioned(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                          stops: [0.0, 1.0],
                        )
                      ),
                      padding: const EdgeInsets.only(bottom: 12, top: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          
                          // 1. Font Selector Pills (Instagram Style)
                          SizedBox(
                            height: 36,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: fontStyles.length,
                              itemBuilder: (context, index) {
                                bool isSelected = selectedFontIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setStateDialog(() => selectedFontIndex = index);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      fontNames[index].toUpperCase(),
                                      style: fontStyles[index].copyWith( // Render label in its own font
                                        fontSize: 12,
                                        color: isSelected ? Colors.black : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        shadows: [], 
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 16),

                          // 2. Bottom Toolbar: Align/Bg | Colors
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                // Left Group: Tools
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                       _MinimalToolbarIcon(
                                         icon: _getAlignIcon(textAlign),
                                         onTap: () {
                                            setStateDialog(() {
                                              if (textAlign == TextAlign.center) textAlign = TextAlign.left;
                                              else if (textAlign == TextAlign.left) textAlign = TextAlign.right;
                                              else textAlign = TextAlign.center;
                                            });
                                         }
                                       ),
                                       const SizedBox(width: 8),
                                       _MinimalToolbarIcon(
                                         icon: showBackground ? IconlyBold.star : IconlyLight.star,
                                         isActive: showBackground,
                                         onTap: () {
                                            setStateDialog(() {
                                              showBackground = !showBackground;
                                            });
                                         }
                                       ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Right Group: Color Palette
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        Colors.white, 
                                        Colors.black,
                                        const Color(0xFFFF5252), 
                                        const Color(0xFFFFAB40), 
                                        const Color(0xFFFFEA00), 
                                        const Color(0xFF69F0AE), 
                                        const Color(0xFF448AFF), 
                                        const Color(0xFFE040FB), 
                                        const Color(0xFFFF4081), 
                                      ].map((c) {
                                        final isSelected = c.value == color.value;
                                        return GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setStateDialog(() => color = c);
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            margin: const EdgeInsets.only(right: 12),
                                            width: isSelected ? 30 : 22,
                                            height: isSelected ? 30 : 22,
                                            decoration: BoxDecoration(
                                              color: c,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                              boxShadow: isSelected ? [
                                                BoxShadow(color: c.withOpacity(0.6), blurRadius: 8)
                                              ] : [],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() => isEditingText = false); 
      
      if (text.isNotEmpty) {
        setState(() {
           final baseScale = 1.0; 
           
          if (existingOverlay != null) {
            existingOverlay.text = text;
            existingOverlay.color = color;
            existingOverlay.textStyle = fontStyles[selectedFontIndex];
            existingOverlay.textAlign = textAlign;
            existingOverlay.showBackground = showBackground;
            existingOverlay.fontSize = fontSize;
          } else {
            overlays.add(StoryOverlay(
              id: _uuid.v4(),
              type: OverlayType.text,
              text: text,
              color: color,
              textStyle: fontStyles[selectedFontIndex],
              textAlign: textAlign,
              showBackground: showBackground,
              fontSize: fontSize,
              position: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
              scale: baseScale,
            ));
          }
        });
      }
    });
  }

  IconData _getAlignIcon(TextAlign align) {
    switch (align) {
      case TextAlign.left: return Icons.format_align_left;
      case TextAlign.right: return Icons.format_align_right;
      default: return Icons.format_align_center;
    }
  }

  Future<void> _addImageOverlay() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        overlays.add(StoryOverlay(
          id: _uuid.v4(),
          type: OverlayType.image,
          imageFile: File(image.path),
          position: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
          scale: 0.5,
        ));
      });
    }
  }

  void _removeOverlay(String id) {
    setState(() {
      overlays.removeWhere((element) => element.id == id);
    });
    HapticFeedback.mediumImpact();
  }

  // --- Capture & Upload ---

  Future<File?> _captureResult() async {
    try {
      if (overlays.isEmpty) return widget.file; 

      if (widget.isVideo) {
        Get.snackbar('Nota', 'Los stickers en video no se guardan en el archivo final en esta versión.', snackPosition: SnackPosition.BOTTOM);
        return widget.file; 
      }

      RenderRepaintBoundary? boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Capture high-res image
      double pixelRatio = 3.0; 
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/edited_story_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      debugPrint('Error capturing story: $e');
      return null;
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
              Get.back(); // Cerrar preview
              if (Navigator.canPop(context)) {
                Get.back(); // Cerrar cámara si existe
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
              Get.back(); // Cerrar preview to take another
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
      final File? fileToUpload = await _captureResult();
      if (fileToUpload == null) throw Exception("Failed to process image");

      if (widget.isVideo) {
        await StoryApi.uploadVideoStory(
          fileToUpload,
          music: selectedMusic,
          bestFriendsOnly: bestFriendsOnly,
          isVipOnly: isVipOnly,
        );
      } else {
        await StoryApi.uploadImageStory(
          fileToUpload,
          music: selectedMusic,
          bestFriendsOnly: bestFriendsOnly,
          isVipOnly: isVipOnly,
        );
      }
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
      body: Stack(
        children: [
          // Canvas (Image + Overlays)
          Positioned.fill(
            child: RepaintBoundary(
              key: _repaintBoundaryKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base Media
                  Center(
                    child: widget.isVideo
                        ? const Icon(Icons.videocam, size: 100, color: Colors.white)
                        : Image.file(
                            widget.file,
                            fit: BoxFit.contain,
                          ),
                  ),
                  
                  // Overlays
                  ...overlays.map((overlay) {
                    return _OverlayWidget(
                     key: ValueKey(overlay.id),
                     overlay: overlay,
                     onUpdate: () => setState(() {}),
                     onEdit: () {
                       if (!isEditingText && overlay.type == OverlayType.text) {
                         _addTextOverlay(existingOverlay: overlay);
                       }
                     },
                     onRemove: () => _removeOverlay(overlay.id),
                     onDragStart: () => setState(() => isDraggingOverlay = true),
                     onDragUpdate: (globalPos) {
                        // Check collision with Trash Can (approx bottom center)
                        final screenHeight = MediaQuery.of(context).size.height;
                        final screenWidth = MediaQuery.of(context).size.width;
                        final trashZoneTop = screenHeight - 100;
                        final trashZoneLeft = (screenWidth / 2) - 40;
                        final trashZoneRight = (screenWidth / 2) + 40;
                        
                        bool inZone = globalPos.dy > trashZoneTop && 
                                      globalPos.dx > trashZoneLeft && 
                                      globalPos.dx < trashZoneRight;
                                      
                        if (isDeleteZoneActive != inZone) {
                           setState(() => isDeleteZoneActive = inZone);
                           if (inZone) HapticFeedback.mediumImpact();
                        }
                     },
                     onDragEnd: (globalPos) {
                        setState(() => isDraggingOverlay = false);
                        if (isDeleteZoneActive) {
                          _removeOverlay(overlay.id);
                          setState(() => isDeleteZoneActive = false);
                           HapticFeedback.heavyImpact();
                        }
                     },
                    );
                  }).toList(),
                  
                   // TRASH CAN ZONE (Visible when dragging)
                  if (isDraggingOverlay)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isDeleteZoneActive ? 1.5 : 1.0,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isDeleteZoneActive ? Colors.red.withOpacity(0.8) : Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle, 
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(IconlyBold.delete, color: Colors.white, size: 30),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Top Controls (AppBar) - Hidden when editing Text
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isEditingText ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: isEditingText,
              child: Stack(
                children: [
                   // Top Bar
                   Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            _GlassControlButton(
                              onTap: () => Get.back(),
                              icon: IconlyLight.arrowLeft,
                            ),
                            const Spacer(),
                            
                            // Add Text Button
                            _GlassControlButton(
                              onTap: () => _addTextOverlay(),
                              child: const Text('Aa', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'serif')),
                            ),
                            const SizedBox(width: 12),
                            
                            // Add Sticker/Image Button
                            _GlassControlButton(
                              onTap: _addImageOverlay,
                              icon: IconlyLight.image, 
                            ),
                            const SizedBox(width: 12),

                            // Music button
                            _GlassControlButton(
                              onTap: _selectMusic,
                              icon: selectedMusic != null ? Icons.music_note_rounded : Icons.music_note_outlined,
                              child: selectedMusic != null ? const Icon(Icons.music_note_rounded, color: Colors.blue) : null,
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
                          ],
                        ),
                      ),
                    ),
                  ),

                   // Upload Button
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isDraggingOverlay ? 0.0 : 1.0,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 30, right: 20),
                        child: GestureDetector(
                          onTap: (isUploading || isDraggingOverlay) ? null : _uploadStory,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                    ),
                  ),

                  // Download Button
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isDraggingOverlay ? 0.0 : 1.0,
                    child: Align(
                       alignment: Alignment.bottomLeft,
                       child: Padding(
                         padding: const EdgeInsets.only(bottom: 30, left: 20),
                         child: _GlassControlButton(
                          onTap: isDraggingOverlay ? () {} : () async {
                            final file = await _captureResult();
                            if (file != null) {
                              Get.snackbar('Guardado', 'Imagen guardada',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.black.withOpacity(0.7),
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(20),
                              );
                            }
                          },
                          icon: IconlyLight.download,
                        ),
                       ),
                    ),
                  ),

                  // Music Info
                  if (selectedMusic != null)
                    Positioned(
                      top: 130, 
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Icon-only button for the bottom toolbar (Alignment etc)
class _MinimalToolbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _MinimalToolbarIcon({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white70, 
          size: 20, 
        ),
      ),
    );
  }
}

class _OverlayWidget extends StatefulWidget {
  final StoryOverlay overlay;
  final VoidCallback onUpdate;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  // Drag Callbacks
  final VoidCallback? onDragStart;
  final Function(Offset)? onDragUpdate;
  final Function(Offset)? onDragEnd;

  const _OverlayWidget({
    Key? key, 
    required this.overlay, 
    required this.onUpdate,
    required this.onEdit,
    required this.onRemove,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  }) : super(key: key);

  @override
  State<_OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<_OverlayWidget> {
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.overlay.position.dx - 100,
      top: widget.overlay.position.dy - 100,
      child: GestureDetector(
        onTap: widget.onEdit,
        onLongPress: widget.onRemove,
        onScaleStart: (details) {
          _baseScale = widget.overlay.scale;
          _baseRotation = widget.overlay.rotation;
          widget.onDragStart?.call();
        },
        onScaleUpdate: (details) {
          setState(() {
            widget.overlay.position += details.focalPointDelta;
            if (details.scale != 1.0) {
              widget.overlay.scale = _baseScale * details.scale;
              widget.overlay.rotation = _baseRotation + details.rotation;
            }
          });
          widget.onUpdate();
          widget.onDragUpdate?.call(details.focalPoint); // Pass global position
        },
        onScaleEnd: (details) {
           widget.onDragEnd?.call(widget.overlay.position); // Logic handled in parent using global tracking if needed, but here we passed updates. 
           // Better to check last known focal point? 
           // Actually onScaleEnd doesn't give position. 
           // We rely on the parent tracking the 'active' state from the last update.
           // Let's pass a dummy offset or handle it differently?
           // The parent `onDragEnd` in the previous edit doesn't rely on the argument for deleting, it relies on `isDeleteZoneActive` state.
           widget.onDragEnd?.call(Offset.zero);
        },
        child: Transform(
          transform: Matrix4.identity()
            ..rotateZ(widget.overlay.rotation)
            ..scale(widget.overlay.scale),
          alignment: Alignment.center,
          child: Container(
             constraints: BoxConstraints(
               maxWidth: MediaQuery.of(context).size.width - 32, // Allow full width minus padding
               minWidth: 50,
               minHeight: 50,
             ),
             child: widget.overlay.type == OverlayType.text
                 ? _buildTextOverlay()
                 : widget.overlay.imageFile != null
                     ? Image.file(
                         widget.overlay.imageFile!,
                         fit: BoxFit.contain,
                       )
                     : const SizedBox(),
          ),
        ),
      ),
    );
  }

  Widget _buildTextOverlay() {
    final bool showBackground = widget.overlay.showBackground;
    final Color color = widget.overlay.color ?? Colors.white;
    final double fontSize = widget.overlay.fontSize;
    final TextStyle? style = widget.overlay.textStyle;
    
    // Check if style has Neon shadows
    bool isNeon = style?.fontFamily == 'Cursive' && (style?.shadows?.isNotEmpty ?? false);
    
    // If not neon, we might add drop shadow for readability if no background
    List<Shadow> shadows = [];
    if (!showBackground && !isNeon) {
      shadows = [
        const Shadow(
          offset: Offset(1.0, 1.0),
          blurRadius: 3.0,
          color: Colors.black45,
        ),
      ];
    }
    
    TextStyle? finalStyle = widget.overlay.textStyle?.copyWith(
      color: showBackground ? (color == Colors.white ? Colors.black : Colors.white) : (isNeon ? Colors.white : color),
      fontSize: fontSize,
      shadows: showBackground ? [] : (isNeon ? widget.overlay.textStyle?.shadows : shadows),
    );

    return Container(
      decoration: showBackground ? BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ) : null,
      padding: showBackground ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4) : EdgeInsets.zero,
      child: Text(
        widget.overlay.text ?? '',
        style: finalStyle,
        textAlign: widget.overlay.textAlign,
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
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
