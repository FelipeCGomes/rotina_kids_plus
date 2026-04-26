import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addTask(TaskModel task) async {
    try {
      DocumentReference docRef = _db.collection('tasks').doc();
      await docRef.set(task.toMap()..['id'] = docRef.id);
    } catch (e) {
      rethrow;
    }
  }

  // Novo método para editar tarefas existentes
  Future<void> updateTask(TaskModel task) async {
    try {
      await _db.collection('tasks').doc(task.id).update(task.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }
}

final taskServiceProvider = Provider<TaskService>((ref) => TaskService());
