import 'dart:ui';
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
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Dynamic Background (Blurred Avatar)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  image: user.photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(user.photoUrl),
                          fit: BoxFit.cover,
                          opacity: 0.6,
                        )
                      : null,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
              ),
              
              // 2. Main Content
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Top Section: Encryption & Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 12, color: Colors.white.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(
                          'End-to-end encrypted',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(flex: 1),
                    
                    // User Info Section
                    Column(
                      children: [
                        // Avatar with ripple effect (simulated with container shadow)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: CachedCircleAvatar(
                            backgroundColor: user.photoUrl.isEmpty ? secondaryColor : primaryColor,
                            imageUrl: user.photoUrl,
                            borderWidth: 0,
                            padding: 0,
                            radius: 60, // Slightly smaller for modern look
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Name
                        Text(
                          user.fullname,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Status / Duration
                        if (!isIncoming && controller.isCallActive.value)
                          Text(
                            controller.callDuration.value,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            isIncoming 
                                ? (isVideo ? 'Incoming video call...' : 'Incoming voice call...') 
                                : 'Calling...',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    
                    const Spacer(flex: 2),
                    
                    // Bottom Controls Section
                    Container(
                      padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Incoming Call Actions
                          if (isIncoming && !controller.isCallActive.value) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionLabel(
                                  label: 'Decline',
                                  child: _buildCircleButton(
                                    icon: Icons.call_end,
                                    color: Colors.red,
                                    size: 70,
                                    iconSize: 32,
                                    onTap: () async => await controller.rejectCall(),
                                  ),
                                ),
                                _buildActionLabel(
                                  label: 'Accept',
                                  child: _buildCircleButton(
                                    icon: isVideo ? Icons.videocam : Icons.call,
                                    color: const Color(0xFF25D366), // WhatsApp Green
                                    size: 70,
                                    iconSize: 32,
                                    onTap: () async => await controller.answerCall(),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Active/Outgoing Call Controls
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2C34), // Dark slate
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildControlIcon(
                                    icon: controller.isSpeakerOn.value ? Icons.volume_up : Icons.volume_up_outlined,
                                    isActive: controller.isSpeakerOn.value,
                                    onTap: () => controller.toggleSpeaker(),
                                  ),
                                  if (isVideo)
                                    _buildControlIcon(
                                      icon: Icons.videocam,
                                      isActive: true, // Always active for video call initially
                                      onTap: () {}, // Toggle video logic if needed
                                    ),
                                  _buildControlIcon(
                                    icon: controller.isMuted.value ? Icons.mic_off : Icons.mic,
                                    isActive: !controller.isMuted.value, // Active means mic is ON
                                    onTap: () => controller.toggleMute(),
                                  ),
                                  _buildControlIcon(
                                    icon: Icons.call_end,
                                    isActive: false, // Special style for end call
                                    isEndCall: true,
                                    onTap: () => controller.endCall(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Back Button (Top Left)
              Positioned(
                top: 50,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                  onPressed: () => Get.back(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionLabel({required String label, required Widget child}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _buildControlIcon({
    required IconData icon,
    required bool isActive,
    bool isEndCall = false,
    required VoidCallback onTap,
  }) {
    if (isEndCall) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
          size: 28,
        ),
      ),
    );
  }
}
 