import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import 'child_providers.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Stream para a tela da Criança (apenas tarefas pendentes)
final todayTasksStreamProvider = StreamProvider.family<List<TaskModel>, String>(
  (ref, childId) {
    final firestore = ref.watch(firestoreProvider);
    return firestore
        .collection('tasks')
        .where('childId', isEqualTo: childId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Solução do Erro 2: Cast explícito para Map
            final data = doc.data();
            return TaskModel.fromMap(data, doc.id);
          }).toList();
        });
  },
);

// Stream para a tela dos Pais: Suporta filtro por criança ou "Todas"
final filteredTasksStreamProvider =
    StreamProvider.family<List<TaskModel>, String?>((ref, childId) {
      final firestore = ref.watch(firestoreProvider);

      Query query = firestore.collection('tasks');

      if (childId != null && childId != 'all') {
        // Filtra por uma criança específica
        query = query.where('childId', isEqualTo: childId);
      } else {
        // Para "Todas", pegamos os IDs de todos os filhos do pai
        final allChildren = ref.watch(parentChildrenStreamProvider).value ?? [];
        if (allChildren.isEmpty) return Stream.value([]);

        final childIds = allChildren.map((c) => c.id).toList();
        query = query.where('childId', whereIn: childIds);
      }

      return query.snapshots().map((snapshot) {
        final tasks = snapshot.docs.map((doc) {
          // Solução do Erro 2: Cast explícito para Map
          final data = doc.data() as Map<String, dynamic>;
          return TaskModel.fromMap(data, doc.id);
        }).toList();

        tasks.sort((a, b) => a.time.compareTo(b.time));
        return tasks;
      });
    });
