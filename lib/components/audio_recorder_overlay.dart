import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:ui'; // Added for ImageFilter

class AudioRecorderOverlay extends StatefulWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSend;
  final Duration recordingDuration;
  final bool isRecording;
  final bool isPressed;

  const AudioRecorderOverlay({
    Key? key,
    this.onCancel,
    this.onSend,
    required this.recordingDuration,
    required this.isRecording,
    required this.isPressed,
  }) : super(key: key);

  @override
  State<AudioRecorderOverlay> createState() => _AudioRecorderOverlayState();
}

class _AudioRecorderOverlayState extends State<AudioRecorderOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  double _slideOffset = 0.0;
  bool _isSliding = false;
  bool _shouldCancel = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-1, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AudioRecorderOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final milliseconds = twoDigits((duration.inMilliseconds % 1000) ~/ 10);
    return '$minutes:$seconds,$milliseconds';
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isRecording) return;
    
    setState(() {
      _slideOffset += details.delta.dx;
      _slideOffset = _slideOffset.clamp(-200.0, 0.0);
      
      // Check if should cancel (slide left more than 80px)
      _shouldCancel = _slideOffset < -80.0;
      _isSliding = _slideOffset.abs() > 20.0;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isRecording) return;
    
    if (_shouldCancel) {
      // Cancel recording
      widget.onCancel?.call();
    } else {
      // Send recording
      widget.onSend?.call();
    }
    
    setState(() {
      _slideOffset = 0.0;
      _shouldCancel = false;
      _isSliding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Stack(
        children: [
          // Background blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          
          // Main recording interface
          Center(
            child: Container(
              width: 300,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: isDark ? Border.all(color: Colors.grey[800]!, width: 1) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Timer display
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Small recording indicator circle
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.red[400] : const Color(0xFF007AFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Timer text
                        Text(
                          _formatDuration(widget.recordingDuration),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[100] : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Instructions
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suelta fuera del círculo para',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                          Text(
                            'cancelar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.red[400] : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Recording button
                  GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: widget.isPressed ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: widget.isPressed 
                                  ? (isDark ? const Color(0xFF4A9EFF) : const Color(0xFF007AFF))
                                  : (isDark ? Colors.grey[600] : Colors.grey[400]),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.isPressed 
                                      ? (isDark ? const Color(0xFF4A9EFF) : const Color(0xFF007AFF))
                                      : (isDark ? Colors.grey[600]! : Colors.grey[400]!)).withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.isPressed ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Slide indicator
          if (_isSliding)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _shouldCancel ? (isDark ? Colors.red[700] : Colors.red) : (isDark ? Colors.grey[800] : Colors.grey),
                      borderRadius: BorderRadius.circular(20),
                      border: isDark ? Border.all(color: Colors.grey[700]!, width: 1) : null,
                    ),
                  child: Text(
                    _shouldCancel ? 'Soltar para cancelar' : 'Desliza para cancelar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 