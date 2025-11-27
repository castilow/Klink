import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messenger/api/video_api.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/models/comment.dart';
import 'package:chat_messenger/screens/home/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoPost {
  final String id;
  final String userId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? caption;
  final int likes;
  final int comments;
  final int shares;
  final int views;
  final DateTime createdAt;
  final User? user;
  final bool isLiked;
  final List<String> likedBy;

  VideoPost({
    required this.id,
    required this.userId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.views = 0,
    required this.createdAt,
    this.user,
    this.isLiked = false,
    this.likedBy = const [],
  });

  factory VideoPost.fromMap(Map<String, dynamic> data, String docId) {
    return VideoPost(
      id: docId,
      userId: data['userId'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      caption: data['caption'],
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      shares: data['shares'] ?? 0,
      views: data['views'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLiked: data['likedBy']?.contains(AuthController.instance.currentUser.userId) ?? false,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  VideoPost copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    int? likes,
    int? comments,
    int? shares,
    int? views,
    DateTime? createdAt,
    User? user,
    bool? isLiked,
    List<String>? likedBy,
  }) {
    return VideoPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      isLiked: isLiked ?? this.isLiked,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}

class VideosController extends GetxController {
  final RxBool isLoading = RxBool(true);
  final RxList<VideoPost> videos = RxList<VideoPost>([]);
  final RxInt currentVideoIndex = RxInt(0);
  final Map<String, VideoPlayerController> videoControllers = {};
  StreamSubscription<List<VideoPost>>? _stream;
  
  // Comments
  final RxList<Comment> currentComments = RxList<Comment>([]);
  final RxBool isLoadingComments = RxBool(false);

  // Contacts for share
  final RxList<User> contacts = RxList<User>([]);
  final RxBool isLoadingContacts = RxBool(false);
  
  // Pagination
  final int pageSize = 10;
  DocumentSnapshot? _lastDocument;
  final RxBool isLoadingMore = RxBool(false);
  final RxBool hasMore = RxBool(true);

  @override
  void onInit() {
    super.onInit();
    _getVideos();
  }

  @override
  void onClose() {
    _stream?.cancel();
    _disposeAllControllers();
    super.onClose();
  }
  
  // Método público para recargar videos
  void reloadVideos() {
    debugPrint('🔄 [VIDEOS_CONTROLLER] Recargando videos manualmente...');
    _stream?.cancel();
    _getVideos();
  }

  // --- Comments ---

  Future<void> fetchComments(String videoId) async {
    isLoadingComments.value = true;
    try {
      // Mock implementation for now as we don't have backend for comments yet
      // In a real app, this would fetch from Firestore
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      currentComments.value = [
        Comment(
          id: '1',
          userId: 'user1',
          text: '¡Increíble video! 🔥',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          user: User(userId: 'user1', fullname: 'Alex', email: '', photoUrl: 'https://i.pravatar.cc/150?u=1'),
        ),
        Comment(
          id: '2',
          userId: 'user2',
          text: 'Me encanta la edición 🎬',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          user: User(userId: 'user2', fullname: 'Sarah', email: '', photoUrl: 'https://i.pravatar.cc/150?u=2'),
        ),
      ];
    } catch (e) {
      print('Error fetching comments: $e');
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> addComment(String videoId, String text) async {
    if (text.trim().isEmpty) return;
    
    try {
      final currentUser = AuthController.instance.currentUser;
      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser.userId,
        text: text,
        createdAt: DateTime.now(),
        user: currentUser,
      );
      
      currentComments.insert(0, newComment);
      
      // Update local video comment count
      final index = videos.indexWhere((v) => v.id == videoId);
      if (index != -1) {
        final video = videos[index];
        videos[index] = video.copyWith(comments: video.comments + 1);
      }
      
      // TODO: Save to backend
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  // --- Contacts for Share ---

  Future<void> fetchContacts() async {
    isLoadingContacts.value = true;
    try {
      // Fetch contacts from UserApi
      final users = await UserApi.getAllUsers();
      // Filter out current user
      final currentUserId = AuthController.instance.currentUser.userId;
      contacts.value = users.where((u) => u.userId != currentUserId).toList();
    } catch (e) {
      print('Error fetching contacts: $e');
    } finally {
      isLoadingContacts.value = false;
    }
  }

  void _disposeAllControllers() {
    for (var controller in videoControllers.values) {
      controller.dispose();
    }
    videoControllers.clear();
  }

  Future<void> _getVideos() async {
    try {
      isLoading.value = true;
      
      final query = FirebaseFirestore.instance
          .collection('Videos')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      _stream = query.snapshots().asyncMap((snapshot) async {
        debugPrint('📹 [VIDEOS_CONTROLLER] Snapshot recibido: ${snapshot.docs.length} documentos');
        debugPrint('📹 [VIDEOS_CONTROLLER] Cambios en snapshot: ${snapshot.docChanges.length}');
        
        final List<VideoPost> videoPosts = [];
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          debugPrint('📹 [VIDEOS_CONTROLLER] Procesando video: ${doc.id}');
          final videoPost = VideoPost.fromMap(data, doc.id);
          
          // Obtener información del usuario
          User? user;
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(videoPost.userId)
                .get();
            
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              user = User.fromMap(userData);
            }
          } catch (e) {
            debugPrint('❌ [VIDEOS_CONTROLLER] Error obteniendo usuario: $e');
          }
          
          videoPosts.add(videoPost.copyWith(user: user));
        }
        
        debugPrint('📹 [VIDEOS_CONTROLLER] Total videos procesados: ${videoPosts.length}');
        return videoPosts;
      }).listen(
        (videoPosts) {
          debugPrint('📹 [VIDEOS_CONTROLLER] Videos recibidos: ${videoPosts.length}');
          if (videoPosts.isNotEmpty) {
            debugPrint('📹 [VIDEOS_CONTROLLER] Primer video ID: ${videoPosts.first.id}');
            debugPrint('📹 [VIDEOS_CONTROLLER] Último video ID: ${videoPosts.last.id}');
          }
          videos.value = videoPosts;
          isLoading.value = false;
          
          // Inicializar reproductores para los primeros videos
          _initializeVideoPlayers();
        },
        onError: (error) {
          debugPrint('❌ [VIDEOS_CONTROLLER] Error obteniendo videos: $error');
          isLoading.value = false;
        },
      );
    } catch (e) {
      debugPrint('Error en _getVideos: $e');
      isLoading.value = false;
    }
  }

  void _initializeVideoPlayers() {
    // Si no hay videos, no hacer nada
    if (videos.isEmpty) {
      debugPrint('📹 [VIDEOS_CONTROLLER] No hay videos para inicializar');
      return;
    }
    
    // PRIMERO: Pausar todos los videos que puedan estar reproduciéndose
    pauseAllVideos();
    
    // SEGUNDO: Inicializar solo el video actual y los adyacentes para optimizar memoria
    // NO reproducir aquí - solo inicializar
    final startIndex = (currentVideoIndex.value - 1).clamp(0, videos.length - 1);
    final endIndex = (currentVideoIndex.value + 2).clamp(0, videos.length);
    
    for (int i = startIndex; i < endIndex; i++) {
      if (i < videos.length && !videoControllers.containsKey(videos[i].id)) {
        _initializePlayer(videos[i]);
      }
    }
    
    // NO reproducir automáticamente aquí
    // La reproducción solo se hará cuando:
    // 1. El usuario esté en la sección de videos (índice 2)
    // 2. Y cambie de página (onPageChanged)
  }

  Future<void> _initializePlayer(VideoPost video) async {
    if (videoControllers.containsKey(video.id)) return;
    
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(video.videoUrl),
      );
      
      await controller.initialize();
      controller.setLooping(true);
      
      // IMPORTANTE: Pausar inmediatamente después de inicializar
      // para asegurar que no se reproduzca automáticamente
      controller.pause();
      
      videoControllers[video.id] = controller;
      
      // NO reproducir automáticamente aquí - solo inicializar
      // La reproducción se maneja en _playCurrentVideo()
      debugPrint('📹 [VIDEOS_CONTROLLER] Video inicializado y pausado: ${video.id}');
    } catch (e) {
      debugPrint('Error inicializando video: $e');
    }
  }

  void _playCurrentVideo() {
    if (videos.isEmpty || currentVideoIndex.value >= videos.length) return;
    
    // Verificar si estamos en la sección de videos antes de reproducir
    try {
      final homeController = Get.find<HomeController>();
      final isInVideosSection = homeController.pageIndex.value == 2;
      
      if (!isInVideosSection) {
        // Si NO estamos en la sección de videos, pausar todos y salir
        pauseAllVideos();
        debugPrint('⏸️ [VIDEOS_CONTROLLER] No estamos en la sección de videos, pausando todos');
        return;
      }
    } catch (e) {
      // Si no se puede encontrar HomeController, pausar todos por seguridad
      pauseAllVideos();
      debugPrint('⏸️ [VIDEOS_CONTROLLER] Error verificando sección, pausando todos: $e');
      return;
    }
    
    final currentVideo = videos[currentVideoIndex.value];
    
    // PRIMERO: Pausar TODOS los videos de forma síncrona
    for (var entry in videoControllers.entries) {
      if (entry.value.value.isInitialized) {
        // Pausar incluso si no está reproduciéndose para asegurar
        if (entry.value.value.isPlaying) {
          entry.value.pause();
          debugPrint('⏸️ [VIDEOS_CONTROLLER] Pausando video: ${entry.key}');
        }
      }
    }
    
    // SEGUNDO: Esperar un momento para asegurar que todos están pausados
    Future.delayed(const Duration(milliseconds: 200), () {
      // Verificar nuevamente que estamos en la sección de videos
      try {
        final homeController = Get.find<HomeController>();
        final isInVideosSection = homeController.pageIndex.value == 2;
        
        if (!isInVideosSection) {
          pauseAllVideos();
          return;
        }
      } catch (e) {
        pauseAllVideos();
        return;
      }
      
      // Verificar nuevamente que todos están pausados
      for (var entry in videoControllers.entries) {
        if (entry.key != currentVideo.id && 
            entry.value.value.isInitialized && 
            entry.value.value.isPlaying) {
          entry.value.pause();
          debugPrint('⏸️ [VIDEOS_CONTROLLER] Pausando video tardío: ${entry.key}');
        }
      }
      
      // TERCERO: Reproducir solo el video actual
      final controller = videoControllers[currentVideo.id];
      if (controller != null && controller.value.isInitialized) {
        if (!controller.value.isPlaying) {
          controller.play();
          debugPrint('▶️ [VIDEOS_CONTROLLER] Reproduciendo video: ${currentVideo.id}');
        }
      } else {
        // Si el controlador no está inicializado, solo inicializarlo
        // NO reproducir aquí - la reproducción se maneja desde onPageChanged
        if (!videoControllers.containsKey(currentVideo.id)) {
          _initializePlayer(currentVideo);
          // NO reproducir después de inicializar
          // El widget verificará la sección y reproducirá si es necesario
        }
      }
    });
  }

  // Pausar todos los videos
  void pauseAllVideos() {
    for (var entry in videoControllers.entries) {
      if (entry.value.value.isInitialized) {
        // Pausar incluso si no está reproduciéndose para asegurar
        if (entry.value.value.isPlaying) {
          entry.value.pause();
          debugPrint('⏸️ [VIDEOS_CONTROLLER] Pausando video: ${entry.key}');
        }
      }
    }
    debugPrint('⏸️ [VIDEOS_CONTROLLER] Todos los videos pausados');
  }

  void onPageChanged(int index) {
    if (index < 0 || index >= videos.length) return;
    
    debugPrint('📹 [VIDEOS_CONTROLLER] Cambio de página: $index');
    
    // PRIMERO: Verificar si estamos en la sección de videos
    try {
      final homeController = Get.find<HomeController>();
      final isInVideosSection = homeController.pageIndex.value == 2;
      
      if (!isInVideosSection) {
        // Si NO estamos en la sección de videos, solo pausar todos y no reproducir
        pauseAllVideos();
        debugPrint('⏸️ [VIDEOS_CONTROLLER] Cambio de página fuera de la sección de videos, pausando todos');
        // Actualizar el índice pero no reproducir
        currentVideoIndex.value = index;
        return;
      }
    } catch (e) {
      // Si no se puede encontrar HomeController, pausar todos por seguridad
      pauseAllVideos();
      debugPrint('⏸️ [VIDEOS_CONTROLLER] Error verificando sección en onPageChanged: $e');
      currentVideoIndex.value = index;
      return;
    }
    
    // SEGUNDO: Pausar todos los videos antes de cambiar
    pauseAllVideos();
    
    // TERCERO: Actualizar el índice
    currentVideoIndex.value = index;
    
    // CUARTO: Inicializar el video actual si no está inicializado
    if (index < videos.length) {
      final currentVideo = videos[index];
      if (!videoControllers.containsKey(currentVideo.id)) {
        _initializePlayer(currentVideo);
      }
    }
    
    // QUINTO: Reproducir el video actual después de un pequeño delay
    // (solo si estamos en la sección de videos, ya verificado arriba)
    Future.delayed(const Duration(milliseconds: 200), () {
      _playCurrentVideo();
    });
    
    // Cargar más videos si estamos cerca del final
    if (index >= videos.length - 3 && hasMore.value && !isLoadingMore.value) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadMoreVideos() async {
    if (isLoadingMore.value || !hasMore.value) return;
    
    try {
      isLoadingMore.value = true;
      
      var query = FirebaseFirestore.instance
          .collection('Videos')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);
      
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        hasMore.value = false;
        isLoadingMore.value = false;
        return;
      }
      
      _lastDocument = snapshot.docs.last;
      
      final List<VideoPost> newVideos = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final videoPost = VideoPost.fromMap(data, doc.id);
        
        // Obtener información del usuario
        User? user;
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(videoPost.userId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            user = User.fromMap(userData);
          }
        } catch (e) {
          debugPrint('Error obteniendo usuario: $e');
        }
        
        newVideos.add(videoPost.copyWith(user: user));
      }
      
      videos.addAll(newVideos);
      
      // Inicializar reproductores para los nuevos videos
      for (var video in newVideos) {
        if (!videoControllers.containsKey(video.id)) {
          _initializePlayer(video);
        }
      }
      
      isLoadingMore.value = false;
    } catch (e) {
      debugPrint('Error cargando más videos: $e');
      isLoadingMore.value = false;
    }
  }

  Future<void> toggleLike(String videoId) async {
    try {
      final currentUserId = AuthController.instance.currentUser.userId;
      final videoIndex = videos.indexWhere((v) => v.id == videoId);
      
      if (videoIndex == -1) return;
      
      final video = videos[videoIndex];
      final isLiked = video.isLiked;
      
      // Actualización optimista
      if (isLiked) {
        videos[videoIndex] = video.copyWith(
          likes: video.likes - 1,
          isLiked: false,
          likedBy: video.likedBy.where((id) => id != currentUserId).toList(),
        );
      } else {
        videos[videoIndex] = video.copyWith(
          likes: video.likes + 1,
          isLiked: true,
          likedBy: [...video.likedBy, currentUserId],
        );
      }
      
      // Actualizar en Firestore
      final videoRef = FirebaseFirestore.instance.collection('Videos').doc(videoId);
      
      if (isLiked) {
        await videoRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await videoRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    } catch (e) {
      debugPrint('Error en toggleLike: $e');
      // Revertir cambio optimista si falla
      _getVideos();
    }
  }

  Future<void> incrementShare(String videoId) async {
    try {
      final videoIndex = videos.indexWhere((v) => v.id == videoId);
      if (videoIndex == -1) return;
      
      final video = videos[videoIndex];
      
      // Actualización optimista
      videos[videoIndex] = video.copyWith(
        shares: video.shares + 1,
      );
      
      // Actualizar en Firestore
      await FirebaseFirestore.instance
          .collection('Videos')
          .doc(videoId)
          .update({
        'shares': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error en incrementShare: $e');
    }
  }

  VideoPlayerController? getVideoController(String videoId) {
    return videoControllers[videoId];
  }

  // Incrementar visitas cuando se ve un video
  Future<void> incrementViews(String videoId) async {
    try {
      final videoIndex = videos.indexWhere((v) => v.id == videoId);
      if (videoIndex == -1) return;
      
      final video = videos[videoIndex];
      
      // Actualización optimista
      videos[videoIndex] = video.copyWith(
        views: video.views + 1,
      );
      
      // Actualizar en Firestore
      await FirebaseFirestore.instance
          .collection('Videos')
          .doc(videoId)
          .update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error en incrementViews: $e');
    }
  }

  // Eliminar video
  Future<void> deleteVideo(String videoId) async {
    try {
      final currentUserId = AuthController.instance.currentUser.userId;
      final video = videos.firstWhere((v) => v.id == videoId);
      
      // Verificar que el usuario es el dueño
      if (video.userId != currentUserId) {
        throw Exception('No tienes permiso para eliminar este video');
      }
      
      // Eliminar de Firestore
      await FirebaseFirestore.instance
          .collection('Videos')
          .doc(videoId)
          .delete();
      
      // El stream se actualizará automáticamente
      debugPrint('✅ Video eliminado: $videoId');
    } catch (e) {
      debugPrint('❌ Error eliminando video: $e');
      rethrow;
    }
  }

  // Upload video
  Future<void> uploadVideo(File videoFile, {String? caption}) async {
    try {
      debugPrint('📤 [VIDEOS_CONTROLLER] Iniciando subida de video...');
      await VideoApi.uploadVideo(
        videoFile: videoFile,
        caption: caption,
      );
      debugPrint('✅ [VIDEOS_CONTROLLER] Video subido exitosamente');
      debugPrint('🔄 [VIDEOS_CONTROLLER] El stream debería actualizarse automáticamente');
      debugPrint('📊 [VIDEOS_CONTROLLER] Videos actuales: ${videos.length}');
      
      // El stream de Firestore se actualizará automáticamente cuando se agregue el nuevo documento
      // No necesitamos hacer nada más, el listener detectará el cambio
    } catch (e) {
      debugPrint('❌ [VIDEOS_CONTROLLER] Error en uploadVideo: $e');
      rethrow;
    }
  }
}

