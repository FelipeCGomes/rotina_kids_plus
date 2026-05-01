import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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
    final taskRef = _db.collection('tasks').doc(taskId);
    batch.update(taskRef, {'status': 'waiting_approval'});
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

  // --- NOVO: Lógica da Lojinha de Avatares ---
  Future<bool> buyOrEquipAvatar(
    ChildModel child,
    String avatarId,
    int cost,
  ) async {
    final isOwned = child.unlockedAvatars.contains(avatarId);
    final batch = _db.batch();
    final childRef = _db.collection('children').doc(child.id);

    if (isOwned) {
      // Se já comprou antes, apenas troca a roupa (equipa) grátis!
      batch.update(childRef, {'avatarId': avatarId});
    } else {
      // Se não comprou, verifica se tem saldo e debita
      if (child.currentXp < cost) return false;
      batch.update(childRef, {
        'currentXp': FieldValue.increment(-cost), // Cobra o XP
        'avatarId': avatarId, // Equipa o avatar
        'unlockedAvatars': FieldValue.arrayUnion([
          avatarId,
        ]), // Salva na mochila da criança
      });
    }
    await batch.commit();
    return true;
  }
}

final childActionServiceProvider = Provider((ref) => ChildActionService());
final activeChildSessionProvider = StateProvider<ChildModel?>((ref) => null);
