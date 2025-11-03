import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/screens/languages/languages_screen.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/api/auth_api.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Vars
    final PreferencesController prefController = Get.find();
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    
    // Safe access to current user
    User currentUser;
    try {
      currentUser = AuthController.instance.currentUser;
    } catch (e) {
      // Fallback to default user if there's an error
      currentUser = User(
        userId: '',
        fullname: 'Usuario',
        username: 'usuario',
        photoUrl: '',
        email: 'usuario@email.com',
        bio: '',
        isOnline: false,
        deviceToken: '',
        status: 'active',
        loginProvider: LoginProvider.email,
        isTyping: false,
        typingTo: '',
        isRecording: false,
        recordingTo: '',
        mutedGroups: const [],
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
        elevation: 0,
        title: Text(
          'Ajustes',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            vertical: defaultPadding,
            horizontal: defaultPadding / 2,
          ),
          child: Column(
            children: [
              // <-- Profile Header Section -->
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Picture and Name
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.editProfile, arguments: {'user': AuthController.instance.currentUser}),
                      child: Column(
                        children: [
                          // Profile Picture
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Obx(() {
                                try {
                                  final user = AuthController.instance.currentUser;
                                  return user.photoUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: user.photoUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                          child: Icon(
                                            Icons.person,
                                            size: 40,
                                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                          child: Icon(
                                            Icons.person,
                                            size: 40,
                                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                        child: Icon(
                                          Icons.person,
                                          size: 40,
                                          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                        ),
                                      );
                                } catch (e) {
                                  return Container(
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                    child: Icon(
                                      Icons.person,
                                      size: 40,
                                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                    ),
                                  );
                                }
                              }),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Name
                          Obx(() {
                            try {
                              final user = AuthController.instance.currentUser;
                              return Text(
                                user.fullname.isNotEmpty ? user.fullname : 'Usuario',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              );
                            } catch (e) {
                              return Text(
                                'Usuario',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              );
                            }
                          }),
                          const SizedBox(height: 4),
                          // Username only
                          Obx(() {
                            try {
                              final user = AuthController.instance.currentUser;
                              return Text(
                                user.username.isNotEmpty ? '@${user.username}' : '@usuario',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                                ),
                              );
                            } catch (e) {
                              return Text(
                                '@usuario',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                                ),
                              );
                            }
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // <-- Profile Options -->
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.blue[700] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: isDarkMode ? Colors.white : Colors.blue[700],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Cambiar foto de perfil',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 16,
                  ),
                  onTap: () => Get.toNamed(AppRoutes.editProfile, arguments: {'user': AuthController.instance.currentUser}),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // <-- My Profile Section -->
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.red[700] : Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      color: isDarkMode ? Colors.white : Colors.red[700],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Mi perfil',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 16,
                  ),
                  onTap: () => Get.toNamed(AppRoutes.editProfile, arguments: {'user': AuthController.instance.currentUser}),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // <-- Appearance Section -->
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.purple[700] : Colors.purple[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.palette,
                      color: isDarkMode ? Colors.white : Colors.purple[700],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Apariencia',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Obx(() {
                    final bool dark = prefController.isDarkMode.value;
                    final bool hasCustomPreference = prefController.hasCustomThemePreference;
                    
                    if (!hasCustomPreference) {
                      return Text(
                        'Automático',
                        style: TextStyle(
                          color: isDarkMode ? Colors.green[400] : Colors.green[600],
                        ),
                      );
                    } else if (dark) {
                      return Text(
                        'Modo Oscuro',
                        style: TextStyle(
                          color: isDarkMode ? Colors.purple[400] : Colors.purple[600],
                        ),
                      );
                    } else {
                      return Text(
                        'Modo Claro',
                        style: TextStyle(
                          color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                        ),
                      );
                    }
                  }),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 16,
                  ),
                  onTap: () => Get.toNamed(AppRoutes.appearance),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // <-- Other Settings -->
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Change Language
                    Obx(() {
                      final String langName = prefController.langName;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.blue[700] : Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.translate,
                            color: isDarkMode ? Colors.white : Colors.blue[700],
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'language'.tr,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: langName.isNotEmpty ? Text(
                          langName,
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ) : null,
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          size: 16,
                        ),
                        onTap: () => Get.to(() => const LanguagesScreen()),
                      );
                    }),
                    
                    Divider(
                      height: 1,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      indent: 56,
                    ),
                    
                    // Terms of Service
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.green[700] : Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          IconlyLight.paper,
                          color: isDarkMode ? Colors.white : Colors.green[700],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'terms_of_service'.tr,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 16,
                      ),
                      onTap: () => AppHelper.openTermsPage(),
                    ),
                    
                    Divider(
                      height: 1,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      indent: 56,
                    ),
                    
                    // Privacy Policy
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.orange[700] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          IconlyLight.lock,
                          color: isDarkMode ? Colors.white : Colors.orange[700],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'privacy_policy'.tr,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 16,
                      ),
                      onTap: () => AppHelper.openPrivacyPage(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // <-- Logout Section -->
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.red[700]! : Colors.red[200]!,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.red[700] : Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: isDarkMode ? Colors.white : Colors.red[700],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'sign_out'.tr,
                    style: TextStyle(
                      color: isDarkMode ? Colors.red[400] : Colors.red[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => AuthApi.signOut(),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
