import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.leading,
    this.hideLeading = false,
    this.height = 60,
    this.title,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.onBackPress,
  });

  final Widget? leading;
  final double height;
  final Widget? title;
  final bool centerTitle, hideLeading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Function()? onBackPress;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    final Color iconColor = isDarkMode ? Colors.white : Colors.black87;
    
    return AppBar(
      backgroundColor: backgroundColor,
      centerTitle: centerTitle,
      leading: hideLeading
          ? null
          : leading ??
              IconButton(
                onPressed: onBackPress ?? () => Get.back(),
                icon: Icon(
                  Icons.arrow_back_ios_new_sharp,
                  color: iconColor,
                  size: 20,
                ),
              ),
      titleSpacing: 0,
      title: title,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
