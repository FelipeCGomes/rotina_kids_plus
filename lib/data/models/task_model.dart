class TaskModel {
  final String id;
  final String title;
  final String category;
  final int xpReward;
  final String status;

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.xpReward,
    this.status = 'pendente',
  });
}
