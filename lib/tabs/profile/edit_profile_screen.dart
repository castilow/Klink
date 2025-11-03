import 'dart:io';

import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/components/default_button.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/components/custom_appbar.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/config/theme_config.dart';

import 'controllers/edit_profile_controller.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EditProfileController controller = Get.put(EditProfileController());
    final User currentUser = AuthController.instance.currentUser;

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: CustomAppBar(
        title: Text('edit_profile'.tr),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // <--- Profile photo --->
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      // Pick image from camera/gallery
                      final File? resultFile =
                          await DialogHelper.showPickImageDialog(
                        isAvatar: true,
                      );
                      // Update file
                      controller.photoFile.value = resultFile;
                    },
                    child: Obx(() {
                      // Get file
                      final File? photoFile = controller.photoFile.value;

                      return Stack(
                        children: [
                          // Photo
                          Container(
                            child: photoFile != null
                                ? CircleAvatar(
                                    radius: 70,
                                    backgroundImage:
                                        FileImage(File(photoFile.path)),
                                  )
                                : CachedCircleAvatar(
                                    radius: 70,
                                    iconSize: 60,
                                    imageUrl: currentUser.photoUrl,
                                  ),
                          ),
                          // Icon
                          Positioned(
                            right: 0,
                            bottom: 16,
                            child: CircleAvatar(
                              backgroundColor: isDarkMode ? Colors.blue[400] : primaryColor,
                              child: Icon(
                                IconlyBold.camera,
                                color: Colors.white, 
                                size: 23,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text("profile_photo".tr,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: isDarkMode ? Colors.grey[400] : greyColor)),
                ),
                const SizedBox(height: 30),

                // <-- Fullname -->
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        IconlyLight.profile,
                        color: isDarkMode ? Colors.blue[400] : primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "fullname".tr,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller.nameController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'enter_your_fullname'.tr,
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: Icon(
                        IconlyLight.profile,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    filled: isDarkMode,
                    fillColor: isDarkMode ? const Color(0xFF1E1E1E) : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.blue[400]! : primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (String? name) {
                    if (name == null || name.trim().isEmpty) {
                      return 'enter_your_fullname'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // <-- Username -->
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => controller.isExtended.toggle(),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alternate_email,
                          color: isDarkMode ? Colors.blue[400] : primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "update_username_for_contact".tr,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Obx(
                          () => Icon(
                            controller.isExtended.value
                                ? IconlyLight.arrowUp2
                                : IconlyLight.arrowDown2,
                            color: isDarkMode ? Colors.blue[400] : primaryColor,
                            size: 18,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Obx(() {
                  if (!controller.isExtended.value) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "username_usage".tr,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: isDarkMode ? Colors.grey[300] : Colors.blue[800],
                                  fontSize: 14,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Username field
                TextFormField(
                  textInputAction: TextInputAction.search,
                  controller: controller.usernameController,
                  validator: AppHelper.usernameValidator,
                  inputFormatters: AppHelper.usernameFormatter,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'enter_your_username'.tr,
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.alternate_email,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    filled: isDarkMode,
                    fillColor: isDarkMode ? const Color(0xFF1E1E1E) : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.blue[400]! : primaryColor,
                        width: 2,
                      ),
                    ),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      child: DefaultButton(
                        height: 35,
                        text: 'check'.tr,
                        onPress: () {
                          final String username =
                              controller.usernameController.text.trim();
                          // Check input
                          if (username.isEmpty) {
                            DialogHelper.showSnackbarMessage(
                                SnackMsgType.error, "enter_your_username".tr);
                            return;
                          }
                          // Check username in database
                          UserApi.checkUsername(username: username);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Bio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDarkMode ? Colors.blue[400] : primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "bio".tr,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  maxLines: 2,
                  controller: controller.bioController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'about_you'.tr,
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.info_outline,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    filled: isDarkMode,
                    fillColor: isDarkMode ? const Color(0xFF1E1E1E) : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.blue[400]! : primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'about_you'.tr;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: defaultPadding * 2,
          ),
          child: DefaultButton(
            height: 45,
            isLoading: controller.isLoading.value,
            width: double.maxFinite,
            text: 'update_account'.tr.toUpperCase(),
            onPress: () => controller.updateAccount(),
          ),
        ),
      ),
    );
  }
}
