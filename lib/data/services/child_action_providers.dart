import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:rotina_kids_plus/data/models/task_model.dart';
import '../models/task_log_model.dart';
import '../models/reward_request_model.dart';
import '../models/child_model.dart';
import '../models/reward_model.dart';

class ChildActionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> completeTask(
    String childId,
    String taskId,
    String taskTitle,
    int xpReward,
  ) async {
    final batch = _db.batch();
    final logRef = _db.collection('task_logs').doc();

    // O Log é criado aguardando aprovação
    final log = TaskLogModel(
      id: logRef.id,
      taskId: taskId,
      taskTitle: taskTitle,
      xpReward: xpReward,
      childId: childId,
      completedAt: DateTime.now(),
      status: 'waiting_approval',
    );
    batch.set(logRef, log.toMap());

    // MÁGICA AQUI: Nós NÃO atualizamos mais a "task" principal.
    // Ela continua intacta no banco de dados como um "molde" para o dia seguinte!

    await batch.commit();
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

// =========================================================================
// MOTOR DE TAREFAS DIÁRIAS
// =========================================================================

final todayTasksStreamProvider = StreamProvider.family<List<TaskModel>, String>((
  ref,
  childId,
) async* {
  final db = FirebaseFirestore.instance;

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  // Mapeia o dia da semana atual para o mesmo formato salvo na sua tela de criação
  const weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  final currentDayStr = weekDays[now.weekday - 1];

  // Escuta os Logs (o que já foi feito HOJE)
  final logsStream = db
      .collection('task_logs')
      .where('childId', isEqualTo: childId)
      .where('completedAt', isGreaterThanOrEqualTo: startOfDay)
      .where('completedAt', isLessThanOrEqualTo: endOfDay)
      .snapshots();

  // Escuta TODAS as tarefas da criança
  final tasksStream = db
      .collection('tasks')
      .where('childId', isEqualTo: childId)
      .snapshots();

  await for (final tasksSnapshot in tasksStream) {
    final logsSnapshot = await logsStream.first;

    final completedTaskIdsToday = logsSnapshot.docs
        .map((doc) => doc.data()['taskId'] as String)
        .toSet();

    final allTasks = tasksSnapshot.docs
        .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
        .toList();

    // Filtra as tarefas que devem aparecer hoje
    final pendingTasksToday = allTasks.where((task) {
      // 1. Se já fez hoje, esconde.
      if (completedTaskIdsToday.contains(task.id)) return false;

      // 2. Se é uma tarefa repetitiva, verifica se ela cai no dia de hoje
      if (task.isRecurring && task.daysOfWeek.isNotEmpty) {
        if (!task.daysOfWeek.contains(currentDayStr)) return false;
      }

      return true;
    }).toList();

    yield pendingTasksToday;
  }
});
