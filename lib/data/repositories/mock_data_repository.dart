import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../models/task_model.dart';

class DataRepository extends ChangeNotifier {
  ChildModel? activeChild = ChildModel(
    id: 'c1',
    name: 'Benício',
    currentXp: 120,
    level: 3,
  );

  List<TaskModel> todayTasks = [
    TaskModel(
      id: 't1',
      title: 'Arrumar a cama',
      category: 'Casa',
      xpReward: 10,
      status: 'concluída',
    ),
    TaskModel(id: 't2', title: 'Fazer lição', category: 'Escola', xpReward: 20),
    TaskModel(
      id: 't3',
      title: 'Tomar vitamina',
      category: 'Alimentação',
      xpReward: 15,
    ),
  ];

  void completeTask(String taskId) {
    final taskIndex = todayTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = todayTasks[taskIndex];
      todayTasks[taskIndex] = TaskModel(
        id: task.id,
        title: task.title,
        category: task.category,
        xpReward: task.xpReward,
        status: 'concluída',
      );
      activeChild = ChildModel(
        id: activeChild!.id,
        name: activeChild!.name,
        currentXp: activeChild!.currentXp + task.xpReward,
        level: activeChild!.level,
      );
      notifyListeners();
    }
  }
}
