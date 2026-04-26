class TaskModel {
  final String id;
  final String childId;
  final String title;
  final String? description; // Novo campo
  final String category;
  final String period;
  final DateTime startDate; // Novo campo
  final String time;
  final int xpReward;
  final String status;
  final bool requiresApproval; // Novo campo

  final String? endTime;
  final bool isRecurring;
  final List<String> daysOfWeek;
  final int? intervalHours;
  final int? durationInDays;

  TaskModel({
    required this.id,
    required this.childId,
    required this.title,
    this.description,
    required this.category,
    required this.period,
    required this.startDate,
    required this.time,
    required this.xpReward,
    this.status = 'pending',
    this.requiresApproval = true,
    this.endTime,
    this.isRecurring = false,
    this.daysOfWeek = const [],
    this.intervalHours,
    this.durationInDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'title': title,
      'description': description,
      'category': category,
      'period': period,
      'startDate': startDate
          .toIso8601String(), // Salva a data em formato padronizado
      'time': time,
      'xpReward': xpReward,
      'status': status,
      'requiresApproval': requiresApproval,
      'endTime': endTime,
      'isRecurring': isRecurring,
      'daysOfWeek': daysOfWeek,
      'intervalHours': intervalHours,
      'durationInDays': durationInDays,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TaskModel(
      id: documentId,
      childId: map['childId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      category: map['category'] ?? 'Outros',
      period: map['period'] ?? 'Manhã',
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : DateTime.now(),
      time: map['time'] ?? '00:00',
      xpReward: map['xpReward']?.toInt() ?? 0,
      status: map['status'] ?? 'pending',
      requiresApproval: map['requiresApproval'] ?? true,
      endTime: map['endTime'],
      isRecurring: map['isRecurring'] ?? false,
      daysOfWeek: List<String>.from(map['daysOfWeek'] ?? []),
      intervalHours: map['intervalHours']?.toInt(),
      durationInDays: map['durationInDays']?.toInt(),
    );
  }
}
