class ChildModel {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final String avatarId;
  final int currentXp;
  final int totalXp;
  final int level;

  ChildModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    required this.avatarId,
    this.currentXp = 0,
    this.totalXp = 0,
    this.level = 1,
  });
}
