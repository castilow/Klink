import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:get/get.dart';

class BasicInfo extends StatelessWidget {
  const BasicInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Obx(() {
      final User currentUser = AuthController.instance.currentUser;

      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding / 2,
        ),
        child: Row(
          children: [
            // Profile photo
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.editProfile, arguments: {'user': currentUser}),
              child: CachedCircleAvatar(
                radius: 50,
                iconSize: 60,
                borderColor: primaryColor,
                backgroundColor: primaryColor,
                imageUrl: currentUser.photoUrl,
              ),
            ),
            const SizedBox(width: 10),
            // Basic info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser.fullname,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDarkMode ? Colors.white : null,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.editProfile, arguments: {'user': currentUser}),
                    child: Text(
                      '@${currentUser.username}',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: isDarkMode ? Colors.blue[400] : primaryColor, 
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser.bio,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDarkMode ? Colors.grey[300] : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Trailing
            IconButton(
              onPressed: () => Get.toNamed(AppRoutes.editProfile, arguments: {'user': currentUser}),
              icon: Icon(
                IconlyLight.editSquare,
                color: isDarkMode ? Colors.blue[400] : primaryColor,
              ),
            ),
          ],
        ),
      );
    });
  }
}
