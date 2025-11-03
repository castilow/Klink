import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dialog_helper.dart';

abstract class PermissionHelper {
  /// Verificar y solicitar permisos de cámara y fotos
  static Future<bool> checkAndRequestImagePermissions() async {
    // Verificar permisos de cámara
    PermissionStatus cameraStatus = await Permission.camera.status;

    // Verificar permisos de fotos
    PermissionStatus photosStatus = await Permission.photos.status;

    // Si no están concedidos, solicitar
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }

    if (!photosStatus.isGranted) {
      photosStatus = await Permission.photos.request();
    }

    // Verificar si fueron denegados permanentemente
    if (cameraStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied) {
      await _showPermissionDeniedDialog();
      return false;
    }

    // Verificar si están concedidos
    bool allGranted = cameraStatus.isGranted && photosStatus.isGranted;

    if (!allGranted) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Se necesitan permisos de cámara y fotos para subir imágenes',
      );
    }

    return allGranted;
  }

  /// Mostrar diálogo cuando los permisos están denegados permanentemente
  static Future<void> _showPermissionDeniedDialog() async {
    return DialogHelper.showAlertDialog(
      title: const Text('Permisos Requeridos'),
      content: const Text(
        'Para subir fotos de perfil, necesitas habilitar los permisos de cámara y fotos en Configuración > Arious > Permisos',
      ),
      actionText: 'Abrir Configuración',
      action: () {
        Get.back();
        openAppSettings();
      },
      showCancelButton: true,
    );
  }

  /// Verificar estado de permisos
  static Future<Map<String, bool>> checkPermissionsStatus() async {
    return {
      'camera': await Permission.camera.isGranted,
      'photos': await Permission.photos.isGranted,
      'storage': await Permission.storage.isGranted,
    };
  }
}
