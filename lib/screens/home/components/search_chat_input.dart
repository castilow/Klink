import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/components/circle_button.dart';
import 'package:chat_messenger/tabs/chats/controllers/chat_controller.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:get/get.dart';

class SearchChatInput extends GetView<ChatController> {
  const SearchChatInput({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;

    return Obx(
      () {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: TextField(
            controller: controller.searchController,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              controller.searchChat();
            },
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            decoration: InputDecoration(
              hintText: 'search_chats'.tr,
              hintStyle: TextStyle(
                color: isDarkMode 
                  ? Colors.white.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.6),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 8, right: 12),
                child: Icon(
                  IconlyLight.search,
                  color: isDarkMode 
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.withOpacity(0.8),
                  size: 24,
                ),
              ),
              suffixIcon: controller.isSearching.value
                  ? Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            controller.clearSerachInput(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.close_rounded,
                              color: isDarkMode 
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey.withOpacity(0.8),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Icon(
                        IconlyLight.filter,
                        color: isDarkMode 
                          ? Colors.white.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.5),
                        size: 20,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
