import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/components/badge_indicator.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
import 'package:chat_messenger/controllers/report_controller.dart';
import 'package:chat_messenger/controllers/global_search_controller.dart';
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
import 'package:chat_messenger/tabs/videos/videos_screen.dart';
import 'package:chat_messenger/tabs/videos/controller/videos_controller.dart';
import 'dart:math' as math;
import '../../components/audio_player_bar.dart';
import '../../components/audio_recorder_overlay.dart';
import '../messages/controllers/message_controller.dart';
import 'package:chat_messenger/components/global_search_bar.dart';
import 'package:chat_messenger/components/klink_ai_button.dart';
import 'package:chat_messenger/components/common_header.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'dart:ui' as ui;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _sessionBtnController;
  late AnimationController _calendarButtonController;
  late AnimationController _addButtonController;

  late AnimationController _orbController;
  late Animation<double> _orbAnimation;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sessionButtonScale;
  late Animation<double> _calendarButtonScale;
  late Animation<double> _addButtonScale;

  bool _isSessionPressed = false;
  bool _isCalendarPressed = false;
  bool _isAddPressed = false;
  bool _isSearchActive = false;

  // Global key para acceder al GlobalSearchBar
  final GlobalKey<GlobalSearchBarState> _searchBarKey = GlobalKey<GlobalSearchBarState>();
  
  late PageController _pageController;

  @override
  void initState() {
    // Initialize animations
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
    );
    
    // Initialize Page Controller
    _pageController = PageController(initialPage: 0);
    
    _orbController = AnimationController(
      duration: const Duration(milliseconds: 2000), // Slow breathing
      vsync: this,
    )..repeat(reverse: true);

    _orbAnimation = CurvedAnimation(
      parent: _orbController,
      curve: Curves.easeInOut,
    );

    _sessionBtnController = AnimationController(
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
      CurvedAnimation(parent: _sessionBtnController, curve: Curves.easeInOut),
    );
    
    _calendarButtonScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _calendarButtonController, curve: Curves.easeInOut),
    );
    
    _addButtonScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _addButtonController, curve: Curves.easeInOut),
    );



    _animationController.forward();
    


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
    _orbController.dispose();
    _pageController.dispose();
    _sessionBtnController.dispose();
    _calendarButtonController.dispose();
    _addButtonController.dispose();

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
    _sessionBtnController.forward().then((_) {
      _sessionBtnController.reverse();
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

  void _onNavigationTap(int index) {
      final HomeController homeController = Get.find();
      if (homeController.pageIndex.value == index) return;
      
      homeController.pageIndex.value = index;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          index, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeInOut
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    // Get Controllers
    final HomeController homeController = Get.find();
    final ChatController chatController = Get.find();

    // Others
    final bool isDarkMode = AppTheme.of(context).isDarkMode;

    return Obx(() {
      // Get page index
      final int pageIndex = homeController.pageIndex.value;

      // Get current user
      final User currentUer = AuthController.instance.currentUser;

      return Scaffold(
      backgroundColor: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
      extendBody: true,
      extendBodyBehindAppBar: true,
        appBar: (pageIndex == 4 || pageIndex == 2 || pageIndex == 0) 
          ? null 
          : PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: SafeArea(
            child: Container(
              height: 80,
              color: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  // Profile button (oculto cuando búsqueda está activa)
                  if (!_isSearchActive) ...[
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _onNavigationTap(4);
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
                  
                  // Search field or Title
                  Expanded(
                    child: pageIndex == 0 
                      ? Text(
                          'Chats',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : GlobalSearchBar(
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
                  
                  // Plus button (oculto cuando búsqueda está activa)
                  if (!_isSearchActive) ...[
                    const SizedBox(width: 12),
                    
                    // Plus button (solo en página de chats - pageIndex == 0)
                    if (pageIndex == 0) ...[
                      const SizedBox(width: 12),
                      const KlinkAIButton(),
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
          top: pageIndex != 4,
          bottom: false, // Allow content to extend to the very bottom
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

                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const ClampingScrollPhysics(),
                        onPageChanged: (index) {
                          homeController.pageIndex.value = index;
                        },
                        itemCount: homeController.pages.length,
                        itemBuilder: (context, index) {
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double value = 1.0;
                              if (_pageController.position.haveDimensions) {
                                value = _pageController.page! - index;
                                value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                              }
                              return Center(
                                child: Transform.scale(
                                  scale: Curves.easeOut.transform(value),
                                  child: Opacity(
                                    opacity: (1 - (1 - value) * 1.5).clamp(0.4, 1.0),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: homeController.pages[index],
                          );
                        },
                      ),
                    ),
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
                        onSend: () => messageController.onMicTapped(),
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
        bottomNavigationBar: (pageIndex == 4 || _isSearchActive)
          ? null 
          : pageIndex == 2 // If in Videos section, show custom video nav bar
              ? _buildVideoNavigationBar(context, homeController, currentUer)
              : Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom > 0 
                        ? MediaQuery.of(context).padding.bottom - 5 // Very close to bottom
                        : 10,
                    top: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode ? const Color(0xFF1F1F1F) : Colors.grey[300]!,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    height: 52, // Balanced compact height
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Chats
                        _buildNavItem(
                          icon: pageIndex == 0 ? IconlyBold.chat : IconlyLight.chat,
                          isSelected: pageIndex == 0,
                          onTap: () => _onNavigationTap(0),
                        ),
                        // Contacts
                        _buildNavItem(
                          icon: pageIndex == 1 ? IconlyBold.user2 : IconlyLight.user2,
                          isSelected: pageIndex == 1,
                          onTap: () => _onNavigationTap(1),
                        ),
                        // CENTER: BREATHING GLOWING ORB
                        AnimatedBuilder(
                          animation: _orbAnimation,
                          builder: (context, child) {
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _onNavigationTap(2);
                              },
                              child: Transform.scale(
                                scale: 1.0 + (0.05 * _orbAnimation.value), // Subtle pulsing scale
                                child: Container(
                                  width: 56, 
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      // Inner intense glow (Breathing)
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withOpacity(0.4 + (0.2 * _orbAnimation.value)),
                                        blurRadius: 15 + (10 * _orbAnimation.value),
                                        spreadRadius: 0,
                                      ),
                                      // Outer ambient glow (Breathing)
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withOpacity(0.1 + (0.1 * _orbAnimation.value)),
                                        blurRadius: 30 + (10 * _orbAnimation.value),
                                        spreadRadius: 2 + (4 * _orbAnimation.value),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Transform.scale(
                                      scale: 1.7, 
                                      child: Image.asset(
                                        'assets/images/orb.gif',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Calls
                        _buildNavItem(
                          icon: pageIndex == 3 ? IconlyBold.call : IconlyLight.call,
                          isSelected: pageIndex == 3,
                          onTap: () => _onNavigationTap(3),
                        ),
                        // Profile
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _onNavigationTap(4);
                          },
                          child: Container(
                            width: 42, // Increased to 42
                            height: 42, // Increased to 42
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: pageIndex == 4 
                                    ? (isDarkMode ? Colors.white : Colors.black) 
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(21),
                              child: CachedCircleAvatar(
                                imageUrl: currentUer.photoUrl,
                                iconSize: currentUer.photoUrl.isEmpty ? 21 : null,
                                radius: 21,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
    });
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,

        child: TweenAnimationBuilder<Color?>(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        tween: ColorTween(
          begin: const Color(0xFF8E8E93), 
          end: isSelected ? Colors.white : const Color(0xFF8E8E93), // Default tween values, will be overridden by builder logic
        ),
        builder: (context, color, child) {
          final isDarkMode = Get.find<PreferencesController>().isDarkMode.value;
          final effectiveColor = isSelected 
              ? (isDarkMode ? Colors.white : Colors.black)
              : (isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70));
              
          return AnimatedScale(
            scale: isSelected ? 1.15 : 1.0, 
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack, // Subtle bounce effect
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Icon(
                icon,
                color: effectiveColor,
                size: 26,
              ),
            ),
          );
        },
      ),
    );
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

  Widget _buildVideoNavigationBar(BuildContext context, HomeController homeController, User currentUser) {
    final isDarkMode = Get.find<PreferencesController>().isDarkMode.value;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom > 0 
            ? MediaQuery.of(context).padding.bottom - 5 // Very close to bottom
            : 10,
        top: 10,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? const Color(0xFF1F1F1F) : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        height: 52, // Balanced compact height
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Match main bar spacing
          children: [
            // 1. Chats
            _AnimatedNavIcon(
              icon: IconlyLight.chat,
              onTap: () {
                HapticFeedback.selectionClick();
                _onNavigationTap(0);
              },
              isActive: homeController.pageIndex.value == 0,
              isDarkMode: isDarkMode,
            ),
            
            // 2. Contacts
            _AnimatedNavIcon(
              icon: IconlyLight.user2,
              onTap: () {
                 HapticFeedback.selectionClick();
                 _onNavigationTap(1);
              },
              isActive: homeController.pageIndex.value == 1,
              isDarkMode: isDarkMode,
            ),
          
          // 3. Center - Camera (Upload Action)
          // 3. Center - BREATHING GLOWING ORB
          GestureDetector(
            onTap: () {
               HapticFeedback.mediumImpact();
               // Stay on page and open upload modal or just act as the Orb does.
               // User asked for the Orb "here too". In main nav, Orb -> Index 2. 
               // Here we are ALREADY at index 2.
               // The original code opened upload modal. I should probably keep that behavior OR just make it congruent.
               // Let's make it simply select index 2 (refresh/stay) effectively acting as "Home of Videos".
               // Or I can trigger the upload modal if they tap it again?
               // The request was "PUT IT HERE TOO", implying visual consistency.
               // I will replace the ICON with the ORB.
               
               // If I strictly follow the visual request:
               homeController.pageIndex.value = 2; 

               // If I want to preserve the "Upload" functionality, I might lose it if I remove the logic.
               // However, the Orb in the main nav goes to Index 2.
               // If I am AT Index 2, and I tap the Orb, maybe I should open the upload modal?
               // The previous code: 
               /*
               if (Get.isRegistered<VideosController>()) {
                 final videosController = Get.find<VideosController>();
                 final isDarkMode = Get.find<PreferencesController>().isDarkMode.value;
                 showUploadVideoModal(context, videosController, isDarkMode);
               }
               */
               // Use that logic? No, the user likely wants the "Orb Experience".
               // I will stick to navigation behavior for consistency.
               // Wait, if I lose the upload ability, that's bad.
               // Use existing logic for onTap but new visuals.
               if (Get.isRegistered<VideosController>()) {
                 final videosController = Get.find<VideosController>();
                 final isDarkMode = Get.find<PreferencesController>().isDarkMode.value;
                 showUploadVideoModal(context, videosController, isDarkMode);
               }
            },
            child: AnimatedBuilder(
              animation: _orbAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (0.05 * _orbAnimation.value),
                  child: Container(
                    width: 56, 
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                          // Inner intense glow (Breathing)
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.4 + (0.2 * _orbAnimation.value)),
                            blurRadius: 15 + (10 * _orbAnimation.value),
                            spreadRadius: 0,
                          ),
                          // Outer ambient glow (Breathing)
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.1 + (0.1 * _orbAnimation.value)),
                            blurRadius: 30 + (10 * _orbAnimation.value),
                            spreadRadius: 2 + (4 * _orbAnimation.value),
                          ),
                      ],
                    ),
                    child: ClipOval(
                      child: Transform.scale(
                        scale: 1.7, 
                        child: Image.asset(
                          'assets/images/orb.gif',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 4. Calls
          _AnimatedNavIcon(
            icon: IconlyLight.call,
            onTap: () {
               HapticFeedback.selectionClick();
               _onNavigationTap(3);
            },
            isActive: homeController.pageIndex.value == 3,
            isDarkMode: isDarkMode,
          ),
          
          // 5. Profile
          GestureDetector(
            onTap: () {
               HapticFeedback.lightImpact();
               _onNavigationTap(4);
            },
            child: Container(
              width: 42, // Increased to 42
              height: 42, // Increased to 42
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: homeController.pageIndex.value == 4 
                      ? (Get.find<PreferencesController>().isDarkMode.value ? Colors.white : Colors.black) 
                      : (Get.find<PreferencesController>().isDarkMode.value ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.1)),
                  width: homeController.pageIndex.value == 4 ? 1.5 : 1.0
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: CachedCircleAvatar(
                  imageUrl: currentUser.photoUrl,
                  radius: 21,
                ),
              ),
            ),
          ),
        ],
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


class _AnimatedNavIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool? isDarkMode; // Make it optional for backward compatibility if used elsewhere

  const _AnimatedNavIcon({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.isDarkMode,
  });

  @override
  State<_AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<_AnimatedNavIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default to true (dark) if not provided, to match old behavior
    final isDark = widget.isDarkMode ?? true; 
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
         _controller.reverse();
         widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque, // Improve touch target
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Touch target padding
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Icon(
            widget.icon,
            color: widget.isActive 
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.5)),
            size: widget.isActive ? 26 : 24, // Active slightly larger
            shadows: [
              if (widget.isActive && isDark)
                const Shadow(
                  color: Colors.white54,
                  blurRadius: 8,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
