import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/child_providers.dart';
import '../../../data/services/firestore_providers.dart'; // Importação necessária para ler as tarefas de hoje

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escuta a lista de filhos do Firestore em tempo real
    final childrenAsync = ref.watch(parentChildrenStreamProvider);

    // 2. Escuta qual criança está selecionada no momento
    final selectedChild = ref.watch(selectedChildProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão dos Pais'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_reaction_outlined),
            tooltip: 'Adicionar Filho',
            onPressed: () => context.push('/add-child'),
          ),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Erro ao carregar dados: $err')),
        data: (children) {
          // Se não houver crianças cadastradas, mostra tela de incentivo
          if (children.isEmpty) {
            return _buildEmptyState(context);
          }

          // Se houver crianças mas nenhuma selecionada, seleciona a primeira da lista
          if (selectedChild == null && children.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(selectedChildProvider.notifier).state = children.first;
            });
            return const Center(child: CircularProgressIndicator());
          }

          // Renderiza o Dashboard com a criança selecionada
          return _buildDashboardContent(context, ref, children, selectedChild!);
        },
      ),
    );
  }

  // Conteúdo principal do Dashboard quando há dados
  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    List<ChildModel> allChildren,
    ChildModel currentChild,
  ) {
    // Escuta as tarefas de hoje para calcular o progresso real
    final tasksAsync = ref.watch(todayTasksStreamProvider(currentChild.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de Resumo da Criança Selecionada
          Card(
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      _getAvatarIcon(currentChild.avatarId),
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome da criança + Botão de Editar
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentChild.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
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
                              constraints:
                                  const BoxConstraints(), // Reduz o espaço em volta do botão
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Nível ${currentChild.level} • ${currentChild.currentXp} XP',
                        ),
                        const SizedBox(height: 10),

                        // Barra de Progresso Real
                        tasksAsync.when(
                          data: (tasks) {
                            final total = tasks.length;
                            final done = tasks
                                .where(
                                  (t) =>
                                      t.status == 'completed' ||
                                      t.status == 'approved',
                                )
                                .length;
                            final progressValue = total == 0
                                ? 0.0
                                : done / total;

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
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progressValue,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[200],
                                    color: Colors.amber,
                                  ),
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
                child: tasksAsync.when(
                  data: (tasks) {
                    final total = tasks.length;
                    final done = tasks
                        .where(
                          (t) =>
                              t.status == 'completed' || t.status == 'approved',
                        )
                        .length;
                    return _buildSummaryCard(
                      context,
                      title: 'Tarefas',
                      value: '$done/$total',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    );
                  },
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
                  title: 'Tempo de Tela',
                  value: '0h 00m', // Fictício por enquanto
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
                hasAlert: true,
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

  // Modal para trocar de criança
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
                        child: Icon(_getAvatarIcon(child.avatarId)),
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
    );
  }

  IconData _getAvatarIcon(String id) {
    switch (id) {
      case 'avatar_dino':
        return Icons.pets;
      case 'avatar_girl':
        return Icons.face_3;
      case 'avatar_hero':
        return Icons.flash_on;
      default:
        return Icons.face;
    }
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
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
