import 'dart:math';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/api/story_api.dart';
import 'package:chat_messenger/components/floating_button.dart';
import 'package:chat_messenger/components/loading_indicator.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
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

  // Paleta de colores elegante: blanco, negro y dorado
  final List<Color> colorPalette = [
    const Color(0xFF000000), // Negro puro
    const Color(0xFFFFFFFF), // Blanco puro
    const Color(0xFFD4AF37), // Dorado elegante
    const Color(0xFF1A1A1A), // Negro suave
    const Color(0xFFFAFAFA), // Blanco cálido
    const Color(0xFFFFD700), // Dorado brillante
    const Color(0xFF2A2A2A), // Negro elegante
    const Color(0xFFF5F5F5), // Blanco perla
    const Color(0xFFB8860B), // Dorado oscuro
    const Color(0xFF000000), // Negro puro
    const Color(0xFFFFFFFF), // Blanco puro
    const Color(0xFFD4AF37), // Dorado elegante
    const Color(0xFF1A1A1A), // Negro suave
    const Color(0xFFFAFAFA), // Blanco cálido
    const Color(0xFFFFD700), // Dorado brillante
    const Color(0xFF000000), // Negro puro
    const Color(0xFFFFFFFF), // Blanco puro
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
        showColorPicker = false; // Cerrar selector de colores
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
        showEmojiKeyboard = false; // Cerrar teclado emoji
        _keyboardFocus.unfocus();
      }
    });
  }

  void _selectColor(Color color) {
    setState(() {
      backgroundColor = color;
      showColorPicker = false;
    });
    _keyboardFocus.requestFocus();
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.98),
              Colors.white.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
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
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: showColorPicker ? 1.0 : 0.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.95),
              Colors.black.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Indicador superior
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Grid de colores
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: colorPalette.length,
                  itemBuilder: (context, index) {
                    final color = colorPalette[index];
                    final isSelected = backgroundColor == color;

                    return GestureDetector(
                      onTap: () => _selectColor(color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: isSelected ? 12 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    );
                  },
                ),
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
    final horizontalPadding = isLargeScreen ? 32.0 : (isTablet ? 24.0 : 16.0);
    final textFontSize = isLargeScreen ? 28.0 : (isTablet ? 24.0 : 20.0);
    final hintFontSize = isLargeScreen ? 24.0 : (isTablet ? 20.0 : 18.0);
    final emojiPickerHeight = isTablet ? 280.0 : 240.0;
    final colorPickerHeight = 120.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ) : null,
        actions: [
          // Random color button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.shuffle, color: Colors.white, size: 22),
              onPressed: _generateRandomColor,
              tooltip: 'Color aleatorio',
            ),
          ),
          // Color palette button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: showColorPicker
                    ? [
                        Colors.white.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.2),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.palette, color: Colors.white, size: 22),
              onPressed: _toggleColorPicker,
              tooltip: 'Seleccionar color',
            ),
          ),
          // Emoji button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: showEmojiKeyboard
                    ? [
                        Colors.white.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.2),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.emoji_emotions,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _toggleEmojiKeyboard,
              tooltip: 'Emojis',
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
        builder: (context, child) {
          final fadeValue = _fadeAnimation.value.clamp(0.0, 1.0).toDouble();
          final scaleValue = _scaleAnimation.value.clamp(0.1, 2.0).toDouble();

          return Opacity(
            opacity: fadeValue,
            child: Transform.scale(
              scale: scaleValue,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  final keyboardHeight = showEmojiKeyboard
                      ? emojiPickerHeight
                      : showColorPicker
                      ? colorPickerHeight
                      : 0.0;
                  final contentHeight =
                      (availableHeight - keyboardHeight - bottomPadding)
                          .clamp(100.0, double.infinity)
                          .toDouble();

                  return Column(
                    children: [
                      // Main content area
                      SizedBox(
                        height: contentHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            // Main text input with enhanced styling (sin Hero)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        backgroundColor.withValues(alpha: 0.95),
                                        backgroundColor.withValues(alpha: 0.85),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: backgroundColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 25,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    maxLines: null,
                                    controller: _textController,
                                    focusNode: _keyboardFocus,
                                    textAlign: TextAlign.center,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      filled: false,
                                      hintText: '✨ Escribe tu historia ✨',
                                      hintStyle: TextStyle(
                                        fontSize: hintFontSize,
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.5,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: isTablet ? 32 : 28,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: textFontSize,
                                      color: Colors.white,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          offset: const Offset(1, 1),
                                          blurRadius: 3,
                                        ),
                                      ],
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
                            const Spacer(),
                          ],
                        ),
                      ),
                      // Animated bottom panels (emoji picker & color picker)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        height: keyboardHeight,
                        width: double.infinity,
                        child: showEmojiKeyboard
                            ? _buildEmojiPicker(emojiPickerHeight, isTablet)
                            : showColorPicker
                            ? _buildColorPicker()
                            : const SizedBox.shrink(),
                      ),
                      SizedBox(height: bottomPadding),
                    ],
                  );
                },
              ),
            ),
          );
        },
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
    _pulseAnimation =
        Tween<double>(
          begin: 1.0,
          end: 1.05, // Reducido para evitar problemas
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
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseValue = _pulseAnimation.value.clamp(0.8, 1.2).toDouble();

        if (widget.isLoading) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: LoadingIndicator(
              size: (widget.isTablet ? 65 : 55).toDouble(),
              color: Colors.white,
            ),
          );
        }

        return Transform.scale(
          scale: pulseValue,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: FloatingButton(icon: Icons.check, onPress: widget.onPressed),
          ),
        );
      },
    );
  }
}
