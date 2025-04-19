// lib/config/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/shared/presentation/screens/loading_screen.dart';
import '../../features/shared/presentation/screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Pantalla inicial de carga
      GoRoute(
        path: '/',
        builder: (context, state) => const LoadingScreen(),
      ),
      
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Autenticación
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      
      // Pantalla principal (temporal)
    ],
  );
});