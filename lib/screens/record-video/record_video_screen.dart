// lib/screens/record-video/record_video_screen.dart

import 'dart:io';                                     // ← Para detectar simulador iOS
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';                  // ← Para CameraController y CameraPreview
import 'controller/record_video_controller.dart';    // ← Tu controlador

class RecordVideoScreen extends StatelessWidget {
  // Crear/obtener la instancia del controlador con Get.put
  final RecordVideoController controller = Get.put(RecordVideoController());

  RecordVideoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // El Scaffold contiene únicamente un Column con la vista de cámara (o placeholder)
    // y los controles (botón grabar, flash, cambiar cámara, timer).
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 1) Previsualización de cámara (o placeholder en simulador/pendiente permisos)
            Expanded(child: _buildCameraPreview()),

            // 2) Controles: flash, switch camera, botón grabar y tiempo
            _buildControls(),
          ],
        ),
      ),
    );
  }

  /// Construye la vista de previsualización de la cámara.
  /// - Si estamos en iOS + simulador (no hay dispositivo físico) y NO se
  ///   inicializó aún la cámara, mostramos un placeholder (fondo negro + texto).
  /// - Si faltan permisos, mostramos botones para solicitarlos.
  /// - Mientras carga la cámara (en un dispositivo real), mostramos CircularProgressIndicator.
  /// - Finalmente, si la cámara ya está inicializada en un dispositivo real,
  ///   devolvemos el CameraPreview.
  Widget _buildCameraPreview() {
    return Obx(() {
      // 1) Detectar simulador iOS: 
      //    Platform.isIOS = true en iOS, pero no hay cámara real en el simulador,
      //    así que isCameraInitialized va a ser false y permissionsGranted false.
      //    Ahí devolvemos un placeholder para evitar que CameraPreview intente iniciarse.
      if (Platform.isIOS &&
          !controller.isCameraInitialized.value &&
          !controller.permissionsGranted) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Text(
              'El simulador iOS no soporta cámara',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        );
      }

      // 2) Si faltan permisos (cámara y/o micrófono), pedimos primero permisos:
      if (!controller.permissionsGranted) {
        return _buildPermissionsRequest();
      }

      // 3) Si la cámara aún no está inicializada (está cargando en dispositivo real):
      if (!controller.isCameraInitialized.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      // 4) Cuando la cámara ya esté inicializada en un dispositivo físico:
      return CameraPreview(controller.cameraController!);
    });
  }

  /// Construye los botones para solicitar permisos de cámara y micrófono.
  /// Se muestra cuando controller.permissionsGranted == false.
  Widget _buildPermissionsRequest() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!controller.hasCameraAccess.value)
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_camera),
                label: const Text('Permitir Cámara'),
                onPressed: controller.requestCameraPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black
                ),
              ),
            const SizedBox(height: 12),
            if (!controller.hasMicrophoneAccess.value)
              ElevatedButton.icon(
                icon: const Icon(Icons.mic),
                label: const Text('Permitir Micrófono'),
                onPressed: controller.requestMicPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Construye la fila de controles inferiores: flash, temporizador, botón de grabar, cambiar cámara.
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Obx(() {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Botón "Flash On/Off"
            IconButton(
              icon: Icon(
                controller.isFlashOn.value ? Icons.flash_on : Icons.flash_off,
                color: controller.isFlashOn.value ? Colors.yellow : Colors.white,
                size: 30,
              ),
              onPressed: controller.toggleFlash,
            ),

            // Temporizador (mm:ss)
            Text(
              controller.formatDuration(),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // Botón central de Grabar/Detener (FloatingActionButton)
            FloatingActionButton(
              backgroundColor: controller.isRecording.value ? Colors.red : Colors.white,
              onPressed: controller.isRecording.value
                  ? controller.stopVideoRecording
                  : controller.startVideoRecording,
              child: Icon(
                controller.isRecording.value ? Icons.stop : Icons.videocam,
                color: controller.isRecording.value ? Colors.white : Colors.black,
                size: 28,
              ),
            ),

            // Botón "Cambiar Cámara"
            IconButton(
              icon: const Icon(Icons.switch_camera, color: Colors.white, size: 30),
              onPressed: controller.switchCamera,
            ),
          ],
        );
      }),
    );
  }
}