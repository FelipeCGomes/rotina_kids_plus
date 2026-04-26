class RewardModel {
  final String id;
  final String childId;
  final String title;
  final String? description;
  final int xpCost;
  final String rewardType;
  final String? appPackageName;
  final int? durationMinutes;
  final bool requiresApproval;
  final bool active;

  RewardModel({
    required this.id,
    required this.childId,
    required this.title,
    this.description,
    required this.xpCost,
    required this.rewardType,
    this.appPackageName,
    this.durationMinutes,
    this.requiresApproval = true,
    this.active = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'title': title,
      'description': description,
      'xpCost': xpCost,
      'rewardType': rewardType,
      'appPackageName': appPackageName,
      'durationMinutes': durationMinutes,
      'requiresApproval': requiresApproval,
      'active': active,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory RewardModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RewardModel(
      id: documentId,
      childId: map['childId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      xpCost: map['xpCost']?.toInt() ?? 0,
      rewardType: map['rewardType'] ?? 'Presente',
      appPackageName: map['appPackageName'],
      durationMinutes: map['durationMinutes']?.toInt(),
      requiresApproval: map['requiresApproval'] ?? true,
      active: map['active'] ?? true,
    );
  }
}
