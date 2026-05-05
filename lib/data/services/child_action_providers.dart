import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:rotina_kids_plus/data/models/task_model.dart';
import '../models/reward_request_model.dart';
import '../models/child_model.dart';
import '../models/reward_model.dart';

class ChildActionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Set<String> _processingTasks = {};

  Future<void> completeTask(
    String childId,
    String taskId,
    String taskTitle,
    int xpReward,
  ) async {
    if (_processingTasks.contains(taskId)) return;
    _processingTasks.add(taskId);

    try {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final batch = _db.batch();
      final logRef = _db.collection('task_logs').doc();

      batch.set(logRef, {
        'id': logRef.id,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'xpReward': xpReward,
        'childId': childId,
        'completedAt': FieldValue.serverTimestamp(),
        'dateString': todayStr,
        'status': 'pending',
      });

      await batch.commit();
    } finally {
      Future.delayed(const Duration(seconds: 3), () {
        _processingTasks.remove(taskId);
      });
    }
  }

  Future<bool> buyReward(ChildModel child, RewardModel reward) async {
    if (child.currentXp < reward.xpCost) return false;
    final batch = _db.batch();
    final childRef = _db.collection('children').doc(child.id);
    batch.update(childRef, {'currentXp': FieldValue.increment(-reward.xpCost)});
    final reqRef = _db.collection('reward_requests').doc();
    final request = RewardRequestModel(
      id: reqRef.id,
      rewardId: reward.id,
      rewardTitle: reward.title,
      xpCost: reward.xpCost,
      childId: child.id,
      requestedAt: DateTime.now(),
      status: reward.requiresApproval ? 'pending' : 'approved',
    );
    batch.set(reqRef, request.toMap());
    await batch.commit();
    return true;
  }

  Future<bool> buyOrEquipAvatar(
    ChildModel child,
    String avatarId,
    int cost,
  ) async {
    final isOwned = child.unlockedAvatars.contains(avatarId);
    final batch = _db.batch();
    final childRef = _db.collection('children').doc(child.id);

    if (isOwned) {
      batch.update(childRef, {'avatarId': avatarId});
    } else {
      if (child.currentXp < cost) return false;
      batch.update(childRef, {
        'currentXp': FieldValue.increment(-cost),
        'avatarId': avatarId,
        'unlockedAvatars': FieldValue.arrayUnion([avatarId]),
      });
    }
    await batch.commit();
    return true;
  }
}

final childActionServiceProvider = Provider((ref) => ChildActionService());
final activeChildSessionProvider = StateProvider<ChildModel?>((ref) => null);

final _rawTasksProvider = StreamProvider.family<List<TaskModel>, String>((
  ref,
  childId,
) {
  return FirebaseFirestore.instance
      .collection('tasks')
      .where('childId', isEqualTo: childId)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

final _rawLogsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((
  ref,
  childId,
) {
  final now = DateTime.now();
  final todayStr =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

  return FirebaseFirestore.instance
      .collection('task_logs')
      .where('childId', isEqualTo: childId)
      .where('dateString', isEqualTo: todayStr)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => doc.data()).toList());
});

final todayTasksStreamProvider =
    Provider.family<AsyncValue<List<TaskModel>>, String>((ref, childId) {
      final tasksAsync = ref.watch(_rawTasksProvider(childId));
      final logsAsync = ref.watch(_rawLogsProvider(childId));

      if (tasksAsync.isLoading || logsAsync.isLoading) {
        return const AsyncValue.loading();
      }

      if (tasksAsync.hasError) {
        return AsyncValue.error(tasksAsync.error!, tasksAsync.stackTrace!);
      }

      if (logsAsync.hasError) {
        return AsyncValue.error(logsAsync.error!, logsAsync.stackTrace!);
      }

      final allTasks = tasksAsync.value ?? [];
      final allLogs = logsAsync.value ?? [];

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      const weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      final currentDayStr = weekDays[now.weekday - 1];

      final completedTaskIdsToday = allLogs
          .map((log) => log['taskId'] as String)
          .toSet();

      final pendingTasksToday = allTasks.where((task) {
        // 1. Já feita hoje?
        if (completedTaskIdsToday.contains(task.id)) return false;

        final taskDate = DateTime(
          task.startDate.year,
          task.startDate.month,
          task.startDate.day,
        );

        // 2. A tarefa é para o futuro?
        if (taskDate.isAfter(todayStart)) return false;

        // 3. Regras de repetição ou dia único
        if (task.isRecurring) {
          if (task.daysOfWeek.isNotEmpty) {
            return task.daysOfWeek.contains(currentDayStr);
          }
          return true; // Repetição diária genérica
        } else {
          // Se for missão única, a data tem que ser EXATAMENTE a de hoje!
          return taskDate.isAtSameMomentAs(todayStart);
        }
      }).toList();

      return AsyncValue.data(pendingTasksToday);
    });
