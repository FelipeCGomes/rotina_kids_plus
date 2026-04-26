import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/task_log_model.dart';
import '../models/reward_request_model.dart';
import '../models/child_model.dart';
import '../models/reward_model.dart';

class ChildActionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Quando a criança clica em "Feito!" na tarefa
  Future<void> completeTask(
    String childId,
    String taskId,
    String taskTitle,
    int xpReward,
  ) async {
    final batch = _db.batch();

    // 1. Cria o Log para o pai aprovar na "Central de Aprovações"
    final logRef = _db.collection('task_logs').doc();
    final log = TaskLogModel(
      id: logRef.id,
      taskId: taskId,
      taskTitle: taskTitle,
      xpReward: xpReward,
      childId: childId,
      completedAt: DateTime.now(),
      status: 'pending',
    );
    batch.set(logRef, log.toMap());

    // 2. Muda o status da tarefa para sumir da lista da criança hoje
    final taskRef = _db.collection('tasks').doc(taskId);
    batch.update(taskRef, {'status': 'waiting_approval'});

    await batch.commit();
  }

  // Quando a criança clica em "Comprar" na lojinha
  Future<bool> buyReward(ChildModel child, RewardModel reward) async {
    if (child.currentXp < reward.xpCost) return false; // Não tem saldo

    final batch = _db.batch();

    // 1. Desconta o XP da criança na hora
    final childRef = _db.collection('children').doc(child.id);
    batch.update(childRef, {'currentXp': FieldValue.increment(-reward.xpCost)});

    // 2. Cria o pedido para o pai
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
}

final childActionServiceProvider = Provider((ref) => ChildActionService());

// Guarda a sessão da criança que está com o celular na mão agora
final activeChildSessionProvider = StateProvider<ChildModel?>((ref) => null);
