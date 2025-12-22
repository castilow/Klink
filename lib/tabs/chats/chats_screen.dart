import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/components/floating_button.dart';
import 'package:chat_messenger/components/scale_button.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/components/loading_indicator.dart';
import 'package:chat_messenger/components/no_data.dart';
import 'package:chat_messenger/models/chat.dart';
import 'package:chat_messenger/tabs/chats/controllers/chat_controller.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/components/klink_ai_button.dart';
import 'package:chat_messenger/screens/contacts/controllers/contact_controller.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';

import 'components/chat_card.dart';
import 'components/stories_section.dart';
import 'components/chat_sections_header.dart';



class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}



class _ChatsScreenState extends State<ChatsScreen> {
  // Vars

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get controllers
    final ChatController controller = Get.find();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Static Header (Title + Logo Button)
            // 1. Static Header (Actions)
            Padding(
              padding: const EdgeInsets.only(top: 10.0, right: 16.0, bottom: 0.0), // Lowered ("bajalo")
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                      // Klink AI Button
                      const KlinkAIButton(),

                      const SizedBox(width: 12),

                      // Add Contact Button ("bton de mas")
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showNewChatModal(context);
                        },
                        child: Container(
                          width: 44,
                          height: 44, // Match KlinkAIButton size
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.black 
                                : Colors.white,
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.08),
                              width: 1.5,
                            ),
                            boxShadow: [
                               BoxShadow(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            IconlyLight.addUser, // "Add Contact" explicit icon
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : Colors.black87,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
            ),



            // 2. Stories Section
            Obx(() => StoriesSection(chats: controller.visibleChats)),

            const SizedBox(height: 15), // Separator

            // 2.5 Chat Sections (Filters)
            const ChatSectionsHeader(),

            // 3. Chat List (Expanded)
            Expanded(
              child: Obx(
                () {
                  if (controller.isLoading.value) {
                    return const LoadingIndicator();
                  } else if (controller.chats.isEmpty) {
                    return NoData(
                      iconData: IconlyBold.chat,
                      text: 'no_chats'.tr,
                      subtitle: 'Start a conversation by tapping the + button below',
                    );
                  }
                  
                  final List<Chat> chats = controller.visibleChats;

                  return AnimationLimiter(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final Chat chat = chats[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: ChatCard(
                                chat,
                                onDeleteChat: () {
                                  if (chat.groupId != null) {
                                    controller.deleteGroupChat(chat.groupId!);
                                  } else {
                                    controller.deleteChat(chat.receiver!.userId);
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

    );
  }

  void _showNewChatModal(BuildContext context) {
    // Ensure ContactController is available
    final contactController = Get.put(ContactController());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E), // Deep dark background
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), // More rounded
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Expanded(
                child: AnimationLimiter(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 375),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        // Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'New Chat',
                              style: TextStyle(
                                fontSize: 26, 
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            ScaleButton(
                              onTap: () => Get.back(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 20, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222), // Neutral dark grey
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: const Row(
                            children: [
                              Icon(IconlyLight.search, color: Colors.grey, size: 22),
                              SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                  cursorColor: Colors.white,
                                  decoration: InputDecoration(
                                    hintText: 'Search name or number',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Actions
                        _buildModalAction(
                          icon: IconlyBold.user2, 
                          gradient: const LinearGradient(
                            colors: [Color(0xFF25D366), Color(0xFF128C7E)], // WhatsApp Green
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          label: 'New Group',
                          onTap: () {
                            Get.back();
                            Get.toNamed(AppRoutes.createGroup, arguments: {'isBroadcast': false});
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildModalAction(
                          icon: IconlyBold.addUser, // Or IconlyBold.profile
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00B4DB), Color(0xFF0083B0)], // Blue Gradient
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          label: 'New Contact',
                          onTap: () {
                            Get.back();
                            Get.toNamed(AppRoutes.contacts);
                          },
                        ),

                        const SizedBox(height: 32),
                        
                        // Contacts List Header
                        const Text(
                          'SUGGESTED',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contacts List
                         Obx(() {
                          if (contactController.isLoading.value) {
                             return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
                          }
                          if (contactController.contacts.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Center(
                                child: Text(
                                  'No contacts found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            );
                          }
                          // Since we are already in AnimationLimiter's children list, we can just return the column of items
                          // But ListView.builder is efficient. 
                          // We should use a Column of items here to maintain stagger order in the main list
                          // OR use ListView.builder with physics: NeverScrollable.
                          return ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: contactController.contacts.length,
                              itemBuilder: (context, index) {
                                final contact = contactController.contacts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: ScaleButton(
                                    onTap: () {
                                      Get.back();
                                      Get.toNamed(AppRoutes.messages, arguments: contact);
                                    },
                                    child: Row(
                                      children: [
                                        Hero(
                                          tag: 'contact_${contact.userId}',
                                          child: CachedCircleAvatar(
                                            imageUrl: contact.photoUrl,
                                            radius: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                contact.fullname,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                contact.bio.isNotEmpty ? contact.bio : 'Available',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.5),
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                        }),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalAction({
    required IconData icon,
    required Gradient gradient,
    required String label,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
