import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Klink Brand Colors - Negro y Cyan
const primaryColor = Color(0xFF000000); // Negro principal
const secondaryColor = Color(0xFF00F7FF); // Cyan brillante
const primaryLight = Color(0xFFFFFFFF); // Blanco puro
const primaryDark = Color(0xFF000000); // Negro puro

// System Colors
const Color greyLight = Color(0xFFF8F8F8); // Blanco puro
const Color greyColor = Color(0xFF6B7280); // Gris neutro
const Color accentColor = Color(0xFF4B5563); // Gris oscuro
const Color premiumBlack = Color(0xFF000000); // Negro premium
const Color errorColor = Color(0xFFE53E3E);
const Color successColor = Color(0xFF38A169);
const Color warningColor = Color(0xFFD69E2E);

// Surface Colors - Elegante
const Color surfaceLight = Color(0xFFFFFFFF);
const Color surfaceDark = Color(0xFF000000); // Negro puro
const Color cardLight = Color(0xFFF8F8F8); // Blanco puro
const Color cardDark = Color(0xFF1A1A1A); // Negro suave

// Light Theme Colors - Elegante
const Color lightThemeBgColor = Color(0xFFFFFFFF); // Blanco puro
const Color lightThemeTextColor = Color(0xFF000000); // Negro puro
const Color lightThemeSecondaryText = Color(0xFF6B7280); // Gris neutro

// Dark Theme Colors - Elegante
const Color darkThemeBgColor = Color(0xFF000000); // Negro puro
const Color darkThemeTextColor = Color(0xFFFFFFFF); // Blanco puro
const Color darkPrimaryContainer = Color(0xFF1A1A1A); // Negro suave
const Color darkSecondaryContainer = Color(0xFF2A2A2A); // Negro elegante

//
// Be careful when changing others below unless you have a specific need.
//

// Other defaults - updated for modern design
const double defaultPadding = 20.0;
const double defaultMargin = 20.0;
const double defaultRadius = 20.0;
const double smallRadius = 12.0;
const double largeRadius = 28.0;

/// Default Border Radius
final BorderRadius borderRadius = BorderRadius.circular(defaultRadius);
final BorderRadius smallBorderRadius = BorderRadius.circular(smallRadius);
final BorderRadius largeBorderRadius = BorderRadius.circular(largeRadius);

/// Default Bottom Sheet Radius
const BorderRadius bottomSheetRadius = BorderRadius.only(
  topLeft: Radius.circular(24),
  topRight: Radius.circular(24),
);

/// Default Top Sheet Radius
const BorderRadius topSheetRadius = BorderRadius.only(
  bottomLeft: Radius.circular(24),
  bottomRight: Radius.circular(24),
);

/// Modern Box Shadow
final List<BoxShadow> boxShadow = [
  BoxShadow(
    blurRadius: 20,
    spreadRadius: 0,
    offset: const Offset(0, 4),
    color: Colors.black.withOpacity(0.08),
  ),
];

/// Subtle Box Shadow
final List<BoxShadow> subtleShadow = [
  BoxShadow(
    blurRadius: 8,
    spreadRadius: 0,
    offset: const Offset(0, 2),
    color: Colors.black.withOpacity(0.04),
  ),
];

/// Card Shadow
final List<BoxShadow> cardShadow = [
  BoxShadow(
    blurRadius: 16,
    spreadRadius: -2,
    offset: const Offset(0, 8),
    color: Colors.black.withOpacity(0.12),
  ),
];

const Duration duration = Duration(milliseconds: 300);

// Modern gradient definitions - Gradientes monocromáticos
// Gradientes Elegantes - Blanco y Negro
const LinearGradient primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF000000), // Negro puro
    Color(0xFF1A1A1A), // Negro suave
  ],
);

const LinearGradient darkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF000000), Color(0xFF1A1A1A)],
);

// Gradiente moderno elegante
const LinearGradient modernPrimaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF000000), // Negro puro
    Color(0xFF4B5563), // Gris oscuro
    Color(0xFFFFFFFF), // Blanco
  ],
);

const LinearGradient modernDarkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF000000), Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
);

// Gradiente negro premium para elementos especiales
const LinearGradient premiumGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF000000), // Negro puro
    Color(0xFF1A1A1A), // Negro suave
    Color(0xFF4B5563), // Gris oscuro
  ],
);

const LinearGradient glassGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x33FFFFFF), Color(0x11FFFFFF)],
);

// <-- Get system overlay theme style -->
SystemUiOverlayStyle getSystemOverlayStyle(bool isDarkMode) {
  final Brightness brightness = isDarkMode ? Brightness.dark : Brightness.light;

  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    // iOS only
    statusBarBrightness: brightness,
    // Android only
    statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    // Android only
    systemNavigationBarColor: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
    // Android only
    systemNavigationBarIconBrightness: isDarkMode
        ? Brightness.light
        : Brightness.dark,
  );
}
