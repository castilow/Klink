import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messenger/api/video_api.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/api/message_api.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/models/comment.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/screens/home/controller/home_controller.dart';
import 'package:chat_messenger/services/video_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:audio_session/audio_session.dart';

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
      // Obtener comentarios de Firestore
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('Videos')
          .doc(videoId)
          .collection('Comments')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Comment> commentsList = [];
      
      for (var doc in commentsSnapshot.docs) {
        final commentData = doc.data();
        final comment = Comment.fromMap(commentData, doc.id);
        
        // Obtener información del usuario
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(comment.userId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final user = User.fromMap(userData);
            commentsList.add(comment.copyWith(user: user));
          } else {
            commentsList.add(comment);
          }
        } catch (e) {
          debugPrint('Error obteniendo usuario para comentario: $e');
          commentsList.add(comment);
        }
      }
      
      currentComments.value = commentsList;
      debugPrint('✅ [VIDEOS_CONTROLLER] Comentarios cargados: ${commentsList.length}');
    } catch (e) {
      debugPrint('❌ [VIDEOS_CONTROLLER] Error obteniendo comentarios: $e');
      currentComments.value = [];
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> addComment(String videoId, String text) async {
    if (text.trim().isEmpty) return;
    
    try {
      final currentUser = AuthController.instance.currentUser;
      final commentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Crear comentario
      final newComment = Comment(
        id: commentId,
        userId: currentUser.userId,
        text: text.trim(),
        createdAt: DateTime.now(),
        user: currentUser,
      );
      
      // Agregar a la lista local (actualización optimista)
      currentComments.insert(0, newComment);
      
      // Actualizar contador local de comentarios
      final index = videos.indexWhere((v) => v.id == videoId);
      if (index != -1) {
        final video = videos[index];
        videos[index] = video.copyWith(comments: video.comments + 1);
      }
      
      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('Videos')
          .doc(videoId)
          .collection('Comments')
          .doc(commentId)
          .set(newComment.toMap());
      
      // Actualizar contador de comentarios en el documento del video
      await FirebaseFirestore.instance
          .collection('Videos')
          .doc(videoId)
          .update({
        'comments': FieldValue.increment(1),
      });
      
      debugPrint('✅ [VIDEOS_CONTROLLER] Comentario agregado: $commentId');
    } catch (e) {
      debugPrint('❌ [VIDEOS_CONTROLLER] Error agregando comentario: $e');
      // Revertir cambio optimista
      if (currentComments.isNotEmpty && currentComments.first.id == DateTime.now().millisecondsSinceEpoch.toString()) {
        currentComments.removeAt(0);
      }
      // Recargar comentarios
      fetchComments(videoId);
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
          
          // Precargar todos los videos en caché en segundo plano
          for (var video in videoPosts) {
            VideoCacheService.instance.preloadVideo(video.videoUrl);
          }
          
          // Inicializar reproductores para los primeros videos
          _initializeVideoPlayers();
          
          // Si estamos en la sección de videos, reproducir el primer video automáticamente
          Future.delayed(const Duration(milliseconds: 500), () {
            try {
              final homeController = Get.find<HomeController>();
              if (homeController.pageIndex.value == 2) {
                playCurrentVideoIfInSection();
              }
            } catch (e) {
              debugPrint('❌ [VIDEOS_CONTROLLER] Error verificando sección después de cargar videos: $e');
            }
          });
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
    
    // SEGUNDO: Inicializar el video actual y más videos adyacentes para precarga optimizada
    // Precargar: 1 anterior + actual + 3 siguientes = 5 videos totales
    // Esto mejora la experiencia al hacer scroll
    final startIndex = (currentVideoIndex.value - 1).clamp(0, videos.length - 1);
    final endIndex = (currentVideoIndex.value + 4).clamp(0, videos.length);
    
    // Inicializar videos de forma asíncrona y priorizada
    // Primero el actual, luego los siguientes, luego el anterior
    final currentIndex = currentVideoIndex.value;
    
    // 1. Inicializar el video actual primero (prioridad alta)
    if (currentIndex < videos.length && !videoControllers.containsKey(videos[currentIndex].id)) {
      _initializePlayer(videos[currentIndex]);
    }
    
    // 2. Inicializar los siguientes videos (prioridad media)
    for (int i = currentIndex + 1; i < endIndex; i++) {
      if (i < videos.length && !videoControllers.containsKey(videos[i].id)) {
        // Agregar delay pequeño para no saturar la red
        Future.delayed(Duration(milliseconds: 100 * (i - currentIndex)), () {
          _initializePlayer(videos[i]);
        });
      }
    }
    
    // 3. Inicializar el video anterior (prioridad baja)
    if (startIndex < currentIndex && !videoControllers.containsKey(videos[startIndex].id)) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _initializePlayer(videos[startIndex]);
      });
    }
    
    // NO reproducir automáticamente aquí
    // La reproducción solo se hará cuando:
    // 1. El usuario esté en la sección de videos (índice 2)
    // 2. Y cambie de página (onPageChanged)
  }

  Future<void> _initializePlayer(VideoPost video) async {
    if (videoControllers.containsKey(video.id)) return;
    
    try {
      // Configurar audio para usar el altavoz principal (no el auricular)
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.moviePlayback,
          avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.movie,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ));
        debugPrint('✅ [VIDEOS_CONTROLLER] Audio configurado para usar altavoz principal');
      } catch (e) {
        debugPrint('⚠️ [VIDEOS_CONTROLLER] Error configurando audio: $e');
      }
      
      // Intentar obtener del caché primero
      final cachedFile = await VideoCacheService.instance.getCachedFile(video.videoUrl);
      
      VideoPlayerController controller;
      
      if (cachedFile != null && await cachedFile.exists()) {
        // Usar archivo en caché para reproducción instantánea
        debugPrint('📦 [VIDEOS_CONTROLLER] Usando video en caché: ${video.id}');
        controller = VideoPlayerController.file(cachedFile);
      } else {
        // Si no está en caché, usar URL de red
        // Pero precargar en caché en segundo plano para la próxima vez
        VideoCacheService.instance.preloadVideo(video.videoUrl);
        
        controller = VideoPlayerController.networkUrl(
          Uri.parse(video.videoUrl),
          // Configuración optimizada para carga rápida
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
          httpHeaders: {
            // Headers para mejorar la carga
            'Connection': 'keep-alive',
          },
        );
      }
      
      // Inicializar de forma asíncrona sin bloquear
      // Esto permite que otros videos se inicialicen en paralelo
      controller.initialize().then((_) {
        if (!videoControllers.containsKey(video.id)) {
          controller.setLooping(true);
          
          videoControllers[video.id] = controller;
          
          // Verificar si este es el video actual y si estamos en la sección de videos
          final isCurrentVideo = videos.isNotEmpty && 
              currentVideoIndex.value < videos.length &&
              videos[currentVideoIndex.value].id == video.id;
          
          if (isCurrentVideo) {
            // Verificar si estamos en la sección de videos
            try {
              final homeController = Get.find<HomeController>();
              final isInVideosSection = homeController.pageIndex.value == 2;
              
              if (isInVideosSection) {
                // Reproducir automáticamente si es el video actual y estamos en la sección
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (controller.value.isInitialized && !controller.value.isPlaying) {
                    controller.play();
                    debugPrint('▶️ [VIDEOS_CONTROLLER] Reproduciendo video automáticamente al inicializar: ${video.id}');
                  }
                });
              } else {
                // Si no estamos en la sección, pausar
                controller.pause();
                debugPrint('⏸️ [VIDEOS_CONTROLLER] Video inicializado y pausado (no en sección): ${video.id}');
              }
            } catch (e) {
              // Si hay error, pausar por seguridad
              controller.pause();
              debugPrint('⏸️ [VIDEOS_CONTROLLER] Video inicializado y pausado (error): ${video.id}');
            }
          } else {
            // Si no es el video actual, pausar
            controller.pause();
            debugPrint('📹 [VIDEOS_CONTROLLER] Video inicializado y pausado: ${video.id}');
          }
        } else {
          // Si ya existe otro controlador, descartar este
          controller.dispose();
        }
      }).catchError((e) {
        debugPrint('❌ [VIDEOS_CONTROLLER] Error inicializando video ${video.id}: $e');
        // Limpiar el controlador si falla
        if (videoControllers.containsKey(video.id)) {
          videoControllers.remove(video.id);
        }
        controller.dispose();
      });
      
    } catch (e) {
      debugPrint('❌ [VIDEOS_CONTROLLER] Error creando controlador para ${video.id}: $e');
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

  // Reproducir el video actual si estamos en la sección de videos
  void playCurrentVideoIfInSection() {
    try {
      final homeController = Get.find<HomeController>();
      final isInVideosSection = homeController.pageIndex.value == 2;
      
      if (!isInVideosSection) {
        debugPrint('⏸️ [VIDEOS_CONTROLLER] No estamos en la sección de videos, no reproducir');
        return;
      }
      
      if (videos.isEmpty) {
        debugPrint('⏸️ [VIDEOS_CONTROLLER] No hay videos para reproducir');
        return;
      }
      
      // Reproducir el video actual
      _playCurrentVideo();
    } catch (e) {
      debugPrint('❌ [VIDEOS_CONTROLLER] Error en playCurrentVideoIfInSection: $e');
    }
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
    
    // CUARTO: Inicializar el video actual si no está inicializado (prioridad máxima)
    if (index < videos.length) {
      final currentVideo = videos[index];
      if (!videoControllers.containsKey(currentVideo.id)) {
        // Inicializar inmediatamente el video actual
        _initializePlayer(currentVideo).then((_) {
          // Después de inicializar, reproducir si estamos en la sección correcta
          Future.delayed(const Duration(milliseconds: 100), () {
            _playCurrentVideo();
          });
        });
      } else {
        // Si ya está inicializado, reproducir inmediatamente
        Future.delayed(const Duration(milliseconds: 100), () {
          _playCurrentVideo();
        });
      }
    }
    
    // QUINTO: Precargar videos siguientes en segundo plano
    // Esto mejora la experiencia al hacer scroll
    _preloadNextVideos(index);
    
    // SEXTO: Cargar más videos si estamos cerca del final
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
      
      // Precargar nuevos videos en caché en segundo plano
      for (var video in newVideos) {
        VideoCacheService.instance.preloadVideo(video.videoUrl);
      }
      
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

  // Compartir video con un usuario a través de mensajes
  Future<void> shareVideoWithUser(String videoId, User receiver) async {
    try {
      final videoIndex = videos.indexWhere((v) => v.id == videoId);
      if (videoIndex == -1) {
        throw Exception('Video no encontrado');
      }
      
      final video = videos[videoIndex];
      
      // Crear mensaje de video
      final Message message = Message(
        msgId: AppHelper.generateID,
        senderId: AuthController.instance.currentUser.userId,
        type: MessageType.video,
        fileUrl: video.videoUrl,
        videoThumbnail: video.thumbnailUrl ?? '',
        textMsg: video.caption?.isNotEmpty == true 
            ? 'Compartí un video: ${video.caption}' 
            : 'Compartí un video',
      );
      
      // Enviar mensaje
      await MessageApi.sendMessage(
        message: message,
        receiver: receiver,
      );
      
      // Incrementar contador de shares
      await incrementShare(videoId);
      
      debugPrint('✅ [VIDEOS_CONTROLLER] Video compartido con ${receiver.fullname}');
    } catch (e) {
      debugPrint('❌ [VIDEOS_CONTROLLER] Error compartiendo video: $e');
      rethrow;
    }
  }

  VideoPlayerController? getVideoController(String videoId) {
    return videoControllers[videoId];
  }

  // Precargar videos siguientes para mejorar la experiencia de scroll
  void _preloadNextVideos(int currentIndex) {
    if (videos.isEmpty) return;
    
    // Precargar los siguientes 2-3 videos que aún no están inicializados
    final endIndex = (currentIndex + 3).clamp(0, videos.length);
    
    for (int i = currentIndex + 1; i < endIndex; i++) {
      if (i < videos.length && !videoControllers.containsKey(videos[i].id)) {
        // Precargar en caché primero (en segundo plano)
        VideoCacheService.instance.preloadVideo(videos[i].videoUrl);
        
        // Luego inicializar el reproductor con delay escalonado
        Future.delayed(Duration(milliseconds: 200 * (i - currentIndex)), () {
          _initializePlayer(videos[i]);
        });
      }
    }
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

