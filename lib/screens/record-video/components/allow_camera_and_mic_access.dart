import 'dart:async';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// 1) Importa aquí tu pantalla de edición:
import 'package:chat_messenger/plugins/video-editor/screens/video_editor_screen.dart';

class RecordVideoController extends GetxController {
  final isCameraInitialized = false.obs;
  final isRecording = false.obs;
  final isFlashOn = false.obs;
  final permissionsGranted = false.obs;
  late CameraController cameraController;
  Timer? _timer;
  final recordDuration = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: true,
    );
    await cameraController.initialize();
    permissionsGranted.value = true;
    isCameraInitialized.value = true;
    // Opcional: forzar modo de flash inicial
    await cameraController.setFlashMode(FlashMode.off);
  }

  void toggleFlash() {
    isFlashOn.value = !isFlashOn.value;
    cameraController.setFlashMode(
      isFlashOn.value ? FlashMode.torch : FlashMode.off,
    );
  }

  void toggleRecording() async {
    if (isRecording.value) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    await cameraController.startVideoRecording();
    isRecording.value = true;
    recordDuration.value = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      recordDuration.value += const Duration(seconds: 1);
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final file = await cameraController.stopVideoRecording();
    isRecording.value = false;
    _goToEditor(file.path);
  }

  String formatDuration() {
    final d = recordDuration.value;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  // 2) Aquí llamas a tu pantalla de edición con la ruta correcta:
  void _goToEditor(String path) {
    Get.to(() => VideoEditorScreen(inputPath: path));
  }

  @override
  void onClose() {
    cameraController.dispose();
    _timer?.cancel();
    super.onClose();
  }
}