import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/mock_data_provider.dart';
import '../../../data/services/firestore_providers.dart';
import '../../../core/utils/tts_service.dart';

class ChildDashboardScreen extends ConsumerWidget {
  const ChildDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pegamos a criança mockada por enquanto (ID 'c1')
    final child = ref.watch(currentChildProvider);

    // Escutamos as tarefas dessa criança no Firestore em tempo real
    final tasksAsyncValue = ref.watch(todayTasksStreamProvider(child.id));

    // Serviço de áudio (Text-To-Speech)
    final ttsService = ref.read(ttsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${child.name}!'),
        actions: [
          Chip(
            avatar: const Icon(Icons.star, color: Colors.amber),
            label: Text('${child.currentXp} XP'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.face, size: 50),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nível ${child.level}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: child.totalXp / 1000,
                ), // Baseado na regra de nível
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: tasksAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Erro ao carregar tarefas: $error')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      'Uhuu! Nenhuma tarefa pendente!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: IconButton(
                          icon: const Icon(
                            Icons.volume_up,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () {
                            ttsService.speak(
                              'Sua tarefa é: ${task.title}. Recompensa de ${task.xpReward} X P.',
                            );
                          },
                        ),
                        title: Text(
                          task.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${task.category} • ${task.time}'),
                        trailing: ElevatedButton.icon(
                          onPressed: () {
                            // Lógica para marcar como concluída no Firestore
                            ref
                                .read(firestoreProvider)
                                .collection('tasks')
                                .doc(task.id)
                                .update({'status': 'completed'});

                            // Feedback visual rápido
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '+${task.xpReward} XP ganhos! Aguardando aprovação.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: Text('+${task.xpReward} XP'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
