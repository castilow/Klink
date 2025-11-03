import 'package:flutter/material.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';

class MessageReactions extends StatelessWidget {
  const MessageReactions({
    super.key,
    required this.message,
    required this.onReactionTap,
    required this.isSender,
  });

  final Message message;
  final Function(String emoji) onReactionTap;
  final bool isSender;

  @override
  Widget build(BuildContext context) {
    if (message.reactions == null || message.reactions!.isEmpty) {
      return const SizedBox.shrink();
    }

    final reactions = message.reactions!;
    final currentUserId = AuthController.instance.currentUser.userId;

    return Container(
      margin: EdgeInsets.only(
        top: 4,
        left: isSender ? 50 : 0,
        right: isSender ? 0 : 50,
      ),
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactions.entries.map((entry) {
          final emoji = entry.key;
          final userIds = entry.value;
          final count = userIds.length;
          final isReactedByMe = userIds.contains(currentUserId);

          return _buildReactionChip(
            emoji: emoji,
            count: count,
            isReactedByMe: isReactedByMe,
            onTap: () => onReactionTap(emoji),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReactionChip({
    required String emoji,
    required int count,
    required bool isReactedByMe,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isReactedByMe 
              ? primaryColor.withOpacity(0.15) 
              : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isReactedByMe 
                ? primaryColor.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 14),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isReactedByMe ? primaryColor : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 