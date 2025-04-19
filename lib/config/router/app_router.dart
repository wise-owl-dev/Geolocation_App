// lib/config/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/shared/presentation/screens/loading_screen.dart';
import '../../features/shared/presentation/screens/splash_screen.dart';
import '../../features/shared/presentation/screens/home_screen.dart';
import '../auth/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

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
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    
    // Redirecciones basadas en autenticación
    redirect: (BuildContext context, GoRouterState state) {
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSignUp = state.matchedLocation == '/signup';
      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToInitialScreen = state.matchedLocation == '/';
      
      final isAuthenticated = authState.isAuthenticated;
      
      // Si está en la pantalla inicial de carga, no redirigir
      if (isGoingToInitialScreen) {
        return null;
      }
      
      // Si va al splash y no está autenticado, permitir
      if (isGoingToSplash && !isAuthenticated) {
        return null;
      }
      
      // Si va a login o signup y no está autenticado, permitir
      if ((isGoingToLogin || isGoingToSignUp) && !isAuthenticated) {
        return null;
      }
      
      // Si está autenticado y va a splash, login o signup, redirigir a home
      if (isAuthenticated && (isGoingToSplash || isGoingToLogin || isGoingToSignUp)) {
        return '/home';
      }
      
      // Si no está autenticado y no va a login, signup o splash, redirigir a login
      if (!isAuthenticated && !isGoingToLogin && !isGoingToSignUp && !isGoingToSplash) {
        return '/login';
      }
      
      return null;
    },
  );
});