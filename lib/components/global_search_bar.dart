import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'dart:ui';

class GlobalSearchBar extends StatefulWidget {
  final bool showInHeader;
  final VoidCallback? onSearchActivated;
  final VoidCallback? onSearchDeactivated;

  const GlobalSearchBar({
    Key? key,
    this.showInHeader = false,
    this.onSearchActivated,
    this.onSearchDeactivated,
  }) : super(key: key);

  @override
  State<GlobalSearchBar> createState() => GlobalSearchBarState();
}

class GlobalSearchBarState extends State<GlobalSearchBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  List<User> _searchResults = [];
  List<User> _allUsers = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _widthAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadUsers();
    _textController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await UserApi.getAllUsers();
      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _textController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    if (query.startsWith('@')) {
      // Buscar solo por username
      final usernameQuery = query.substring(1).toLowerCase();
      final results = _allUsers.where((user) =>
        user.username.toLowerCase().contains(usernameQuery)
      ).toList();
      setState(() {
        _searchResults = results;
      });
    } else {
      // Buscar por nombre, username o email
      final results = _allUsers.where((user) =>
        user.fullname.toLowerCase().contains(query.toLowerCase()) ||
        user.username.toLowerCase().contains(query.toLowerCase()) ||
        user.email.toLowerCase().contains(query.toLowerCase())
      ).toList();
      setState(() {
        _searchResults = results;
      });
    }
  }

  void _activateSearch() {
    setState(() {
      _isSearching = true;
    });
    
    _animationController.forward();
    _focusNode.requestFocus();
    
    // Notificar al padre que se activó la búsqueda
    widget.onSearchActivated?.call();
  }

  void _deactivateSearch() {
    setState(() {
      _isSearching = false;
      _textController.clear();
      _searchResults.clear();
    });
    
    _animationController.reverse();
    _focusNode.unfocus();
    
    // Notificar al padre que se desactivó la búsqueda
    widget.onSearchDeactivated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    
    if (widget.showInHeader) {
      if (_isSearching) {
        // Modo de búsqueda activo - barra expandida
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Botón de regreso
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                onPressed: _deactivateSearch,
              ),
              
              // Barra de búsqueda expandida
              Expanded(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _widthAnimation.value,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDarkMode 
                                ? const Color(0xFF2A2A2A) 
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(22),
                            border: isDarkMode
                                ? Border.all(
                                    color: const Color(0xFF404040).withOpacity(0.6),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar usuarios y conversaciones',
                              hintStyle: TextStyle(
                                color: isDarkMode 
                                    ? const Color(0xFF9CA3AF) 
                                    : const Color(0xFF64748B),
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: isDarkMode 
                                    ? const Color(0xFF9CA3AF) 
                                    : const Color(0xFF64748B),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      } else {
        // Modo normal - barra compacta
        return GestureDetector(
          onTap: _activateSearch,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: isDarkMode
                  ? Border.all(
                      color: const Color(0xFF404040).withOpacity(0.6),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search,
                  color: isDarkMode
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF64748B),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Buscar',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return Container();
  }

  // Método para obtener el contenido de búsqueda (para usar en el padre)
  Widget buildSearchContent() {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDarkMode ? Colors.white : Colors.blue,
        ),
      );
    }

    if (_textController.text.isEmpty) {
      return _buildEmptyState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return _buildSearchResults();
  }

  Widget _buildEmptyState() {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Busca conversaciones y usuarios',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escribe @username para buscar usuarios específicos',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildUserTile(_searchResults[index], isDarkMode);
      },
    );
  }

  Widget _buildUserTile(User user, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? const Color(0xFF1E1E1E) 
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode 
              ? const Color(0xFF404040) 
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CachedCircleAvatar(
          imageUrl: user.photoUrl,
          radius: 24,
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        ),
        title: Text(
          user.fullname.isNotEmpty ? user.fullname : 'Usuario',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          user.username.isNotEmpty ? '@${user.username}' : 'Sin username',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: user.isOnline 
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode ? Colors.black : Colors.white,
                  width: 2,
                ),
              ),
            )
          : null,
        onTap: () {
          _deactivateSearch();
          Get.toNamed(
            AppRoutes.profileView,
            arguments: {
              'user': user,
              'isGroup': false,
            },
          );
        },
      ),
    );
  }

  // Getter para verificar si está en modo búsqueda
  bool get isSearching => _isSearching;
}
