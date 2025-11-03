import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/components/global_search_bar.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:flutter/services.dart';

class CommonHeader extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showSearch;
  final bool showProfile;
  final bool showCards;
  final VoidCallback? onProfileTap;
  final VoidCallback? onCardsTap;
  
  const CommonHeader({
    Key? key,
    this.title,
    this.actions,
    this.showSearch = true,
    this.showProfile = true,
    this.showCards = true,
    this.onProfileTap,
    this.onCardsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    final User currentUser = AuthController.instance.currentUser;

    return SafeArea(
      child: Container(
        height: 80,
        padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
        child: Row(
          children: [
            // Profile button
            if (showProfile)
              GestureDetector(
                onTap: onProfileTap ?? () {
                  HapticFeedback.lightImpact();
                  Get.toNamed(AppRoutes.profile);
                },
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedCircleAvatar(
                      imageUrl: currentUser.photoUrl,
                      iconSize: currentUser.photoUrl.isEmpty ? 14 : null,
                      radius: 20,
                    ),
                  ),
                ),
              ),
            
            if (showProfile) const SizedBox(width: 12),
            
            // Title or Search field
            Expanded(
              child: title != null
                ? Text(
                    title!,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : showSearch
                  ? GlobalSearchBar(showInHeader: true)
                  : const SizedBox.shrink(),
            ),
            
            // Actions
            if (actions != null) ...[
              const SizedBox(width: 12),
              ...actions!,
            ],
            
            // Cards button
            if (showCards) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onCardsTap ?? () {
                  HapticFeedback.lightImpact();
                  Get.toNamed(AppRoutes.cardList);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1C1C1E)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                    border: isDarkMode
                        ? Border.all(
                            color: const Color(0xFF404040).withOpacity(0.6),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Icon(
                    Icons.credit_card,
                    color: isDarkMode
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
