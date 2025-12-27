import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/components/custom_appbar.dart';
import 'package:chat_messenger/components/floating_button.dart';
import 'package:chat_messenger/components/loading_indicator.dart';
import 'package:chat_messenger/components/no_data.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/helpers/routes_helper.dart';
import 'package:chat_messenger/screens/contacts/controllers/contact_controller.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:get/get.dart';

import 'components/contact_card.dart';
import '../../tabs/chats/components/chat_search_bar.dart';

class ContactsScreen extends GetView<ContactController> {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    "contacts".tr,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar (Visual trigger)
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.contactSearch),
                    child: Container(
                       height: 40,
                       decoration: BoxDecoration(
                         color: isDarkMode
                             ? const Color(0xFF2A2A2A)
                             : const Color(0xFFF1F5F9),
                         borderRadius: BorderRadius.circular(12),
                         border: isDarkMode
                             ? Border.all(
                                 color: const Color(0xFF404040).withOpacity(0.6),
                                 width: 1,
                               )
                             : null,
                       ),
                       padding: const EdgeInsets.symmetric(horizontal: 16),
                       child: Row(
                         children: [
                           Icon(
                             IconlyLight.search,
                             color: isDarkMode
                                 ? const Color(0xFF9CA3AF)
                                 : const Color(0xFF64748B),
                             size: 20,
                           ),
                           const SizedBox(width: 12),
                           Text(
                             'search'.tr,
                             style: TextStyle(
                               color: isDarkMode
                                   ? const Color(0xFF9CA3AF)
                                   : const Color(0xFF64748B),
                               fontSize: 16,
                             ),
                           ),
                         ],
                       ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact List
            Expanded(
              child: Obx(() {
                // Check loading
                if (controller.isLoading.value) {
                  return const LoadingIndicator();
                } else if (controller.contacts.isEmpty) {
                  return NoData(
                    iconData: IconlyBold.profile,
                    text: 'no_contacts'.tr,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.contacts.length,
                  itemBuilder: (context, index) {
                    final User user = controller.contacts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ContactCard(
                        user: user,
                        onPress: () {
                          Get.back();
                          RoutesHelper.toMessages(user: user);
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => Get.toNamed(AppRoutes.contactSearch),
          elevation: 0,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: const Icon(IconlyBold.addUser, color: Colors.white),
        ),
      ),
    );
  }
}
