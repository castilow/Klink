import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:get/get.dart';

class ProfilePhotoPicker extends StatelessWidget {
  final File? photoFile;
  final Function(File) onImageSelected;

  const ProfilePhotoPicker({
    super.key,
    this.photoFile,
    required this.onImageSelected,
  });

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        onImageSelected(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      // Notificaciones deshabilitadas
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        child: photoFile != null
            ? ClipOval(
                child: Image.file(
                  photoFile!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                IconlyLight.camera,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
      ),
    );
  }
} 