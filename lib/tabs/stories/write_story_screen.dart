import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chat_messenger/api/story_api.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/tabs/stories/components/story_settings_bottom_sheet.dart';
import 'package:chat_messenger/tabs/stories/components/music_search_screen.dart';
import 'package:chat_messenger/models/story/submodels/story_music.dart';
import 'package:chat_messenger/media/helpers/media_helper.dart';
import 'package:chat_messenger/tabs/stories/story_preview_screen.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

class WriteStoryScreen extends StatefulWidget {
  const WriteStoryScreen({super.key});

  @override
  State<WriteStoryScreen> createState() => _WriteStoryScreenState();
}

class _WriteStoryScreenState extends State<WriteStoryScreen>
    with TickerProviderStateMixin {
  final FocusNode _keyboardFocus = FocusNode();
  final TextEditingController _textController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Color backgroundColor = const Color(0xFF673AB7); // Deep Purple default for premium text feeling
  bool showEmojiKeyboard = false;
  bool showColorPicker = false;
  bool isLoading = false;
  List<String> bestFriendsOnly = [];
  bool isVipOnly = false;
  StoryMusic? selectedMusic;

  // Premium Color Palette
  int currentFontIndex = 0;
  
  final List<TextStyle> fontStyles = [
    GoogleFonts.roboto(fontWeight: FontWeight.bold),
    GoogleFonts.lobster(fontWeight: FontWeight.normal),
    GoogleFonts.oswald(fontWeight: FontWeight.bold),
    GoogleFonts.dancingScript(fontWeight: FontWeight.bold),
    GoogleFonts.permanentMarker(fontWeight: FontWeight.normal),
    GoogleFonts.vt323(fontWeight: FontWeight.normal),
    GoogleFonts.pacifico(fontWeight: FontWeight.normal),
    GoogleFonts.bebasNeue(fontWeight: FontWeight.normal),
  ];

  final List<Color> colorPalette = [
    const Color(0xFF000000), // Black
    const Color(0xFF1A1A1A), // Dark Grey
    const Color(0xFFFFFFFF), // White
    const Color(0xFFF44336), // Red
    const Color(0xFFE91E63), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF2196F3), // Blue
    const Color(0xFF03A9F4), // Light Blue
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF009688), // Teal
    const Color(0xFF4CAF50), // Green
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFFCDDC39), // Lime
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFFFFC107), // Amber
    const Color(0xFFFF9800), // Orange
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF795548), // Brown
    const Color(0xFF607D8B), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _toggleEmojiKeyboard() {
    setState(() {
      showEmojiKeyboard = !showEmojiKeyboard;
      if (showEmojiKeyboard) {
        showColorPicker = false;
      }
    });
    if (showEmojiKeyboard) {
      _keyboardFocus.unfocus();
    } else {
      _keyboardFocus.requestFocus();
    }
  }

  void _toggleColorPicker() {
    setState(() {
      showColorPicker = !showColorPicker;
      if (showColorPicker) {
        showEmojiKeyboard = false;
        _keyboardFocus.unfocus();
      }
    });
  }

  void _selectColor(Color color) {
    setState(() {
      backgroundColor = color;
      // Keep color picker open for better UX
    });
  }

  void _toggleFont() {
    setState(() {
      currentFontIndex = (currentFontIndex + 1) % fontStyles.length;
    });
  }

  void _generateRandomColor() {
    final randomColor = colorPalette[Random().nextInt(colorPalette.length)];
    setState(() {
      backgroundColor = randomColor;
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() => isLoading = true);
      
      final permission = await Permission.photos.request();
      if (permission.isDenied) {
        setState(() => isLoading = false);
        DialogHelper.showSnackbarMessage(
          SnackMsgType.error,
          'Necesitas permisos para acceder a la galería',
        );
        return;
      }

      // Usar getAssets que es más confiable en iOS
      final List<File>? files = await MediaHelper.getAssets(
        maxAssets: 1,
        requestType: RequestType.image,
      );

      setState(() => isLoading = false);

      if (files != null && files.isNotEmpty) {
        final File imageFile = files.first;
        
        // Verificar que el archivo existe y es válido
        if (await imageFile.exists()) {
          // Navegar a la pantalla de preview para agregar música y configuraciones
          Get.to(
            () => StoryPreviewScreen(
              file: imageFile,
              isVideo: false,
            ),
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300),
          );
        } else {
          DialogHelper.showSnackbarMessage(
            SnackMsgType.error,
            'El archivo seleccionado no es válido',
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error al seleccionar imagen: $e');
      // Solo mostrar error si no es una cancelación del usuario
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('cancel') && 
          !errorStr.contains('cancelled') &&
          !errorStr.contains('cloudphotolibraryerrordomain') &&
          !errorStr.contains('invalid_image')) {
        DialogHelper.showSnackbarMessage(
          SnackMsgType.error,
          'Error al seleccionar la imagen. Intenta con otra foto.',
        );
      }
    }
  }

  Widget _buildEmojiPicker(double height, bool isTablet) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: showEmojiKeyboard ? 1.0 : 0.0,
      child: Container(
        height: height,
        color: const Color(0xFF121212),
        child: EmojiPicker(
          onEmojiSelected: ((category, emoji) {
            setState(() {
              _textController.text = _textController.text + emoji.emoji;
            });
          }),
          config: Config(
            height: height,
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              emojiSizeMax: isTablet ? 32 : 28,
              backgroundColor: const Color(0xFF121212),
              columns: 7,
            ),
            categoryViewConfig: const CategoryViewConfig(
              backgroundColor: Color(0xFF121212),
              indicatorColor: Colors.blue,
              iconColorSelected: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: showColorPicker ? 80 : 0,
      child: showColorPicker
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: colorPalette.length,
                itemBuilder: (context, index) {
                  final color = colorPalette[index];
                  final isSelected = backgroundColor == color;

                  return GestureDetector(
                    onTap: () => _selectColor(color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: isSelected ? 40 : 32,
                      height: isSelected ? 40 : 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: isSelected ? 3 : 1.5,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildTopBarIcon({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isActive = false,
    Color? activeColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive 
              ? (activeColor ?? Colors.white).withOpacity(0.2)
              : Colors.black.withOpacity(0.2),
          border: Border.all(
            color: isActive 
                ? (activeColor ?? Colors.white).withOpacity(0.5) 
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? (activeColor ?? Colors.white) : Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildTopToolbar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(IconlyLight.arrowLeft, color: Colors.white, size: 24),
              ),
              Row(
                children: [
                  _buildTopBarIcon(
                    icon: IconlyBold.image,
                    onPressed: _pickImageFromGallery,
                    tooltip: 'Gallery',
                    activeColor: Colors.greenAccent,
                  ),
                  _buildTopBarIcon(
                    icon: Icons.text_fields_rounded,
                    onPressed: _toggleFont,
                    tooltip: 'Change Font',
                  ),
                  _buildTopBarIcon(
                    icon: IconlyBold.swap,
                    onPressed: _generateRandomColor,
                    tooltip: 'Random Color',
                  ),
                  _buildTopBarIcon(
                    icon: Icons.palette_rounded,
                    onPressed: _toggleColorPicker, 
                    tooltip: 'Colors',
                    isActive: showColorPicker,
                  ),
                  _buildTopBarIcon(
                    icon: Icons.emoji_emotions_rounded, // Material rounded looks better than default
                    onPressed: _toggleEmojiKeyboard,
                    tooltip: 'Emojis',
                    isActive: showEmojiKeyboard,
                    activeColor: Colors.amber,
                  ),
                  _buildTopBarIcon(
                    icon: selectedMusic != null ? Icons.music_note_rounded : Icons.music_note_outlined,
                    onPressed: () async {
                      final music = await Get.to<StoryMusic>(
                        () => const MusicSearchScreen(allowCurrentlyPlaying: true),
                      );
                      if (music != null) {
                        setState(() {
                          selectedMusic = music;
                        });
                      }
                    },
                    tooltip: 'Music',
                    isActive: selectedMusic != null,
                    activeColor: Colors.blueAccent,
                  ),
                  _buildTopBarIcon(
                    icon: isVipOnly ? IconlyBold.star : IconlyLight.star,
                    onPressed: () {
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
                    tooltip: 'VIP',
                    isActive: isVipOnly,
                    activeColor: Colors.amber,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    // Responsive sizing
    final textFontSize = isLargeScreen ? 36.0 : (isTablet ? 32.0 : 28.0);
    final hintFontSize = isLargeScreen ? 32.0 : (isTablet ? 28.0 : 24.0);
    final emojiPickerHeight = isTablet ? 300.0 : 260.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  backgroundColor,
                  Color.lerp(backgroundColor, Colors.black, 0.4)!,
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // New Glassmorphism Toolbar
                _buildTopToolbar(context),

                // Main Text Area
                Expanded(
                  child: GestureDetector(
                    onTap: () => _keyboardFocus.requestFocus(),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: TextField(
                          controller: _textController,
                          focusNode: _keyboardFocus,
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center, // Center vertically
                          maxLines: null,
                          expands: true,
                          autofocus: true,
                          style: fontStyles[currentFontIndex].copyWith(
                            fontSize: textFontSize,
                            color: Colors.white,
                            height: 1.4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.8),
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type something...',
                            hintStyle: fontStyles[currentFontIndex].copyWith(
                              fontSize: hintFontSize,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.all(24),
                            filled: true,
                            fillColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              _scaleController.forward();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Color Picker (if active)
                _buildColorPicker(),

                // Emoji Picker (if active)
                if (showEmojiKeyboard)
                  SizedBox(
                    height: emojiPickerHeight,
                    child: _buildEmojiPicker(emojiPickerHeight, isTablet),
                  ),

                // Bottom send button
                if (!showEmojiKeyboard)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: SafeArea(
                      child: _buildSendButton(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: isLoading ? null : () async {
        if (_textController.text.trim().isEmpty) {
          DialogHelper.showSnackbarMessage(
            SnackMsgType.error,
            'Escribe algo para publicar',
            duration: 1,
          );
          return;
        }
        setState(() => isLoading = true);
        try {
          await StoryApi.uploadTextStory(
            text: _textController.text.trim(),
            bgColor: backgroundColor,
            music: selectedMusic,
            bestFriendsOnly: bestFriendsOnly,
            isVipOnly: isVipOnly,
          );
          setState(() {
            _textController.clear();
            selectedMusic = null;
            isLoading = false;
          });
        } catch (e) {
          setState(() => isLoading = false);
          DialogHelper.showSnackbarMessage(
            SnackMsgType.error,
            'Error al publicar: $e',
          );
        }
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Share',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    IconlyBold.send,
                    color: Colors.black,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }
}

