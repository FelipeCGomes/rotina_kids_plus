import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rotina_kids_plus/core/theme/app_routes.dart';
import '../../data/repositories/mock_data_repository.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<DataRepository>();
    final child = repo.activeChild;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Painel de Controle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smartphone_rounded),
            tooltip: 'Visão da Criança',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.childHome),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.star, color: Colors.white),
            ),
            title: Text(
              child?.name ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            subtitle: Text('${child?.currentXp ?? 0} XP disponíveis'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tarefas Pendentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...repo.todayTasks
              .where((t) => t.status == 'pendente')
              .map((task) => _buildTaskCard(task, false)),
          const SizedBox(height: 16),
          const Text(
            'Tarefas Concluídas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ...repo.todayTasks
              .where((t) => t.status == 'concluída')
              .map((task) => _buildTaskCard(task, true)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(dynamic task, bool isCompleted) {
    return Card(
      color: isCompleted ? Colors.grey.shade100 : Colors.white,
      child: ListTile(
        leading: Icon(
          isCompleted
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: isCompleted ? Colors.green : Colors.grey,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: Text(
          '+ ${task.xpReward} XP',
          style: TextStyle(
            color: isCompleted ? Colors.grey : Colors.amber,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
