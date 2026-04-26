import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Usando o import absoluto (garante que ele ache o arquivo)
import 'package:rotina_kids_plus/data/services/auth_service.dart';

// Provider do serviço de autenticação
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// StreamProvider para escutar o estado do usuário (logado ou não)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).userState;
});
