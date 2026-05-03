import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    await Future.delayed(const Duration(seconds: 2));

    // Leitura síncrona e direta no Firebase
    final user = FirebaseAuth.instance.currentUser;

    if (mounted) {
      if (user != null) {
        context.go('/mode-selection');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F44),
      body: Stack(
        fit: StackFit.expand, // Força a tela a usar 100% do espaço disponível
        children: [
          // 1. A IMAGEM DE FUNDO
          Image.asset(
            'assets/img/splash_screen.png',
            fit: BoxFit
                .cover, // Faz a imagem preencher toda a tela sem deixar bordas
          ),

          // 2. O INDICADOR DE CARREGAMENTO (Por cima da imagem)
          const SafeArea(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Joga a rodinha lá pro final
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                SizedBox(
                  height: 60,
                ), // Dá um respiro para não ficar colado no rodapé
              ],
            ),
          ),
        ],
      ),
    );
  }
}
