import 'package:flutter/material.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:get/get.dart';

import '../controllers/contact_controller.dart';

class ContactCard extends GetView<ContactController> {
  const ContactCard({
    super.key,
    required this.user,
    required this.onPress,
  });

  final User user;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    return GestureDetector(
      onTap: onPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? darkDividerColor : lightDividerColor,
            ),
          ),
        ),
        child: Row(
          children: [
            CachedCircleAvatar(
              imageUrl: user.photoUrl,
              radius: 28,
              isOnline: user.isOnline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullname,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(
                          color: isDarkMode 
                              ? darkThemeSecondaryText 
                              : lightThemeSecondaryText,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
