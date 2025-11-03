import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/call_controller.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final User user = args['user'] as User;
    final bool isIncoming = args['isIncoming'] as bool;
    final String? channelId = args['channelId'] as String?;
    final bool isVideo = args['isVideo'] as bool? ?? false;

    return GetBuilder<CallController>(
      init: CallController(),
      builder: (controller) {
        // Handle incoming call from notification
        if (isIncoming && channelId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            // Handle the incoming call with ZEGOCLOUD
            await controller.handleIncomingCall(
              callerId: user.userId,
              channelId: channelId,
              isVideo: isVideo,
              callerName: user.fullname,
            );
          });
        }
        
        // Start outgoing call automatically
        if (!isIncoming && !controller.isCallActive.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await controller.startOutgoingCall(
              receiver: user,
              isVideo: isVideo,
            );
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                // Top section with user info
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // User photo
                        CachedCircleAvatar(
                          backgroundColor: user.photoUrl.isEmpty ? secondaryColor : primaryColor,
                          imageUrl: user.photoUrl,
                          borderWidth: 0,
                          padding: 0,
                          radius: 80,
                        ),
                        const SizedBox(height: 24),
                        // User name
                        Text(
                          user.fullname,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Call status
                        Text(
                          isIncoming ? 'Llamada entrante...' : 'Llamando...',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Call duration (for ongoing calls)
                        if (!isIncoming && controller.isCallActive.value)
                          Text(
                            controller.callDuration.value,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom section with controls
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (isIncoming && !controller.isCallActive.value) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Reject
                              GestureDetector(
                                onTap: () async {
                                  await controller.rejectCall();
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.call_end,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                              // Accept
                              GestureDetector(
                                onTap: () async {
                                  await controller.answerCall();
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.call,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Call controls row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Mute button
                            _buildControlButton(
                              icon: controller.isMuted.value ? Icons.mic_off : Icons.mic,
                              color: controller.isMuted.value ? Colors.red : Colors.white,
                              onPressed: () => controller.toggleMute(),
                            ),
                            // Speaker button
                            _buildControlButton(
                              icon: controller.isSpeakerOn.value ? Icons.volume_up : Icons.volume_down,
                              color: controller.isSpeakerOn.value ? Colors.green : Colors.white,
                              onPressed: () => controller.toggleSpeaker(),
                            ),
                            // More options button
                            _buildControlButton(
                              icon: Icons.more_vert,
                              color: Colors.white,
                              onPressed: () => controller.showMoreOptions(),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Hang up button
                        GestureDetector(
                          onTap: () => controller.endCall(),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }
} 