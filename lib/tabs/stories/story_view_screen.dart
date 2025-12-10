import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/report_controller.dart';
import 'package:chat_messenger/api/report_api.dart';
import 'package:chat_messenger/helpers/date_helper.dart';

import 'package:chat_messenger/helpers/routes_helper.dart';
import 'package:chat_messenger/models/story/story.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/tabs/stories/controller/story_view_controller.dart';
import 'package:chat_messenger/api/story_api.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:get/get.dart';
import 'package:story_view/story_view.dart';
import 'dart:ui';

class StoryViewScreen extends StatelessWidget {
  const StoryViewScreen({super.key, required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoryViewController(story: story));
    final ReportController reportController = Get.find();
    final User user = story.user!;
    
    final screenWidth = MediaQuery.of(context).size.width;

    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    
    // Responsive sizing
    final topMargin = MediaQuery.of(context).padding.top + (isTablet ? 24 : 20);
    final avatarRadius = isLargeScreen ? 28.0 : (isTablet ? 24.0 : 20.0);
    final iconSize = isLargeScreen ? 32.0 : (isTablet ? 28.0 : 24.0);
    final chatIconSize = isLargeScreen ? 40.0 : (isTablet ? 36.0 : 32.0);
    final textFontSize = isLargeScreen ? 20.0 : (isTablet ? 18.0 : 16.0);
    final timeFontSize = isLargeScreen ? 16.0 : (isTablet ? 14.0 : 12.0);
    final horizontalPadding = isTablet ? 20.0 : 16.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom + (isTablet ? 28 : 20);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Enhanced Story View with blur background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: StoryView(
              storyItems: controller.storyItems,
              controller: controller.storyController,
              onComplete: () => Get.back(),
              onStoryShow: (StoryItem item, index) {
                controller.getStoryItemIndex(index);
                controller.markSeen();
              },
            ),
          ),
          
          // Enhanced header with glassmorphism effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: EdgeInsets.only(top: topMargin),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 16 : 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Enhanced back button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => Get.back(),
                            icon: Icon(
                              IconlyLight.arrowLeft2,
                              color: Colors.white,
                              size: iconSize,
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        
                        // Enhanced profile avatar with glow effect
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.8),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              RoutesHelper.toProfileView(user, false).then(
                                (value) => Get.back(),
                              );
                            },
                            child: CachedCircleAvatar(
                              radius: avatarRadius,
                              imageUrl: user.photoUrl,
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        
                        // Enhanced user info
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile name with enhanced styling
                              Text(
                                user.fullname,
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  color: Colors.white,
                                  fontSize: textFontSize,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      offset: const Offset(1, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isTablet ? 4 : 2),
                              // Time with enhanced styling
                              Text(
                                story.updatedAt != null 
                                    ? story.updatedAt!.formatDateTime
                                    : 'now'.tr,
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: timeFontSize,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      offset: const Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Enhanced action buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Enhanced chat button
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor,
                                    primaryColor.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  RoutesHelper.toMessages(user: user).then((value) => Get.back());
                                },
                                icon: Icon(
                                  IconlyBold.chat,
                                  color: Colors.white,
                                  size: chatIconSize * 0.6,
                                ),
                              ),
                            ),
                            SizedBox(width: isTablet ? 12 : 8),
                            
                            // Enhanced more options button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: PopupMenuButton<String>(
                                icon: Icon(
                                  IconlyBold.moreCircle,
                                  color: Colors.white,
                                  size: iconSize,
                                ),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                ),
                                itemBuilder: (context) {
                                  final List<PopupMenuEntry<String>> items = [];
                                  
                                  // Delete option (solo si es el dueño)
                                  if (story.isOwner) {
                                    items.add(
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              IconlyBold.delete,
                                              color: Colors.red,
                                              size: isTablet ? 20 : 18,
                                            ),
                                            SizedBox(width: isTablet ? 12 : 8),
                                            Text(
                                              'Eliminar historia',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: isTablet ? 16 : 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  // Report option (solo si NO es el dueño)
                                  if (!story.isOwner) {
                                    items.add(
                                      PopupMenuItem<String>(
                                        value: 'report',
                                        child: Row(
                                          children: [
                                            Icon(
                                              IconlyBold.infoCircle,
                                              color: Colors.red,
                                              size: isTablet ? 20 : 18,
                                            ),
                                            SizedBox(width: isTablet ? 12 : 8),
                                            Text(
                                              'report'.tr,
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: isTablet ? 16 : 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  return items;
                                },
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    // Mostrar diálogo de confirmación
                                    final confirm = await Get.dialog<bool>(
                                      AlertDialog(
                                        title: const Text('Eliminar historia'),
                                        content: const Text('¿Estás seguro de que quieres eliminar esta historia? Esta acción no se puede deshacer.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Get.back(result: false),
                                            child: Text('Cancelar'.tr),
                                          ),
                                          TextButton(
                                            onPressed: () => Get.back(result: true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    
                                    if (confirm == true) {
                                      // Eliminar la historia
                                      await StoryApi.deleteStory(story: story);
                                      // Cerrar la pantalla
                                      Get.back();
                                    }
                                  } else if (value == 'report') {
                                    reportController.reportDialog(
                                      type: ReportType.story,
                                      story: story.toMap(),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Music info overlay (si hay música en el item actual)
          Obx(() {
            final music = controller.currentMusic;
            if (music == null) return const SizedBox.shrink();
            
            return Positioned(
              bottom: bottomPadding + 80, // Encima de los botones de acción
              left: horizontalPadding,
              right: horizontalPadding,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 16 : 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: const Color(0xFF00E5FF),
                            size: isTablet ? 24 : 20,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                music.trackName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                music.artistName,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isTablet ? 14 : 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Equalizer animation placeholder
                        Row(
                          children: List.generate(3, (index) => 
                            Container(
                              width: 3,
                              height: 12 + (index % 2 * 8),
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          
          // Enhanced bottom actions with glassmorphism
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: EdgeInsets.only(bottom: bottomPadding),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Enhanced like button
                        Expanded(
                          child: Container(
                            height: isTablet ? 56 : 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00E5FF), // Cyan
                                  Color(0xFF2979FF), // Blue
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2979FF).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                onTap: () {
                                  // Like action
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      IconlyBold.heart,
                                      color: Colors.white,
                                      size: isTablet ? 24 : 20,
                                    ),
                                    SizedBox(width: isTablet ? 8 : 6),
                                    Text(
                                      'like'.tr,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 16 : 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        
                        // Enhanced share button
                        Expanded(
                          child: Container(
                            height: isTablet ? 56 : 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                onTap: () {
                                  // Share action
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      IconlyBold.send,
                                      color: Colors.white,
                                      size: isTablet ? 24 : 20,
                                    ),
                                    SizedBox(width: isTablet ? 8 : 6),
                                    Text(
                                      'share'.tr,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 16 : 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
