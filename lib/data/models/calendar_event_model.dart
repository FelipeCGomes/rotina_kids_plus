class CalendarEventModel {
  final String id;
  final String parentId;
  final String childId; // Pode ser 'all' se for um evento para a família toda
  final String title;
  final String? description;
  final String category;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? location;
  final bool notifyParents;
  final bool visibleToChild;

  CalendarEventModel({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.title,
    this.description,
    required this.category,
    required this.startDateTime,
    required this.endDateTime,
    this.location,
    this.notifyParents = true,
    this.visibleToChild =
        false, // Por padrão, a criança só vê a rotina diária, não a agenda inteira
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'childId': childId,
      'title': title,
      'description': description,
      'category': category,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'location': location,
      'notifyParents': notifyParents,
      'visibleToChild': visibleToChild,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory CalendarEventModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return CalendarEventModel(
      id: documentId,
      parentId: map['parentId'] ?? '',
      childId: map['childId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      category: map['category'] ?? 'Outros',
      startDateTime: map['startDateTime'] != null
          ? DateTime.parse(map['startDateTime'])
          : DateTime.now(),
      endDateTime: map['endDateTime'] != null
          ? DateTime.parse(map['endDateTime'])
          : DateTime.now().add(const Duration(hours: 1)),
      location: map['location'],
      notifyParents: map['notifyParents'] ?? true,
      visibleToChild: map['visibleToChild'] ?? false,
    );
  }
}
