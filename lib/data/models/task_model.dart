class TaskModel {
  final String id;
  final String childId;
  final String title;
  final String category;
  final String time; // Ex: '08:00'
  final int xpReward;
  final String status; // 'pending', 'completed'

  TaskModel({
    required this.id,
    required this.childId,
    required this.title,
    required this.category,
    required this.time,
    required this.xpReward,
    this.status = 'pending',
  });
}
