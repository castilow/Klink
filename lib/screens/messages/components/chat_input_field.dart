import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/components/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// Imports for your project's models and controllers
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/models/group.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:chat_messenger/screens/messages/components/attachment/attachment_menu.dart';
import 'dart:math' as math;
import 'package:chat_messenger/models/location.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({
    super.key,
    this.user,
    this.group,
    this.isAI = false,
  });

  final User? user;
  final Group? group;
  final bool isAI;

  @override
  ChatInputFieldState createState() => ChatInputFieldState();
}
class ChatInputFieldState extends State<ChatInputField>
    with TickerProviderStateMixin {
  
  // Controladores
  final MessageController controller = Get.find();
  
  // --- Grabación instantánea (sin long-press) ---
  bool _isPointerDown = false;
  bool _dragUnlocked = false; // arrastre bloqueado por defecto

  void _startRecordingInstant(TapDownDetails details) {
    if (_isTextMsg) return;
    // Inicia grabación real en el controlador para generar un audio reproducible
    controller.startVoiceRecording();
    HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() {
        _isRecording = true;
        _isLocked = false;
        _recordingTime = 0;
        _dragStart = details.globalPosition;
        _dragCurrent = details.globalPosition;
        _showCancelHint = false;
        _isPointerDown = true;
        _overlayArmed = false;
      });
    }
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (mounted) setState(() => _recordingTime++);
    });
    // Armar overlay en el siguiente frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _overlayArmed = true);
    });
  }

  void _updateRecordingPan(DragUpdateDetails details) {
    if (!_isRecording || _dragStart == null) return;
    if (mounted) setState(() => _dragCurrent = details.globalPosition);

    final dx = details.globalPosition.dx - _dragStart!.dx;
    if (mounted) setState(() => _showCancelHint = dx < -50);

    if (dx < -100) {
      HapticFeedback.heavyImpact();
      controller.cancelRecording();
      _cancelRecording();
    }
  }

  void _endRecordingPan(DragEndDetails details) {
    if (_isLocked) return;
    HapticFeedback.lightImpact();
    if (_isRecording) {
      // Detiene y envía el audio real inmediatamente al soltar
      controller.stopRecordingAndSend();
    }
    _isPointerDown = false;
    _cancelRecording(animate: false);
  }

  // Estados
  bool _isTextMsg = false;
  final TextEditingController _textController = TextEditingController();
  bool _showScrollButton = false;
  bool _isVisible = false;

  // Grabación
  bool _isRecording = false;
  int _recordingTime = 0; // en centésimas
  Timer? _recordingTimer;
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _showCancelHint = false;
  // Evita que el overlay capture un PointerUp espurio justo al aparecer
  bool _overlayArmed = false;

  // Offsets del micrófono al arrastrar
  double _micOffsetX = 0;
  double _micOffsetY = 0;

  // Umbral para cancelar al deslizar a la derecha
  final double _cancelThreshold = 100;

  // Keys para detectar la zona de "Cancelar" y el mic
  final GlobalKey _cancelKey = GlobalKey();
  final GlobalKey _micKey = GlobalKey();

  // Lock no requerido por esta solicitud
  bool _isLocked = false;

  // Animaciones
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  late final AnimationController _micTapController;
  late final Animation<double> _micTapScale;

  // Colores
  final Color primaryColor = const Color(0xFF000000);
  final Color iconColor = const Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();

    // Configurar animación de pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _pulseScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // Animación de "pop" para el botón de micrófono (estado normal)
    _micTapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _micTapScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _micTapController, curve: Curves.easeOutBack),
    );
    _micTapController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _micTapController.reverse();
      }
    });

    // Mostrar input con animación y programar scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isVisible = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showScrollButton = true);
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _micTapController.dispose();
    _recordingTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _handleTextChange(String value) {
    if (mounted) setState(() => _isTextMsg = value.trim().isNotEmpty);
  }

  void _handleSend() {
    final String text = controller.textController.text.trim();
    if (text.isNotEmpty) {
      controller.sendMessage(MessageType.text, text: text);
      controller.textController.clear();
      if (mounted) setState(() => _isTextMsg = false);
    }
  }

  // ---------- Lógica de grabación con Long Press (mantener presionado) ----------

  void _startRecordingHold(LongPressStartDetails details) {
    if (_isTextMsg) return;
    // Inicia grabación real en el controlador
    controller.startVoiceRecording();
    HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() {
        _isRecording = true;
        _isLocked = false; // no usado en esta iteración
        _recordingTime = 0;
        _dragStart = details.globalPosition;
        _dragCurrent = details.globalPosition;
        _showCancelHint = false;
        _overlayArmed = false;
      });
    }
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (mounted) setState(() => _recordingTime++);
    });
    // Armar overlay en el siguiente frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _overlayArmed = true);
    });
  }

  void _updateRecordingHold(LongPressMoveUpdateDetails details) {
    if (!_isRecording || _dragStart == null) return;
    if (mounted) setState(() => _dragCurrent = details.globalPosition);

    final dx = details.globalPosition.dx - _dragStart!.dx;

    if (mounted) {
      setState(() {
        _showCancelHint = dx < -50;
      });
    }

    if (dx < -100) {
      // Cancelación por deslizar a la izquierda
      HapticFeedback.heavyImpact();
      controller.cancelRecording();
      _cancelRecording();
      return;
    }
  }

  void _endRecordingHold(LongPressEndDetails details) {
    if (_isLocked) return; // no aplicable aquí, pero dejamos la guardia
    HapticFeedback.lightImpact();

    // Enviar inmediatamente al soltar si estaba grabando
    if (_isRecording) {
      controller.stopRecordingAndSend();
    }
    _cancelRecording(animate: false);
  }

  // ---------------------------------------------------------------------------

  void _cancelRecording({bool animate = true}) {
    if (animate) {
      if (mounted) setState(() => _dragCurrent = null);
      Future.delayed(const Duration(milliseconds: 200), _resetRecordingState);
    } else {
      _resetRecordingState();
    }
  }

  void _resetRecordingState() {
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isLocked = false;
        _dragStart = null;
        _dragCurrent = null;
        _showCancelHint = false;
        _recordingTime = 0;
        _micOffsetX = 0;
        _micOffsetY = 0;
        _overlayArmed = false;
      });
    }
    _recordingTimer?.cancel();
  }

  String _formatRecordingTime(int time) {
    final m = time ~/ 6000;
    final s = ((time % 6000) ~/ 100).toString().padLeft(2, '0');
    final cs = (time % 100).toString().padLeft(2, '0');
    return '$m:$s,$cs';
  }

  void _handleScrollDown() {
    if (mounted) setState(() => _showScrollButton = false);
    controller.scrollToBottom();
  }

  void _cancelReply() {
    controller.cancelReply();
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AttachmentMenu(
          sendDocs: (List<File>? files) async {
            if (files == null || files.isEmpty) return;
            for (final file in files) {
              await controller.sendMessage(MessageType.doc, file: file);
            }
          },
          sendImage: (File? image) async {
            print('🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️ sendImage CALLBACK LLAMADO 🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️');
            print('   - image != null: ${image != null}');
            print('   - image path: ${image?.path ?? "NULL"}');
            if (image == null) {
              print('   - ❌ image es null, retornando');
              return;
            }
            print('   - ✅ Llamando a controller.sendMessage(MessageType.image, file: image)');
            await controller.sendMessage(MessageType.image, file: image);
            print('   - ✅ sendMessage completado');
          },
          sendVideo: (File? video) async {
            if (video == null) return;
            await controller.sendMessage(MessageType.video, file: video);
          },
          sendLocation: (Location? location) async {
            if (location == null) return;
            await controller.sendMessage(MessageType.location, location: location);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Elevamos todo un poquito más con una pequeña traslación hacia arriba
    const lift = 0.0;
final bool kbOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return AnimatedOpacity(
      opacity: _isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedScale(
        scale: _isVisible ? 1 : 0.95,
        duration: const Duration(milliseconds: 300),
        child: Transform.translate(
          offset: const Offset(0, lift),
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 6.0,
                  bottom: kbOpen ? 10.0 : 40.0,
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Floating Glass Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(

                          decoration: BoxDecoration(
                            color: widget.isAI
                                ? (Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF0F172A).withOpacity(0.8) // Darker, richer for AI
                                    : Colors.white.withOpacity(0.9))
                                : (Theme.of(context).brightness == Brightness.dark 
                                    ? const Color(0xFF1E1E1E) 
                                    : const Color(0xFFFFFFFF)).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(
                              color: widget.isAI
                                  ? const Color(0xFF00E5FF).withOpacity(0.5) // Premium Cyan Border
                                  : (Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.white.withOpacity(0.1) 
                                      : Colors.black.withOpacity(0.05)),
                              width: widget.isAI ? 1.5 : 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.isAI 
                                    ? const Color(0xFF00E5FF).withOpacity(0.2) // Cyan glow
                                    : Colors.black.withOpacity(0.1),
                                blurRadius: widget.isAI ? 12 : 20,
                                offset: widget.isAI ? const Offset(0, 2) : const Offset(0, 10),
                                spreadRadius: widget.isAI ? 1 : 0,
                              ),
                            ],
                          ),
                          child: Obx(() {
                            final bool isDark = Theme.of(context).brightness == Brightness.dark;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (controller.isReplying && controller.replyMessage.value != null)
                                  _buildReplyView(),

                                if (controller.editingMessage.value != null)
                                  _buildEditBar(),

                                // 🔹 Si estoy grabando, muestro la barra especial
                                if (_isRecording)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                                    child: _buildRecordingMode(),
                                  )
                                else
                                  _buildNormalInput(),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              
  // Eliminado el overlay global de PointerUp (se maneja en gestos locales)

          ),
        ),
      ),
    );
  }

  Widget _buildReplyView() {
    final Message msg = controller.replyMessage.value!;
    String _getSenderName() {
      try {
        if (widget.group != null) {
          return widget.group!.getMemberProfile(msg.senderId).fullname;
        }
        if (widget.user != null) {
          return msg.isSender ? 'Tú' : widget.user!.fullname;
        }
      } catch (_) {}
      return 'Usuario';
    }

    Widget _buildPreview() {
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      if (msg.type == MessageType.audio) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgIcon('assets/icons/microphone.svg', width: 16, height: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              'Audio',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }
      return Text(
        msg.textMsg,
        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getSenderName(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 2),
                _buildPreview(),
              ],
            ),
          ),
          GestureDetector(
            // Sensibilidad inmediata para cerrar
            onTapDown: (_) => _cancelReply(),
            child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEditBar() {
    final msg = controller.editingMessage.value!;
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          const Icon(Icons.edit, size: 18, color: Color(0xFF000000)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar mensaje',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  msg.textMsg,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              controller.cancelEdit();
              if (mounted) setState(() => _isTextMsg = false);
            },
            child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalInput() {
    final bool kbOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconsColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: SafeArea(
        top: false,
        bottom: false, // Handled by parent padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end, // Align to bottom for multi-line
          children: [
            // Attachment Button
            GestureDetector(
              onTapDown: (_) => _showAttachmentMenu(),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Icon(
                  Icons.attach_file_rounded,
                  color: iconsColor,
                  size: 26,
                ),
              ),
            ),
            // Input Field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: TextField(
                  controller: controller.textController,
                  focusNode: controller.chatFocusNode,
                  onChanged: (v) {
                    _handleTextChange(v);
                    controller.isTextMsg.value = v.trim().isNotEmpty;
                  },
                  maxLines: null, // Auto-grow
                  minLines: 1,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                  cursorColor: isDark ? Colors.white : primaryColor,
                  decoration: InputDecoration(
                    hintText: controller.isEditing ? 'Edit message...' : 'Message',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                      fontSize: 16,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        // TODO: Open sticker picker
                        debugPrint("Sticker button tapped");
                      },
                      child: Icon(
                        Icons.sticky_note_2_outlined, // Sticker icon
                        color: iconsColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Send / Mic Button
            controller.editingMessage.value != null
                ? GestureDetector(
                    onTap: () async {
                      await controller.saveEditedMessage();
                      if (mounted) setState(() => _isTextMsg = false);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.check_circle,
                        color: isDark ? Colors.white : primaryColor,
                        size: 32,
                      ),
                    ),
                  )
                : _isTextMsg
                    ? GestureDetector(
                        onTap: _handleSend,
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: widget.isAI ? BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ) : null,
                          child: Icon(
                            Icons.send_rounded,
                            color: widget.isAI ? Colors.white : (isDark ? Colors.white : primaryColor),
                            size: 28,
                          ),
                        ),
                      )
                      : GestureDetector(
                        onTapDown: (details) {
                          _micTapController.forward(from: 0);
                          Future.delayed(const Duration(milliseconds: 90), () {
                            if (mounted) _startRecordingInstant(details);
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: widget.isAI ? BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ) : null,
                          child: ScaleTransition(
                            scale: _micTapScale,
                            child: Icon(
                              Icons.mic_none_rounded,
                              color: widget.isAI ? Colors.white : iconsColor,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }
Widget _buildRecordingMode() {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    color: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Tiempo (izq) + "Cancelar" centrado (compensado por el hueco del mic)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: Stack(
                    children: [
                      // Tiempo a la izquierda
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.red[400] : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatRecordingTime(_recordingTime),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // "Cancelar" centrado
                      Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: const Offset(48, 0), // compensa el hueco del mic (96/2)
                          child: GestureDetector(
                            key: _cancelKey,
                            onTapDown: (_) {
                              controller.cancelRecording();
                              _cancelRecording(animate: true);
                            },
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                color: isDark ? Colors.grey[200] : Colors.grey[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 96), // reserva para el botón grande de mic
            ],
          ),

          // Micrófono flotante arrastrable y cancelable al chocar con "Cancelar"
          Positioned(
            right: -50,
            top: -45,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,

              onPanStart: (_) {
                if (mounted) setState(() => _isPointerDown = true);
              },

              onPanUpdate: (details) {
                setState(() {
                  _micOffsetX += details.delta.dx;
                  _micOffsetY += details.delta.dy;

                  // Detecta si el centro del mic cae cerca del centro de "Cancelar"
                  final RenderBox? cancelBox =
                      _cancelKey.currentContext?.findRenderObject() as RenderBox?;
                  final RenderBox? micBox =
                      _micKey.currentContext?.findRenderObject() as RenderBox?;

                  if (cancelBox != null && micBox != null) {
                    final Offset cancelCenter =
                        cancelBox.localToGlobal(cancelBox.size.center(Offset.zero));
                    final Offset micCenter =
                        micBox.localToGlobal(micBox.size.center(Offset.zero));

                    final double dx = (micCenter.dx - cancelCenter.dx).abs();
                    final double dy = (micCenter.dy - cancelCenter.dy).abs();

                    const double hitRadius = 48.0; // sensibilidad
                    if (dx <= hitRadius && dy <= hitRadius) {
                      HapticFeedback.heavyImpact();
                      _isPointerDown = false;
                      _cancelRecording();
                      return;
                    }
                  }
                });
              },

              onPanEnd: (_) {
                if (mounted) {
                  setState(() {
                    _isPointerDown = false;
                    _micOffsetX = 0;
                    _micOffsetY = 0;
                  });
                }
                // Arrastre finalizado: si sigue grabando, enviar
                if (_isRecording) {
                  controller.stopRecordingAndSend();
                  _cancelRecording(animate: false);
                }
              },

              child: Padding(
                padding: const EdgeInsets.all(12.0), // más área para agarrar
                child: AnimatedContainer(
                  key: _micKey,
                  duration: _isPointerDown
                      ? Duration.zero
                      : const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()..translate(_micOffsetX, _micOffsetY),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) {
                          return Transform.scale(
                            scale: _pulseScale.value * 1.35,
                            child: Opacity(
                              opacity: _pulseOpacity.value,
                              child: Container(
                                width: 108,
                                height: 108,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (isDark ? const Color(0xFF4A9EFF) : Colors.blue).withOpacity(isDark ? 0.25 : 0.18),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF4A9EFF) : const Color(0xFF1DA1F2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.4 : 0.22),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SvgIcon(
                            'assets/icons/microphone.svg',
                            width: 40,
                            height: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ], // <- CIERRA children del Stack PRINCIPAL
      ),   // <- cierra Stack
   );
  }
}