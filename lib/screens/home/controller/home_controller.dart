import 'package:chat_messenger/screens/contacts/controllers/contact_controller.dart';
import 'package:chat_messenger/tabs/chats/controllers/chat_controller.dart';
import 'package:chat_messenger/tabs/groups/controllers/group_controller.dart';
import 'package:chat_messenger/tabs/stories/controller/story_controller.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/tabs/stories/stories_screen.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/tabs/chats/chats_screen.dart';
import 'package:chat_messenger/screens/dashboard_screen.dart';
import 'package:chat_messenger/screens/cards_screen.dart';
import 'package:chat_messenger/screens/investment_screen.dart';

class HomeController extends GetxController {
  // Vars
  final RxInt pageIndex = 0.obs;

  // List of tab pages (Calls tab removed)
  final List<Widget> pages = [
    const ChatsScreen(),
    const DashboardScreen(),
    const StoriesScreen(),
    const InvestmentScreen(),
    const CardsScreen(),
  ];

  @override
  void onInit() {
    Get.put(ContactController(), permanent: true);
    Get.put(ChatController(), permanent: true);
    Get.put(GroupController(), permanent: true);
    Get.put(StoryController(), permanent: true);
    super.onInit();
  }
}
