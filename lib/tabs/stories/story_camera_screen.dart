import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/tabs/stories/story_preview_screen.dart';
import 'dart:async';
import 'dart:io';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class StoryCamera extends StatefulWidget {
  const StoryCamera({
    super.key,
    required this.cameras,
    required this.isVideo,
  });

  final List<CameraDescription> cameras;
  final bool isVideo;

  @override
  State<StoryCamera> createState() => _StoryCameraState();
}

class _StoryCameraState extends State<StoryCamera>
    with TickerProviderStateMixin {
  late CameraController _cameraController;
  late AnimationController _recordingController;
  late AnimationController _flashController;
  late Animation<double> _recordingAnimation;
  late Animation<double> _flashAnimation;
  
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  String? _capturedImagePath;
  String? _capturedVideoPath;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeCamera();
  }

  void _initializeControllers() {
    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _recordingAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _recordingController, curve: Curves.easeInOut),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );
    
    _recordingController.repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    try {
      final camera = widget.cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: widget.isVideo,
      );
      
      await _cameraController.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      // Notificaciones deshabilitadas
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _recordingController.dispose();
    _flashController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      
      await _cameraController.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      
      _flashController.forward().then((_) {
        _flashController.reverse();
      });
      
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      setState(() {
        _isFrontCamera = !_isFrontCamera;
        _isInitialized = false;
      });
      
      await _cameraController.dispose();
      
      final camera = _isFrontCamera 
          ? widget.cameras.firstWhere(
              (cam) => cam.lensDirection == CameraLensDirection.front,
              orElse: () => widget.cameras.first,
            )
          : widget.cameras.firstWhere(
              (cam) => cam.lensDirection == CameraLensDirection.back,
              orElse: () => widget.cameras.first,
            );
      
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: widget.isVideo,
      );
      
      await _cameraController.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  Future<void> _capturePhoto() async {
    try {
      HapticFeedback.heavyImpact();
      
      final image = await _cameraController.takePicture();
      setState(() {
        _capturedImagePath = image.path;
      });
      
      // Notificaciones deshabilitadas
      
      // Navegar a preview después de un breve delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToPreview();
      });
      
    } catch (e) {
      // Notificaciones deshabilitadas
    }
  }

  Future<void> _startVideoRecording() async {
    try {
      HapticFeedback.heavyImpact();
      
      await _cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      
      // Timer para contar segundos
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingSeconds++;
          });
          
          // Límite de 30 segundos para stories
          if (_recordingSeconds >= 30) {
            _stopVideoRecording();
          }
        }
      });
      
    } catch (e) {
      // Notificaciones deshabilitadas
    }
  }

  Future<void> _stopVideoRecording() async {
    try {
      _recordingTimer?.cancel();
      
      final video = await _cameraController.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _capturedVideoPath = video.path;
      });
      
      HapticFeedback.heavyImpact();
      
      // Notificaciones deshabilitadas
      
      // Navegar a preview después de un breve delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToPreview();
      });
      
    } catch (e) {
      // Notificaciones deshabilitadas
    }
  }

  Future<void> _navigateToPreview() async {
    if (_capturedImagePath != null) {
      // Navegar a preview con opciones de música y VIP
      final imageFile = File(_capturedImagePath!);
      Get.to(() => StoryPreviewScreen(
        file: imageFile,
        isVideo: false,
      ));
    } else if (_capturedVideoPath != null) {
      // Navegar a preview con opciones de música y VIP
      final videoFile = File(_capturedVideoPath!);
      Get.to(() => StoryPreviewScreen(
        file: videoFile,
        isVideo: true,
      ));
    }
  }

  Future<void> _pickImageFromGallery() async {
    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 1,
        requestType: RequestType.common,
      ),
    );

    if (assets != null && assets.isNotEmpty) {
      final file = await assets.first.file;
      if (file != null) {
        final isVideo = assets.first.type == AssetType.video;
        Get.to(() => StoryPreviewScreen(
          file: file,
          isVideo: isVideo,
        ));
      }
    }
  }

  String _formatRecordingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final double widthPreview = _isInitialized 
        ? (_cameraController.value.previewSize?.width ?? 0)
        : 0;
    final double heightPreview = _isInitialized 
        ? (_cameraController.value.previewSize?.height ?? 0)
        : 0;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && widthPreview > 0 && heightPreview > 0)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: isPortrait ? heightPreview : widthPreview,
                  height: isPortrait ? widthPreview : heightPreview,
                  child: CameraPreview(_cameraController),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          
          // Top controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    
                    // Recording timer or Aa Button (when not recording)
                    if (_isRecording)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatRecordingTime(_recordingSeconds),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Text Mode (Aa) Button - Top Position
                      GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoutes.writeStory);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'Aa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    // Flash toggle
                    GestureDetector(
                      onTap: _toggleFlash,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isFlashOn 
                              ? Colors.yellow.withOpacity(0.8)
                              : Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery Button (Left)
                    GestureDetector(
                      onTap: _pickImageFromGallery,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    
                    // Capture/Record button
                    GestureDetector(
                      onTap: widget.isVideo
                          ? (_isRecording ? _stopVideoRecording : _startVideoRecording)
                          : _capturePhoto,
                      child: AnimatedBuilder(
                        animation: _isRecording ? _recordingAnimation : 
                                  const AlwaysStoppedAnimation(1.0),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isRecording ? _recordingAnimation.value : 1.0,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _isRecording ? Colors.red : Colors.white,
                                shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                                borderRadius: _isRecording ? BorderRadius.circular(16) : null,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording ? Colors.red : Colors.white)
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: widget.isVideo && !_isRecording
                                  ? const Icon(
                                      Icons.videocam,
                                      color: Colors.black,
                                      size: 32,
                                    )
                                  : _isRecording
                                      ? const Icon(
                                          Icons.stop,
                                          color: Colors.white,
                                          size: 32,
                                        )
                                      : null,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Switch Camera (Right)
                    GestureDetector(
                      onTap: _switchCamera,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
