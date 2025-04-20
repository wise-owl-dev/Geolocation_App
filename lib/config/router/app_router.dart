import 'package:go_router/go_router.dart';
import 'package:maps/features/auth/auth.dart';
import 'package:maps/features/menu/menu.dart';
import 'package:maps/features/splash/splash.dart';



final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [

    ///* Auth Routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),

    ///* Splash Route
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    ///* Menu Routes
    GoRoute(
      path: '/admin-menu',
      builder: (context, state) => const AdminMenuScreen(),
    ),
    GoRoute(
      path: '/operador-menu',
      builder: (context, state) => const OperadorMenuScreen(),
    ),
    GoRoute(
      path: '/user-menu',
      builder: (context, state) => const UserMenuScreen(),
    ),
  ],
  ///! TODO: Bloquear si no se está autenticado de alguna manera
);