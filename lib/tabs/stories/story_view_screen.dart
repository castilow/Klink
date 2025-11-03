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
                                itemBuilder: (context) => [
                                  // Report option
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
                                ],
                                onSelected: (value) {
                                  if (value == 'report') {
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
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withValues(alpha: 0.8),
                                  primaryColor.withValues(alpha: 0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 10,
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
                                        fontWeight: FontWeight.w600,
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
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
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
