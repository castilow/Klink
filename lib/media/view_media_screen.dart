import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/components/custom_appbar.dart';
import 'package:chat_messenger/components/loading_indicator.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:video_player/video_player.dart';
import 'package:audio_session/audio_session.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

class ViewMediaScreen extends StatefulWidget {
  const ViewMediaScreen({
    super.key,
    required this.fileUrl,
    this.isVideo = false,
  });

  final String fileUrl;
  final bool isVideo;

  @override
  State<ViewMediaScreen> createState() => _ViewMediaScreenState();
}

class _ViewMediaScreenState extends State<ViewMediaScreen> {
  // Controllers
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _showAppBar = true;

  void _loadVideo() async {
    if (!widget.isVideo) return;

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
    } catch (e) {
      debugPrint('⚠️ Error configurando audio: $e');
    }

    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.fileUrl));
    await _videoController?.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
    );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showAppBar
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.5),
              elevation: 0,
              leading: IconButton(
                onPressed: () => Get.back(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => AppHelper.downloadFile(widget.fileUrl),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      IconlyLight.download,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleAppBar,
        child: Container(
          color: Colors.black,
          child: SafeArea(
            bottom: false,
            child: Builder(builder: (_) {
              final bool isInitialized = _chewieController != null &&
                  _chewieController!.videoPlayerController.value.isInitialized;

              if (widget.isVideo) {
                if (isInitialized) {
                  return Chewie(
                    controller: _chewieController!,
                  );
                }
                return const Center(
                  child: LoadingIndicator(size: 35),
                );
              }

              return Hero(
                tag: widget.fileUrl,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: widget.fileUrl.startsWith('/')
                        ? Image.file(
                            File(widget.fileUrl),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildErrorWidget();
                            },
                          )
                        : CachedNetworkImage(
                            imageUrl: widget.fileUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: LoadingIndicator(size: 35),
                            ),
                            errorWidget: (context, url, error) => _buildErrorWidget(),
                          ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconlyLight.dangerCircle,
              color: Colors.white.withOpacity(0.7),
              size: 50,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar la imagen',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
