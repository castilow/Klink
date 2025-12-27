import 'package:flutter/material.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/config/theme_config.dart';

class StoryItem extends StatelessWidget {
  final String imageUrl;
  final String name;
  final bool isMe;
  final bool hasStory;
  final bool isSeen; // Add isSeen property
  final VoidCallback? onTap;

  const StoryItem({
    super.key,
    required this.imageUrl,
    required this.name,
    this.isMe = false,
    this.hasStory = true,
    this.isSeen = false, // Add isSeen
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Gradient Border Ring
                if (hasStory)
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // If seen, show simple grey border. If not, show gradient.
                      border: isSeen 
                        ? Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5)
                        : null,
                      gradient: isSeen ? null : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF00E5FF), // Cyan
                          Color(0xFF2979FF), // Blue
                          Color(0xFF6228D7), // Purple
                        ],
                      ),
                      boxShadow: isSeen ? null : [
                        BoxShadow(
                          color: const Color(0xFF2979FF).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                // Border gap
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
                // Avatar
                CachedCircleAvatar(
                  imageUrl: imageUrl,
                  radius: 29,
                ),
                // Add button for "Me" (only if no story)
                if (isMe && !hasStory)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Flexible(
              child: Text(
                isMe ? 'Your Story' : name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
