import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/child_model.dart';
import '../models/task_model.dart';

// Simula a criança logada ou selecionada pelo pai
final currentChildProvider = StateProvider<ChildModel>((ref) {
  return ChildModel(
    id: 'c1',
    parentId: 'p1',
    name: 'Leo',
    age: 8,
    avatarId: 'avatar_hero',
    currentXp: 120,
    totalXp: 450,
    level: 3,
  );
});

// Simula as tarefas do dia
final todayTasksProvider = StateProvider<List<TaskModel>>((ref) {
  return [
    TaskModel(
      id: 't1',
      childId: 'c1',
      title: 'Arrumar a Cama',
      category: 'Casa',
      time: '07:30',
      xpReward: 10,
    ),
    TaskModel(
      id: 't2',
      childId: 'c1',
      title: 'Dever de Casa',
      category: 'Escola',
      time: '14:00',
      xpReward: 30,
    ),
    TaskModel(
      id: 't3',
      childId: 'c1',
      title: 'Escovar os dentes',
      category: 'Higiene',
      time: '20:30',
      xpReward: 10,
    ),
  ];
});
