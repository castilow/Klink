import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/models/search_item.dart';
import 'package:chat_messenger/routes/app_routes.dart';

class GlobalSearchController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final RxBool isSearching = RxBool(false);
  final RxList<SearchItem> searchResults = <SearchItem>[].obs;
  final RxString currentQuery = ''.obs;

  // Lista de elementos que se pueden buscar en la aplicación
  final List<SearchItem> searchableItems = [
    // Secciones principales
    SearchItem(
      id: 'portfolio',
      title: 'Portafolio',
      subtitle: 'Ver tu cartera de inversiones',
      route: AppRoutes.investment,
      category: 'Inversiones',
      searchTerms: ['portafolio', 'portfolio', 'inversiones', 'cartera', 'criptomonedas', 'crypto'],
      iconData: 'investment',
      description: 'Gestiona tu portafolio de criptomonedas y ve tus inversiones',
    ),
    SearchItem(
      id: 'dashboard',
      title: 'Dashboard',
      subtitle: 'Panel principal de control',
      route: AppRoutes.dashboard,
      category: 'Principal',
      searchTerms: ['dashboard', 'panel', 'inicio', 'principal', 'control'],
      iconData: 'dashboard',
      description: 'Panel principal con información general',
    ),
    SearchItem(
      id: 'wallet',
      title: 'Billetera',
      subtitle: 'Gestiona tu billetera digital',
      route: AppRoutes.wallet,
      category: 'Finanzas',
      searchTerms: ['billetera', 'wallet', 'dinero', 'fondos', 'saldo'],
      iconData: 'wallet',
      description: 'Administra tu billetera digital y fondos',
    ),
    SearchItem(
      id: 'eth_dashboard',
      title: 'Ethereum Dashboard',
      subtitle: 'Panel de Ethereum',
      route: AppRoutes.ethDashboard,
      category: 'Criptomonedas',
      searchTerms: ['ethereum', 'eth', 'ether', 'criptomoneda'],
      iconData: 'ethereum',
      description: 'Panel específico para gestionar Ethereum',
    ),
    SearchItem(
      id: 'woop_dashboard',
      title: 'WOOP Dashboard',
      subtitle: 'Panel de tokens WOOP',
      route: AppRoutes.woopDashboard,
      category: 'Tokens',
      searchTerms: ['woop', 'token', 'woonkly'],
      iconData: 'woop',
      description: 'Panel para gestionar tokens WOOP',
    ),
    SearchItem(
      id: 'price',
      title: 'Precios',
      subtitle: 'Ver precios de criptomonedas',
      route: AppRoutes.price,
      category: 'Mercado',
      searchTerms: ['precios', 'prices', 'cotizaciones', 'mercado', 'valor'],
      iconData: 'price',
      description: 'Consulta precios actuales del mercado',
    ),
    SearchItem(
      id: 'contacts',
      title: 'Contactos',
      subtitle: 'Gestiona tus contactos',
      route: AppRoutes.contacts,
      category: 'Social',
      searchTerms: ['contactos', 'contacts', 'amigos', 'usuarios'],
      iconData: 'contacts',
      description: 'Administra tu lista de contactos',
    ),
    SearchItem(
      id: 'profile',
      title: 'Perfil',
      subtitle: 'Ver y editar tu perfil',
      route: AppRoutes.profile,
      category: 'Cuenta',
      searchTerms: ['perfil', 'profile', 'cuenta', 'usuario', 'configuracion'],
      iconData: 'profile',
      description: 'Gestiona tu perfil y configuraciones',
    ),
    SearchItem(
      id: 'settings',
      title: 'Configuración',
      subtitle: 'Ajustes de la aplicación',
      route: AppRoutes.settings,
      category: 'Sistema',
      searchTerms: ['configuracion', 'settings', 'ajustes', 'opciones'],
      iconData: 'settings',
      description: 'Configura la aplicación según tus preferencias',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    // Listener para el campo de búsqueda
    searchController.addListener(_onSearchChanged);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    final query = searchController.text.trim();
    currentQuery.value = query;
    
    if (query.isEmpty) {
      isSearching.value = false;
      searchResults.clear();
    } else {
      isSearching.value = true;
      performSearch(query);
    }
  }

  void performSearch(String query) {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    final results = searchableItems
        .where((item) => item.matchesSearch(query))
        .toList();

    // Ordenar resultados por relevancia
    results.sort((a, b) {
      final queryLower = query.toLowerCase();
      
      // Priorizar coincidencias exactas en el título
      if (a.title.toLowerCase() == queryLower) return -1;
      if (b.title.toLowerCase() == queryLower) return 1;
      
      // Luego coincidencias que empiecen con la búsqueda
      if (a.title.toLowerCase().startsWith(queryLower)) return -1;
      if (b.title.toLowerCase().startsWith(queryLower)) return 1;
      
      // Finalmente orden alfabético
      return a.title.compareTo(b.title);
    });

    searchResults.assignAll(results);
  }

  void clearSearch() {
    searchController.clear();
    isSearching.value = false;
    searchResults.clear();
    currentQuery.value = '';
  }

  void navigateToResult(SearchItem item) {
    // Limpiar búsqueda
    clearSearch();
    
    // Navegar a la ruta correspondiente manteniendo el stack de navegación
    Get.toNamed(item.route);
  }

  void selectSearchResult(int index) {
    if (index >= 0 && index < searchResults.length) {
      navigateToResult(searchResults[index]);
    }
  }
} 