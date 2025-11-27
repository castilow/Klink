class LanguageConfig {
  static const List<Map<String, String>> supportedLanguages = [
    {
      'code': 'en',
      'name': 'English - (United States)',
      'flag': 'assets/flags/en.png',
      'nativeName': 'English',
    },
    {
      'code': 'es',
      'name': 'Español - (España)',
      'flag': 'assets/flags/es.png',
      'nativeName': 'Español',
    },
    {
      'code': 'fr',
      'name': 'Français - (France)',
      'flag': 'assets/flags/fr.png',
      'nativeName': 'Français',
    },
    {
      'code': 'de',
      'name': 'Deutsch - (Deutschland)',
      'flag': 'assets/flags/de.png',
      'nativeName': 'Deutsch',
    },
    {
      'code': 'it',
      'name': 'Italiano - (Italia)',
      'flag': 'assets/flags/it.png',
      'nativeName': 'Italiano',
    },
    {
      'code': 'pt',
      'name': 'Português - (Portugal)',
      'flag': 'assets/flags/pt.png',
      'nativeName': 'Português',
    },
    {
      'code': 'ar',
      'name': 'العربية - (السعودية)',
      'flag': 'assets/flags/ar.png',
      'nativeName': 'العربية',
    },
    {
      'code': 'ru',
      'name': 'Русский - (Россия)',
      'flag': 'assets/flags/ru.png',
      'nativeName': 'Русский',
    },
    {
      'code': 'zh',
      'name': '中文 - (中国)',
      'flag': 'assets/flags/zh.png',
      'nativeName': '中文',
    },
    {
      'code': 'id',
      'name': 'Bahasa Indonesia - (Indonesia)',
      'flag': 'assets/flags/id.png',
      'nativeName': 'Bahasa Indonesia',
    },
    {
      'code': 'ja',
      'name': '日本語 - (日本)',
      'flag': 'assets/flags/ja.png',
      'nativeName': '日本語',
    },
    {
      'code': 'hi',
      'name': 'हिंदी - (भारत)',
      'flag': 'assets/flags/in.png',
      'nativeName': 'हिंदी',
    },
  ];

  static String getLanguageName(String code) {
    final language = supportedLanguages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {'name': 'Unknown'},
    );
    return language['name'] ?? 'Unknown';
  }

  static String getLanguageFlag(String code) {
    final language = supportedLanguages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {'flag': 'assets/flags/en.png'},
    );
    return language['flag'] ?? 'assets/flags/en.png';
  }

  static String getNativeName(String code) {
    final language = supportedLanguages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {'nativeName': 'Unknown'},
    );
    return language['nativeName'] ?? 'Unknown';
  }

  static List<String> getLanguageCodes() {
    return supportedLanguages.map((lang) => lang['code']!).toList();
  }
} 