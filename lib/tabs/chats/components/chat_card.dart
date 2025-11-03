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

    return Dismissible(
      key: Key(chat.receiver!.userId),
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
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete,
              color: Colors.white,
              size: 30,
            ),
            SizedBox(height: 4),
            Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? greyLight.withOpacity(0.10) : greyLight,
              ),
            ),
          ),
          child: StreamBuilder<User>(
            stream: UserApi.getUserUpdates(user.userId),
            builder: (context, snapshot) {
              updatedUser = snapshot.data;
              final User receiver = updatedUser ?? user;

              return Row(
                children: [
                  CachedCircleAvatar(
                    imageUrl: receiver.photoUrl,
                    radius: 28,
                    isOnline: receiver.isOnline,
                    borderColor: chat.unread > 0 ? primaryColor : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              receiver.fullname,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SentTime(
                              time: chat.isDeleted ? chat.updatedAt : chat.sentAt,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: LastMessage(chat: chat, user: receiver),
                            ),
                            if (chat.isMuted) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.volume_off,
                                color: greyColor,
                                size: 16,
                              ),
                            ],
                            const SizedBox(width: 8),
                            BadgeCount(
                              counter: chat.unread,
                              bgColor: const Color(0xFFfa4e1c),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
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

    return Expanded(
      child: Text(
        chat.lastMsg,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 1, // Limitar a una sola línea
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}