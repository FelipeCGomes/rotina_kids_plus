class TaskLogModel {
  final String id;
  final String taskId;
  final String taskTitle;
  final int xpReward;
  final String childId;
  final DateTime completedAt;
  final String status; // 'pending', 'approved', 'rejected'

  TaskLogModel({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.xpReward,
    required this.childId,
    required this.completedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'xpReward': xpReward,
      'childId': childId,
      'completedAt': completedAt.toIso8601String(),
      'status': status,
    };
  }

  factory TaskLogModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TaskLogModel(
      id: documentId,
      taskId: map['taskId'] ?? '',
      taskTitle: map['taskTitle'] ?? '',
      xpReward: map['xpReward']?.toInt() ?? 0,
      childId: map['childId'] ?? '',
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }
}
