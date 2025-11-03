import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:chat_messenger/config/app_config.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../camera/camera_screen.dart';
import 'components/picker_theme.dart';

abstract class MediaHelper {
  ///
  /// Media Helper APIs
  ///
  static final BuildContext context = Get.context!;

  // Get asset from device storage
  static Future<List<File>?> getAssets({
    int maxAssets = 1,
    RequestType requestType = RequestType.image,
  }) async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: maxAssets,
        requestType: requestType,
        themeColor: primaryColor,
        textDelegate: const EnglishAssetPickerTextDelegate(),
      ),
    );

    if (result == null) return null;

    final List<File> files = [];
    for (final asset in result) {
      final File? file = await asset.file;
      if (file != null) files.add(file);
    }
    return files;
  }

  // Get GIF from GIPHY
  static Future<GiphyGif?> getGif() async {
    return await GiphyGet.getGif(
      context: context,
      apiKey: AppConfig.giphyApiKey,
      tabColor: primaryColor,
    );
  }

  // Get file from device storage
  static Future<File?> getFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null) return null;
    return File(result.files.single.path!);
  }

  // Get file mime type
  static String? getMimeType(String path) {
    return lookupMimeType(path);
  }

  // Get file name from url
  static String getFirebaseFileName(String url) {
    return url.split('/').last.split('?').first;
  }

  // Get file extension
  static String getFileExtension(String fileName) {
    return fileName.split('.').last;
  }

  // Get file size
  static Future<String> getFileSize(String filepath) async {
    final file = File(filepath);
    final int bytes = await file.length();
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Get temporary directory
  static Future<String> getTemporaryPath() async {
    final Directory tempDir = await getTemporaryDirectory();
    return tempDir.path;
  }

  // Get image from camera
  static Future<File?> getImageFromCamera() async {
    final File? file = await Get.to(() => const CameraScreen());
    if (file == null) return null;
    return file;
  }

  // Get video from camera
  static Future<File?> getVideoFromCamera() async {
    final File? file = await Get.to(() => const CameraScreen(isVideo: true));
    if (file == null) return null;
    return file;
  }

  // Crop image
  static Future<File?> cropImage(File imageFile) async {
    final bool isDarkMode = AppTheme.of(Get.context!).isDarkMode;

    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      maxWidth: 1280,
      maxHeight: 1080,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'edit_image'.tr,
          toolbarColor: primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'edit_image'.tr,
          doneButtonTitle: 'done'.tr,
          cancelButtonTitle: 'cancel'.tr,
          hidesNavigationBar: true,
        ),
      ],
    );

    if (croppedFile == null) return null;
    return File(croppedFile.path);
  }

  ///
  ///  File Extension Methods
  ///

  // Check image file
  static bool isImage(String path) {
    return _getMimeType(path).contains('image');
  }

  // Check video file
  static bool isVideo(String path) {
    return _getMimeType(path).contains('video');
  }

  // Check audio file
  static bool isAudio(String path) {
    return _getMimeType(path).contains('audio');
  }

  // Check PDF file
  static bool isPDF(String path) {
    return _getMimeType(path).contains('pdf');
  }

  // Check Excel file
  static bool isExcel(String path) {
    return _getMimeType(path).contains('excel');
  }

  // Check Doc file
  static bool isDoc(String path) {
    return _getMimeType(path).contains('doc');
  }

  // Get file mime type
  static String _getMimeType(String path) {
    return lookupMimeType(path)?.toLowerCase() ?? '';
  }

  // Pick media from gallery
  static Future<File?> pickMediaFromGallery({
    RequestType type = RequestType.common,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality ?? 100,
      );
      
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('Error picking media from gallery: $e');
      return null;
    }
  }

  // Pick video from gallery
  static Future<File?> pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // límite de 10 minutos
      );
      
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  // Format duration
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
