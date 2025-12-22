import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/tabs/chats/controllers/chat_controller.dart';

class ChatSectionsHeader extends StatelessWidget {
  const ChatSectionsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.find<ChatController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme-aware colors for Plus Button
    final plusBtnColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final plusBtnBorder = isDark ? const Color(0xFF2C2C2E) : Colors.transparent;
    final plusIconColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    
    // Shadow for plus button in light mode
    final List<BoxShadow>? plusBtnShadow = isDark ? null : [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];

    return Container(
      height: 34, // Ultra compact
      margin: const EdgeInsets.only(bottom: 8),
      child: Obx(() => ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            context,
            label: 'Todos',
            isSelected: controller.activeFilter.value == ChatFilter.all,
            onTap: () => controller.setFilter(ChatFilter.all),
          ),
          const SizedBox(width: 10), // Balanced spacing
          _buildFilterChip(
             context,
             label: 'No leídos',
             count: controller.unreadCount,
             isSelected: controller.activeFilter.value == ChatFilter.unread,
             onTap: () => controller.setFilter(ChatFilter.unread),
          ),
          const SizedBox(width: 10),
           _buildFilterChip(
             context,
            label: 'Archivados',
            isSelected: controller.activeFilter.value == ChatFilter.archived,
            onTap: () => controller.setFilter(ChatFilter.archived),
          ),
          const SizedBox(width: 10),
          _buildFilterChip(
             context,
            label: 'Grupos',
            count: controller.groupsCount,
            isSelected: controller.activeFilter.value == ChatFilter.groups,
            onTap: () => controller.setFilter(ChatFilter.groups),
          ),
           const SizedBox(width: 10),
           // Plus Button
           GestureDetector(
             onTap: () {},
             child: Container(
               width: 30, // Smaller
               height: 30, 
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: plusBtnColor,
                 border: Border.all(color: plusBtnBorder),
                 boxShadow: plusBtnShadow,
               ),
               child: Icon(Icons.add, color: plusIconColor, size: 16),
             ),
           ),
        ],
      )),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    bool isSelected = false,
    int? count,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Klink Premium Compact Style
    final selectedBg = const Color(0xFF00E5FF).withOpacity(0.12); 
    final selectedText = const Color(0xFF00E5FF); 
    
    // Theme-aware unselected colors
    final unselectedBg = isDark ? const Color(0xFF2C2C2E) : Colors.white; 
    final unselectedBorder = isDark ? Colors.white.withOpacity(0.08) : Colors.transparent; // No border in light mode if using shadow
    final unselectedText = isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1C1C1E);
    final unselectedCountColor = isDark ? Colors.white54 : Colors.grey[600];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Minimal vertical padding
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(
            color: isSelected ? selectedText.withOpacity(0.2) : unselectedBorder,
            width: 0.5, // Thinner border
          ),
          boxShadow: [
            if (!isDark && !isSelected) // Add shadow in light mode for "pill" look
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5, // Crisp small font
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? selectedText : unselectedText,
                height: 1.2, // Tighter line height
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              // Simplified count badge (no background, just colored text)
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? selectedText.withOpacity(0.8) : unselectedCountColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
