import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:camera/camera.dart';
import 'package:chat_messenger/models/chat.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/tabs/chats/components/story_item.dart';
import 'package:chat_messenger/tabs/stories/controller/story_controller.dart';
import 'package:chat_messenger/tabs/stories/story_view_screen.dart';
import 'package:chat_messenger/tabs/stories/story_camera_screen.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:get/get.dart';

class StoriesSection extends StatelessWidget {
  final List<Chat> chats;

  const StoriesSection({
    super.key,
    required this.chats,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthController.instance.currentUser;
    
    // Verificar si StoryController está disponible
    if (!Get.isRegistered<StoryController>()) {
      return const SizedBox.shrink();
    }
    
    final storyController = Get.find<StoryController>();

    return Obx(() {
      // Filtrar solo usuarios con historias activas (no expiradas)
      final activeStories = storyController.stories
          .where((story) => story.hasValidItems) // Solo historias con items válidos (< 24 horas)
          .toList();

      // Verificar si el usuario actual tiene historias activas
      final currentUserHasStory = activeStories
          .any((story) => story.userId == currentUser.userId);

      // Obtener historias de otros usuarios
      final otherStories = activeStories
          .where((s) => s.userId != currentUser.userId)
          .toList();

      // Calcular el total de items (Your Story + otros usuarios)
      final totalItems = 1 + otherStories.length;

      return Container(
        height: 110,
        margin: const EdgeInsets.only(bottom: 10),
        child: AnimationLimiter(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              // Item 0: Your Story
              if (index == 0) {
                if (currentUserHasStory) {
                  final myStory = activeStories.firstWhere(
                    (s) => s.userId == currentUser.userId,
                  );
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      horizontalOffset: 50.0,
                      child: FadeInAnimation(
                        child: StoryItem(
                          imageUrl: currentUser.photoUrl,
                          name: 'Your Story',
                          isMe: true,
                          hasStory: true,
                          onTap: () {
                            Get.bottomSheet(
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.visibility_outlined),
                                      title: const Text('Ver historia'),
                                      onTap: () {
                                        Get.back();
                                        Get.to(() => StoryViewScreen(story: myStory));
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.add_circle_outline),
                                      title: const Text('Crear otra historia'),
                                      onTap: () async {
                                        Get.back();
                                        final cameras = await availableCameras();
                                        Get.to(() => StoryCamera(cameras: cameras, isVideo: false));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                } else {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      horizontalOffset: 50.0,
                      child: FadeInAnimation(
                        child: StoryItem(
                          imageUrl: currentUser.photoUrl,
                          name: 'Your Story',
                          isMe: true,
                          hasStory: false,
                          onTap: () async {
                            final cameras = await availableCameras();
                            Get.to(() => StoryCamera(cameras: cameras, isVideo: false));
                          },
                        ),
                      ),
                    ),
                  );
                }
              }

              // Items 1..N: Other Stories
              final storyIndex = index - 1;
              final story = otherStories[storyIndex];
              final user = story.user;

              // Si por alguna razón el usuario es nulo, usar placeholders o saltar
              if (user == null) return const SizedBox.shrink();

              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: StoryItem(
                      imageUrl: user.photoUrl,
                      name: user.fullname.split(' ')[0], // First name only
                      hasStory: true,
                      onTap: () {
                        Get.to(() => StoryViewScreen(story: story));
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
