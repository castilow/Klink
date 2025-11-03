import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/api/report_api.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/api/message_api.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/components/custom_appbar.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/app_controller.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/controllers/report_controller.dart';
import 'package:chat_messenger/helpers/date_helper.dart';
import 'package:chat_messenger/helpers/routes_helper.dart';
import 'package:chat_messenger/models/app_info.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import 'components/action_button.dart';
import 'controllers/profile_view_controller.dart';

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({
    super.key,
    required this.user,
    required this.isGroup,
  });

  final User user;
  final bool isGroup;

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }
  
  // Calcula la opacidad del título en el AppBar basado en el scroll
  double get _titleOpacity {
    const double fadeStart = 200.0;
    const double fadeEnd = 300.0;
    
    if (_scrollOffset <= fadeStart) return 0.0;
    if (_scrollOffset >= fadeEnd) return 1.0; // Se mantiene visible una vez alcanzado
    
    return (_scrollOffset - fadeStart) / (fadeEnd - fadeStart);
  }
  
  // Calcula la opacidad de la imagen de fondo
  double get _backgroundOpacity {
    const double fadeStart = 100.0;
    const double fadeEnd = 300.0;
    
    if (_scrollOffset <= fadeStart) return 1.0;
    if (_scrollOffset >= fadeEnd) return 0.0; // Se mantiene invisible una vez desvanecida
    
    return 1.0 - ((_scrollOffset - fadeStart) / (fadeEnd - fadeStart));
  }
  
  // Calcula el color del AppBar - se mantiene blanco una vez alcanzado el límite
  Color get _appBarColor {
    const double fadeStart = 200.0;
    const double fadeEnd = 300.0;
    
    if (_scrollOffset <= fadeStart) return Colors.transparent;
    if (_scrollOffset >= fadeEnd) return Colors.white; // Se mantiene blanco para siempre
    
    double opacity = (_scrollOffset - fadeStart) / (fadeEnd - fadeStart);
    return Colors.white.withOpacity(opacity);
  }

  void _showFullScreenImage(BuildContext context, [String? imageUrl]) {
    final String displayImageUrl = imageUrl ?? widget.user.photoUrl;
    final String heroTag = imageUrl != null ? 'image-$imageUrl' : 'profile-${widget.user.userId}';
    
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (BuildContext context, _, __) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Hero(
              tag: heroTag,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: displayImageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                          size: 64,
                        ),
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
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    final controller = Get.put(ProfileViewController(widget.user.userId));
    final ReportController reportController = Get.find();

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom Sliver App Bar with profile photo
          SliverAppBar(
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: isDarkMode ? (_appBarColor == Colors.white ? const Color(0xFF1E1E1E) : _appBarColor) : _appBarColor,
            foregroundColor: isDarkMode ? (_titleOpacity > 0.5 ? Colors.white : Colors.white) : (_titleOpacity > 0.5 ? Colors.black : Colors.white),
            title: Opacity(
              opacity: _titleOpacity,
              child: Text(
                widget.user.fullname,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            actions: [
              // Botón "Editar" 
              Opacity(
                opacity: _titleOpacity,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed: () {
                      Get.toNamed(AppRoutes.editProfile, arguments: {'user': widget.user});
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Editar',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo que aparece al hacer scroll
                  Container(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  ),
                  
                  // Background image - user photo as full background con fade effect
                  Opacity(
                    opacity: _backgroundOpacity,
                    child: GestureDetector(
                      onTap: () => widget.user.photoUrl.isNotEmpty 
                        ? _showFullScreenImage(context)
                        : null,
                      child: Hero(
                        tag: 'profile-${widget.user.userId}',
                        child: Container(
                          decoration: BoxDecoration(
                            image: widget.user.photoUrl.isNotEmpty 
                              ? DecorationImage(
                                  image: NetworkImage(widget.user.photoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                            gradient: widget.user.photoUrl.isEmpty 
                              ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isDarkMode 
                                    ? [
                                        primaryColor.withOpacity(0.8),
                                        Colors.black,
                                      ]
                                    : [
                                        primaryColor,
                                        secondaryColor,
                                      ],
                                )
                              : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Dark overlay for better text visibility (también con fade)
                  Opacity(
                    opacity: _backgroundOpacity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // User name and status overlaid at bottom - ELIMINADOS
                  // Positioned(
                  //   bottom: 120,
                  //   left: 24,
                  //   right: 24,
                  //   child: Opacity(
                  //     opacity: _backgroundOpacity,
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         // Nombre del usuario eliminado
                  //         // Estado "últ. vez recientemente" eliminado
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  
                  // Action buttons at bottom (con fade effect) - ELIMINADOS
                  // Positioned(
                  //   bottom: 24,
                  //   left: 24,
                  //   right: 24,
                  //   child: Opacity(
                  //     opacity: _backgroundOpacity,
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //       children: [
                  //         // Botones eliminados: llamar, video, silenciar, buscar, más
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: defaultPadding),
                    // Profile name with online status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.user.fullname,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              FutureBuilder<User?>(
                                future: UserApi.getUser(widget.user.userId),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const SizedBox.shrink();
                                  final User? updatedUser = snapshot.data;
                                  if (updatedUser == null) return const SizedBox.shrink();
                                  return Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: updatedUser.isOnline ? Colors.green : Colors.grey,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (updatedUser.isOnline ? Colors.green : Colors.grey).withOpacity(0.5),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Username
                                                    Text(
                            '@${widget.user.username}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isDarkMode ? Colors.grey[400] : greyColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Last seen with animation
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: defaultPadding,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDarkMode 
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                              ),
                            ),
                            child: FutureBuilder<User?>(
                              future: UserApi.getUser(widget.user.userId),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox.shrink();
                                final User? updatedUser = snapshot.data;
                                if (updatedUser == null) return const SizedBox.shrink();
                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    updatedUser.isOnline 
                                      ? 'online'.tr
                                      : "${updatedUser.lastActive?.getLastSeenTime}",
                                    key: ValueKey(updatedUser.isOnline),
                                    style: TextStyle(
                                      color: updatedUser.isOnline ? Colors.green : (isDarkMode ? Colors.grey[300] : Colors.grey[600]),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action Buttons
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: defaultPadding,
                        horizontal: defaultPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: defaultPadding * 1.5,
                              vertical: defaultPadding * 0.7,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  IconlyBold.chat,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'message'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Contact info and media sections like in reference image
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 16),
                      child: Column(
                        children: [
                          // Media grid - imágenes reales de la conversación
                          Container(
                            height: 300,
                            child: StreamBuilder<List<Message>>(
                              stream: MessageApi.getMessages(widget.user.userId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_library_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay imágenes compartidas',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                // Filtrar solo mensajes con imágenes
                                final imageMessages = snapshot.data!
                                    .where((message) => message.type == MessageType.image && !message.isDeleted && message.fileUrl.isNotEmpty)
                                    .toList();
                                
                                if (imageMessages.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_library_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay imágenes compartidas',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                return GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                  ),
                                  itemCount: imageMessages.length,
                                  itemBuilder: (context, index) {
                                    final message = imageMessages[index];
                                    return GestureDetector(
                                      onTap: () => _showFullScreenImage(context, message.fileUrl),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: message.fileUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              color: isDarkMode ? Colors.grey[400] : Colors.grey,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bio section
                    if (widget.user.bio.isNotEmpty) ...[
                      const Divider(height: 32),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
                        padding: const EdgeInsets.all(defaultPadding),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDarkMode 
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                ? Colors.black.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.white.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    IconlyBold.infoSquare,
                                    color: isDarkMode ? Colors.white : primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'about'.tr,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: isDarkMode ? Colors.white : primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.user.bio,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Divider(height: 32),

                    // Security info
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
                                              decoration: BoxDecoration(
                          color: isDarkMode 
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDarkMode 
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                          ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.white.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(IconlyLight.lock, color: isDarkMode ? Colors.white : primaryColor),
                        ),
                        title: Text(
                          'encrypted_message'.tr,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'end_to_end_encrypted'.tr,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDarkMode ? Colors.grey[400] : greyColor,
                          ),
                        ),
                      ),
                    ),

                    // Block and Report options
                    const SizedBox(height: defaultPadding),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDarkMode 
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          Obx(() {
                            final bool isBlocked = controller.isBlocked.value;
                            return ListTile(
                              onTap: () => controller.toggleBlockUser(),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.red.withOpacity(0.2) : errorColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(IconlyLight.closeSquare, color: isDarkMode ? Colors.red[300] : errorColor),
                              ),
                              title: Text(
                                "${isBlocked ? 'unblock'.tr : 'block'.tr} ${widget.user.fullname}",
                                style: TextStyle(
                                  color: isDarkMode ? Colors.red[300] : errorColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }),
                          const Divider(height: 1),
                          ListTile(
                            onTap: () => reportController.reportDialog(
                              type: ReportType.user,
                              userId: widget.user.userId,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.red.withOpacity(0.2) : errorColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(IconlyLight.infoSquare, color: isDarkMode ? Colors.red[300] : errorColor),
                            ),
                            title: Text(
                              "${'report'.tr} ${widget.user.fullname}",
                              style: TextStyle(
                                color: isDarkMode ? Colors.red[300] : errorColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: defaultPadding * 2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }




}
