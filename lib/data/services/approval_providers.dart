import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_log_model.dart';
import '../models/reward_request_model.dart';
import 'firestore_providers.dart';
import 'child_providers.dart';

class ApprovalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- TAREFAS ---
  Future<void> approveTask(TaskLogModel log) async {
    final batch = _db.batch();
    // 1. Marca o log como aprovado
    batch.update(_db.collection('task_logs').doc(log.id), {
      'status': 'approved',
    });
    // 2. Adiciona o XP para a criança (currentXp para gastar, totalXp para subir de nível)
    batch.update(_db.collection('children').doc(log.childId), {
      'currentXp': FieldValue.increment(log.xpReward),
      'totalXp': FieldValue.increment(log.xpReward),
    });
    await batch.commit();
  }

  Future<void> rejectTask(String logId) async {
    await _db.collection('task_logs').doc(logId).update({'status': 'rejected'});
  }

  // --- PRÊMIOS ---
  Future<void> approveReward(String requestId) async {
    // O XP já foi descontado no momento que a criança pediu. Então só aprovamos o status.
    await _db.collection('reward_requests').doc(requestId).update({
      'status': 'approved',
    });
  }

  Future<void> rejectReward(RewardRequestModel request) async {
    final batch = _db.batch();
    // 1. Marca como rejeitado
    batch.update(_db.collection('reward_requests').doc(request.id), {
      'status': 'rejected',
    });
    // 2. Devolve o XP para a criança (reembolso)
    batch.update(_db.collection('children').doc(request.childId), {
      'currentXp': FieldValue.increment(request.xpCost),
    });
    await batch.commit();
  }
}

final approvalServiceProvider = Provider<ApprovalService>(
  (ref) => ApprovalService(),
);

// Stream: Tarefas Aguardando Aprovação
final pendingTasksStreamProvider =
    StreamProvider.family<List<TaskLogModel>, String?>((ref, childId) {
      Query query = ref
          .watch(firestoreProvider)
          .collection('task_logs')
          .where('status', isEqualTo: 'pending');

      if (childId != null && childId != 'all') {
        query = query.where('childId', isEqualTo: childId);
      } else {
        final allChildren = ref.watch(parentChildrenStreamProvider).value ?? [];
        if (allChildren.isEmpty) return Stream.value([]);
        query = query.where(
          'childId',
          whereIn: allChildren.map((c) => c.id).toList(),
        );
      }

      return query.snapshots().map(
        (snap) => snap.docs
            .map(
              (doc) => TaskLogModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList(),
      );
    });

// Stream: Prêmios Aguardando Aprovação
final pendingRewardsStreamProvider =
    StreamProvider.family<List<RewardRequestModel>, String?>((ref, childId) {
      Query query = ref
          .watch(firestoreProvider)
          .collection('reward_requests')
          .where('status', isEqualTo: 'pending');

      if (childId != null && childId != 'all') {
        query = query.where('childId', isEqualTo: childId);
      } else {
        final allChildren = ref.watch(parentChildrenStreamProvider).value ?? [];
        if (allChildren.isEmpty) return Stream.value([]);
        query = query.where(
          'childId',
          whereIn: allChildren.map((c) => c.id).toList(),
        );
      }

      return query.snapshots().map(
        (snap) => snap.docs
            .map(
              (doc) => RewardRequestModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList(),
      );
    });
