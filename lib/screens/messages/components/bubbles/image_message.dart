import 'dart:io';
import 'dart:ui' as ui;
import 'package:chat_messenger/components/cached_card_image.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:chat_messenger/screens/messages/components/read_time_status.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/media/view_media_screen.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageMessage extends StatefulWidget {
  const ImageMessage(this.message, {super.key, this.isGroup = false});

  // Params
  final Message message;
  final bool isGroup;

  @override
  State<ImageMessage> createState() => _ImageMessageState();
}

class _ImageMessageState extends State<ImageMessage> {
  double? _aspectRatio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  Future<void> _loadImageDimensions() async {
    try {
      if (widget.message.fileUrl.startsWith('/')) {
        // Imagen local
        final file = File(widget.message.fileUrl);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          final width = frame.image.width.toDouble();
          final height = frame.image.height.toDouble();
          frame.image.dispose();
          
          if (width > 0 && height > 0 && mounted) {
            setState(() {
              _aspectRatio = width / height;
              _isLoading = false;
            });
          }
          return;
        }
      } else {
        // Imagen remota - detectar dimensiones cuando se carga
        final imageProvider = CachedNetworkImageProvider(widget.message.fileUrl);
        final completer = imageProvider.resolve(const ImageConfiguration());
        
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (ImageInfo info, bool synchronousCall) {
            final width = info.image.width.toDouble();
            final height = info.image.height.toDouble();
            if (width > 0 && height > 0 && mounted) {
              setState(() {
                _aspectRatio = width / height;
                _isLoading = false;
              });
            }
            completer.removeListener(listener);
          },
          onError: (exception, stackTrace) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            completer.removeListener(listener);
          },
        );
        
        completer.addListener(listener);
        return;
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final MessageController controller = Get.find();
    
    return GestureDetector(
      onTap: () {
        if (!controller.isFileUploading(widget.message.fileUrl)) {
          Get.to(() => ViewMediaScreen(fileUrl: widget.message.fileUrl));
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
          minWidth: MediaQuery.of(context).size.width * 0.45,
          maxHeight: MediaQuery.of(context).size.height * 0.4,
          minHeight: 120,
        ),
        child: _aspectRatio != null
            ? AspectRatio(
                aspectRatio: _aspectRatio!,
                child: _buildImageContainer(),
              )
            : _buildImageContainer(),
      ),
    );
  }

  Widget _buildImageContainer() {
    final MessageController controller = Get.find();
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFCCCCCC),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen (local o remota)
            _buildImage(),
            
            // Indicador de progreso
            Obx(() {
              if (controller.isFileUploading(widget.message.fileUrl)) {
                return Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => controller.cancelUpload(widget.message.fileUrl),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            Center(
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Tiempo y verificación
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ReadTimeStatus(
                  message: widget.message,
                  isGroup: widget.isGroup,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.message.fileUrl.startsWith('/')) {
      return Image.file(
        File(widget.message.fileUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
          );
        },
      );
    } else {
      return CachedCardImage(
        widget.message.fileUrl,
        fit: BoxFit.cover,
      );
    }
  }
}
