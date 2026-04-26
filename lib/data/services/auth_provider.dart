import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importação correta apontando para o arquivo na mesma pasta
import 'auth_service.dart';

// Provider do serviço de autenticação
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// StreamProvider para escutar o estado do usuário (logado ou não)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).userState;
});
