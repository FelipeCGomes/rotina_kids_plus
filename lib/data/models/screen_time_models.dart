class AppUsageModel {
  final String appName;
  final String packageName;
  final int durationMinutes;
  final String category;

  AppUsageModel({
    required this.appName,
    required this.packageName,
    required this.durationMinutes,
    this.category = 'Outros',
  });
}

class ScreenRuleModel {
  final String id;
  final String childId;
  final String appName;
  final String packageName;
  final String ruleType; // 'block' (Bloqueado) ou 'limit' (Limite de tempo)
  final int? maxMinutes;
  final bool active;

  ScreenRuleModel({
    required this.id,
    required this.childId,
    required this.appName,
    required this.packageName,
    required this.ruleType,
    this.maxMinutes,
    this.active = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'appName': appName,
      'packageName': packageName,
      'ruleType': ruleType,
      'maxMinutes': maxMinutes,
      'active': active,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory ScreenRuleModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ScreenRuleModel(
      id: documentId,
      childId: map['childId'] ?? '',
      appName: map['appName'] ?? '',
      packageName: map['packageName'] ?? '',
      ruleType: map['ruleType'] ?? 'block',
      maxMinutes: map['maxMinutes']?.toInt(),
      active: map['active'] ?? true,
    );
  }
}
