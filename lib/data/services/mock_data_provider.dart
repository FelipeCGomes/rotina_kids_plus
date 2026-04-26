import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/child_model.dart';
import '../models/task_model.dart';

final currentChildProvider = StateProvider<ChildModel>((ref) {
  return ChildModel(
    id: 'c1',
    parentId: 'p1',
    name: 'Leo',
    lastName: 'Silva', // Adicionado
    birthDate: DateTime.now().subtract(
      const Duration(days: 365 * 8),
    ), // Substituiu o 'age: 8'
    sex: 'Masculino', // Adicionado
    avatarId: 'avatar_hero',
    currentXp: 120,
    totalXp: 450,
    level: 3,
  );
});

final todayTasksProvider = StateProvider<List<TaskModel>>((ref) {
  return [
    TaskModel(
      id: 't1',
      childId: 'c1',
      title: 'Arrumar a Cama',
      category: 'Casa',
      period: 'Manhã',
      startDate: DateTime.now(),
      time: '07:30',
      xpReward: 10,
      requiresApproval: true,
      isRecurring: true,
      daysOfWeek: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex'],
    ),
    TaskModel(
      id: 't2',
      childId: 'c1',
      title: 'Dever de Casa',
      description: 'Matemática e Ciências',
      category: 'Escola',
      period: 'Tarde',
      startDate: DateTime.now(),
      time: '14:00',
      endTime: '16:00',
      xpReward: 30,
      requiresApproval: true,
    ),
    TaskModel(
      id: 't3',
      childId: 'c1',
      title: 'Antibiótico',
      category: 'Medicamento',
      period: 'Manhã',
      startDate: DateTime.now(),
      time: '08:00',
      xpReward: 5,
      requiresApproval: false,
      isRecurring: true,
      daysOfWeek: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'],
      intervalHours: 8,
      durationInDays: 7,
    ),
  ];
});
