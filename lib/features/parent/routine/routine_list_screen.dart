import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/child_providers.dart';
import '../../../data/services/firestore_providers.dart';
import '../../../data/services/task_providers.dart';

class RoutineListScreen extends ConsumerStatefulWidget {
  const RoutineListScreen({super.key});

  @override
  ConsumerState<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends ConsumerState<RoutineListScreen> {
  String _filterId = 'all';

  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedChildProvider);
    if (selected != null) _filterId = selected.id;
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenStreamProvider);
    final tasksAsync = ref.watch(filteredTasksStreamProvider(_filterId));

    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Rotina')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-task'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          childrenAsync.when(
            data: (children) => _buildFilterBar(children),
            loading: () => const SizedBox(height: 60),
            error: (_, _) => const SizedBox.shrink(),
          ),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
              data: (tasks) {
                if (tasks.isEmpty)
                  return const Center(
                    child: Text('Nenhuma tarefa encontrada.'),
                  );

                final grouped = {
                  'Manhã': tasks.where((t) => t.period == 'Manhã').toList(),
                  'Tarde': tasks.where((t) => t.period == 'Tarde').toList(),
                  'Noite': tasks.where((t) => t.period == 'Noite').toList(),
                };

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection(
                      'Manhã',
                      Icons.wb_sunny,
                      Colors.orange,
                      grouped['Manhã']!,
                    ),
                    _buildSection(
                      'Tarde',
                      Icons.wb_cloudy,
                      Colors.blue,
                      grouped['Tarde']!,
                    ),
                    _buildSection(
                      'Noite',
                      Icons.nights_stay,
                      Colors.indigo,
                      grouped['Noite']!,
                    ),
                    const SizedBox(height: 70),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(List<ChildModel> children) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: _filterId == 'all',
            onSelected: (val) => setState(() => _filterId = 'all'),
          ),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                avatar: Icon(_getIcon(child.avatarId), size: 16),
                label: Text(child.name),
                selected: _filterId == child.id,
                onSelected: (val) => setState(() => _filterId = child.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<TaskModel> tasks,
  ) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        ...tasks.map((t) => _buildTaskCard(t)),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final children = ref.watch(parentChildrenStreamProvider).value ?? [];
    final child = children.firstWhere(
      (c) => c.id == task.childId,
      orElse: () => ChildModel(
        id: '',
        parentId: '',
        name: '?',
        lastName: '',
        birthDate: DateTime.now(),
        sex: 'Masculino',
        avatarId: 'avatar_default',
      ),
    );

    // CORREÇÃO: Mostra os dias da semana na lista (ex: Seg, Qua, Sex)
    final dateString = task.isRecurring
        ? ' • ${task.daysOfWeek.join(', ')}'
        : ' • ${DateFormat('dd/MM').format(task.startDate)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          child: Icon(_getIcon(child.avatarId), size: 20),
        ),
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${task.time}$dateString • ${child.name}'),
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => context.push('/create-task', extra: task),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              onPressed: () => _deleteTask(task),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTask(TaskModel task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskServiceProvider).deleteTask(task.id);
              Navigator.pop(ctx);
            },
            child: const Text('Sim', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String id) {
    if (id == 'avatar_dino') return Icons.pets;
    if (id == 'avatar_girl') return Icons.face_3;
    return Icons.face;
  }
}
