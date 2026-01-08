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

  @override
  void didUpdateWidget(ImageMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el fileUrl cambió, recargar dimensiones
    if (oldWidget.message.fileUrl != widget.message.fileUrl) {
      _aspectRatio = null;
      _isLoading = true;
      _loadImageDimensions();
      // Forzar reconstrucción del widget
      setState(() {});
    }
  }

  Future<void> _loadImageDimensions([String? fileUrl]) async {
    try {
      final url = fileUrl ?? widget.message.fileUrl;
      if (url.isEmpty) {
        _isLoading = false;
        if (mounted) setState(() {});
        return;
      }
      
      if (url.startsWith('/')) {
        // Imagen local
        final file = File(url);
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
        final imageProvider = CachedNetworkImageProvider(url);
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
    // LOG CRÍTICO: Verificar si el widget se está construyendo
    print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨 ImageMessage.build EJECUTADO 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
    print('   - msgId: ${widget.message.msgId}');
    print('   - type: ${widget.message.type}');
    print('   - fileUrl: ${widget.message.fileUrl.isEmpty ? "VACÍO" : widget.message.fileUrl.substring(0, widget.message.fileUrl.length > 50 ? 50 : widget.message.fileUrl.length)}...');
    print('   - fileUrl length: ${widget.message.fileUrl.length}');
    print('   - fileUrl startsWith http: ${widget.message.fileUrl.startsWith("http")}');
    debugPrint('🚨 ImageMessage.build: INICIADO - msgId=${widget.message.msgId}, type=${widget.message.type}');
    debugPrint('🚨 ImageMessage.build: fileUrl inicial=${widget.message.fileUrl.isEmpty ? "VACÍO" : widget.message.fileUrl.substring(0, 50)}...');
    
    final MessageController controller = Get.find();
    
    // Observar cambios en los mensajes y el trigger de actualización
    return Obx(() {
      // Observar el trigger para forzar reconstrucción
      final _ = controller.imageMessageUpdateTrigger.value;
      final messagesLength = controller.messages.length;
      
      String currentFileUrl = widget.message.fileUrl;
      
      // Intentar obtener el mensaje actualizado de la lista
      try {
        final foundMessage = controller.messages.firstWhere(
          (m) => m.msgId == widget.message.msgId,
        );
        if (foundMessage.fileUrl.isNotEmpty && foundMessage.fileUrl.startsWith('http')) {
          currentFileUrl = foundMessage.fileUrl;
          print('   - ✅ fileUrl actualizado desde controlador: ${currentFileUrl.substring(0, 50)}...');
          debugPrint('🖼️ ImageMessage.build: fileUrl actualizado desde controlador: ${currentFileUrl.substring(0, 50)}...');
        }
      } catch (e) {
        print('   - ⚠️ Mensaje no encontrado en controlador, usando fileUrl del widget');
        debugPrint('🖼️ ImageMessage.build: Mensaje no encontrado en controlador, usando fileUrl del widget');
        currentFileUrl = widget.message.fileUrl;
      }
      
      print('   - fileUrl final: ${currentFileUrl.isEmpty ? "VACÍO" : currentFileUrl.substring(0, 50)}..., length=${currentFileUrl.length}, startsWith http=${currentFileUrl.startsWith("http")}');
      debugPrint('🖼️ ImageMessage.build: fileUrl final=${currentFileUrl.isEmpty ? "VACÍO" : currentFileUrl.substring(0, 50)}..., length=${currentFileUrl.length}, startsWith http=${currentFileUrl.startsWith("http")}');
      
      // Si no hay fileUrl válido, mostrar placeholder
      if (currentFileUrl.isEmpty || !currentFileUrl.startsWith('http')) {
        print('   - ⚠️ fileUrl inválido, mostrando placeholder');
        print('   - currentFileUrl: "$currentFileUrl"');
        print('   - isEmpty: ${currentFileUrl.isEmpty}');
        print('   - startsWith http: ${currentFileUrl.startsWith("http")}');
        debugPrint('⚠️ ImageMessage.build: fileUrl inválido, mostrando placeholder');
        return Container(
          key: ValueKey('placeholder_${widget.message.msgId}'),
          width: MediaQuery.of(context).size.width * 0.75,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Cargando imagen...',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'fileUrl: ${currentFileUrl.isEmpty ? "VACÍO" : currentFileUrl.substring(0, currentFileUrl.length > 30 ? 30 : currentFileUrl.length)}...',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      
      print('   - ✅✅✅ Construyendo imagen con fileUrl válido ✅✅✅');
      print('   - fileUrl completo: $currentFileUrl');
      print('   - fileUrl length: ${currentFileUrl.length}');
      debugPrint('✅ ImageMessage.build: Construyendo imagen con fileUrl válido');
      
      // MOSTRAR LA IMAGEN DIRECTAMENTE - Key único basado en fileUrl para forzar reconstrucción
      return GestureDetector(
        key: ValueKey('gesture_${widget.message.msgId}_${currentFileUrl.hashCode}'),
        onTap: () {
          if (!controller.isFileUploading(currentFileUrl) && currentFileUrl.isNotEmpty) {
            Get.to(() => ViewMediaScreen(fileUrl: currentFileUrl));
          }
        },
        child: _buildImageContainerDirect(widget.message, currentFileUrl),
      );
    });
  }

  // Método simplificado que siempre muestra la imagen directamente
  Widget _buildImageContainerDirect(Message message, String fileUrl) {
    debugPrint('📦 _buildImageContainerDirect: msgId=${message.msgId}, fileUrl=${fileUrl.substring(0, fileUrl.length > 50 ? 50 : fileUrl.length)}...');
    
    final screenWidth = MediaQuery.of(context).size.width;
    final MessageController controller = Get.find();
    
    return Container(
      key: ValueKey('image_container_${message.msgId}_${fileUrl.hashCode}'),
      width: screenWidth * 0.75,
      height: 300,
      constraints: BoxConstraints(
        minWidth: 200,
        minHeight: 200,
        maxWidth: screenWidth * 0.75,
        maxHeight: 400,
      ),
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
            // IMAGEN - SIEMPRE MOSTRAR DIRECTAMENTE - SIN NINGÚN WRAPPER
            _buildImage(message, fileUrl),
            
            // Indicador de carga si está subiendo
            Obx(() {
              if (controller.isFileUploading(fileUrl)) {
                return Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            
            // Tiempo y estado de lectura
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
                  message: message,
                  isGroup: widget.isGroup,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContainer(Message message, String fileUrl) {
    final MessageController controller = Get.find();
    final screenWidth = MediaQuery.of(context).size.width;
    
    debugPrint('📦 _buildImageContainer: msgId=${message.msgId}, fileUrl length=${fileUrl.length}, fileUrl=${fileUrl.isEmpty ? "VACÍO" : fileUrl.substring(0, fileUrl.length > 50 ? 50 : fileUrl.length)}...');
    
    // Calcular altura basada en aspectRatio si está disponible, sino usar altura por defecto
    double containerHeight = 200;
    if (_aspectRatio != null && _aspectRatio! > 0) {
      final maxWidth = screenWidth * 0.75;
      containerHeight = maxWidth / _aspectRatio!;
      if (containerHeight > 400) containerHeight = 400;
      if (containerHeight < 200) containerHeight = 200;
    }
    
    return Container(
      // Tamaño dinámico basado en aspectRatio si está disponible
      width: screenWidth * 0.75,
      height: containerHeight,
      constraints: BoxConstraints(
        minWidth: 200,
        minHeight: 200,
        maxWidth: screenWidth * 0.75,
        maxHeight: 400,
      ),
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
            // Imagen (local o remota) - SIEMPRE mostrar directamente
            _buildImage(message, fileUrl),
            
            // Indicador de progreso
            Obx(() {
              final currentFileUrl = message.fileUrl.isNotEmpty 
                  ? message.fileUrl 
                  : widget.message.fileUrl;
              if (controller.isFileUploading(currentFileUrl)) {
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
                  message: message,
                  isGroup: widget.isGroup,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Message message, String fileUrl) {
    // Debug: Log fileUrl
    debugPrint('🖼️ _buildImage INICIADO: msgId=${message.msgId}, fileUrl length=${fileUrl.length}, fileUrl = ${fileUrl.isEmpty ? "VACÍO" : fileUrl.substring(0, fileUrl.length > 50 ? 50 : fileUrl.length)}...');
    
    // Si no hay fileUrl, mostrar placeholder
    if (fileUrl.isEmpty) {
      debugPrint('⚠️ _buildImage: fileUrl está vacío, mostrando placeholder');
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.image,
            size: 50,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    if (fileUrl.startsWith('/')) {
      debugPrint('📁 _buildImage: Imagen local detectada');
      // Imagen local
      final file = File(fileUrl);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              ),
            );
          }
          
          if (snapshot.hasData && snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ _buildImage: Error cargando imagen local: $error');
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            );
          }
          
          debugPrint('⚠️ _buildImage: Archivo local no existe: $fileUrl');
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 50,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    } else {
      // Imagen remota - FORZAR renderizado directo
      print('🌐🌐🌐 _buildImage: Imagen remota detectada 🌐🌐🌐');
      print('   - fileUrl: ${fileUrl.substring(0, fileUrl.length > 80 ? 80 : fileUrl.length)}...');
      print('   - fileUrl length: ${fileUrl.length}');
      print('   - fileUrl startsWith http: ${fileUrl.startsWith("http")}');
      debugPrint('🌐 _buildImage: Imagen remota detectada: ${fileUrl.substring(0, fileUrl.length > 80 ? 80 : fileUrl.length)}...');
      
      if (fileUrl.isEmpty || !fileUrl.startsWith('http')) {
        print('⚠️⚠️⚠️ _buildImage: fileUrl no es una URL válida: "$fileUrl"');
        debugPrint('⚠️ _buildImage: fileUrl no es una URL válida: "$fileUrl"');
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(
              Icons.image,
              size: 50,
              color: Colors.grey,
            ),
          ),
        );
      }
      
      // Usar CachedNetworkImage directamente - SIMPLIFICADO
      print('✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅ CREANDO CACHEDNETWORKIMAGE ✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅');
      print('   - URL: ${fileUrl.substring(0, fileUrl.length > 100 ? 100 : fileUrl.length)}...');
      print('   - URL length: ${fileUrl.length}');
      print('   - URL startsWith http: ${fileUrl.startsWith("http")}');
      print('   - URL completa: $fileUrl');
      debugPrint('✅✅✅ _buildImage: Creando CachedNetworkImage con URL: ${fileUrl.substring(0, fileUrl.length > 80 ? 80 : fileUrl.length)}...');
      
      // VERIFICAR: Intentar cargar la imagen directamente para ver si hay errores
      try {
        // Verificar que la URL es válida
        final uri = Uri.parse(fileUrl);
        print('   - ✅ URI parseada correctamente: ${uri.scheme}://${uri.host}...');
      } catch (e) {
        print('   - ❌ ERROR parseando URI: $e');
        debugPrint('❌ ERROR parseando URI: $e');
      }
      
      print('   - 🖼️🖼️🖼️ CREANDO CachedNetworkImage 🖼️🖼️🖼️');
      print('   - imageUrl: ${fileUrl.substring(0, fileUrl.length > 100 ? 100 : fileUrl.length)}...');
      debugPrint('🖼️🖼️🖼️ CREANDO CachedNetworkImage 🖼️🖼️🖼️');
      
      return CachedNetworkImage(
        key: ValueKey('cached_image_${fileUrl.hashCode}_${DateTime.now().millisecondsSinceEpoch}'),
        imageUrl: fileUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 800,
        memCacheHeight: 800,
        fadeInDuration: const Duration(milliseconds: 200),
        httpHeaders: {
          'Cache-Control': 'no-cache',
        },
        placeholder: (context, url) {
          print('⏳⏳⏳ CachedNetworkImage PLACEHOLDER (cargando): $url');
          debugPrint('⏳ CachedNetworkImage placeholder: $url');
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          );
        },
        errorWidget: (context, url, error) {
          print('❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌ ERROR CACHEDNETWORKIMAGE ❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌');
          print('❌ URL que falló: $url');
          print('❌ Error: $error');
          print('❌ Tipo de error: ${error.runtimeType}');
          print('❌ Stack trace: ${StackTrace.current}');
          debugPrint('❌❌❌ ERROR CachedNetworkImage: $error');
          debugPrint('❌❌❌ URL que falló: $url');
          debugPrint('❌❌❌ Tipo de error: ${error.runtimeType}');
          return Container(
            color: Colors.red[100],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.red,
                ),
                const SizedBox(height: 8),
                Text(
                  'Error cargando imagen',
                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                ),
                Text(
                  url.substring(0, url.length > 50 ? 50 : url.length),
                  style: TextStyle(fontSize: 10, color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }
  }
}
