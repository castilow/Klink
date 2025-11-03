class SearchItem {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final List<String> searchTerms;
  final String category;
  final String? iconData;
  final String? description;

  const SearchItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.searchTerms,
    required this.category,
    this.iconData,
    this.description,
  });

  // Método para verificar si coincide con una búsqueda
  bool matchesSearch(String query) {
    final searchQuery = query.toLowerCase();

    // Buscar en título, subtitle y términos de búsqueda
    return title.toLowerCase().contains(searchQuery) ||
           subtitle.toLowerCase().contains(searchQuery) ||
           searchTerms.any((term) => term.toLowerCase().contains(searchQuery)) ||
           (description?.toLowerCase().contains(searchQuery) ?? false);
  }
} 