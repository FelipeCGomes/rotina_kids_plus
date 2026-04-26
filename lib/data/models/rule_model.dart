class RuleModel {
  final String id;
  final String parentId;
  final String title;
  final String description;

  RuleModel({
    required this.id,
    required this.parentId,
    required this.title,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'title': title,
      'description': description,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory RuleModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RuleModel(
      id: documentId,
      parentId: map['parentId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }
}
