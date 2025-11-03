import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../screens/messages/controllers/message_controller.dart';
import '../api/user_api.dart';

class AudioPlayerBar extends StatelessWidget {
  final Message message;
  final VoidCallback? onClose;
  final VoidCallback? onPlayPause;
  final VoidCallback? onSpeedChange;
  final bool isPlaying;
  final double playbackSpeed;

  const AudioPlayerBar({
    Key? key,
    required this.message,
    this.onClose,
    this.onPlayPause,
    this.onSpeedChange,
    required this.isPlaying,
    required this.playbackSpeed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Play/Pause button
          Container(
            margin: const EdgeInsets.only(left: 16),
            child: GestureDetector(
              onTap: onPlayPause,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF00A884),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          
          // User info and message type
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<String>(
                    future: _getSenderName(message.senderId),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Mensaje de voz',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Speed control
          GestureDetector(
            onTap: onSpeedChange,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.speed,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${playbackSpeed.toInt()}X',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Close button
          GestureDetector(
            onTap: onClose,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.close,
                size: 20,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<String> _getSenderName(String senderId) async {
    try {
      // Use static method to get user name
      final user = await UserApi.getUser(senderId);
      return user?.fullname ?? 'Usuario';
    } catch (e) {
      return 'Usuario';
    }
  }
} 