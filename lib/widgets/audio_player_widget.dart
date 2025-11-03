import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:chat_messenger/models/message.dart';

class AudioPlayerWidget extends StatefulWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final Function(Duration) onSeek;
  final bool isSender;
  final String? timestamp;
  final bool isRead;
  final bool showTimestamp;
  final String? transcription;

  const AudioPlayerWidget({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onSeek,
    this.isSender = false,
    this.timestamp,
    this.isRead = false,
    this.showTimestamp = true,
    this.transcription,
    this.message,
  });

  final Message? message;

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveformController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Alturas deterministas del espectro + estado UI
  late final List<double> _waveformDataFixed;
  bool _isInitialized = false;
  bool _showTranscription = false;
  bool _isDragging = false;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _waveformDataFixed = _buildSeededHeights(barCountBase: 25);
    _isInitialized = true;
  }

  void _initializeAnimations() {
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutBack),
    );

    if (widget.isPlaying) {
      _waveformController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  // Si tienes waveform real en Message, úsala; si no, mantenemos patrón bonito estable
  List<double> _buildSeededHeights({int barCountBase = 25}) {
    final seed = widget.message?.hashCode ?? 42; // evita depender de Message.id
    final rnd = math.Random(seed);
    return List.generate(barCountBase, (i) {
      final t = i / (barCountBase - 1);
      final base = 0.25 + 0.55 * math.sin(t * math.pi); // curva suave
      final jitter = (rnd.nextDouble() - 0.5) * 0.08;
      return (base + jitter).clamp(0.16, 0.92);
    });
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _waveformController.repeat();
        _pulseController.repeat(reverse: true);
      } else {
        _waveformController.stop();
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _waveformController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Play/Pause inmediato (optimista) + avisar al padre
  void _handlePlayPauseTap() {
    if (!widget.isPlaying) {
      _waveformController.repeat();
      _pulseController.repeat(reverse: true);
    } else {
      _waveformController.stop();
      _pulseController.stop();
      _pulseController.reset();
    }
    widget.onPlayPause();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return m == 0 ? '0:$s' : '$m:$s';
  }

  String _speedLabel() {
    if (_playbackSpeed == 1.0) return '1x';
    if (_playbackSpeed == 1.5) return '1.5x';
    return '2x';
  }

  Color _getBubbleColor() {
    return widget.isSender ? const Color(0xFFDCF8C6) : Colors.white;
  }

  Color _getTextColor() => Colors.black87;
  Color _getWaveformColor() => const Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const SizedBox.shrink();

    // --- Cálculo de ancho (evitar overflow) ---
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxWidth = screenWidth * 0.6;

    final double secs = widget.duration.inSeconds.toDouble();
    double base = secs <= 1 ? 160.0 : (secs <= 9 ? 240.0 : 320.0);

    const double kMinSafeWidth = 210.0; // caben botón, pills y timestamp
    double dynamicWidth = math.min(maxWidth, math.max(kMinSafeWidth, base));
    final bool isCompact = dynamicWidth <= 220.0;

    return SizedBox(
      width: dynamicWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getBubbleColor(),
          borderRadius: BorderRadius.circular(18), // look WhatsApp
          // sin sombra para no “engordar” visualmente
        ),
        child: Row(
          children: [
            _buildPlayButton(),
            const SizedBox(width: 12),
            Expanded(child: _buildWhatsAppStyleWaveform()),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSpeedButton(),
                      if (!isCompact && widget.transcription != null) ...[
                        const SizedBox(width: 6),
                        _buildTranscriptionButton(),
                      ],
                    ],
                  ),
                  if (widget.showTimestamp) _buildTimestampSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    final buttonSize = isLargeScreen ? 36.0 : (isTablet ? 34.0 : 32.0);
    final iconSize = isLargeScreen ? 18.0 : (isTablet ? 17.0 : 16.0);
    final shadowBlur = isLargeScreen ? 8.0 : (isTablet ? 6.0 : 4.0);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPlaying ? _pulseAnimation.value : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: GestureDetector(
              onTap: _handlePlayPauseTap, // <- play inmediato
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  color: _getWaveformColor(),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getWaveformColor().withOpacity(0.3),
                      blurRadius: shadowBlur,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    widget.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Barras con color de progreso + tap/drag seek
  Widget _buildWhatsAppStyleWaveform() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLarge = screenWidth > 900;
    final timeFs = isLarge ? 12.0 : (isTablet ? 11.5 : 11.0);

    final durMs = widget.duration.inMilliseconds.clamp(1, 1 << 30);
    final secs = widget.duration.inSeconds.toDouble();
    final int barCount = secs <= 1 ? 12 : (secs <= 9 ? 18 : 26);

    final bars = List.generate(barCount, (i) {
      final idx = ((i / (barCount - 1)) * (_waveformDataFixed.length - 1)).round();
      return _waveformDataFixed[idx];
    });

    final progress = (widget.position.inMilliseconds / durMs).clamp(0.0, 1.0);
    final currentBar = (progress * barCount).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => setState(() => _isDragging = true),
          onHorizontalDragUpdate: (d) =>
              _handleSeekFromLocalPosition(d.localPosition.dx, barCount),
          onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
          onTapDown: (d) => _handleSeekFromLocalPosition(d.localPosition.dx, barCount),
          child: SizedBox(
            height: 34,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final barW = math.max(2.0, w / (barCount * 2.2));
                final gap = (barW * 0.8).clamp(1.0, 6.0); // evita gaps grandes
                final played = _getWaveformColor();
                final future = _getWaveformColor().withOpacity(0.35);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(barCount, (i) {
                    final h = bars[i] * 32.0;
                    final isPlayed = i <= currentBar;
                    return Container(
                      width: barW,
                      height: h,
                      margin: EdgeInsets.symmetric(horizontal: gap / 2),
                      decoration: BoxDecoration(
                        color: isPlayed ? played : future,
                        borderRadius: BorderRadius.circular(1.2),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              _formatDuration(widget.position),
              style: TextStyle(
                color: _getTextColor().withOpacity(0.7),
                fontSize: timeFs,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(width: 3, height: 3, decoration: BoxDecoration(color: _getWaveformColor(), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              _formatDuration(widget.duration),
              style: TextStyle(
                color: _getTextColor().withOpacity(0.7),
                fontSize: timeFs,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleSeekFromLocalPosition(double dx, int barCount) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final usable = (box.size.width - 80).clamp(60.0, box.size.width);
    final local = dx.clamp(0.0, usable);
    final ratio = (local / usable).clamp(0.0, 1.0);
    final ms = (widget.duration.inMilliseconds * ratio).round();
    widget.onSeek(Duration(milliseconds: ms));
  }

  Widget _buildTranscriptionButton() {
    return GestureDetector(
      onTap: () => setState(() => _showTranscription = !_showTranscription),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _getWaveformColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getWaveformColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.keyboard_arrow_right, size: 14, color: _getWaveformColor()),
            const SizedBox(width: 4),
            Text(
              'A',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getWaveformColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    final timestampFontSize = isLargeScreen ? 11.0 : (isTablet ? 10.5 : 10.0);
    final iconSize = isLargeScreen ? 14.0 : (isTablet ? 13.0 : 12.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.timestamp != null) ...[
          Text(
            widget.timestamp!,
            style: TextStyle(
              color: _getTextColor().withOpacity(0.7),
              fontSize: timestampFontSize,
            ),
          ),
          SizedBox(width: isLargeScreen ? 6.0 : (isTablet ? 5.0 : 4.0)),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.done,
              size: iconSize,
              color: widget.isRead
                  ? _getWaveformColor()
                  : _getTextColor().withOpacity(0.5),
            ),
            if (widget.isRead) ...[
              SizedBox(width: isLargeScreen ? 2.0 : (isTablet ? 1.5 : 1.0)),
              Icon(Icons.done, size: iconSize, color: _getWaveformColor()),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedButton() {
    void cycle() {
      setState(() {
        if (_playbackSpeed == 1.0) _playbackSpeed = 1.5;
        else if (_playbackSpeed == 1.5) _playbackSpeed = 2.0;
        else _playbackSpeed = 1.0;
      });
      // Si usas un player externo, emite aquí el cambio real:
      // widget.onChangeSpeed?.call(_playbackSpeed);
    }

    return GestureDetector(
      onTap: cycle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _getWaveformColor().withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _getWaveformColor().withOpacity(0.28),
            width: 1,
          ),
        ),
        child: Text(
          _speedLabel(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _getWaveformColor(),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// Notas para el reproductor real:
// 	•	El cambio visual de play/pause es inmediato con _handlePlayPauseTap(), pero la lógica real de audio sigue en tu callback onPlayPause().
// 	•	Si usas just_audio o similar, conecta el cambio de velocidad en donde corresponda (dejé el comentario onChangeSpeed por si lo manejas desde arriba).