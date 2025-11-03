// lib/screens/record-video/controller/record_video_controller.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';

class RecordVideoController extends GetxController {
  // ─────────── STATE ───────────

  /// Si estamos en un simulador iOS (no inicializamos cámara)
  final RxBool isSimulator = false.obs;

  /// Indica si la cámara ya está inicializada correctamente
  final RxBool isCameraInitialized = false.obs;

  /// Indica si en este momento se está grabando
  final RxBool isRecording = false.obs;

  /// Indica si el flash está encendido
  final RxBool isFlashOn = false.obs;

  /// Indica si estamos usando la cámara trasera
  final RxBool isRearCamera = true.obs;

  // Permisos
  final RxBool hasCameraAccess       = false.obs;
  final RxBool isCameraDeniedForever = false.obs;
  final RxBool hasMicrophoneAccess   = false.obs;
  final RxBool isMicDeniedForever    = false.obs;

  // Controlador de cámara y lista de cámaras disponibles
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  final RxInt selectedCamera = 0.obs;

  // Contador de duración del video (en segundos)
  final RxInt videoCounter = 0.obs;
  Timer? _timer;

  bool get permissionsGranted =>
      hasCameraAccess.value && hasMicrophoneAccess.value;

  // ─────────── LIFE-CYCLE ───────────

  @override
  void onInit() {
    super.onInit();
    _checkIfSimulator();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    _timer?.cancel();
    super.onClose();
  }

  // ─────────── INITIALIZATION ───────────

  Future<void> _checkIfSimulator() async {
    if (GetPlatform.isIOS) {
      final deviceInfo = await DeviceInfoPlugin().iosInfo;
      isSimulator.value = deviceInfo.isPhysicalDevice == false;
    }
    requestCameraPermission();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      cameraController = CameraController(
        cameras[selectedCamera.value],
        ResolutionPreset.high,
        enableAudio: true,
      );
      await cameraController!.initialize();
      isCameraInitialized.value = true;
      cameraController!.setFlashMode(FlashMode.off);
    } catch (e) {
      debugPrint('_initializeCamera() -> error: $e');
    }
  }

  // ─────────── PERMISSIONS ───────────

  Future<void> requestCameraPermission() async {
    if (isSimulator.value) {
      // En simulador no pedimos permisos, forzamos a false
      hasCameraAccess.value = false;
      return;
    }

    final status = await Permission.camera.status;
    if (status.isGranted) {
      hasCameraAccess.value = true;
    } else if (status.isPermanentlyDenied) {
      isCameraDeniedForever.value = true;
    } else {
      final result = await Permission.camera.request();
      hasCameraAccess.value = result.isGranted;
      isCameraDeniedForever.value = result.isPermanentlyDenied;
    }
    if (hasCameraAccess.value) {
      requestMicPermission();
    }
  }

  Future<void> requestMicPermission() async {
    if (isSimulator.value) {
      // En simulador no pedimos permisos, forzamos a false
      hasMicrophoneAccess.value = false;
      return;
    }

    final status = await Permission.microphone.status;
    if (status.isGranted) {
      hasMicrophoneAccess.value = true;
    } else if (status.isPermanentlyDenied) {
      isMicDeniedForever.value = true;
    } else {
      final result = await Permission.microphone.request();
      hasMicrophoneAccess.value = result.isGranted;
      isMicDeniedForever.value  = result.isPermanentlyDenied;
    }
    if (permissionsGranted) {
      _initializeCamera();
    }
  }

  // ─────────── UI ACTIONS ───────────

  /// Enciende/apaga el flash.
  void toggleFlash() {
    if (isSimulator.value) return;

    isFlashOn.toggle();
    cameraController?.setFlashMode(
      isFlashOn.value ? FlashMode.torch : FlashMode.off,
    );
  }

  /// Cambia entre cámara frontal y trasera.
  Future<void> switchCamera() async {
    if (isSimulator.value) return;

    isCameraInitialized.value = false;
    isRearCamera.toggle(); // no reactivo, solo para lógica interna
    selectedCamera.value = isRearCamera.value ? 0 : 1;

    await cameraController?.dispose();
    await _initializeCamera();
  }

  /// Comienza a grabar video.
  Future<void> startVideoRecording() async {
    if (isSimulator.value || cameraController == null) return;

    isRecording.value = true;
    await cameraController!.startVideoRecording();
    _startVideoTimer();
  }

  /// Detiene la grabación y devuelve el video.
  Future<void> stopVideoRecording() async {
    if (isSimulator.value || cameraController == null) return;

    final file = await cameraController!.stopVideoRecording();
    isRecording.value = false;
    _timer?.cancel();
    videoCounter.value = 0;

    Get.back(result: File(file.path));
  }

  /// Inicia el temporizador para contar segundos de grabación.
  void _startVideoTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      videoCounter.value++;
    });
  }

  /// Formatea la duración en mm:ss (para el temporizador en pantalla).
  String formatDuration() {
    final d = Duration(seconds: videoCounter.value);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }

  /// Maneja un video seleccionado de la galería
  void openVideoEditor(File videoFile) {
    Get.back(result: videoFile);
  }
}