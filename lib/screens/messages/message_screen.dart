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
import 'components/typing_indicator.dart';

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
          return Obx(() {
            // Observar también el trigger de actualización de imágenes para forzar reconstrucción
            final imageUpdateTrigger = controller.imageMessageUpdateTrigger.value;
            
            // IMPORTANTE: Acceder directamente a controller.messages para que GetX lo observe
            // Iterar sobre la lista para forzar la observación de GetX
            final List<Message> messages = controller.messages.toList();
            final int messagesLength = controller.messages.length;
            
            // Forzar observación accediendo a un elemento de la lista si existe
            if (messages.isNotEmpty) {
              final _ = messages.first.msgId; // Forzar acceso para observación
            }
            
            debugPrint('🔄 message_screen.Obx: Reconstruyendo con ${messages.length} mensajes, imageUpdateTrigger=$imageUpdateTrigger, messagesLength=$messagesLength');
            
            // Debug: Verificar mensajes de imagen en la lista
            final imageMessages = messages.where((m) => m.type == MessageType.image).toList();
            if (imageMessages.isNotEmpty) {
              debugPrint('🖼️ message_screen.Obx: Hay ${imageMessages.length} mensajes de imagen en la lista');
              for (var imgMsg in imageMessages) {
                debugPrint('🖼️ message_screen.Obx: Imagen msgId=${imgMsg.msgId}, fileUrl=${imgMsg.fileUrl.isEmpty ? "VACÍO" : imgMsg.fileUrl.substring(0, imgMsg.fileUrl.length > 50 ? 50 : imgMsg.fileUrl.length)}...');
              }
            }
            
            // Verificar si debemos mostrar el indicador de escritura de la IA (reactivo)
            final bool showTypingIndicator = !isGroup && 
                user?.userId == 'klink_ai_assistant' && 
                controller.isAIResponding.value;
            
            debugPrint('💬 showTypingIndicator: $showTypingIndicator (isGroup: $isGroup, userId: ${user?.userId}, isAIResponding: ${controller.isAIResponding.value}, messages.length: ${messages.length})');
            
            final int itemCount = messages.length + (showTypingIndicator ? 1 : 0);
            
            debugPrint('💬 message_screen.Obx: itemCount=$itemCount, messages.length=${messages.length}');

            return AnimationLimiter(
              child: ListView.builder(
                // Key que incluye información sobre mensajes de imagen y el trigger para detectar cambios en fileUrl
                key: ValueKey('messages_${messages.length}_${imageUpdateTrigger}_${messages.where((m) => m.type == MessageType.image).map((m) => m.fileUrl.isEmpty ? "empty" : m.fileUrl.substring(0, m.fileUrl.length > 10 ? 10 : m.fileUrl.length)).join("_")}'),
                reverse: true,
                shrinkWrap: true,
                cacheExtent: double.maxFinite,
                controller: controller.scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  debugPrint('🔵 message_screen.itemBuilder: index=$index, itemCount=$itemCount, messages.length=${messages.length}, showTypingIndicator=$showTypingIndicator');
                  
                  // Si es el último item y debemos mostrar el indicador de escritura
                  if (showTypingIndicator && index == 0) {
                    debugPrint('🔵 message_screen.itemBuilder: Mostrando indicador de escritura');
                    return _buildAITypingBubble(context, user!);
                  }
                  
                  // Ajustar el índice para acceder a los mensajes
                  final int messageIndex = showTypingIndicator ? index - 1 : index;
                  
                  debugPrint('🔵 message_screen.itemBuilder: messageIndex=$messageIndex después de ajuste');
                  
                  // Validar que el índice esté dentro del rango
                  if (messageIndex < 0 || messageIndex >= messages.length) {
                    debugPrint('⚠️ message_screen.itemBuilder: messageIndex fuera de rango (messageIndex=$messageIndex, messages.length=${messages.length})');
                    return const SizedBox.shrink();
                  }
                
                final Message message = messages[messageIndex];
                
                debugPrint('🔵 message_screen.itemBuilder: Mensaje encontrado: msgId=${message.msgId}, type=${message.type}, index=$messageIndex');
                
                // Debug log para mensajes de imagen
                if (message.type == MessageType.image) {
                  debugPrint('🖼️ message_screen.itemBuilder: Mensaje de imagen ${message.msgId}, fileUrl: ${message.fileUrl.isEmpty ? "VACÍO" : message.fileUrl.substring(0, message.fileUrl.length > 50 ? 50 : message.fileUrl.length)}...');
                  debugPrint('🖼️ message_screen.itemBuilder: messageIndex=$messageIndex, totalMessages=${messages.length}');
                  debugPrint('🖼️ message_screen.itemBuilder: isSender=${message.isSender}, senderId=${message.senderId}');
                }

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
                  // Check first element in reverse order (ajustado para messageIndex)
                  if (messageIndex == messages.length - 1) {
                    dateSeparator = GroupDateSeparator(sentAt.formatDateTime);
                  } else
                  // Validate the index in range
                  if (messageIndex + 1 < messages.length) {
                    // Get previous date in reverse order
                    DateTime prevDate = messages[messageIndex + 1].sentAt!;
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
                    // Show encrypted notice (ajustado para messageIndex)
                    if (!isGroup && messageIndex == messages.length - 1)
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
                        child: Obx(() {
                          // Observar también los mensajes para forzar reconstrucción cuando cambian
                          // Acceder directamente a la lista para que GetX la observe
                          final int messagesLength = controller.messages.length;
                          final int updateTrigger = controller.imageMessageUpdateTrigger.value;
                          
                          // Obtener el mensaje actualizado de la lista para asegurar que tenemos la última versión
                          final int msgIndex = controller.messages.indexWhere((m) => m.msgId == message.msgId);
                          final Message currentMessage = msgIndex != -1 
                              ? controller.messages[msgIndex] 
                              : message;
                          
                          if (currentMessage.type == MessageType.image) {
                            debugPrint('🖼️ message_screen.AnimatedSwitcher.Obx: Mensaje de imagen ${currentMessage.msgId}, fileUrl=${currentMessage.fileUrl.isEmpty ? "VACÍO" : currentMessage.fileUrl.substring(0, currentMessage.fileUrl.length > 50 ? 50 : currentMessage.fileUrl.length)}..., messagesLength=$messagesLength, updateTrigger=$updateTrigger');
                          }
                          
                          // Forzar observación de la lista accediendo a un elemento
                          final _ = messagesLength;
                          final __ = updateTrigger;
                          
                          return Container(
                            // Key único que incluye fileUrl para mensajes de imagen, para que se reconstruya cuando cambia el fileUrl
                            // Usar hash del fileUrl completo para detectar cambios
                            key: currentMessage.type == MessageType.image 
                                ? ValueKey('${currentMessage.msgId}_${currentMessage.fileUrl.hashCode}_${currentMessage.fileUrl.isEmpty ? "empty" : (currentMessage.fileUrl.startsWith('http') ? "remote" : "local")}')
                                : ValueKey(currentMessage.msgId),
                            margin: controller.isMultiSelectMode.value
                                ? const EdgeInsets.symmetric(vertical: 1.0)
                                : null,
                            child: AnimationConfiguration.staggeredList(
                              position: messageIndex,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: ParticleDisintegrationEffect(
                                    trigger: controller.animatingMessageIds.contains(currentMessage.msgId),
                                    child: isGroup && currentMessage.type == MessageType.groupUpdate
                                        ? UpdateMessage(
                                            group: group!,
                                            message: currentMessage,
                                          )
                                        : BubbleMessage(
                                            message: currentMessage,
                                            user: user,
                                            group: group,
                                            controller: controller,
                                            onTapProfile: currentMessage.isSender
                                                ? null
                                                : () => RoutesHelper.toProfileView(
                                                    senderUser, isGroup),
                                            onReplyMessage: currentMessage.isDeleted
                                                ? null
                                                : () => controller.replyToMessage(currentMessage),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        });
        }
      },
    );
  }

  /// Widget para mostrar la burbuja de escritura de la IA
  Widget _buildAITypingBubble(BuildContext context, User aiUser) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final PreferencesController prefController = Get.find();
    final Color backgroundColor = prefController.getReceivedBubbleColor(isDarkMode);
    final Color textColor = PreferencesController.getContrastTextColor(backgroundColor);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar de la IA (opcional, similar a las burbujas normales)
          Container(
            margin: const EdgeInsets.only(right: 8, top: 4),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: CircleAvatar(
              backgroundImage: aiUser.photoUrl.isNotEmpty
                  ? NetworkImage(aiUser.photoUrl)
                  : null,
              backgroundColor: Colors.grey[300],
              child: aiUser.photoUrl.isEmpty
                  ? Icon(Icons.smart_toy, color: Colors.grey[600], size: 20)
                  : null,
            ),
          ),
          // Burbuja con indicador de escritura
          Obx(() {
            final double radius = prefController.customBubbleRadius.value;
            return Container(
              constraints: const BoxConstraints(
                minWidth: 60,
                maxWidth: 200,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.98),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: Radius.circular(radius),
                  bottomLeft: Radius.circular(radius),
                  bottomRight: Radius.circular(radius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: TypingIndicator(
                color: textColor,
                size: 8.0,
              ),
            );
          }),
        ],
      ),
    );
  }

}
