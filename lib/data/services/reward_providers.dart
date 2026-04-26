import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward_model.dart';
import 'firestore_providers.dart';
import 'child_providers.dart';

class RewardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addReward(RewardModel reward) async {
    DocumentReference docRef = _db.collection('rewards').doc();
    await docRef.set(reward.toMap()..['id'] = docRef.id);
  }

  Future<void> updateReward(RewardModel reward) async {
    await _db.collection('rewards').doc(reward.id).update(reward.toMap());
  }

  Future<void> deleteReward(String rewardId) async {
    await _db.collection('rewards').doc(rewardId).delete();
  }
}

final rewardServiceProvider = Provider<RewardService>((ref) => RewardService());

// Stream para escutar os prêmios cadastrados
final filteredRewardsStreamProvider =
    StreamProvider.family<List<RewardModel>, String?>((ref, childId) {
      final firestore = ref.watch(firestoreProvider);
      Query query = firestore.collection('rewards');

      if (childId != null && childId != 'all') {
        query = query.where('childId', isEqualTo: childId);
      } else {
        final allChildren = ref.watch(parentChildrenStreamProvider).value ?? [];
        if (allChildren.isEmpty) return Stream.value([]);
        final childIds = allChildren.map((c) => c.id).toList();
        query = query.where('childId', whereIn: childIds);
      }

      return query.snapshots().map((snapshot) {
        final rewards = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return RewardModel.fromMap(data, doc.id);
        }).toList();
        // Ordena do mais barato para o mais caro
        rewards.sort((a, b) => a.xpCost.compareTo(b.xpCost));
        return rewards;
      });
    });
