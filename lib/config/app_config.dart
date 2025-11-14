abstract class AppConfig {
  ///
  /// <-- APP CONFIGURATION -->
  ///

  /// App Name
  static const String appName = "Klink";

  /// Email for Support
  static const String appEmail = "info@klink.com";

  /// App Version
  static const String appVersion = "Android v1.0.0 - iOS v1.0.0";

  // App identifiers
  static const String iOsAppId = "com.klinks.app";
  static const String androidPackageName = "com.klinks.app";

  /// Privacy Policy Link
  static const String privacyPolicyUrl = "https://klink.com/privacy-policy/";

  /// Terms of Service Link
  static const String termsOfServiceUrl = "https://klink.com/terms-of-service/";

  ///
  /// <-- Video & Voice Call Configuration (ZEGOCLOUD) -->
  ///
  
  /// ZEGOCLOUD Configuration
  static const int zegoAppID = 2093046624; // Como int, no String
  static const String zegoAppSign = "d8a32d41d4df792f3d1c335ba4ac5f8e3128691f1ab40828ffde3b33b6812749";
  static const String zegoCallbackSecret = "d8a32d41d4df792f3d1c335ba4ac5f8e";
  static const String zegoServerSecret = "b710e9082ba38afc465403a9c0b1a71f";

  ///
  /// <-- GIF API Configuration -->
  ///
  static const String gifAPiKey = "wKeA54tB1p5yPFj573XvppXKA8yIr9L8";

  /// GIPHY API Key
  static const String giphyApiKey = "wKeA54tB1p5yPFj573XvppXKA8yIr9L8";

  //
  // <-- AD Configuration -->
  //

  // Android Ad Units
  static const String androidBannerID = "ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy";
  static const String androidInterstitialID = "ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy";

  // iOS Ad Units
  static const String iOsBannerID = "ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy";
  static const String iOsInterstitialID = "ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy";
}