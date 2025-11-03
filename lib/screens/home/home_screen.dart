import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/components/badge_indicator.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
import 'package:chat_messenger/controllers/report_controller.dart';
import 'package:chat_messenger/controllers/global_search_controller.dart';
import 'package:chat_messenger/tabs/stories/controller/story_controller.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/helpers/ads/ads_helper.dart';
import 'package:chat_messenger/helpers/ads/banner_ad_helper.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/tabs/chats/controllers/chat_controller.dart';
import 'package:chat_messenger/services/firebase_messaging_service.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';

import 'controller/home_controller.dart';
import 'dart:math' as math;
import '../../components/audio_player_bar.dart';
import '../../components/audio_recorder_overlay.dart';
import '../messages/controllers/message_controller.dart';
import 'package:chat_messenger/components/global_search_bar.dart';
import 'package:chat_messenger/components/common_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _sessionButtonController;
  late AnimationController _calendarButtonController;
  late AnimationController _addButtonController;
  late AnimationController _siriOrbController;
  late AnimationController _siriWave1Controller;
  late AnimationController _siriWave2Controller;
  late AnimationController _siriPulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sessionButtonScale;
  late Animation<double> _calendarButtonScale;
  late Animation<double> _addButtonScale;
  late Animation<double> _siriOrbRotation;
  late Animation<double> _siriWave1;
  late Animation<double> _siriWave2;
  late Animation<double> _siriPulse;

  bool _isSessionPressed = false;
  bool _isCalendarPressed = false;
  bool _isAddPressed = false;
  bool _isSearchActive = false;

  // Global key para acceder al GlobalSearchBar
  final GlobalKey<GlobalSearchBarState> _searchBarKey = GlobalKey<GlobalSearchBarState>();

  @override
  void initState() {
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _sessionButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _calendarButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _addButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Controladores para el orb estilo Siri
    _siriOrbController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _siriWave1Controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _siriWave2Controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _siriPulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _sessionButtonScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _sessionButtonController, curve: Curves.easeInOut),
    );
    
    _calendarButtonScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _calendarButtonController, curve: Curves.easeInOut),
    );
    
    _addButtonScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _addButtonController, curve: Curves.easeInOut),
    );

    // Animaciones para el orb estilo Siri
    _siriOrbRotation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _siriOrbController, curve: Curves.linear),
    );

    _siriWave1 = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _siriWave1Controller, curve: Curves.easeInOut),
    );

    _siriWave2 = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _siriWave2Controller, curve: Curves.easeInOut),
    );

    _siriPulse = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _siriPulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    
    // Iniciar animaciones continuas del orb Siri
    _siriOrbController.repeat();
    _siriWave1Controller.repeat(reverse: true);
    _siriWave2Controller.repeat(reverse: true);
    _siriPulseController.repeat(reverse: true);

    // Init other controllers
    Get.put(ReportController(), permanent: true);
    Get.put(PreferencesController(), permanent: true);

    // Load Ads
    AdsHelper.loadAds(interstitial: false);

    // Listen to incoming firebase push notifications
    FirebaseMessagingService.initFirebaseMessagingUpdates();

    // Update user presence
    UserApi.updateUserPresenceInRealtimeDb();

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sessionButtonController.dispose();
    _calendarButtonController.dispose();
    _addButtonController.dispose();
    _siriOrbController.dispose();
    _siriWave1Controller.dispose();
    _siriWave2Controller.dispose();
    _siriPulseController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // <-- Handle the user presence -->
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Only update presence if state changes to resumed or inactive/paused
    if (state == AppLifecycleState.resumed) {
      UserApi.updateUserPresence(true);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      UserApi.updateUserPresence(false);
    }
  }
  // END

  void _animateSessionButton() {
    _sessionButtonController.forward().then((_) {
      _sessionButtonController.reverse();
    });
  }

  void _animateCalendarButton() {
    _calendarButtonController.forward().then((_) {
      _calendarButtonController.reverse();
    });
  }

  void _animateAddButton() {
    _addButtonController.forward().then((_) {
      _addButtonController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get Controllers
    final HomeController homeController = Get.find();
    final ChatController chatController = Get.find();
    final StoryController storyController = Get.find();

    // Others
    final bool isDarkMode = AppTheme.of(context).isDarkMode;

    return Obx(() {
      // Get page index
      final int pageIndex = homeController.pageIndex.value;

      // Get current user
      final User currentUer = AuthController.instance.currentUser;

      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: SafeArea(
            child: Container(
              height: 80,
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  // Profile button (oculto cuando búsqueda está activa)
                  if (!_isSearchActive) ...[
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Get.toNamed(AppRoutes.profile);
                      },
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedCircleAvatar(
                            imageUrl: currentUer.photoUrl,
                            iconSize: currentUer.photoUrl.isEmpty ? 14 : null,
                            radius: 20,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                  ],
                  
                  // Search field
                  Expanded(
                    child: GlobalSearchBar(
                      key: _searchBarKey,
                      showInHeader: true,
                      onSearchActivated: () {
                        setState(() {
                          _isSearchActive = true;
                        });
                      },
                      onSearchDeactivated: () {
                        setState(() {
                          _isSearchActive = false;
                        });
                      },
                    ),
                  ),
                  
                  // Cards button y Plus button (ocultos cuando búsqueda está activa)
                  if (!_isSearchActive) ...[
                    const SizedBox(width: 12),
                    
                    // Cards button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Get.toNamed(AppRoutes.cardList);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1C1C1E)
                              : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                          border: isDarkMode
                              ? Border.all(
                                  color: const Color(0xFF404040).withOpacity(0.6),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Icon(
                          Icons.credit_card,
                          color: isDarkMode
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF64748B),
                          size: 18,
                        ),
                      ),
                    ),
                    
                    // Plus button (solo en página de chats - pageIndex == 0)
                    if (pageIndex == 0) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showNewChatMenu(context, isDarkMode);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1C1C1E)
                                : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                            border: isDarkMode
                                ? Border.all(
                                    color: const Color(0xFF404040).withOpacity(0.6),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Icon(
                            Icons.add,
                            color: isDarkMode
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF64748B),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(width: 12),
                    
                    // Calendar button (solo en página 2)
                    if (pageIndex == 2) ...[
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Get.toNamed(AppRoutes.session);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF2A2A2A).withOpacity(0.8)
                                : Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDarkMode
                                  ? const Color(0xFF404040).withOpacity(0.5)
                                  : Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            IconlyLight.logout,
                            color: isDarkMode ? Colors.white : Colors.black54,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Contenido principal o resultados de búsqueda
              if (_isSearchActive) ...[
                // Resultados de búsqueda
                _searchBarKey.currentState?.buildSearchContent() ?? Container(),
              ] else ...[
                // Contenido normal de la aplicación
                Column(
                  children: [
                    // Show Banner Ad
                    if (pageIndex != 0)
                      BannerAdHelper.showBannerAd(margin: pageIndex == 1 ? 8 : 0),

                    // Show the body content
                    Expanded(child: homeController.pages[pageIndex]),
                  ],
                ),
              ],
              
              // Audio Recorder Overlay
              Obx(() {
                final messageController = MessageController.globalInstance;
                return messageController.showRecordingOverlay.value
                    ? AudioRecorderOverlay(
                        isRecording: messageController.isRecording.value,
                        recordingDuration: messageController.recordingDurationValue.value,
                        isPressed: messageController.isMicPressed.value,
                        onCancel: () => messageController.onMicCancelled(),
                        onSend: () => messageController.onMicReleased(),
                      )
                    : const SizedBox.shrink();
              }),
              
              // Audio Player Bar (top)
              Obx(() {
                final messageController = MessageController.globalInstance;
                
                return messageController.showAudioPlayerBar.value && messageController.currentPlayingMessage.value != null
                    ? Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: AudioPlayerBar(
                          message: messageController.currentPlayingMessage.value!,
                          isPlaying: messageController.isPlaying,
                          playbackSpeed: messageController.playbackSpeed,
                          onClose: () => messageController.stopAudio(),
                          onPlayPause: () {
                            if (messageController.isPlaying) {
                              messageController.pauseAudio();
                            } else {
                              messageController.resumeAudio();
                            }
                          },
                          onSpeedChange: () => messageController.changePlaybackSpeed(),
                        ),
                      )
                    : const SizedBox.shrink();
              }),
            ],
          ),
        ),
        bottomNavigationBar: _isSearchActive 
          ? null 
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [
                          const Color(0xFF000000).withOpacity(0.95),
                          const Color(0xFF1A1A1A).withOpacity(0.98),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withOpacity(0.95),
                          const Color(0xFFF8FAFC),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  currentIndex: pageIndex,
                  onTap: (int index) {
                    HapticFeedback.selectionClick();
                    homeController.pageIndex.value = index;
                    // View stories
                    if (index == 2) {
                      storyController.viewStories();
                    }
                  },
                  type: BottomNavigationBarType.fixed,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  selectedItemColor: isDarkMode ? Colors.white : Colors.black,
                  unselectedItemColor: isDarkMode
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF64748B),
                  items: [
                    // Chats
                    BottomNavigationBarItem(
                      label: 'chats'.tr,
                      icon: BadgeIndicator(
                        icon: pageIndex == 0 ? IconlyBold.chat : IconlyLight.chat,
                        isNew: chatController.newMessage,
                      ),
                    ),
                    // Dashboard
                    BottomNavigationBarItem(
                      label: 'Dashboard'.tr,
                      icon: Icon(
                        pageIndex == 1 ? IconlyBold.chart : IconlyLight.chart,
                      ),
                    ),
                    // Stories - SIN TEXTO Y MÁS GRANDE
                    BottomNavigationBarItem(
                      label: '', // Sin texto
                      icon: _buildSiriOrb(storyController.hasUnviewedStories),
                    ),
                    // Investment
                    BottomNavigationBarItem(
                      label: 'Invertir'.tr,
                      icon: Icon(
                        pageIndex == 3 ? IconlyBold.swap : IconlyLight.swap,
                      ),
                    ),
                    // Cards
                    BottomNavigationBarItem(
                      label: 'Tarjetas'.tr,
                      icon: Icon(
                        pageIndex == 4 ? IconlyBold.wallet : IconlyLight.wallet,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
    });
  }

  void _showSearchModal(BuildContext context, bool isDarkMode) {
    final GlobalSearchController controller = Get.put(GlobalSearchController());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF000000) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Header con campo de búsqueda
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    // Botón de retroceso
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? const Color(0xFF1C1C1E) 
                              : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: isDarkMode 
                              ? const Color(0xFF8E8E93) 
                              : const Color(0xFF6D6D70),
                          size: 18,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Campo de búsqueda
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: controller.searchController,
                          autofocus: true,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar "Datos de la cuenta"',
                            hintStyle: TextStyle(
                              color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Botón Cancelar
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Grid de opciones (como Revolut)
              Expanded(
                child: Obx(() {
                  if (!controller.isSearching.value) {
                    return _buildRevolutSearchGrid(isDarkMode);
                  }

                  if (controller.searchResults.isEmpty) {
                    return _buildSearchNoResults(isDarkMode, controller.currentQuery.value);
                  }

                  return _buildSearchResultsList(controller, isDarkMode, ScrollController());
                }),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      controller.clearSearch();
    });
  }

  // Nuevo widget para el orb estilo Siri - MÁS GRANDE Y HACIA ABAJO
  Widget _buildSiriOrb(bool hasUnviewedStories) {
    return Transform.translate(
      offset: const Offset(0, 8), // Mover hacia abajo
      child: Container(
        width: 48, // Más grande (era 32)
        height: 48, // Más grande (era 32)
        child: Stack(
          children: [
            // Imagen del orb GIF con más zoom
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Transform.scale(
                  scale: 1.5, // Zoom al GIF
                  child: Image.asset(
                    'assets/images/orb.gif',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Badge indicator si hay historias no vistas
            if (hasUnviewedStories)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.6),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode, User currentUser) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1A1A1A).withOpacity(0.95)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(25),
        border: isDarkMode
            ? Border.all(
                color: const Color(0xFF404040).withOpacity(0.6),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.1),
            blurRadius: isDarkMode ? 12 : 8,
            offset: Offset(0, isDarkMode ? 4 : 2),
          ),
          if (isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 0),
              spreadRadius: 1,
            ),
        ],
      ),
    );
  }

  Widget _buildRevolutSearchGrid(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Grid de 2x2 como Revolut
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primera fila
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildRevolutGridItem(
                          icon: Icons.currency_exchange,
                          iconColor: const Color(0xFF007AFF),
                          title: 'exchange_rates'.tr,
                          isDarkMode: isDarkMode,
                          onTap: () {
                            Navigator.of(Get.context!).pop();
                            Future.delayed(const Duration(milliseconds: 100), () {
                              Get.toNamed(AppRoutes.dashboard);
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 1,
                        color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                      ),
                      Expanded(
                        child: _buildRevolutGridItem(
                          icon: Icons.account_balance_wallet,
                          iconColor: const Color(0xFF5AC8FA),
                          title: 'Cajeros\nautomáticos',
                          isDarkMode: isDarkMode,
                          onTap: () {
                            Navigator.of(Get.context!).pop();
                            Future.delayed(const Duration(milliseconds: 100), () {
                              Get.toNamed(AppRoutes.cards);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Línea divisora
                Container(
                  height: 1,
                  color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                ),
                
                // Segunda fila
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildRevolutGridItem(
                          icon: Icons.lightbulb_outline,
                          iconColor: const Color(0xFFFF9500),
                          title: 'Aprende',
                          isDarkMode: isDarkMode,
                          onTap: () {
                            Navigator.of(Get.context!).pop();
                            // Future.delayed(const Duration(milliseconds: 100), () {
                            //   Get.toNamed(AppRoutes.learn);
                            // });
                          },
                        ),
                      ),
                      Container(
                        width: 1,
                        color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                      ),
                      Expanded(
                        child: _buildRevolutGridItem(
                          icon: Icons.help_outline,
                          iconColor: const Color(0xFF5856D6),
                          title: 'Ayuda',
                          isDarkMode: isDarkMode,
                          onTap: () {
                            Navigator.of(Get.context!).pop();
                            // Future.delayed(const Duration(milliseconds: 100), () {
                            //   Get.toNamed(AppRoutes.help);
                            // });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Acciones rápidas adicionales
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildRevolutListItem(
                  icon: Icons.dashboard,
                  iconColor: const Color(0xFF007AFF),
                  title: 'Dashboard'.tr,
                  subtitle: 'Ver resumen general'.tr,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.of(Get.context!).pop();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      Get.toNamed(AppRoutes.dashboard);
                    });
                  },
                ),
                Divider(
                  height: 1,
                  color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                ),
                _buildRevolutListItem(
                  icon: Icons.account_balance_wallet,
                  iconColor: const Color(0xFF1A1A1A),
                  title: 'Billetera',
                  subtitle: 'manage_funds'.tr,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.of(Get.context!).pop();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      Get.toNamed(AppRoutes.wallet);
                    });
                  },
                ),
                Divider(
                  height: 1,
                  color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                ),
                _buildRevolutListItem(
                  icon: Icons.credit_card,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Tarjetas'.tr,
                  subtitle: 'Administrar tarjetas'.tr,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.of(Get.context!).pop();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      Get.toNamed(AppRoutes.cards);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevolutListItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
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
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevolutGridItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 48,
              color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            const SizedBox(height: 16),
            Text(
              'search_any_function'.tr,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'find_quickly_what_you_need'.tr,
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchNoResults(bool isDarkMode, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            const SizedBox(height: 16),
            Text(
              'no_results'.tr,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'no_results_for'.trParams({'query': query}),
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(GlobalSearchController controller, bool isDarkMode, ScrollController scrollController) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: controller.searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
      ),
      itemBuilder: (context, index) {
        final item = controller.searchResults[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              // Pequeño delay para que el modal se cierre antes de navegar
              Future.delayed(const Duration(milliseconds: 100), () {
                Get.toNamed(item.route);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              child: Row(
                children: [
                  // Icono
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getIconColor(item.iconData).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIconData(item.iconData),
                      color: _getIconColor(item.iconData),
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Contenido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        if (item.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Flecha
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'investment':
        return Icons.trending_up;
      case 'dashboard':
        return Icons.dashboard;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'ethereum':
        return Icons.currency_bitcoin;
      case 'woop':
        return Icons.token;
      case 'cards':
        return Icons.credit_card;
      case 'price':
        return Icons.show_chart;
      case 'contacts':
        return Icons.contacts;
      case 'profile':
        return Icons.person;
      case 'settings':
        return Icons.settings;
      default:
        return Icons.apps;
    }
  }

  Color _getIconColor(String? iconName) {
    switch (iconName) {
      case 'investment':
        return const Color(0xFF10B981);
      case 'dashboard':
        return const Color(0xFF000000);
      case 'wallet':
        return const Color(0xFF1A1A1A);
      case 'ethereum':
        return const Color(0xFF2A2A2A);
      case 'woop':
        return const Color(0xFFF59E0B);
      case 'cards':
        return const Color(0xFFEF4444);
      case 'price':
        return const Color(0xFF06B6D4);
      case 'contacts':
        return const Color(0xFFEC4899);
      case 'profile':
        return const Color(0xFF84CC16);
      case 'settings':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'good_morning'.tr;
    } else if (hour < 17) {
      return 'good_afternoon'.tr;
    } else {
      return 'good_evening'.tr;
    }
  }

  // Mostrar menú para nuevo chat
  void _showNewChatMenu(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Título
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Nuevo chat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Opción: Nuevo chat individual
                _buildMenuOption(
                  context: context,
                  isDarkMode: isDarkMode,
                  icon: Icons.person_add,
                  title: 'Nuevo chat',
                  subtitle: 'Iniciar conversación individual',
                  onTap: () {
                    Get.back();
                    Get.toNamed(AppRoutes.contacts);
                  },
                ),
                
                // Opción: Crear grupo
                _buildMenuOption(
                  context: context,
                  isDarkMode: isDarkMode,
                  icon: Icons.group_add,
                  title: 'Crear grupo',
                  subtitle: 'Crear grupo de chat',
                  onTap: () {
                    Get.back();
                    Get.toNamed(AppRoutes.createGroup, arguments: {'isBroadcast': false});
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // Construir opción del menú
  Widget _buildMenuOption({
    required BuildContext context,
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Icono
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? const Color(0xFF2A2A2A) 
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDarkMode 
                      ? Colors.white 
                      : const Color(0xFF374151),
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode 
                            ? const Color(0xFF8E8E93) 
                            : const Color(0xFF6D6D70),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Flecha
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDarkMode 
                    ? const Color(0xFF8E8E93) 
                    : const Color(0xFF6D6D70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
