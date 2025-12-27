import 'dart:ui';
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
  CameraController? _cameraController;
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
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      // Si falla la inicialización, el controlador queda como null
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _recordingController.dispose();
    _flashController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    try {
      if (_cameraController == null || !_isInitialized) return;
      
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      
      await _cameraController!.setFlashMode(
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
      if (_cameraController == null) return;
      
      setState(() {
        _isFrontCamera = !_isFrontCamera;
        _isInitialized = false;
      });
      
      await _cameraController!.dispose();
      
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
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Error switching camera: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    try {
      if (_cameraController == null || !_isInitialized) return;
      
      HapticFeedback.heavyImpact();
      
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImagePath = image.path;
      });
      
      // Notificaciones deshabilitadas
      
      // Navegar a preview después de un breve delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToPreview();
      });
      
    } catch (e) {
      print('Error capturing photo: $e');
      // Notificaciones deshabilitadas
    }
  }

  Future<void> _startVideoRecording() async {
    try {
      if (_cameraController == null || !_isInitialized) return;
      
      HapticFeedback.heavyImpact();
      
      await _cameraController!.startVideoRecording();
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
      print('Error starting video recording: $e');
      // Notificaciones deshabilitadas
    }
  }

  Future<void> _stopVideoRecording() async {
    try {
      if (_cameraController == null) return;
      
      _recordingTimer?.cancel();
      
      final video = await _cameraController!.stopVideoRecording();
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
      print('Error stopping video recording: $e');
      setState(() {
        _isRecording = false;
      });
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
    try {
      // Calculate responsive grid count
      final width = MediaQuery.of(context).size.width;
      final int gridCount = width > 600 ? 5 : 3; // 3 columns for mobile, 5 for tablet

      // Custom Premium Theme for Asset Picker
      final ThemeData theme = ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        canvasColor: const Color(0xFF1E293B), // Slate 800
        cardColor: const Color(0xFF1E293B),
        
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF), // Cyan selection
          secondary: Color(0xFF00B8D4),
          surface: Color(0xFF1E293B),
          onSurface: Colors.white,
          background: Color(0xFF0F172A),
        ),
        
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF00E5FF),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        
        // Style specific to the "Confirm" button if it uses ElevatedButton (or often it uses TextButton with styling)
        // We'll override the button theme generally to be safe
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black, // Dark text on Cyan
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );

      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.common,
          gridCount: gridCount,
          pageSize: 120,
          pickerTheme: theme,
          textDelegate: const EnglishAssetPickerTextDelegate(),
        ),
      );

      if (assets != null && assets.isNotEmpty) {
        try {
          final file = await assets.first.file;
          if (file != null && mounted) {
            final isVideo = assets.first.type == AssetType.video;
            Get.to(() => StoryPreviewScreen(
              file: file,
              isVideo: isVideo,
              // Pass metadata if needed
            ));
          }
        } catch (e) {
          debugPrint('Error getting file from asset: $e');
        }
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      // Common errors: permission denied, icloud sync, etc.
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
    final double widthPreview = _isInitialized && _cameraController != null
        ? (_cameraController!.value.previewSize?.width ?? 0)
        : 0;
    final double heightPreview = _isInitialized && _cameraController != null
        ? (_cameraController!.value.previewSize?.height ?? 0)
        : 0;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && widthPreview > 0 && heightPreview > 0 && _cameraController != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: isPortrait ? heightPreview : widthPreview,
                  height: isPortrait ? widthPreview : heightPreview,
                  child: CameraPreview(_cameraController!),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    _GlassControlButton(
                      onTap: () => Get.back(),
                      icon: IconlyLight.closeSquare,
                    ),
                    
                    // Recording timer (Centered)
                    if (_isRecording)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
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
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                    // Right Side Controls (Vertical Stack)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Flash toggle
                        _GlassControlButton(
                          onTap: _toggleFlash,
                          icon: _isFlashOn ? IconlyBold.image : IconlyLight.image, 
                          child: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: _isFlashOn ? Colors.yellow : Colors.white,
                            size: 24,
                          ),
                        ),
                        
                        // Text Mode Button (Aa)
                        if (!_isRecording) ...[
                          const SizedBox(height: 16),
                          _GlassControlButton(
                            onTap: () {
                              Get.toNamed(AppRoutes.writeStory);
                            },
                            child: const Text(
                              'Aa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
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
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery Button (Left)
                    _GlassControlButton(
                      onTap: _pickImageFromGallery,
                      icon: IconlyLight.image,
                      size: 50,
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
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _isRecording ? Colors.red : Colors.white.withOpacity(0.2),
                                  shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                                  borderRadius: _isRecording ? BorderRadius.circular(16) : null,
                                ),
                                child: _isRecording
                                    ? const Icon(Icons.stop, color: Colors.white, size: 32)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Switch Camera (Right)
                    _GlassControlButton(
                      onTap: _switchCamera,
                      icon: IconlyLight.swap, // Or stick to material if not available
                      child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
                      size: 50,
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

class _GlassControlButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? child;
  final double size;

  const _GlassControlButton({
    required this.onTap,
    this.icon,
    this.child,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: child ?? Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
