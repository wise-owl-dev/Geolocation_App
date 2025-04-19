// lib/core/error/error_handler.dart
import 'package:flutter/material.dart';

class ErrorHandler {
  // Método para mostrar SnackBar con errores de autenticación
  static void showAuthErrorSnackBar(BuildContext context, dynamic error) {
    String errorMessage = 'Error de autenticación: Intentalo nuevamente';
    
    // Si el error es un String, usamos ese mensaje
    if (error is String) {
      errorMessage = error;
    } 
    // Si el error es una Exception, intentamos extraer el mensaje
    else if (error is Exception) {
      errorMessage = error.toString().replaceAll('Exception: ', '');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // Método para mostrar SnackBar genéricos
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // Método para mostrar diálogo con error
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}