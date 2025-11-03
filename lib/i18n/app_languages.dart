import 'package:get/get.dart';

import 'lang/en.dart';
import 'lang/es.dart';
import 'lang/fr.dart';
import 'lang/de.dart';
import 'lang/it.dart';
import 'lang/pt.dart';
import 'lang/ar.dart';

class AppLanguages extends Translations {

  @override
  // App supported languages
  Map<String, Map<String, String>> get keys {
    return {
      "en": english,
      "es": spanish,
      "fr": french,
      "de": german,
      "it": italian,
      "pt": portuguese,
      "ar": arabic,
    };
  }
}
