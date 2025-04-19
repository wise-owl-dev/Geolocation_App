// config/theme/color_schemes.dart
import 'package:flutter/material.dart';

// Colores basados en el autobús de la imagen
const Color _primaryColor = Color(0xFF1A3B70);  // Azul marino
const Color _accentColor = Color(0xFF8B1D3C);   // Rojo burgundy
const Color _neutralColor = Color(0xFFD1D1D1);  // Gris plata
const Color _lightBlueColor = Color(0xFF4A78B5); // Azul claro

// Esquema de colores para modo claro
final lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  
  // Colores principales
  primary: _primaryColor,
  onPrimary: Colors.white,
  primaryContainer: _lightBlueColor.withOpacity(0.2),
  onPrimaryContainer: _primaryColor,
  
  // Colores secundarios
  secondary: _accentColor,
  onSecondary: Colors.white,
  secondaryContainer: _accentColor.withOpacity(0.1),
  onSecondaryContainer: _accentColor,
  
  // Colores de fondo
  background: Colors.white,
  onBackground: Colors.black,
  
  // Colores de superficie
  surface: Colors.white,
  onSurface: Colors.black,
  surfaceVariant: _neutralColor.withOpacity(0.3),
  onSurfaceVariant: Colors.black87,
  
  // Colores de error
  error: Colors.red,
  onError: Colors.white,
  errorContainer: Colors.red.shade100,
  onErrorContainer: Colors.red.shade900,
  
  // Otros colores
  outline: _neutralColor,
  outlineVariant: _neutralColor.withOpacity(0.5),
  shadow: Colors.black.withOpacity(0.1),
  scrim: Colors.black.withOpacity(0.3),
  inverseSurface: Colors.black,
  onInverseSurface: Colors.white,
  inversePrimary: _lightBlueColor,
);

// Esquema de colores para modo oscuro
final darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  
  // Colores principales
  primary: _lightBlueColor,
  onPrimary: Colors.white,
  primaryContainer: _primaryColor.withOpacity(0.7),
  onPrimaryContainer: Colors.white,
  
  // Colores secundarios
  secondary: Color(0xFFE57A90), // Versión más clara del rojo para modo oscuro
  onSecondary: Colors.black,
  secondaryContainer: _accentColor.withOpacity(0.6),
  onSecondaryContainer: Colors.white,
  
  // Colores de fondo
  background: Color(0xFF121212),
  onBackground: Colors.white,
  
  // Colores de superficie
  surface: Color(0xFF1E1E1E),
  onSurface: Colors.white,
  surfaceVariant: Color(0xFF2C2C2C),
  onSurfaceVariant: Colors.white70,
  
  // Colores de error
  error: Colors.red.shade300,
  onError: Colors.black,
  errorContainer: Colors.red.shade900,
  onErrorContainer: Colors.white,
  
  // Otros colores
  outline: Colors.grey.shade500,
  outlineVariant: Colors.grey.shade700,
  shadow: Colors.black,
  scrim: Colors.black.withOpacity(0.5),
  inverseSurface: Colors.white,
  onInverseSurface: Colors.black,
  inversePrimary: _primaryColor,
);