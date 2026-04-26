import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Pequeno atraso para animação da logo
    await Future.delayed(const Duration(seconds: 2));

    // Verificamos o estado atual da stream de autenticação
    final user = ref.read(authStateProvider).value;

    if (mounted) {
      if (user != null) {
        // Se estiver logado, vai para seleção de modo (ou home se já tiver modo salvo)
        context.go('/mode-selection');
      } else {
        // Se não estiver logado, vai para a tela de login
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_care, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'Rotina Kids+',
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
