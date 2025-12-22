import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/screens/messages/components/klink_ai_history_screen.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:chat_messenger/screens/messages/components/chat_input_field.dart';
import 'package:chat_messenger/controllers/klink_ai_chat_controller.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import 'package:chat_messenger/screens/messages/components/typing_indicator_bubble.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';

class KlinkAIChatView extends StatefulWidget {
  final User user;

  const KlinkAIChatView({super.key, required this.user});

  @override
  State<KlinkAIChatView> createState() => _KlinkAIChatViewState();
}

class _KlinkAIChatViewState extends State<KlinkAIChatView> with TickerProviderStateMixin {
  late MessageController controller;
  late AnimationController _bgController;
  late Animation<Color?> _bgColor1;
  late Animation<Color?> _bgColor2;
  late DateTime _sessionStartTime;
  
  // Passport animations
  late AnimationController _passportController;
  late AnimationController _passportShimmerController;
  late Animation<double> _passportFlipAnimation;
  late Animation<double> _passportShimmerAnimation;
  late Animation<double> _interiorOpacityAnimation;
  late Animation<Offset> _passportScrollAnimation;
  bool _isPassportOpen = false;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime(2024); // Show all history by default
    _showContent = false; // Inicializar para mostrar el pasaporte primero
    
    // Inicializar KlinkAIChatController si no existe
    if (!Get.isRegistered<KlinkAIChatController>()) {
      Get.put(KlinkAIChatController());
    }
    final klinkAIController = Get.find<KlinkAIChatController>();
    
    // Inicializar un nuevo chat si no hay uno activo
    if (!klinkAIController.hasActiveChat()) {
      klinkAIController.initializeNewChat();
    }
    
    // Initialize controller for this chat
    // Ensure we don't duplicate if it already exists
    if (Get.isRegistered<MessageController>()) {
      // If the controller exists but for a different user, delete it and create a new one
      final existingController = Get.find<MessageController>();
      if (existingController.user?.userId != widget.user.userId) {
        debugPrint('⚠️ Replacing MessageController: User mismatch (${existingController.user?.userId} vs ${widget.user.userId})');
        // Need to delete carefully
        Get.delete<MessageController>();
        controller = Get.put(MessageController(isGroup: false, user: widget.user));
      } else {
        debugPrint('✅ Using existing MessageController for user: ${widget.user.userId}');
        controller = existingController;
      }
    } else {
       debugPrint('🆕 Creating new MessageController for user: ${widget.user.userId}');
       controller = Get.put(MessageController(isGroup: false, user: widget.user));
    }

    // Background Animation
    _bgController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _bgColor1 = ColorTween(
      begin: const Color(0xFF0F2027),
      end: const Color(0xFF203A43),
    ).animate(_bgController);

    _bgColor2 = ColorTween(
      begin: const Color(0xFF2C5364),
      end: const Color(0xFF0F2027),
    ).animate(_bgController);
    
    // Initialize passport animations
    _passportController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _passportShimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _passportFlipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _passportController, curve: Curves.easeInOut),
    );
    _passportShimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _passportShimmerController, curve: Curves.easeInOut),
    );
    _interiorOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _passportController, 
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
    _passportScrollAnimation = Tween<Offset>(
      begin: Offset.zero, 
      end: const Offset(0, -2.0),
    ).animate(
      CurvedAnimation(
        parent: _passportController, 
        curve: const Interval(0.0, 0.8, curve: Curves.easeInCubic),
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _passportController.dispose();
    _passportShimmerController.dispose();
    // Do not dispose controller here if it's managed by GetX pages, but since we did Get.put, we might need to.
    // Standard MessageScreen relies on GetX to dispose when route pops.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _bgColor1.value!,
                  _bgColor2.value!,
                  Colors.black,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Main Content with top padding for header (only show after passport opens)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: _showContent
                    ? Padding(
                        key: const ValueKey('content'),
                        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 70),
                        child: Column(
                          children: [
                            Expanded(child: _buildMessageList()),
                            ChatInputField(user: widget.user, isAI: true),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty-content')),
                ),
                
                // Passport (shown before content)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: !_showContent
                    ? Center(
                        key: const ValueKey('passport'),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          child: Transform.translate(
                            offset: const Offset(0, -10),
                            child: _buildWorldIDPassport(),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
                ),
                
                // Floating Header (only show after passport opens)
                if (_showContent)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildHeader(context),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            bottom: 12,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                onPressed: () => Get.back(),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset('assets/images/app_logo.png'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Klink AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // New Conversation Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () async {
                    // Crear nueva conversación con nuevo chatId
                    final klinkAIController = Get.find<KlinkAIChatController>();
                    klinkAIController.initializeNewChat();
                    
                    // Limpiar mensajes actuales y recargar
                    controller.messages.clear();
                    controller.reloadMessages();
                    
                    // Create new visual session
                    setState(() {
                      _sessionStartTime = DateTime.now();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // History Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () async {
                    // Guardar conversación actual antes de ir al historial
                    final result = await Get.to(() => KlinkAIHistoryScreen(user: widget.user));
                    // Si se seleccionó una conversación, recargar mensajes
                    if (result == true) {
                      // Actualizar _sessionStartTime para mostrar todos los mensajes de la conversación seleccionada
                      setState(() {
                        _sessionStartTime = DateTime(2024); // Mostrar todo el historial
                      });
                      // Recargar mensajes con el nuevo chatId
                      controller.reloadMessages();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Colors.cyan));
      }
      
      // Filter based on session start time
      final displayMessages = controller.messages.where((m) {
        if (m.sentAt == null) return true; // Pending messages (just sent)
        return m.sentAt!.isAfter(_sessionStartTime);
      }).toList();
      
      // Si no hay mensajes, mostrar indicador de nueva conversación
      if (displayMessages.isEmpty) {
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Logo Effect
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Welcome Text
                Text(
                  'Klink AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.cyan.withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '¿En qué puedo ayudarte hoy?',
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
      
      
      // Calculate total item count: messages + typing indicator (if active)
      final showTypingIndicator = controller.isAIResponding.value;
      final itemCount = displayMessages.length + (showTypingIndicator ? 1 : 0);
      
      return AnimationLimiter(
        child: ListView.builder(
          reverse: true,
          itemCount: itemCount,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemBuilder: (context, index) {
            // If typing indicator is shown, it should be at index 0 (since reverse: true)
            if (showTypingIndicator && index == 0) {
               return AnimationConfiguration.staggeredList(
                position: 0,
                duration: const Duration(milliseconds: 375),
                child: const SlideAnimation(
                  verticalOffset: 20.0,
                  child: FadeInAnimation(
                    child: TypingIndicatorBubble(),
                  ),
                ),
              );
            }
            
            // Adjust index to get message from list
            final messageIndex = showTypingIndicator ? index - 1 : index;
            final message = displayMessages[messageIndex];
            final isMe = message.isSender;

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        // Glassmorphism effect
                        color: isMe 
                            ? const Color(0xFF00E5FF).withOpacity(0.15) 
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                        ),
                        border: Border.all(
                          color: isMe 
                              ? const Color(0xFF00E5FF).withOpacity(0.3) 
                              : Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        message.textMsg,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildWorldIDPassport() {
    final screenHeight = MediaQuery.of(context).size.height;
    final passportHeight = (screenHeight * 0.6).clamp(500.0, 700.0);
    
    return GestureDetector(
      onTap: _handlePassportTap,
      child: Stack(
        children: [
          // Página interior (debajo)
          AnimatedBuilder(
            animation: _interiorOpacityAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _interiorOpacityAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: passportHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Imagen de la página interior
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/worldcoin-passport-interior.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        
                        // Efecto de brillo sutil en la página interior
                        AnimatedBuilder(
                          animation: _passportShimmerAnimation,
                          builder: (context, child) {
                            return Positioned.fill(
                              child: Transform.translate(
                                offset: Offset(_passportShimmerAnimation.value * MediaQuery.of(context).size.width * 0.5, 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.05),
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Portada del pasaporte (encima)
          AnimatedBuilder(
            animation: _passportFlipAnimation,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_passportFlipAnimation.value * math.pi * 0.6),
                child: Container(
                  width: double.infinity,
                  height: passportHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[900]!,
                        Colors.black,
                        Colors.grey[800]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Imagen del pasaporte (portada)
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/worldcoin-passport.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        
                        // Efecto de brillo en la portada
                        AnimatedBuilder(
                          animation: _passportShimmerAnimation,
                          builder: (context, child) {
                            return Positioned.fill(
                              child: Transform.translate(
                                offset: Offset(_passportShimmerAnimation.value * MediaQuery.of(context).size.width, 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handlePassportTap() {
    HapticFeedback.lightImpact();
    
    if (_isPassportOpen) {
      return; // No permitir cerrar una vez abierto
    }

    setState(() {
      _isPassportOpen = true;
    });
    
    // Iniciar animación del pasaporte
    _passportController.forward().then((_) {
      // Esperar un poco más antes de mostrar el contenido para que la animación se vea completa
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _showContent = true;
          });
        }
      });
    });
  }

}
