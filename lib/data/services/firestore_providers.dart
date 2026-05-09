import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';
import 'child_providers.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider legado usado por algumas telas.
///
/// Atenção:
/// A tela da criança agora deve usar `childTodayTasksProvider`,
/// que fica em `child_action_providers.dart`.
///
/// Mantive este provider para evitar quebrar outras telas que ainda usam ele.
final todayTasksStreamProvider = StreamProvider.family<List<TaskModel>, String>(
  (ref, childId) {
    final firestore = ref.watch(firestoreProvider);

    return firestore
        .collection('tasks')
        .where('childId', isEqualTo: childId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();

          final weekDaysMap = {
            1: 'Seg',
            2: 'Ter',
            3: 'Qua',
            4: 'Qui',
            5: 'Sex',
            6: 'Sáb',
            7: 'Dom',
          };

          final todayStr = weekDaysMap[now.weekday];

          final tasks = snapshot.docs
              .map((doc) {
                final data = doc.data();
                return TaskModel.fromMap(data, doc.id);
              })
              .where((task) {
                if (task.isRecurring) {
                  return task.daysOfWeek.contains(todayStr);
                }

                return task.startDate.year == now.year &&
                    task.startDate.month == now.month &&
                    task.startDate.day == now.day;
              })
              .toList();

          tasks.sort((a, b) => a.time.compareTo(b.time));

          return tasks;
        });
  },
);

/// Stream para a tela dos pais:
/// lista completa de tarefas, filtrando por criança ou por todos os filhos.
final filteredTasksStreamProvider =
    StreamProvider.family<List<TaskModel>, String?>((ref, childId) {
      final firestore = ref.watch(firestoreProvider);

      Query query = firestore.collection('tasks');

      if (childId != null && childId != 'all') {
        query = query.where('childId', isEqualTo: childId);
      } else {
        final allChildren = ref.watch(parentChildrenStreamProvider).value ?? [];

        if (allChildren.isEmpty) {
          return Stream.value([]);
        }

        final childIds = allChildren.map((c) => c.id).toList();

        query = query.where('childId', whereIn: childIds);
      }

      return query.snapshots().map((snapshot) {
        final tasks = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return TaskModel.fromMap(data, doc.id);
        }).toList();

        tasks.sort((a, b) => a.time.compareTo(b.time));

        return tasks;
      });
    });
