class RewardRequestModel {
  final String id;
  final String rewardId;
  final String rewardTitle;
  final int xpCost;
  final String childId;
  final DateTime requestedAt;
  final String status; // 'pending', 'approved', 'rejected'

  RewardRequestModel({
    required this.id,
    required this.rewardId,
    required this.rewardTitle,
    required this.xpCost,
    required this.childId,
    required this.requestedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rewardId': rewardId,
      'rewardTitle': rewardTitle,
      'xpCost': xpCost,
      'childId': childId,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status,
    };
  }

  factory RewardRequestModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return RewardRequestModel(
      id: documentId,
      rewardId: map['rewardId'] ?? '',
      rewardTitle: map['rewardTitle'] ?? '',
      xpCost: map['xpCost']?.toInt() ?? 0,
      childId: map['childId'] ?? '',
      requestedAt: map['requestedAt'] != null
          ? DateTime.parse(map['requestedAt'])
          : DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }
}
