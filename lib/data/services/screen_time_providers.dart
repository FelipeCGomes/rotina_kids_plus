import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/screen_time_models.dart';
import 'firestore_providers.dart';
import 'child_providers.dart';

// --- SERVIÇO DE REGRAS (REAL NO FIRESTORE) ---
class ScreenRuleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addRule(ScreenRuleModel rule) async {
    DocumentReference docRef = _db.collection('screen_rules').doc();
    await docRef.set(rule.toMap()..['id'] = docRef.id);
  }

  Future<void> toggleRuleState(String ruleId, bool isActive) async {
    await _db.collection('screen_rules').doc(ruleId).update({
      'active': isActive,
    });
  }

  Future<void> deleteRule(String ruleId) async {
    await _db.collection('screen_rules').doc(ruleId).delete();
  }
}

final screenRuleServiceProvider = Provider<ScreenRuleService>(
  (ref) => ScreenRuleService(),
);

// Stream das regras cadastradas pelo pai
final childScreenRulesProvider =
    StreamProvider.family<List<ScreenRuleModel>, String>((ref, childId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('screen_rules')
          .where('childId', isEqualTo: childId)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((doc) => ScreenRuleModel.fromMap(doc.data(), doc.id))
                .toList(),
          );
    });

// --- SERVIÇO DE USO DE APPS (MOCK PARA UI) ---
// No futuro, isso será substituído por um MethodChannel chamando o Kotlin
final todayAppUsageProvider = Provider.family<List<AppUsageModel>, String>((
  ref,
  childId,
) {
  return [
    AppUsageModel(
      appName: 'YouTube',
      packageName: 'com.google.android.youtube',
      durationMinutes: 85,
      category: 'Vídeo',
    ),
    AppUsageModel(
      appName: 'Roblox',
      packageName: 'com.roblox.client',
      durationMinutes: 45,
      category: 'Jogos',
    ),
    AppUsageModel(
      appName: 'TikTok',
      packageName: 'com.zhiliaoapp.musically',
      durationMinutes: 30,
      category: 'Rede Social',
    ),
    AppUsageModel(
      appName: 'Chrome',
      packageName: 'com.android.chrome',
      durationMinutes: 15,
      category: 'Navegador',
    ),
  ];
});
