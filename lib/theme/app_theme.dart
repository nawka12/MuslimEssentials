import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define colors
  static const Color primaryColor = Color(0xFF4CAF50);  // Green
  static const Color primaryDarkColor = Color(0xFF388E3C);  // Darker Green
  static const Color accentColor = Color(0xFF8BC34A);  // Light Green
  static const Color backgroundLightColor = Color(0xFFF5F5F5);
  static const Color backgroundDarkColor = Color(0xFF121212);
  static const Color surfaceDarkColor = Color(0xFF1E1E1E);
  static const Color cardDarkColor = Color(0xFF2C2C2C);

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Colors
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundLightColor,
      canvasColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
      ),
      
      // Typography
      textTheme: GoogleFonts.rubikTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.poppins(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.poppins(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: GoogleFonts.poppins(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: Colors.black87, 
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.rubik(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.rubik(
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.rubik(
          color: Colors.black87,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      
      // Cards
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.rubik(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.rubik(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Navigation bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        space: 24,
        thickness: 1,
        color: Color(0xFFEEEEEE),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Colors
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundDarkColor,
      canvasColor: surfaceDarkColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceDarkColor,
        background: backgroundDarkColor,
      ),
      
      // Typography
      textTheme: GoogleFonts.rubikTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: Colors.white, 
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.rubik(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.rubik(
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.rubik(
          color: Colors.white70,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDarkColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      
      // Cards
      cardTheme: CardTheme(
        elevation: 0,
        color: cardDarkColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF323232)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryDarkColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.rubik(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.rubik(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Navigation bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDarkColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        space: 24,
        thickness: 1,
        color: Color(0xFF323232),
      ),
    );
  }
} 