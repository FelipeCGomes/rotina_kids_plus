import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'child_service.dart';
import '../models/child_model.dart';
import 'auth_provider.dart';

final childServiceProvider = Provider<ChildService>((ref) {
  return ChildService();
});

// =========================================================
// MÁGICA: O app descobre quem está logado (Pai ou Criança)
// =========================================================
final parentChildrenStreamProvider = StreamProvider<List<ChildModel>>((
  ref,
) async* {
  final user = ref.watch(authStateProvider).value;
  final childService = ref.watch(childServiceProvider);
  final db = FirebaseFirestore.instance;

  if (user != null) {
    // 1. CHECAGEM CAMINHO B: Esse e-mail pertence a uma criança?
    if (user.email != null && user.email!.isNotEmpty) {
      final childQuery = await db
          .collection('children')
          .where('childEmail', isEqualTo: user.email)
          .get();

      if (childQuery.docs.isNotEmpty) {
        // É a criança! O app retorna apenas o perfil dela, isolando o resto.
        yield [
          ChildModel.fromMap(
            childQuery.docs.first.data(),
            childQuery.docs.first.id,
          ),
        ];
        return; // Para a execução aqui
      }
    }

    // 2. CHECAGEM CAMINHO A: Não é criança, então é o Pai. Busca todos os filhos.
    yield* childService.getChildrenByParent(user.uid);
  } else {
    yield [];
  }
});

final selectedChildProvider = StateProvider<ChildModel?>((ref) => null);
