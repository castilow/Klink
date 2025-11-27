import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class VoiceRecordingMode extends StatefulWidget {
  final Duration recordingDuration;
  final bool isRecording;
  final bool isLocked;
  final VoidCallback? onCancel;
  final VoidCallback? onSend;
  final VoidCallback? onLock;
  final VoidCallback? onPause;

  const VoiceRecordingMode({
    Key? key,
    required this.recordingDuration,
    required this.isRecording,
    required this.isLocked,
    this.onCancel,
    this.onSend,
    this.onLock,
    this.onPause,
  }) : super(key: key);

  @override
  State<VoiceRecordingMode> createState() => _VoiceRecordingModeState();
}

class _VoiceRecordingModeState extends State<VoiceRecordingMode>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ringAnimation;

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

    _ringController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _ringAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOut,
    ));

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
      _ringController.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceRecordingMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
      _ringController.repeat();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _ringController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final centiseconds = twoDigits((duration.inMilliseconds % 1000) ~/ 10);
    return '$minutes:$seconds,$centiseconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SafeArea(
        child: Stack(
          children: [
            // Main recording interface
            Row(
              children: [
                // Left side - Recording indicator and timer
                Row(
                  children: [
                    // Red recording dot with pulse animation
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Timer
                    Text(
                      _formatDuration(widget.recordingDuration),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: widget.recordingDuration.inMilliseconds < 500 
                            ? Colors.red 
                            : Colors.black87,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Center - Cancel button
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 40,
                  child: GestureDetector(
                    onTap: widget.onCancel,
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Right side - Large recording button
                _buildRecordingButton(),
              ],
            ),
            
            // Lock/Pause container - positioned above mic button
            Positioned(
              top: -64,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (!widget.isLocked) ...[
                      // Lock button
                      GestureDetector(
                        onTap: widget.onLock,
                        child: Icon(
                          Icons.lock_open,
                          color: const Color(0xFF00A884),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Up arrow
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: const Color(0xFF00A884),
                        size: 16,
                      ),
                    ] else ...[
                      // Pause button when locked
                      GestureDetector(
                        onTap: widget.onPause,
                        child: Icon(
                          Icons.pause,
                          color: const Color(0xFF00A884),
                          size: 24,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingButton() {
    return Transform.translate(
      offset: const Offset(24, -24),
      child: Stack(
        children: [
          // Pulsing ring animation
          AnimatedBuilder(
            animation: _ringAnimation,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00A884).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          
          // Main button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return GestureDetector(
                onTap: widget.isRecording && widget.onSend != null
                    ? () {
                        debugPrint('🎤 Botón de micrófono tocado en VoiceRecordingMode');
                        widget.onSend?.call();
                      }
                    : null,
                child: Transform.scale(
                  scale: widget.isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A884),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A884).withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isLocked ? Icons.keyboard_arrow_up : Icons.mic,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 