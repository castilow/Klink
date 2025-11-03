import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/controllers/global_search_controller.dart';
import 'package:chat_messenger/models/search_item.dart';
import 'package:chat_messenger/theme/app_theme.dart';

class GlobalSearchScreen extends StatelessWidget {
  const GlobalSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalSearchController controller = Get.put(GlobalSearchController());
    final bool isDarkMode = AppTheme.of(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                    size: 20,
                  ),
                  onPressed: () {
                    controller.clearSearch();
                    Get.back();
                  },
                ),
                Expanded(
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1A1A1A).withOpacity(0.95)
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
                      controller: controller.searchController,
                      autofocus: true,
                      style: TextStyle(
                        color: isDarkMode ? const Color(0xFFF8FAFC) : Colors.grey[800],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar secciones...',
                        hintStyle: TextStyle(
                          color: isDarkMode
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF64748B),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDarkMode
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF64748B),
                          size: 18,
                        ),
                        suffixIcon: Obx(() => controller.isSearching.value
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: isDarkMode
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF64748B),
                                  size: 18,
                                ),
                                onPressed: controller.clearSearch,
                              )
                            : const SizedBox.shrink()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (!controller.isSearching.value) {
                return _buildEmptyState(isDarkMode);
              }

              if (controller.searchResults.isEmpty) {
                return _buildNoResults(isDarkMode, controller.currentQuery.value);
              }

              return _buildSearchResults(controller, isDarkMode);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1A1A1A).withOpacity(0.8)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.search,
              size: 64,
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Busca cualquier sección',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba con "portafolio", "dashboard" o "billetera"',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(bool isDarkMode, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1A1A1A).withOpacity(0.8)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.search_off,
              size: 64,
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No se encontraron resultados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay coincidencias para "$query"',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(GlobalSearchController controller, bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.searchResults.length,
      itemBuilder: (context, index) {
        final SearchItem item = controller.searchResults[index];
        return _buildSearchResultItem(item, controller, isDarkMode);
      },
    );
  }

  Widget _buildSearchResultItem(SearchItem item, GlobalSearchController controller, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1A1A1A).withOpacity(0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode
            ? Border.all(
                color: const Color(0xFF404040).withOpacity(0.3),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: isDarkMode ? 8 : 4,
            offset: Offset(0, isDarkMode ? 3 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            controller.navigateToResult(item);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getIconColor(item.iconData),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(item.iconData),
                    color: Colors.white,
                    size: 24,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getIconColor(item.iconData).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getIconColor(item.iconData),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Flecha
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ),
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
} 