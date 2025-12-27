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
  const StoryViewScreen({super.key, required this.story, this.onStoryComplete});

  final Story story;
  final VoidCallback? onStoryComplete;

  @override
  Widget build(BuildContext context) {
    // Use a unique tag based on story ID to ensure each page has its own controller
    final controller = Get.put(StoryViewController(story: story), tag: story.id);
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
          // Story View
          // Wrap in ExcludeSemantics to prevent 'parentDataDirty' errors during PageView scroll
          ExcludeSemantics(
            child: StoryView(
              storyItems: controller.storyItems,
              controller: controller.storyController,
              onComplete: () {
                if (onStoryComplete != null) {
                  onStoryComplete!();
                } else {
                  Get.back();
                }
              },
              onStoryShow: (StoryItem item, index) {
                controller.getStoryItemIndex(index);
                controller.markSeen();
              },
            ),
          ),
          
          // Gradients for legibility
          Positioned.fill(
            child: Column(
              children: [
                // Top gradient - Smoother and less intrusive
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                const Spacer(),
                // Bottom gradient - Smoother
                Container(
                  height: 250, // Increased height for safe area coverage
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.0, 0.5, 0.8, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Clean Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(top: topMargin),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                     // Back button
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        IconlyLight.arrowLeft2,
                        color: Colors.white,
                        size: iconSize,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.2),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    
                    // User info
                    GestureDetector(
                      onTap: () {
                        RoutesHelper.toProfileView(user, false).then(
                          (value) => Get.back(),
                        );
                      },
                      child: Hero(
                        tag: 'story_avatar_${story.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: CachedCircleAvatar(
                            radius: avatarRadius - 2,
                            imageUrl: user.photoUrl,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 10),
                    
                    // Name and Metadata (Two - Line Layout)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line 1: Username
                          Text(
                            user.fullname,
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 1), // Subtle spacing
                          
                          // Line 2: Time • Music
                          Row(
                            children: [
                              Text(
                                story.updatedAt != null 
                                    ? story.updatedAt!.formatDateTime
                                    : 'now'.tr,
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              // Music Info
                              Obx(() {
                                final music = controller.currentMusic;
                                if (music == null) return const SizedBox.shrink();
                                return Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        " • ",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900, // Thicker dot
                                        ),
                                      ),
                                      Icon(
                                        Icons.music_note_rounded,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 11,
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          music.trackName,
                                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                            color: Colors.white.withOpacity(0.95), // Slightly brighter
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.5),
                                                offset: const Offset(0, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // More Button Only (Chat moved to bottom)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              cardColor: const Color(0xFF1E1E1E),
                              popupMenuTheme: PopupMenuThemeData(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.1), 
                                    width: 0.5
                                  ),
                                ),
                              ),
                            ),
                            child: PopupMenuButton<String>(
                              icon: Icon(
                                IconlyBold.moreCircle,
                                color: Colors.white,
                                size: iconSize,
                              ),
                              padding: EdgeInsets.zero,
                              offset: const Offset(0, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              itemBuilder: (context) {
                                final List<PopupMenuEntry<String>> items = [];
                                
                                if (story.isOwner) {
                                  items.add(
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(IconlyBold.delete, color: Colors.red, size: 20),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Eliminar historia',
                                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                
                                if (!story.isOwner) {
                                  items.add(
                                    PopupMenuItem<String>(
                                      value: 'report',
                                      child: Row(
                                        children: [
                                          const Icon(IconlyBold.infoCircle, color: Colors.red, size: 20),
                                          const SizedBox(width: 12),
                                          Text(
                                            'report'.tr,
                                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
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
                                  final confirm = await Get.dialog<bool>(
                                    AlertDialog(
                                      backgroundColor: const Color(0xFF1E1E1E),
                                      title: const Text('Eliminar historia', style: TextStyle(color: Colors.white)),
                                      content: const Text(
                                        '¿Estás seguro de que quieres eliminar esta historia? Esta acción no se puede deshacer.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(result: false),
                                          child: Text('Cancelar'.tr, style: const TextStyle(color: Colors.white)),
                                        ),
                                        TextButton(
                                          onPressed: () => Get.back(result: true),
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  
                                  if (confirm == true) {
                                    await StoryApi.deleteStory(story: story);
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          

          
          // Unified Bottom Footer (Input + Actions)
          Positioned(
            bottom: bottomPadding,
            left: horizontalPadding,
            right: horizontalPadding,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)), // Slide from bottom
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Row(
                children: [
                  // Input Field (Navigates to Chat)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Pause story if needed, then navigate
                        controller.storyController.pause();
                        RoutesHelper.toMessages(user: user).then((value) {
                          controller.storyController.play();
                        });
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Increased blur
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.0), // Subtle border
                              color: Colors.black.withOpacity(0.2),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.12),
                                  Colors.white.withOpacity(0.06),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Enviar mensaje...",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Like Button
                  _buildGlassActionButton(
                    icon: IconlyBold.heart,
                    onTap: () {
                      // Like logic
                      controller.storyController.pause(); // Optional: pause for effect
                      // Implement like logic here
                      Future.delayed(const Duration(milliseconds: 200), () {
                        controller.storyController.play();
                      });
                    },
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Share Button
                  _buildGlassActionButton(
                    icon: IconlyBold.send,
                    onTap: () {
                      // Share logic
                      controller.storyController.pause();
                      // Implement share logic here
                      // Example: Share.share(...)
                      Future.delayed(const Duration(milliseconds: 500), () {
                         controller.storyController.play();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Increased blur
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.12), // Subtle border
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.06),
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: Icon(
                icon,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
