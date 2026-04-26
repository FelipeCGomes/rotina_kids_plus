import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rule_model.dart';
import 'auth_provider.dart';

class RuleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addRule(RuleModel rule) async {
    DocumentReference docRef = _db.collection('family_rules').doc();
    await docRef.set(rule.toMap()..['id'] = docRef.id);
  }

  Future<void> updateRule(RuleModel rule) async {
    await _db.collection('family_rules').doc(rule.id).update(rule.toMap());
  }

  Future<void> deleteRule(String id) async {
    await _db.collection('family_rules').doc(id).delete();
  }
}

final ruleServiceProvider = Provider<RuleService>((ref) => RuleService());

final familyRulesStreamProvider = StreamProvider<List<RuleModel>>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('family_rules')
      .where('parentId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) {
        final rules = snap.docs
            .map((doc) => RuleModel.fromMap(doc.data(), doc.id))
            .toList();
        // Ordena pela data de criação
        rules.sort((a, b) => a.id.compareTo(b.id));
        return rules;
      });
});
