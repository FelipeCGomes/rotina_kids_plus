import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

// Provedor da instância do Firestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Stream que escuta as tarefas em tempo real de uma criança específica
final todayTasksStreamProvider = StreamProvider.family<List<TaskModel>, String>(
  (ref, childId) {
    final firestore = ref.watch(firestoreProvider);

    return firestore
        .collection('tasks')
        .where('childId', isEqualTo: childId)
        .where(
          'status',
          isEqualTo: 'pending',
        ) // Traz apenas as tarefas pendentes
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return TaskModel(
              id: doc.id,
              childId: data['childId'] ?? '',
              title: data['title'] ?? '',
              category: data['category'] ?? '',
              time: data['time'] ?? '',
              xpReward: data['xpReward'] ?? 0,
              status: data['status'] ?? 'pending',
            );
          }).toList();
        });
  },
);
