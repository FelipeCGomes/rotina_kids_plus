import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'child_service.dart';
import '../models/child_model.dart';
import 'auth_provider.dart';

// Provider do serviço
final childServiceProvider = Provider<ChildService>((ref) {
  return ChildService();
});

// Stream que escuta as crianças do pai logado atualmente
final parentChildrenStreamProvider = StreamProvider<List<ChildModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final childService = ref.watch(childServiceProvider);

  if (user != null) {
    return childService.getChildrenByParent(user.uid);
  } else {
    return Stream.value([]);
  }
});

// Estado para guardar a criança que o pai selecionou no momento (para ver o dashboard específico dela)
final selectedChildProvider = StateProvider<ChildModel?>((ref) => null);
