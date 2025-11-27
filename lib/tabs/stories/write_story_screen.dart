import 'dart:math';
import 'dart:ui';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/api/story_api.dart';
import 'package:chat_messenger/components/floating_button.dart';
import 'package:chat_messenger/components/loading_indicator.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/tabs/stories/components/story_settings_bottom_sheet.dart';
import 'package:chat_messenger/tabs/stories/components/music_search_screen.dart';
import 'package:chat_messenger/models/story/submodels/story_music.dart';
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

  Color backgroundColor = const Color(0xFF000000);
  bool showEmojiKeyboard = false;
  bool showColorPicker = false;
  bool isLoading = false;
  List<String> bestFriendsOnly = [];
  bool isVipOnly = false;
  StoryMusic? selectedMusic;

  // Premium Color Palette
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

  void _generateRandomColor() {
    final randomColor = colorPalette[Random().nextInt(colorPalette.length)];
    setState(() {
      backgroundColor = randomColor;
    });
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
        margin: const EdgeInsets.only(left: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive 
              ? (activeColor ?? Colors.white).withOpacity(0.2) 
              : Colors.black.withOpacity(0.3),
          border: Border.all(
            color: isActive 
                ? (activeColor ?? Colors.white).withOpacity(0.5) 
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? (activeColor ?? Colors.white) : Colors.white,
          size: 24,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
            ),
          ],
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
      body: Stack(
        children: [
          // Background
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
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Get.back(),
                      ),
                      const Spacer(),
                      
                      // Tools
                      _buildTopBarIcon(
                        icon: Icons.shuffle,
                        onPressed: _generateRandomColor,
                        tooltip: 'Random Color',
                      ),
                      _buildTopBarIcon(
                        icon: Icons.palette_outlined,
                        onPressed: _toggleColorPicker,
                        tooltip: 'Colors',
                        isActive: showColorPicker,
                      ),
                      _buildTopBarIcon(
                        icon: Icons.emoji_emotions_outlined,
                        onPressed: _toggleEmojiKeyboard,
                        tooltip: 'Emojis',
                        isActive: showEmojiKeyboard,
                      ),
                      _buildTopBarIcon(
                        icon: selectedMusic != null ? Icons.music_note : Icons.music_off_outlined,
                        onPressed: () async {
                          // Navegar a búsqueda de música, que a su vez navegará a selección de segmento
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
                        icon: isVipOnly ? Icons.star : Icons.star_border,
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
                ),

                // Main Text Area
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: TextField(
                        controller: _textController,
                        focusNode: _keyboardFocus,
                        textAlign: TextAlign.center,
                        maxLines: null,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: textFontSize,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        decoration: InputDecoration(
                          hintText: 'Escribe tu historia...',
                          hintStyle: TextStyle(
                            fontSize: hintFontSize,
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
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

                // Color Picker (if active)
                _buildColorPicker(),

                // Emoji Picker (if active)
                if (showEmojiKeyboard)
                  SizedBox(
                    height: emojiPickerHeight,
                    child: _buildEmojiPicker(emojiPickerHeight, isTablet),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedFloatingActionButton(
        isLoading: isLoading,
        isTablet: isTablet,
        showEmojiKeyboard: showEmojiKeyboard,
        onPressed: () async {
          if (_textController.text.trim().isEmpty) {
            DialogHelper.showSnackbarMessage(
              SnackMsgType.error,
              'type_a_story'.tr,
              duration: 1,
            );
            return;
          }
          setState(() => isLoading = true);
          // Upload the text story
          await StoryApi.uploadTextStory(
            text: _textController.text.trim(),
            bgColor: backgroundColor,
            music: selectedMusic,
            bestFriendsOnly: bestFriendsOnly,
            isVipOnly: isVipOnly,
          );
          setState(() => isLoading = false);
        },
      ),
    );
  }
}

class AnimatedFloatingActionButton extends StatefulWidget {
  const AnimatedFloatingActionButton({
    super.key,
    required this.isLoading,
    required this.isTablet,
    required this.showEmojiKeyboard,
    required this.onPressed,
  });

  final bool isLoading;
  final bool isTablet;
  final bool showEmojiKeyboard;
  final VoidCallback onPressed;

  @override
  State<AnimatedFloatingActionButton> createState() =>
      _AnimatedFloatingActionButtonState();
}

class _AnimatedFloatingActionButtonState
    extends State<AnimatedFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showEmojiKeyboard) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        if (widget.isLoading) {
          return Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.5),
            ),
            child: const LoadingIndicator(size: 30, color: Colors.white),
          );
        }

        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2979FF).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingButton(
              icon: Icons.send,
              onPress: widget.onPressed,
            ),
          ),
        );
      },
    );
  }
}
