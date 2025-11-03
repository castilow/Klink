import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class VoiceRecordingBottomBar extends StatefulWidget {
  final Duration recordingDuration;
  final bool isRecording;
  final VoidCallback? onCancel;
  final VoidCallback? onSend;
  final VoidCallback? onSlideToCancel;

  const VoiceRecordingBottomBar({
    Key? key,
    required this.recordingDuration,
    required this.isRecording,
    this.onCancel,
    this.onSend,
    this.onSlideToCancel,
  }) : super(key: key);

  @override
  State<VoiceRecordingBottomBar> createState() => _VoiceRecordingBottomBarState();
}

class _VoiceRecordingBottomBarState extends State<VoiceRecordingBottomBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;
  
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
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceRecordingBottomBar oldWidget) {
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
      _slideOffset = _slideOffset.clamp(-150.0, 0.0);
      
      // Check if should cancel (slide left more than 60px)
      _shouldCancel = _slideOffset < -60.0;
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
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Left side - Recording indicator and timer
              Row(
                children: [
                  // Red recording dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Timer
                  Text(
                    _formatDuration(widget.recordingDuration),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Cancel button
              GestureDetector(
                onTap: widget.onCancel,
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Large microphone button
              GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: widget.isRecording ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007AFF).withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic,
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
    );
  }
} 