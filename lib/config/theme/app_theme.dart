// config/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'color_schemes.dart';

class AppTheme {
  final bool isDarkMode;

  AppTheme({
    required this.isDarkMode
  });

  ThemeData getTheme() {
    return ThemeData(
      // Usar los esquemas de colores definidos
      colorScheme: isDarkMode 
        ? darkColorScheme 
        : lightColorScheme,
      
      // Estilo de AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode 
          ? darkColorScheme.primary 
          : lightColorScheme.primary,
        foregroundColor: isDarkMode 
          ? darkColorScheme.onPrimary 
          : lightColorScheme.onPrimary,
        elevation: 0,
      ),
      
      // Estilo de botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode 
            ? darkColorScheme.primary 
            : lightColorScheme.primary,
          foregroundColor: isDarkMode 
            ? darkColorScheme.onPrimary 
            : lightColorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Estilo de TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDarkMode 
            ? darkColorScheme.primary 
            : lightColorScheme.primary,
        ),
      ),
      
      // Estilo para campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkMode 
          ? darkColorScheme.surfaceVariant.withOpacity(0.1) 
          : lightColorScheme.surfaceVariant.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkMode 
              ? darkColorScheme.outline 
              : lightColorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkMode 
              ? darkColorScheme.outline 
              : lightColorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkMode 
              ? darkColorScheme.primary 
              : lightColorScheme.primary,
            width: 2,
          ),
        ),
      ),
      
      // Tipografía
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
      
      // Uso de Material 3
      useMaterial3: true,
    );
  }
}