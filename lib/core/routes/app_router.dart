import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/mode_selection/mode_selection_screen.dart';
import '../../features/parent/dashboard/parent_dashboard_screen.dart';
import '../../features/child/dashboard/child_dashboard_screen.dart';
import '../../data/services/auth_provider.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/mode-selection',
      builder: (context, state) => const ModeSelectionScreen(),
    ),
    GoRoute(
      path: '/parent-home',
      builder: (context, state) => const ParentDashboardScreen(),
    ),
    GoRoute(
      path: '/child-home',
      builder: (context, state) => const ChildDashboardScreen(),
    ),
  ],
  // Lógica de redirecionamento global (Opcional: implementar futuramente)
  
  redirect: (context, state) {
    // Aqui podemos verificar se o usuário está logado e mandar para login ou home
    return null;
  },

);