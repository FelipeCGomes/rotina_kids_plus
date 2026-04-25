import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rotina_kids_plus/core/routes/app_routes.dart';
import '../../data/repositories/mock_data_repository.dart';

class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<DataRepository>();
    final child = repo.activeChild;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Olá, ${child?.name ?? ''}!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Chip(
              backgroundColor: Colors.amber,
              label: Text(
                '${child?.currentXp ?? 0} XP',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              avatar: const Icon(
                Icons.attach_money_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suas missões:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: repo.todayTasks.length,
                itemBuilder: (context, index) {
                  final task = repo.todayTasks[index];
                  final isDone = task.status == 'concluída';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        isDone ? Icons.check_circle : Icons.circle_outlined,
                        color: isDone ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: isDone
                          ? null
                          : ElevatedButton(
                              onPressed: () => repo.completeTask(task.id),
                              child: const Text('Feito!'),
                            ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                ),
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.parentHome,
                ),
                icon: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'Voltar para Painel Pai',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
