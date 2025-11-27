import 'dart:io';

import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/components/chat_background_wrapper.dart';
import 'package:chat_messenger/api/message_api.dart';
import 'package:chat_messenger/components/loading_indicator.dart';
import 'package:chat_messenger/components/no_data.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
import 'package:chat_messenger/helpers/routes_helper.dart';
import 'package:chat_messenger/models/group.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/helpers/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/tabs/groups/components/update_message.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import 'components/appbar_tools.dart';
import 'components/encrypted_notice.dart';
// import 'components/msg_appbar_tools.dart';
import 'components/multi_select_app_bar.dart';
import 'components/multi_select_bottom_actions.dart';
import 'controllers/block_controller.dart';
import 'components/bubble_message.dart';
import 'components/chat_input_field.dart';
import 'components/group_date_separator.dart';
import 'components/scroll_down_button.dart';
import 'controllers/message_controller.dart';
import '../../components/audio_player_bar.dart';
import '../../components/audio_recorder_overlay.dart';
import '../../components/voice_recording_bottom_bar.dart';
import '../../components/voice_recording_mode.dart';
import 'components/klink_ai_chat_view.dart';
import 'package:chat_messenger/components/particle_disintegration_effect.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({
    super.key,
    required this.isGroup,
    this.user,
    this.groupId,
  });

  final bool isGroup;
  final User? user;
  final String? groupId;

  @override
  Widget build(BuildContext context) {
    // Check for Klink AI User
    if (user?.userId == 'klink_ai_assistant') {
      return KlinkAIChatView(user: user!);
    }

    // Init controllers
    final MessageController controller = Get.put(
      MessageController(isGroup: isGroup, user: user),
    );
    Get.put(BlockController(user?.userId));

    // Find instance
    final PreferencesController prefController = Get.find();

    // Check group
    if (isGroup) {
      prefController.getGroupWallpaperPath(
        controller.selectedGroup!.groupId,
      );
    } else {
      prefController.getChatWallpaperPath();
    }

    return Obx(
      () {
        // Get selected group instance
        Group? group = controller.selectedGroup;

        final Widget appBar = controller.isMultiSelectMode.value
            ? MultiSelectAppBar(controller: controller)
            : AppBarTools(isGroup: isGroup, user: user, group: group);

        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          // Permitimos que el cuerpo se redimensione con el teclado para que la barra siempre sea visible
          resizeToAvoidBottomInset: true,
          backgroundColor: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
          appBar: appBar as PreferredSizeWidget,
          bottomNavigationBar: Obx(() {
            final globalController = MessageController.globalInstance;
            return globalController.showVoiceRecordingBar.value
                ? VoiceRecordingMode(
                    isRecording: globalController.isRecording.value,
                    recordingDuration: globalController.recordingDurationValue.value,
                    isLocked: globalController.isRecordingLocked.value,
                    onCancel: () => globalController.onMicCancelled(),
                    onSend: () => globalController.onMicTapped(),
                    onLock: () => globalController.onLockRecording(),
                    onPause: () => globalController.onPauseRecording(),
                  )
                : const SizedBox.shrink();
          }),
          body: Obx(
            () {
              // Get wallpaper path
              final String? wallpaperPath = isGroup
                  ? prefController.groupWallpaperPath.value
                  : prefController.chatWallpaperPath.value;

              return Stack(
                clipBehavior: Clip.none, // Permite que el botón sobresalga
                children: [
                  // Audio Player Bar (top)
                  Obx(() {
                    final globalController = MessageController.globalInstance;
                    return globalController.showAudioPlayerBar.value && globalController.currentPlayingMessage.value != null
                        ? Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: AudioPlayerBar(
                              message: globalController.currentPlayingMessage.value!,
                              isPlaying: globalController.isPlaying,
                              playbackSpeed: globalController.playbackSpeed,
                              onClose: () => globalController.stopAudio(),
                              onPlayPause: () {
                                if (globalController.isPlaying) {
                                  globalController.pauseAudio();
                                } else {
                                  globalController.resumeAudio();
                                }
                              },
                              onSpeedChange: () => globalController.changePlaybackSpeed(),
                            ),
                          )
                        : const SizedBox.shrink();
                  }),
                  
                  // Audio Recorder Overlay
                  Obx(() {
                    final globalController = MessageController.globalInstance;
                    return globalController.showRecordingOverlay.value
                        ? AudioRecorderOverlay(
                            isRecording: globalController.isRecording.value,
                            recordingDuration: globalController.recordingDurationValue.value,
                            isPressed: globalController.isMicPressed.value,
                            onCancel: () => globalController.onMicCancelled(),
                            onSend: () => globalController.onMicTapped(),
                          )
                        : const SizedBox.shrink();
                  }),
                  


                  // Contenido principal del chat
                  ChatBackgroundWrapper(
                    child: GestureDetector(
                      // Cerrar el teclado SOLO con un toque (tap),
                      // para permitir desplazar/scroll con el teclado abierto
                      onTap: () {
                        final MessageController messageController = Get.find();
                        messageController.chatFocusNode.unfocus();
                      },
                      onPanEnd: (DragEndDetails details) {
                        // Detectar swipe hacia la derecha para volver a la lista de chats
                        // Verificar que es un swipe horizontal hacia la derecha con velocidad suficiente
                        // y que no sea demasiado vertical (para evitar confusión con scroll)
                        final double dx = details.velocity.pixelsPerSecond.dx;
                        final double dy = details.velocity.pixelsPerSecond.dy.abs();
                        
                        if (dx > 300 && dx > dy) {
                          // Swipe hacia la derecha detectado - navegar de vuelta a la lista de chats
                          Get.back();
                        }
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          // Multi-select toolbar - ELIMINADO
                          // MultiSelectToolbar(controller: controller),
                          // <-- List of Messages -->
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: defaultPadding),
                              child: _buildMessagesList(wallpaperPath),
                            ),
                          ),
                          // <--- ChatInput or MultiSelect Bottom Actions --->
                          Obx(() => controller.isMultiSelectMode.value
                              ? MultiSelectBottomActions(controller: controller)
                              : ChatInputField(
                                  user: user,
                                  group: group,
                                ),
                          ),
                        ],
                        ),
                      ),
                    ),
                  

                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMessagesList(String? wallpaperPath) {
    // Get messages controller instance
    final MessageController controller = Get.find();
    // Get selected group instance
    Group? group = controller.selectedGroup;

    return Obx(
      () {
        // Check loading state
        if (controller.isLoading.value) {
          return const Center(child: LoadingIndicator(size: 35));
        } 
        // Check if messages list is empty
        else if (controller.messages.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NoData(
                iconData: IconlyBold.chat,
                text: 'no_messges'.tr,
                textColor: wallpaperPath != null ? Colors.white : null,
              ),
              const SizedBox(height: 16),
              // Add retry button for better UX
                             ElevatedButton(
                 onPressed: () {
                   debugPrint('Retry button pressed - reloading messages');
                   controller.reloadMessages();
                 },
                 child: Text('Reintentar'),
               ),
            ],
          );
        } 
        else {
          // Get Messages List in reversed order
          final List<Message> messages = controller.messages;

          return AnimationLimiter(
            child: ListView.builder(
              reverse: true,
              shrinkWrap: true,
              cacheExtent: double.maxFinite,
              controller: controller.scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                
                final Message message = messages[index];

                // Message rendering

                // Check unread message to update it
                if (!isGroup) {
                  if (!message.isSender && !message.isRead) {
                    MessageApi.readMsgReceipt(
                      messageId: message.msgId,
                      receiverId: user!.userId,
                    );
                  }
                }

                // <--- Handle group date --->
                final DateTime? sentAt = message.sentAt;
                Widget dateSeparator = const SizedBox.shrink();

                // Check sent time
                if (sentAt != null) {
                  // Check first element in reverse order
                  if (index == messages.length - 1) {
                    dateSeparator = GroupDateSeparator(sentAt.formatDateTime);
                  } else
                  // Validate the index in range
                  if (index + 1 < messages.length) {
                    // Get previous date in reverse order
                    DateTime prevDate = messages[index + 1].sentAt!;
                    // Check different dates
                    if (!(sentAt.isSameDate(prevDate))) {
                      dateSeparator = GroupDateSeparator(
                        sentAt.formatDateTime,
                      );
                    }
                  }
                }

                // Get sender user
                final User senderUser =
                    isGroup ? group!.getMemberProfile(message.senderId) : user!;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show Group Date time
                    dateSeparator,
                    // Show encrypted notice
                    if (!isGroup && index == messages.length - 1)
                      const EncryptedNotice(),
                    // Bubble message
                    GestureDetector(
                      onLongPress: () {
                        if (message.type == MessageType.groupUpdate) return;
                        if (!controller.isMultiSelectMode.value) {
                          controller.enterMultiSelectMode(message);
                        } else {
                          controller.toggleMessageSelection(message);
                        }
                      },
                      onTap: () {
                        if (controller.isMultiSelectMode.value) {
                          controller.toggleMessageSelection(message);
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1.0,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          key: ValueKey(message.msgId), // Key único para AnimatedSwitcher
                          margin: controller.isMultiSelectMode.value
                              ? const EdgeInsets.symmetric(vertical: 1.0)
                              : null,
                          child: AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Obx(() => ParticleDisintegrationEffect(
                                  trigger: controller.animatingMessageIds.contains(message.msgId),
                                  child: isGroup && message.type == MessageType.groupUpdate
                                      ? UpdateMessage(
                                          group: group!,
                                          message: message,
                                        )
                                      : BubbleMessage(
                                          message: message,
                                          user: user,
                                          group: group,
                                          controller: controller,
                                          onTapProfile: message.isSender
                                              ? null
                                              : () => RoutesHelper.toProfileView(
                                                  senderUser, isGroup),
                                          onReplyMessage: message.isDeleted
                                              ? null
                                              : () => controller.replyToMessage(message),
                                        ),
                                )),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      },
    );
  }

}
