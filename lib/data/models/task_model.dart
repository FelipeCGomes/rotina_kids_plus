import 'package:cloud_firestore/cloud_firestore.dart'; // IMPORT NOVO: Para o Flutter entender o Timestamp

class TaskModel {
  final String id;
  final String childId;
  final String title;
  final String? description;
  final String category;
  final String period;
  final DateTime startDate;
  final String time;
  final int xpReward;
  final String status;
  final bool requiresApproval;
  final String? endTime;
  final bool isRecurring;
  final List<dynamic> daysOfWeek;
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
      'startDate': startDate.toIso8601String(),
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
    // =================================================================
    // TRADUTOR UNIVERSAL DE DATAS (O Fim do Bug do Fuso Horário)
    // =================================================================
    DateTime parseDate(dynamic dateData) {
      if (dateData == null) return DateTime.now();

      // Se vier em formato de Relógio do Firebase
      if (dateData is Timestamp) return dateData.toDate();

      try {
        String dateStr = dateData.toString();
        // Se vier com o fuso horário UTC acoplado (A letra 'T')
        if (dateStr.contains('T')) {
          final datePart = dateStr.split('T')[0];
          final parts = datePart.split('-');
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
        return DateTime.parse(dateStr).toLocal();
      } catch (e) {
        return DateTime.now();
      }
    }

    return TaskModel(
      id: documentId,
      childId: map['childId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      category: map['category'] ?? 'Outros',
      period: map['period'] ?? 'Manhã',
      startDate: parseDate(map['startDate']), // Passando pelo Tradutor!
      time: map['time'] ?? '00:00',
      xpReward: map['xpReward']?.toInt() ?? 0,
      status: map['status'] ?? 'pending',
      requiresApproval: map['requiresApproval'] ?? true,
      endTime: map['endTime'],
      isRecurring: map['isRecurring'] ?? false,
      daysOfWeek: map['daysOfWeek'] ?? [],
      intervalHours: map['intervalHours']?.toInt(),
      durationInDays: map['durationInDays']?.toInt(),
    );
  }
}
