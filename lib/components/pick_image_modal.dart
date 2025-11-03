import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/helpers/permission_helper.dart';

class PickImageModal extends StatelessWidget {
  const PickImageModal({super.key, required this.isAvatar});

  final bool isAvatar;

  // Handle picked image
  Future<File?> _pickAndCropImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source);

      if (pickedFile != null) {
        // Set aspect ratio list
        final aspectRatioList = [
          isAvatar
              ? CropAspectRatioPreset.square
              : CropAspectRatioPreset.original,
        ];

        // Crop the image
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          maxWidth: 640,
          maxHeight: 960,
          compressQuality: 100,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'crop_image'.tr,
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: aspectRatioList,
            ),
            IOSUiSettings(
              title: 'crop_image'.tr,
              aspectRatioPresets: aspectRatioList,
            ),
          ],
        );

        if (croppedFile == null) return null;

        return File(croppedFile.path);
      }
    } catch (e) {
      print('Error picking/cropping image: $e');
      // Notificaciones deshabilitadas
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(defaultRadius),
          topRight: Radius.circular(defaultRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: const EdgeInsets.only(left: 8.0),
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'photo'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close, 
                  color: isDarkMode ? Colors.grey[400] : greyColor,
                ),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          Divider(
            height: 0,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          ListTile(
            leading: Icon(
              IconlyLight.image,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            title: Text(
              'gallery'.tr,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            onTap: () async {
              // Verificar permisos primero
              bool hasPermissions =
                  await PermissionHelper.checkAndRequestImagePermissions();
              if (hasPermissions) {
                File? croppedImage = await _pickAndCropImage(
                  ImageSource.gallery,
                );
                Get.back(result: croppedImage);
              } else {
                Get.back(); // Cerrar modal si no hay permisos
              }
            },
          ),
          ListTile(
            leading: Icon(
              IconlyLight.camera,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            title: Text(
              'camera'.tr,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            onTap: () async {
              // Verificar permisos primero
              bool hasPermissions =
                  await PermissionHelper.checkAndRequestImagePermissions();
              if (hasPermissions) {
                File? croppedImage = await _pickAndCropImage(
                  ImageSource.camera,
                );
                Get.back(result: croppedImage);
              } else {
                Get.back(); // Cerrar modal si no hay permisos
              }
            },
          ),
        ],
      ),
    );
  }
}
