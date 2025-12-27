import 'dart:ui'; // Needed for ImageFilter
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/media/helpers/media_helper.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/models/location.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:get/get.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart'; // Exports photo_manager
import 'package:path_provider/path_provider.dart';

import 'package:camera/camera.dart'; // Import camera package

class AttachmentMenu extends StatefulWidget {
  const AttachmentMenu({
    super.key,
    required this.sendDocs,
    required this.sendImage,
    required this.sendVideo,
    required this.sendLocation,
  });

  final Function(List<File>?) sendDocs;
  final Function(File?) sendImage, sendVideo;
  final Function(Location?) sendLocation;

  @override
  State<AttachmentMenu> createState() => _AttachmentMenuState();
}

class _AttachmentMenuState extends State<AttachmentMenu> {
  final MessageController messageController = Get.find();
  
  // Asset Management
  List<AssetEntity> _recentAssets = [];
  final List<AssetEntity> _selectedAssets = [];
  bool _isLoadingAssets = true;
  
  // Camera
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _fetchRecentAssets();
    _initializeCamera();
  }
  
  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _fetchRecentAssets() async {
    try {
      // Request permissions first (AssetPicker handles this usually, but good to be safe)
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth && !ps.hasAccess) {
        if (mounted) setState(() => _isLoadingAssets = false);
        return;
      }

      // Fetch "Recent" album
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isNotEmpty) {
        // Get recent assets (top 100)
        final List<AssetEntity> assets = await albums.first.getAssetListRange(
          start: 0, 
          end: 100,
        );
        
        if (mounted) {
          setState(() {
            _recentAssets = assets;
            _isLoadingAssets = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingAssets = false);
      }
    } catch (e) {
      debugPrint('Error fetching assets: $e');
      if (mounted) setState(() => _isLoadingAssets = false);
    }
  }

  void _toggleAssetSelection(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        _selectedAssets.add(asset);
      }
    });
  }
  
  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      final XFile image = await _cameraController!.takePicture();
      Get.back(); // Close menu
      widget.sendImage(File(image.path));
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _sendSelectedAssets() async {
    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    int successCount = 0;
    int failedCount = 0;
    final List<String> failedAssets = [];

    try {
      for (final asset in _selectedAssets) {
        File? file;
        
        // Método 1: Intentar obtener el archivo directamente
        try {
          file = await asset.file;
        } catch (e) {
          debugPrint('Error getting file: $e');
        }

        // Método 2: Si falla, intentar originFile
        if (file == null) {
          try {
            file = await asset.originFile;
          } catch (e) {
            debugPrint('Error getting originFile: $e');
          }
        }

        // Si logramos obtener el archivo, enviarlo
        if (file != null && await file.exists()) {
          try {
            // Check exact type just in case
            if (asset.type == AssetType.video) {
              await widget.sendVideo(file);
            } else {
              await widget.sendImage(file);
            }
            successCount++;
          } catch (e) {
            debugPrint('Error sending file: $e');
            failedCount++;
            failedAssets.add(asset.title ?? 'Unknown');
          }
        } else {
          debugPrint('Could not retrieve file for asset: ${asset.id} (likely in iCloud)');
          failedCount++;
          failedAssets.add(asset.title ?? 'Foto en iCloud');
        }
      }
      
      // Close Loading
      if (mounted) Navigator.of(context).pop(); 
      
      // Mostrar resultado
      if (mounted) {
        if (failedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    successCount > 0
                        ? 'Se enviaron $successCount fotos.'
                        : 'No se pudieron enviar las fotos.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Algunas fotos están en iCloud. Ábrelas en la app Fotos para descargarlas al dispositivo primero.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: successCount > 0 ? Colors.orange : Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        
        // Cerrar el menú después de procesar todo
        if (successCount > 0) {
          Get.back();
        }
      }
      
    } catch (e) {
      // Close Loading
      if (mounted) Navigator.of(context).pop();
      
      debugPrint('Error sending assets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al enviar fotos: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Improved Glassmorphism Colors
    final Color bgColor = isDark 
        ? const Color(0xFF1E293B).withOpacity(0.8) // Darker Slate for better contrast
        : Colors.white.withOpacity(0.9);           // More opaque white for readability
        
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final Color iconColor = isDark ? Colors.white70 : Colors.black54;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), // More rounded
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Softer blur
        child: Container(
          height: MediaQuery.of(context).size.height * 0.70, // Slightly taller
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // 1. Header (Recents + Manage)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                       if (_selectedAssets.isNotEmpty) 
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAssets.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black12,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, size: 20, color: textColor),
                            ),
                          ),
                        
                        if (_selectedAssets.isNotEmpty) const SizedBox(width: 12),

                        Text(
                          _selectedAssets.isNotEmpty 
                              ? '${_selectedAssets.length} Selected' 
                              : 'Recents',
                          style: TextStyle(
                            fontSize: 22, // Larger header
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    
                    if (_selectedAssets.isNotEmpty)
                      GestureDetector(
                        onTap: _sendSelectedAssets,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF2979FF)], 
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2979FF).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Send',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _handleImagePicker, 
                        child: Text(
                          'Manage',
                          style: TextStyle(
                            fontSize: 17,
                            color: const Color(0xFF2979FF), // Brighter Blue
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Photo Grid (Scrollable)
              Expanded(
                child: _isLoadingAssets 
                    ? Center(child: CircularProgressIndicator(color: isDark ? Colors.white : Colors.blue))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        // Add 1 for the camera preview
                        itemCount: _recentAssets.length + 1,
                        itemBuilder: (context, index) {
                          // Index 0 is the Camera Preview
                          if (index == 0) {
                             return GestureDetector(
                               onTap: _takePicture,
                               child: Padding( // Slight padding to simulate grid spacing
                                 padding: const EdgeInsets.all(1.0), 
                                 child: ClipRRect(
                                   borderRadius: BorderRadius.circular(8), // Rounded corners for camera cell
                                   child: Container(
                                     color: Colors.black,
                                     child: Stack(
                                       fit: StackFit.expand,
                                       children: [
                                         if (_isCameraInitialized && _cameraController != null)
                                            FittedBox(
                                             fit: BoxFit.cover,
                                             child: SizedBox(
                                               width: _cameraController!.value.previewSize?.height ?? 1,
                                               height: _cameraController!.value.previewSize?.width ?? 1,
                                               child: CameraPreview(_cameraController!),
                                             ),
                                           )
                                         else
                                           const Center(child: Icon(Icons.camera_alt, color: Colors.white38)),
                                         
                                         // Overlay Icon
                                         Center(
                                           child: Container(
                                             width: 40,
                                             height: 40,
                                             decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2)
                                             ),
                                             child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                           ),
                                         )
                                       ],
                                     ),
                                   ),
                                 ),
                               ),
                             );
                          }
                          
                          // Adjust index for assets
                          final assetIndex = index - 1;
                          final asset = _recentAssets[assetIndex];
                          final isSelected = _selectedAssets.contains(asset);
                          
                          return GestureDetector(
                            onTap: () => _toggleAssetSelection(asset),
                            child: Container( // Wrap in Container for margin/spacing if needed
                             padding: const EdgeInsets.all(1.0),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4), // Subtle rounding
                                    child: Image(
                                      image: AssetEntityImageProvider(
                                        asset,
                                        isOriginal: false,
                                        thumbnailSize: const ThumbnailSize.square(300), 
                                      ),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                         return Container(
                                           color: isDark ? Colors.white10 : Colors.grey[200],
                                           child: const Icon(Icons.broken_image, color: Colors.grey),
                                         );
                                      },
                                    ),
                                  ),
                                  // Selection Overlay
                                  if (isSelected)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        color: const Color(0xFF2979FF).withOpacity(0.4),
                                        child: const Center(
                                          child: Icon(Icons.check_circle, color: Colors.white, size: 32),
                                        ),
                                      ),
                                    ),
                                  // Selection Circle (Unselected)
                                  if (!isSelected)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          color: Colors.black.withOpacity(0.1),
                                        ),
                                      ),
                                    ),
                                    
                                  // Video Indicator
                                  if (asset.type == AssetType.video)
                                    const Positioned(
                                      left: 6,
                                      bottom: 6,
                                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // 3. Bottom Action Bar (Attachment Types)
              Container(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 24), // More bottom padding
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white.withOpacity(0.6),
                  border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomAction(
                        context,
                        icon: IconlyBold.image,
                        label: 'Gallery',
                        color: Colors.blueAccent,
                        onTap: _handleImagePicker,
                      ),
                  const SizedBox(width: 24),
                  _buildBottomAction(
                    context,
                    icon: IconlyBold.document,
                    label: 'File',
                    color: Colors.orange,
                    onTap: _handleDocumentPicker,
                  ),
                  const SizedBox(width: 24),
                  _buildBottomAction(
                    context,
                    icon: IconlyBold.location,
                    label: 'Location',
                    color: Colors.green,
                    onTap: () async {
                      Get.back();
                      final Location? position = await AppHelper.getUserCurrentLocation();
                      if (position != null) widget.sendLocation(position);
                    },
                  ),
                  const SizedBox(width: 24),
                   _buildBottomAction(
                    context,
                    icon: Icons.person_rounded,
                    label: 'Contact',
                    color: Colors.purple, // Changed to Purple
                    onTap: () {
                       Get.back();
                    },
                  ),
                   const SizedBox(width: 24),
                   _buildBottomAction(
                    context,
                    icon: Icons.music_note_rounded,
                    label: 'Audio',
                    color: Colors.pinkAccent,
                    onTap: () {
                         Get.back();
                    },
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildBottomAction(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15), // Subtle bg
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // --- Handlers ---

  Future<void> _handleImagePicker() async {
    // Navigate to full gallery picker
    // Since we are already showing recents, this button opens the full album view
   
    Get.back(); // Close existing sheet to open picker or push picker

    // Standard picker logic
     final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 10,
        requestType: RequestType.common,
      ),
    );

    if (assets != null && assets.isNotEmpty) {
      for (final asset in assets) {
        final File? file = await asset.file;
        if (file != null) {
          if (asset.type == AssetType.video) {
             widget.sendVideo(file);
          } else {
             widget.sendImage(file);
          }
        }
      }
    }
  }

  Future<void> _handleDocumentPicker() async {
    Get.back();
    final file = await MediaHelper.getFile();
    if (file == null) return;
    messageController.sendMessage(MessageType.doc, file: file);
  }
}
