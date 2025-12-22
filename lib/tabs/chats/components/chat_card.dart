import 'package:flutter/material.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/components/message_badge.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/helpers/routes_helper.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/models/chat.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/components/badge_count.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/components/sent_time.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/tabs/stories/controller/story_controller.dart';

// ignore: must_be_immutable
class ChatCard extends StatelessWidget {
  ChatCard(
    this.chat, {
    super.key,
    required this.onDeleteChat,
  });

  final Chat chat;
  User? updatedUser;
  final Function()? onDeleteChat;

  @override
  Widget build(BuildContext context) {
    // Vars
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    final User user = chat.receiver!;

    // Usar groupId si existe, sino userId
    final chatKey = chat.groupId != null && chat.groupId!.isNotEmpty 
        ? chat.groupId! 
        : chat.receiver!.userId;
    
    return Dismissible(
      key: Key(chatKey),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {
        DismissDirection.endToStart: 0.7,
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          if (onDeleteChat != null) {
            onDeleteChat!();
          }
          return true;
        }
        return false;
      },
      background: _buildSwipeActions(context, user),
      secondaryBackground: Container(
        color: errorColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          // Check if this is a group chat
          if (chat.groupId != null) {
            // Navigate to group messages
            RoutesHelper.toMessages(
              isGroup: true,
              groupId: chat.groupId,
            );
          } else {
            // Navigate to individual user messages
            RoutesHelper.toMessages(user: updatedUser ?? user);
          }
          chat.viewChat();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          // Telegram style: 72px height typically, larger avatar
          height: 76, 
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: chat.groupId != null 
            ? _buildGroupChatContent(context, user)
            : StreamBuilder<User>(
                stream: UserApi.getUserUpdates(user.userId),
                builder: (context, snapshot) {
                  updatedUser = snapshot.data;
                  final User receiver = updatedUser ?? user;

                  // Check for active story
                  bool hasStory = false;
                  if (Get.isRegistered<StoryController>()) {
                    final StoryController storyController = Get.find();
                    hasStory = storyController.stories.any((s) => s.userId == receiver.userId);
                  }

              return _buildChatContent(context, receiver, hasStory);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGroupChatContent(BuildContext context, User user) {
    // For groups, use the user directly without StreamBuilder
    return _buildChatContent(context, user, false);
  }

  Widget _buildChatContent(BuildContext context, User receiver, bool hasStory) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    
    return Row(
      children: [
        Hero(
          tag: 'avatar_${receiver.userId}',
          child: Container(
            padding: hasStory ? const EdgeInsets.all(2) : EdgeInsets.zero,
            decoration: hasStory ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue, // WhatsApp-style blue indicator
                width: 2,
              ),
            ) : null,
            child: CachedCircleAvatar(
              imageUrl: receiver.photoUrl,
              radius: 28, // 56px diameter
              isOnline: receiver.isOnline,
              isGroup: chat.groupId != null, // Indicate if it's a group
              // If hasStory is true, we use the container border, so set this to null or keep for unread
              borderColor: null, 
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.black : lightDividerColor,
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        receiver.fullname,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700, // Bolder title
                          fontSize: 16,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SentTime(
                      time: chat.isDeleted ? chat.updatedAt : chat.sentAt,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: LastMessage(chat: chat, user: receiver),
                    ),
                    if (chat.isMuted) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.volume_off,
                        color: greyColor,
                        size: 14,
                      ),
                    ],
                    if (chat.unread > 0) ...[
                      const SizedBox(width: 8),
                      BadgeCount(
                        counter: chat.unread,
                        bgColor: primaryColor, // Telegram Blue badge
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeActions(BuildContext context, User user) {
    return Container(
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionButton(
            color: Colors.orange,
            icon: Icons.folder,
            label: 'Archivar',
            onTap: () {
              print('Archivar chat: ${user.fullname}');
            },
          ),
          _buildActionButton(
            color: Colors.blue,
            icon: Icons.volume_off,
            label: 'Silenciar',
            onTap: () {
              print('Silenciar chat: ${user.fullname}');
            },
          ),
          _buildActionButton(
            color: Colors.red,
            icon: Icons.delete,
            label: 'Eliminar',
            onTap: () {
              if (onDeleteChat != null) onDeleteChat!();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        color: color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LastMessage extends StatelessWidget {
  const LastMessage({
    super.key,
    required this.chat,
    required this.user,
  });

  final Chat chat;
  final User user;

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        Theme.of(context).textTheme.bodyMedium!.copyWith(color: primaryColor);
    final String currentUserId = AuthController.instance.currentUser.userId;

    final isTypingToMe = user.isTyping && user.typingTo == currentUserId;

    if (chat.isDeleted) {
      return MessageDeleted(
        iconSize: 22,
        isSender: chat.isSender,
      );
    } else if (chat.deletedMessagesCount > 0) {
      return Row(
        children: [
          const Icon(
            Icons.delete_outline,
            size: 16,
            color: greyColor,
          ),
          const SizedBox(width: 4),
          Text(
            "${chat.deletedMessagesCount} ${chat.deletedMessagesCount == 1 ? 'mensaje eliminado' : 'mensajes eliminados'}",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: greyColor,
              fontStyle: FontStyle.italic,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else if (isTypingToMe) {
      return Text(
        "typing".tr,
        style: style,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      chat.lastMsg,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: greyColor, // Lighter gray for message preview
        height: 1.2,
      ),
      maxLines: 1, // Limitar a una sola línea
      overflow: TextOverflow.ellipsis,
    );
  }
}