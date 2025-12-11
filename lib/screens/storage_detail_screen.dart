import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/models/chat.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';

enum StorageCategory {
  conversations,
  photos,
  videos,
  documents,
  audio,
}

class StorageDetailScreen extends StatefulWidget {
  final StorageCategory category;
  final String title;

  const StorageDetailScreen({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  State<StorageDetailScreen> createState() => _StorageDetailScreenState();
}

class ChatStorageInfo {
  final Chat chat;
  final double size;
  final int count;

  ChatStorageInfo({
    required this.chat,
    required this.size,
    required this.count,
  });
}

class _StorageDetailScreenState extends State<StorageDetailScreen> {
  final AuthController authController = Get.find<AuthController>();
  bool _isLoading = true;
  List<ChatStorageInfo> _chatsInfo = [];

  @override
  void initState() {
    super.initState();
    _calculateChatSizes();
  }

  Future<void> _calculateChatSizes() async {
    setState(() => _isLoading = true);
    _chatsInfo.clear();

    try {
      final userId = authController.currentUser.userId;
      
      // Obtener todos los chats del usuario
      final chatsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Chats')
          .get();

      final List<ChatStorageInfo> tempChatsInfo = [];

      for (var chatDoc in chatsSnapshot.docs) {
        final chatData = chatDoc.data();
        final chatId = chatDoc.id;
        final isGroup = chatData['groupId'] != null;
        
        // Obtener información del usuario o grupo
        User? user;
        String chatName = 'Chat';
        
        if (isGroup) {
          // Es un grupo
          try {
            final groupDoc = await FirebaseFirestore.instance
                .collection('Groups')
                .doc(chatId)
                .get();
            if (groupDoc.exists) {
              final groupData = groupDoc.data();
              chatName = groupData?['name'] ?? 'Grupo';
            }
          } catch (e) {
            debugPrint('Error getting group info: $e');
          }
        } else {
          // Es un chat individual
          try {
            user = await UserApi.getUser(chatId);
            chatName = user?.fullname ?? 'Usuario';
          } catch (e) {
            debugPrint('Error getting user info: $e');
          }
        }

        // Obtener mensajes de esta conversación
        final messagesSnapshot = await chatDoc.reference
            .collection('Messages')
            .get();

        double chatSize = 0;
        int itemCount = 0;

        for (var msgDoc in messagesSnapshot.docs) {
          final data = msgDoc.data();
          final type = data['type'] as String?;
          final fileUrl = data['fileUrl'] as String? ?? '';

          bool shouldInclude = false;
          double estimatedSize = 0;

          switch (widget.category) {
            case StorageCategory.conversations:
              if (type == 'text') {
                shouldInclude = true;
                estimatedSize = 1024; // ~1 KB por mensaje de texto
              }
              break;
            case StorageCategory.photos:
              if (type == 'image' || type == 'gif') {
                shouldInclude = true;
                estimatedSize = 500 * 1024; // 500 KB promedio
                itemCount++;
              }
              break;
            case StorageCategory.videos:
              if (type == 'video') {
                shouldInclude = true;
                estimatedSize = 5 * 1024 * 1024; // 5 MB promedio
                itemCount++;
              }
              break;
            case StorageCategory.documents:
              if (type == 'doc') {
                shouldInclude = true;
                estimatedSize = 1 * 1024 * 1024; // 1 MB promedio
                itemCount++;
              }
              break;
            case StorageCategory.audio:
              if (type == 'audio') {
                shouldInclude = true;
                estimatedSize = 200 * 1024; // 200 KB promedio
                itemCount++;
              }
              break;
          }

          if (shouldInclude) {
            chatSize += estimatedSize;
          }
        }

        // También buscar archivos locales relacionados con este chat
        if (widget.category != StorageCategory.conversations) {
          final localSize = await _calculateLocalFilesSize(chatId, widget.category);
          chatSize += localSize;
        }

        // Solo agregar si tiene contenido de este tipo
        if (chatSize > 0) {
          final chat = Chat.fromMap(chatData, doc: chatDoc, receiver: user);
          tempChatsInfo.add(ChatStorageInfo(
            chat: chat,
            size: chatSize,
            count: itemCount,
          ));
        }
      }

      // Ordenar por tamaño (de mayor a menor)
      tempChatsInfo.sort((a, b) => b.size.compareTo(a.size));
      
      setState(() {
        _chatsInfo = tempChatsInfo;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('Error calculating chat sizes: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<double> _calculateLocalFilesSize(String chatId, StorageCategory category) async {
    double totalSize = 0;
    
    try {
      final cacheDir = await getTemporaryDirectory();
      final documentsDir = await getApplicationDocumentsDirectory();
      
      final directories = [cacheDir, documentsDir];
      
      for (var dir in directories) {
        if (await dir.exists()) {
          await for (var entity in dir.list(recursive: true)) {
            if (entity is File) {
              try {
                final path = entity.path.toLowerCase();
                final fileName = entity.uri.pathSegments.last.toLowerCase();
                
                // Verificar si el archivo está relacionado con este chat
                if (path.contains(chatId.toLowerCase()) || fileName.contains(chatId.toLowerCase())) {
                  bool shouldInclude = false;
                  
                  switch (category) {
                    case StorageCategory.photos:
                      shouldInclude = path.contains('.jpg') || path.contains('.jpeg') || 
                                    path.contains('.png') || path.contains('.gif') ||
                                    path.contains('.webp');
                      break;
                    case StorageCategory.videos:
                      shouldInclude = path.contains('.mp4') || path.contains('.mov') ||
                                    path.contains('.avi') || path.contains('.mkv');
                      break;
                    case StorageCategory.documents:
                      shouldInclude = path.contains('.pdf') || path.contains('.doc') ||
                                    path.contains('.docx') || path.contains('.xls') ||
                                    path.contains('.xlsx') || path.contains('.ppt') ||
                                    path.contains('.pptx') || path.contains('.txt');
                      break;
                    case StorageCategory.audio:
                      shouldInclude = path.contains('.mp3') || path.contains('.wav') ||
                                    path.contains('.m4a') || path.contains('.aac') ||
                                    path.contains('.ogg');
                      break;
                    default:
                      break;
                  }
                  
                  if (shouldInclude) {
                    totalSize += await entity.length();
                  }
                }
              } catch (e) {
                // Ignorar errores
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating local files size: $e');
    }
    
    return totalSize;
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

  String _getCategoryIcon() {
    switch (widget.category) {
      case StorageCategory.conversations:
        return '💬';
      case StorageCategory.photos:
        return '📷';
      case StorageCategory.videos:
        return '🎥';
      case StorageCategory.documents:
        return '📄';
      case StorageCategory.audio:
        return '🎵';
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
          widget.title,
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
            onPressed: _calculateChatSizes,
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
            : _chatsInfo.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getCategoryIcon(),
                          style: const TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay ${widget.title.toLowerCase()}',
                          style: TextStyle(
                            fontSize: 18,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No se encontraron archivos de este tipo',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatsInfo.length,
                    itemBuilder: (context, index) {
                      final chatInfo = _chatsInfo[index];
                      final chat = chatInfo.chat;
                      final userName = chat.receiver?.fullname ?? 
                                     (chat.groupId != null ? 'Grupo' : 'Usuario');
                      final userPhoto = chat.receiver?.photoUrl ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                            // Avatar
                            CachedCircleAvatar(
                              imageUrl: userPhoto,
                              radius: 28,
                            ),
                            const SizedBox(width: 16),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        _formatBytes(chatInfo.size),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: primaryColor,
                                        ),
                                      ),
                                      if (chatInfo.count > 0) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${chatInfo.count} ${chatInfo.count == 1 ? 'archivo' : 'archivos'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Arrow
                            Icon(
                              Icons.chevron_right,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

