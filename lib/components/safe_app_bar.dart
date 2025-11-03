import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SafeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final double elevation;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const SafeAppBar({
    super.key,
    required this.title,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = false,
    this.elevation = 0,
    this.leading,
    this.automaticallyImplyLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading ?? (Navigator.canPop(context) ? IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: foregroundColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          size: 20,
        ),
        onPressed: () {
          Get.back();
        },
      ) : null),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 