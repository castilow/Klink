import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chat_messenger/config/theme_config.dart';

class AppTheme {
  final BuildContext context;

  // Constructor
  AppTheme(this.context);

  /// Get context using "of" syntax
  static AppTheme of(BuildContext context) => AppTheme(context);

  /// Get current theme mode => [dark or light]
  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;

// <--- Build light theme --->
  ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightThemeBgColor,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: getSystemOverlayStyle(false),
        backgroundColor: primaryColor,
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      iconTheme: const IconThemeData(color: lightThemeTextColor, size: 28),
      textTheme: GoogleFonts.interTextTheme(customTextTheme).apply(
        bodyColor: lightThemeTextColor,
        displayColor: lightThemeTextColor,
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: secondaryColor,
        surface: surfaceLight,
        error: errorColor,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryColor,
        selectedIconTheme: const IconThemeData(color: primaryColor, size: 28),
        unselectedItemColor: lightThemeSecondaryText,
        showUnselectedLabels: true,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: inputDecorationTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      outlinedButtonTheme: outlinedButtonTheme,
      dividerTheme: dividerThemeData,
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
      ),
    );
  }

  // <--- Build dark theme --->
  ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkThemeBgColor,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: darkPrimaryContainer,
        systemOverlayStyle: getSystemOverlayStyle(true),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      iconTheme: const IconThemeData(color: darkThemeTextColor, size: 28),
      // Asegurar contraste de íconos en modo oscuro
      primaryIconTheme: const IconThemeData(color: Colors.white, size: 28),
      textTheme: GoogleFonts.interTextTheme(customTextTheme).apply(
        bodyColor: darkThemeTextColor,
        displayColor: darkThemeTextColor,
      ),
      colorScheme: const ColorScheme.dark().copyWith(
        primary: primaryColor,
        primaryContainer: darkPrimaryContainer,
        secondary: secondaryColor,
        surface: surfaceDark,
        error: errorColor,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 8,
        backgroundColor: surfaceDark,
        selectedItemColor: primaryLight,
        unselectedItemColor: darkThemeTextColor.withOpacity(0.6),
        unselectedIconTheme: const IconThemeData(size: 28),
        selectedIconTheme: const IconThemeData(color: primaryLight, size: 28),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: inputDecorationTheme.copyWith(
        fillColor: darkSecondaryContainer,
        hintStyle: TextStyle(color: darkThemeTextColor.withOpacity(0.6)),
      ),
      elevatedButtonTheme: elevatedButtonTheme,
      outlinedButtonTheme: outlinedButtonTheme,
      dividerTheme: dividerThemeData,
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
      ),
    );
  }

  // Get text color
  Color? get textColor => isDarkMode ? darkThemeTextColor : lightThemeTextColor;

  // Build Custom TextTheme
  TextTheme get customTextTheme => TextTheme(
        headlineSmall: TextStyle(
            fontSize: 24.0, 
            fontWeight: FontWeight.w700, 
            color: textColor,
            letterSpacing: -0.5),
        titleLarge: TextStyle(
            fontSize: 20.0, 
            fontWeight: FontWeight.w600, 
            color: textColor,
            letterSpacing: -0.3),
        titleMedium: TextStyle(
            fontSize: 16.0, 
            fontWeight: FontWeight.w600, 
            color: textColor,
            letterSpacing: -0.2),
        bodyLarge: TextStyle(
            fontSize: 16.0, 
            fontWeight: FontWeight.w400,
            color: textColor,
            height: 1.5),
        bodyMedium: TextStyle(
            fontSize: 14.0, 
            fontWeight: FontWeight.w400,
            color: textColor,
            height: 1.4),
        bodySmall: TextStyle(
            fontSize: 12.0, 
            fontWeight: FontWeight.w400,
            color: textColor?.withOpacity(0.8),
            height: 1.3),
      );

  final inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: greyLight,
    focusColor: primaryColor,
    hintStyle: const TextStyle(color: greyColor),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: defaultPadding,
      vertical: defaultPadding,
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(defaultRadius),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: greyLight.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(defaultRadius),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: primaryColor, width: 2),
      borderRadius: BorderRadius.circular(defaultRadius),
    ),
  );

  final elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding * 1.5,
        vertical: defaultPadding * 0.75,
      ),
    ),
  );

  final outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(width: 2, color: primaryColor),
      foregroundColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding * 1.5,
        vertical: defaultPadding * 0.75,
      ),
    ),
  );

  final dividerThemeData = const DividerThemeData(
    thickness: 1,
    color: greyLight,
  );
}
