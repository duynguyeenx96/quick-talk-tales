import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Color palette inspired by Duolingo and kid-friendly apps
  static const Color primaryGreen = Color(0xFF58CC02);
  static const Color secondaryBlue = Color(0xFF1CB0F6);
  static const Color accentPink = Color(0xFFFF4B4B);
  static const Color accentOrange = Color(0xFFFF9600);
  static const Color accentPurple = Color(0xFFCE82FF);
  static const Color backgroundLight = Color(0xFFF7F7F7);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF3C3C3C);
  static const Color textSecondary = Color(0xFF777777);
  
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: _createMaterialColor(primaryGreen),
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'Nunito', // Kid-friendly font
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Nunito',
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryGreen.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
          fontFamily: 'Nunito',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
          fontFamily: 'Nunito',
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(
          color: textSecondary,
          fontFamily: 'Nunito',
        ),
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: secondaryBlue,
        tertiary: accentPink,
        surface: cardBackground,
        background: backgroundLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
    );
  }
  
  // Helper method to create MaterialColor from Color
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

// Predefined gradients for different elements
class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppTheme.primaryGreen, Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient blueGradient = LinearGradient(
    colors: [AppTheme.secondaryBlue, Color(0xFF2196F3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [AppTheme.accentPink, Color(0xFFE91E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [AppTheme.accentOrange, Color(0xFFFF5722)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}