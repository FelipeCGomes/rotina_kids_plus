import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:rotina_kids_plus/core/utils/app_radar_service.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/services/child_providers.dart';
import '../../../data/services/firestore_providers.dart';

final pendingApprovalsProvider = StreamProvider.family<int, List<String>>((
  ref,
  childIds,
) {
  if (childIds.isEmpty) return Stream.value(0);
  return FirebaseFirestore.instance
      .collection('task_logs')
      .where('childId', whereIn: childIds)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snap) => snap.docs.length);
});

final parentRawTasksProvider = StreamProvider.family<List<TaskModel>, String>((
  ref,
  childId,
) {
  return FirebaseFirestore.instance
      .collection('tasks')
      .where('childId', isEqualTo: childId)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

final parentRawLogsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, childId) {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      return FirebaseFirestore.instance
          .collection('task_logs')
          .where('childId', isEqualTo: childId)
          .where('dateString', isEqualTo: todayStr)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => doc.data()).toList());
    });

final dailyProgressProvider =
    Provider.family<AsyncValue<Map<String, int>>, String>((ref, childId) {
      final tasksAsync = ref.watch(parentRawTasksProvider(childId));
      final logsAsync = ref.watch(parentRawLogsProvider(childId));

      if (tasksAsync.isLoading || logsAsync.isLoading) {
        return const AsyncValue.loading();
      }
      if (tasksAsync.hasError) {
        return const AsyncValue.data({'total': 0, 'done': 0});
      }

      final allTasks = tasksAsync.value ?? [];
      final allLogs = logsAsync.value ?? [];

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      const weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      final currentDayStr = weekDays[now.weekday - 1];

      // =================================================================
      // CORREÇÃO MATEMÁTICA DA BARRA DE PROGRESSO DO PAI
      // =================================================================
      final todaysTasks = allTasks.where((task) {
        final taskDate = DateTime(
          task.startDate.year,
          task.startDate.month,
          task.startDate.day,
        );

        if (taskDate.isAfter(todayStart)) return false;

        if (task.isRecurring) {
          if (task.daysOfWeek.isNotEmpty) {
            return task.daysOfWeek.contains(currentDayStr);
          }
          return true;
        } else {
          return taskDate.isAtSameMomentAs(todayStart);
        }
      }).toList();

      final total = todaysTasks.length;
      final completedIds = allLogs
          .map((log) => log['taskId'] as String)
          .toSet();
      int done = todaysTasks
          .where((task) => completedIds.contains(task.id))
          .length;

      return AsyncValue.data({'total': total, 'done': done});
    });

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(parentChildrenStreamProvider);
    final selectedChildSnapshot = ref.watch(selectedChildProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão dos Pais', style: TextStyle(fontSize: 30)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_reaction_outlined),
            tooltip: 'Adicionar Filho',
            onPressed: () => context.push('/add-child'),
          ),

          IconButton(
            icon: const Icon(Icons.smart_toy, size: 28),
            tooltip: 'Ir para Modo Criança',
            onPressed: () => context.go('/child-selection'),
          ),

          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Meu Perfil',
            onPressed: () => context.push('/parent-profile'),
          ),
        ],
      ),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Erro ao carregar dados: $err')),
        data: (children) {
          final childIds = children.map((c) => c.id).toList();
          AppRadarService().startParentRadar(childIds);

          if (children.isEmpty) {
            return _buildEmptyState(context);
          }

          if (selectedChildSnapshot == null ||
              !children.any((c) => c.id == selectedChildSnapshot.id)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(selectedChildProvider.notifier).state = children.first;
            });
            return const Center(child: CircularProgressIndicator());
          }

          final liveChild = children.firstWhere(
            (c) => c.id == selectedChildSnapshot.id,
          );

          final pendingCountAsync = ref.watch(
            pendingApprovalsProvider(childIds),
          );
          final hasPendingApprovals = (pendingCountAsync.value ?? 0) > 0;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(parentChildrenStreamProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: _buildDashboardContent(
              context,
              ref,
              children,
              liveChild,
              hasPendingApprovals,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    List<ChildModel> allChildren,
    ChildModel currentChild,
    bool hasPendingApprovals,
  ) {
    final progressAsync = ref.watch(dailyProgressProvider(currentChild.id));

    final bool isOnline =
        currentChild.lastActive != null &&
        DateTime.now().difference(currentChild.lastActive!).inMinutes < 3;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: _renderAvatar(
                          context,
                          currentChild.avatarId,
                          size: 70,
                        ),
                      ),
                      if (isOnline)
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentChild.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () => context.push(
                                '/add-child',
                                extra: currentChild,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isOnline
                              ? 'Online agora'
                              : currentChild.lastActive != null
                              ? 'Visto às ${DateFormat('HH:mm').format(currentChild.lastActive!)}'
                              : 'Offline',
                          style: TextStyle(
                            color: isOnline ? Colors.green[700] : Colors.grey,
                            fontWeight: isOnline
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nível ${currentChild.level} • ${currentChild.currentXp} XP',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        progressAsync.when(
                          data: (stats) {
                            final total = stats['total'] ?? 0;
                            final done = stats['done'] ?? 0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progresso de Hoje: $done/$total tarefas',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: total == 0 ? 0.0 : done / total,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.amber,
                                  backgroundColor: Colors.grey[200],
                                ),
                              ],
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, size: 30),
                    onPressed: () =>
                        _showChildSelector(context, ref, allChildren),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Resumo de Hoje',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: progressAsync.when(
                  data: (stats) => _buildSummaryCard(
                    context,
                    title: 'Tarefas',
                    value: '${stats['done']}/${stats['total']}',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    onTap: () =>
                        _showDailyTasksDetail(context, ref, currentChild),
                  ),
                  loading: () => _buildSummaryCard(
                    context,
                    title: 'Tarefas',
                    value: '...',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  error: (_, _) => _buildSummaryCard(
                    context,
                    title: 'Tarefas',
                    value: 'Erro',
                    icon: Icons.error_outline,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Saldo de Tempo',
                  value:
                      '${currentChild.timeBalance ~/ 60}h ${(currentChild.timeBalance % 60).toString().padLeft(2, '0')}m',
                  icon: Icons.smartphone,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Atalhos de Gestão',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            children: [
              _buildShortcutAction(
                context,
                icon: Icons.list_alt,
                label: 'Rotina',
                onTap: () => context.push('/routine-list'),
              ),
              _buildShortcutAction(
                context,
                icon: Icons.card_giftcard,
                label: 'Prêmios',
                onTap: () => context.push('/reward-list'),
              ),
              _buildShortcutAction(
                context,
                icon: Icons.approval,
                label: 'Aprovar',
                hasAlert: hasPendingApprovals,
                onTap: () => context.push('/approvals'),
              ),
              _buildShortcutAction(
                context,
                icon: Icons.timer,
                label: 'Tempo',
                onTap: () => context.push('/screen-time'),
              ),
              _buildShortcutAction(
                context,
                icon: Icons.rule,
                label: 'Regras',
                onTap: () => context.push('/rules'),
              ),
              _buildShortcutAction(
                context,
                icon: Icons.calendar_month,
                label: 'Agenda',
                onTap: () => context.push('/calendar'),
              ),
              _buildShortcutAction(
                context,
                icon: Icons.forum,
                label: 'Comunidade',
                onTap: () => context.push('/community'),
              ),
              _buildShortcutAction(
                context,
                icon: Icons.person_add,
                label: 'Novo Filho',
                onTap: () => context.push('/add-child'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDailyTasksDetail(
    BuildContext context,
    WidgetRef ref,
    ChildModel childModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final tasksAsync = ref.watch(parentRawTasksProvider(childModel.id));
            final logsAsync = ref.watch(parentRawLogsProvider(childModel.id));

            if (tasksAsync.isLoading || logsAsync.isLoading) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final allTasks = tasksAsync.value ?? [];
            final allLogs = logsAsync.value ?? [];
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            const weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
            final currentDayStr = weekDays[now.weekday - 1];

            // =================================================================
            // CORREÇÃO MATEMÁTICA NA ABA DE DETALHES (BOTTOM SHEET)
            // =================================================================
            final todaysTasks = allTasks.where((task) {
              final taskDate = DateTime(
                task.startDate.year,
                task.startDate.month,
                task.startDate.day,
              );

              if (taskDate.isAfter(todayStart)) return false;

              if (task.isRecurring) {
                if (task.daysOfWeek.isNotEmpty) {
                  return task.daysOfWeek.contains(currentDayStr);
                }
                return true;
              } else {
                return taskDate.isAtSameMomentAs(todayStart);
              }
            }).toList();

            final completedIds = allLogs
                .map((log) => log['taskId'] as String)
                .toSet();

            final pendingTasks = todaysTasks
                .where((t) => !completedIds.contains(t.id))
                .toList();
            final doneTasks = todaysTasks
                .where((t) => completedIds.contains(t.id))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Container(
                    width: 50,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Diário de Missões',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_filled,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Falta Fazer (${pendingTasks.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (pendingTasks.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Tudo limpo! Nada pendente.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ...pendingTasks.map(
                          (t) => Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                t.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(t.time),
                              trailing: VibratingNudgeIcon(
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('nudges')
                                        .add({
                                          'childId': childModel.id,
                                          'taskId': t.id,
                                          'title': t.title,
                                          'timestamp':
                                              FieldValue.serverTimestamp(),
                                        });

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Avisando o ${childModel.name}... 📳',
                                          ),
                                          backgroundColor: Colors.blueAccent,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('Erro ao enviar nudge: $e');
                                  }
                                },
                              ),
                            ),
                          ),
                        ),

                        const Divider(height: 40, thickness: 2),

                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 10),
                            Text(
                              'Missões Concluídas (${doneTasks.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (doneTasks.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Nenhuma missão feita ainda.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ...doneTasks.map(
                          (t) => Card(
                            color: Colors.green[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              title: Text(
                                t.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.green,
                                ),
                              ),
                              trailing: Text(
                                '+${t.xpReward} XP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChildSelector(
    BuildContext context,
    WidgetRef ref,
    List<ChildModel> children,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecione o Perfil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: _renderAvatar(context, child.avatarId, size: 40),
                      ),
                      title: Text(
                        child.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Nível ${child.level}'),
                      onTap: () {
                        ref.read(selectedChildProvider.notifier).state = child;
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue,
                ),
                title: const Text('Adicionar novo perfil'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/add-child');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Nenhum perfil de criança encontrado.'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/add-child'),
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar meu primeiro filho'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderAvatar(
    BuildContext context,
    String avatarData, {
    double size = 40,
  }) {
    if (avatarData.contains('<svg')) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: SvgPicture.string(avatarData, fit: BoxFit.cover),
        ),
      );
    }
    IconData fallbackIcon;
    if (avatarData == 'avatar_dino') {
      fallbackIcon = Icons.pets;
    } else if (avatarData == 'avatar_girl') {
      fallbackIcon = Icons.face_3;
    } else if (avatarData == 'avatar_hero') {
      fallbackIcon = Icons.flash_on;
    } else {
      fallbackIcon = Icons.face;
    }
    return Icon(
      fallbackIcon,
      size: size * 0.6,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool hasAlert = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              if (hasAlert)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class VibratingNudgeIcon extends StatefulWidget {
  final Future<void> Function() onPressed;

  const VibratingNudgeIcon({super.key, required this.onPressed});

  @override
  State<VibratingNudgeIcon> createState() => _VibratingNudgeIconState();
}

class _VibratingNudgeIconState extends State<VibratingNudgeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );

    _animation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isProcessing
        ? const SizedBox(
            width: 48,
            height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        : RotationTransition(
            turns: _animation,
            child: IconButton(
              icon: const Icon(
                Icons.vibration,
                color: Colors.blueAccent,
                size: 28,
              ),
              tooltip: 'Enviar Lembrete',
              onPressed: () async {
                if (_isProcessing) return;

                setState(() => _isProcessing = true);

                HapticFeedback.heavyImpact();

                _controller.repeat(reverse: true);

                await widget.onPressed();

                if (mounted) {
                  _controller.stop();
                  _controller.reset();
                  setState(() => _isProcessing = false);
                }
              },
            ),
          );
  }
}
