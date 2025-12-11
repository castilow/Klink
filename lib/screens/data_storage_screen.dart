import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/screens/storage_detail_screen.dart';

class DataStorageScreen extends StatefulWidget {
  const DataStorageScreen({super.key});

  @override
  State<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends State<DataStorageScreen> {
  final AuthController authController = Get.find<AuthController>();
  bool _isLoading = true;
  
  // Storage data
  double _totalSize = 0;
  double _conversationsSize = 0;
  double _photosSize = 0;
  double _videosSize = 0;
  double _documentsSize = 0;
  double _audioSize = 0;
  double _cacheSize = 0;
  
  int _conversationsCount = 0;
  int _photosCount = 0;
  int _videosCount = 0;
  int _documentsCount = 0;
  int _audioCount = 0;

  @override
  void initState() {
    super.initState();
    _calculateStorage();
  }

  Future<void> _calculateStorage() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = authController.currentUser.userId;
      
      // Calcular tamaño de conversaciones (mensajes en Firestore)
      await _calculateConversationsSize(userId);
      
      // Calcular tamaño de archivos en cache
      await _calculateCacheSize();
      
      // Calcular tamaño total
      _totalSize = _conversationsSize + _photosSize + _videosSize + 
                   _documentsSize + _audioSize + _cacheSize;
      
    } catch (e) {
      debugPrint('Error calculating storage: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateConversationsSize(String userId) async {
    try {
      // Obtener todos los chats del usuario
      final chatsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Chats')
          .get();

      int totalMessages = 0;
      int images = 0;
      int videos = 0;
      int docs = 0;
      int audios = 0;

      for (var chatDoc in chatsSnapshot.docs) {
        final messagesSnapshot = await chatDoc.reference
            .collection('Messages')
            .get();
        
        totalMessages += messagesSnapshot.docs.length;

        for (var msgDoc in messagesSnapshot.docs) {
          final data = msgDoc.data();
          final type = data['type'] as String?;
          
          if (type == 'image' || type == 'gif') {
            images++;
            // Estimar tamaño promedio de imagen: 500 KB
            _photosSize += 500 * 1024;
          } else if (type == 'video') {
            videos++;
            // Estimar tamaño promedio de video: 5 MB
            _videosSize += 5 * 1024 * 1024;
          } else if (type == 'doc') {
            docs++;
            // Estimar tamaño promedio de documento: 1 MB
            _documentsSize += 1 * 1024 * 1024;
          } else if (type == 'audio') {
            audios++;
            // Estimar tamaño promedio de audio: 200 KB
            _audioSize += 200 * 1024;
          }
        }
      }

      // Tamaño de conversaciones (mensajes de texto): ~1 KB por mensaje
      _conversationsSize = totalMessages * 1024;
      _conversationsCount = totalMessages;
      _photosCount = images;
      _videosCount = videos;
      _documentsCount = docs;
      _audioCount = audios;

    } catch (e) {
      debugPrint('Error calculating conversations size: $e');
    }
  }

  Future<void> _calculateCacheSize() async {
    try {
      // Calcular tamaño del cache de imágenes
      final cacheDir = await getTemporaryDirectory();
      final cachePath = cacheDir.path;
      
      // Buscar archivos en el directorio de cache
      final cacheDirectory = Directory(cachePath);
      if (await cacheDirectory.exists()) {
        await for (var entity in cacheDirectory.list(recursive: true)) {
          if (entity is File) {
            try {
              final size = await entity.length();
              final fileName = entity.path.toLowerCase();
              
              if (fileName.contains('.jpg') || fileName.contains('.jpeg') || 
                  fileName.contains('.png') || fileName.contains('.gif') ||
                  fileName.contains('.webp')) {
                _photosSize += size;
              } else if (fileName.contains('.mp4') || fileName.contains('.mov') ||
                         fileName.contains('.avi') || fileName.contains('.mkv')) {
                _videosSize += size;
              } else if (fileName.contains('.pdf') || fileName.contains('.doc') ||
                         fileName.contains('.docx') || fileName.contains('.xls') ||
                         fileName.contains('.xlsx') || fileName.contains('.ppt') ||
                         fileName.contains('.pptx') || fileName.contains('.txt')) {
                _documentsSize += size;
              } else if (fileName.contains('.mp3') || fileName.contains('.wav') ||
                         fileName.contains('.m4a') || fileName.contains('.aac') ||
                         fileName.contains('.ogg')) {
                _audioSize += size;
              } else {
                _cacheSize += size;
              }
            } catch (e) {
              // Ignorar errores al leer archivos
            }
          }
        }
      }

      // También calcular cache de documentos de la app
      final documentsDir = await getApplicationDocumentsDirectory();
      final documentsPath = documentsDir.path;
      final documentsDirectory = Directory(documentsPath);
      if (await documentsDirectory.exists()) {
        await for (var entity in documentsDirectory.list(recursive: true)) {
          if (entity is File) {
            try {
              final size = await entity.length();
              final fileName = entity.path.toLowerCase();
              
              // Excluir el archivo de cache de chats que ya contamos
              if (fileName.contains('chats_cache.json')) continue;
              
              if (fileName.contains('.jpg') || fileName.contains('.jpeg') || 
                  fileName.contains('.png') || fileName.contains('.gif') ||
                  fileName.contains('.webp')) {
                _photosSize += size;
              } else if (fileName.contains('.mp4') || fileName.contains('.mov') ||
                         fileName.contains('.avi') || fileName.contains('.mkv')) {
                _videosSize += size;
              } else if (fileName.contains('.pdf') || fileName.contains('.doc') ||
                         fileName.contains('.docx') || fileName.contains('.xls') ||
                         fileName.contains('.xlsx') || fileName.contains('.ppt') ||
                         fileName.contains('.pptx') || fileName.contains('.txt')) {
                _documentsSize += size;
              } else if (fileName.contains('.mp3') || fileName.contains('.wav') ||
                         fileName.contains('.m4a') || fileName.contains('.aac') ||
                         fileName.contains('.ogg')) {
                _audioSize += size;
              } else {
                _cacheSize += size;
              }
            } catch (e) {
              // Ignorar errores al leer archivos
            }
          }
        }
      }

    } catch (e) {
      debugPrint('Error calculating cache size: $e');
    }
  }

  String _formatBytes(double bytes) {
    if (bytes < 1024) {
      return '${bytes.toStringAsFixed(0)} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    final backgroundColor = isDarkMode ? darkThemeBgColor : lightThemeBgColor;
    final textColor = isDarkMode ? darkThemeTextColor : lightThemeTextColor;
    final cardColor = isDarkMode ? darkPrimaryContainer : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Data and Storage',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: textColor,
            ),
            onPressed: _calculateStorage,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Storage Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.storage,
                            size: 48,
                            color: primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Almacenamiento Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatBytes(_totalSize),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Storage Breakdown
                    Text(
                      'Desglose de Almacenamiento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Conversaciones
                    _buildStorageItem(
                      context,
                      isDarkMode,
                      icon: Icons.chat_bubble_outline,
                      title: 'Conversaciones',
                      size: _conversationsSize,
                      count: _conversationsCount,
                      color: Colors.blue,
                      onTap: () => Get.to(() => const StorageDetailScreen(
                        category: StorageCategory.conversations,
                        title: 'Conversaciones',
                      )),
                    ),

                    const SizedBox(height: 12),

                    // Fotos
                    _buildStorageItem(
                      context,
                      isDarkMode,
                      icon: Icons.photo_outlined,
                      title: 'Fotos',
                      size: _photosSize,
                      count: _photosCount,
                      color: Colors.purple,
                      onTap: () => Get.to(() => const StorageDetailScreen(
                        category: StorageCategory.photos,
                        title: 'Fotos',
                      )),
                    ),

                    const SizedBox(height: 12),

                    // Videos
                    _buildStorageItem(
                      context,
                      isDarkMode,
                      icon: Icons.videocam_outlined,
                      title: 'Videos',
                      size: _videosSize,
                      count: _videosCount,
                      color: Colors.red,
                      onTap: () => Get.to(() => const StorageDetailScreen(
                        category: StorageCategory.videos,
                        title: 'Videos',
                      )),
                    ),

                    const SizedBox(height: 12),

                    // Documentos
                    _buildStorageItem(
                      context,
                      isDarkMode,
                      icon: Icons.description_outlined,
                      title: 'Documentos',
                      size: _documentsSize,
                      count: _documentsCount,
                      color: Colors.orange,
                      onTap: () => Get.to(() => const StorageDetailScreen(
                        category: StorageCategory.documents,
                        title: 'Documentos',
                      )),
                    ),

                    const SizedBox(height: 12),

                    // Audio
                    _buildStorageItem(
                      context,
                      isDarkMode,
                      icon: Icons.audiotrack_outlined,
                      title: 'Audio',
                      size: _audioSize,
                      count: _audioCount,
                      color: Colors.green,
                      onTap: () => Get.to(() => const StorageDetailScreen(
                        category: StorageCategory.audio,
                        title: 'Audio',
                      )),
                    ),

                    const SizedBox(height: 12),

                    // Cache
                    _buildStorageItem(
                      context,
                      isDarkMode,
                      icon: Icons.cached,
                      title: 'Cache y Otros',
                      size: _cacheSize,
                      count: 0,
                      color: Colors.grey,
                    ),

                    const SizedBox(height: 32),

                    // Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.blue[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Los tamaños son estimaciones basadas en los archivos almacenados localmente y en la nube.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode ? Colors.grey[300] : Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStorageItem(
    BuildContext context,
    bool isDarkMode, {
    required IconData icon,
    required String title,
    required double size,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    final textColor = isDarkMode ? darkThemeTextColor : lightThemeTextColor;
    final cardColor = isDarkMode ? darkPrimaryContainer : Colors.white;
    final percentage = _totalSize > 0 ? (size / _totalSize * 100) : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatBytes(size),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$count ${count == 1 ? 'archivo' : 'archivos'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                  if (percentage > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

