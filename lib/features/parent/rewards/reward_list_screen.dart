import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/reward_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/child_providers.dart';
import '../../../data/services/reward_providers.dart';

class RewardListScreen extends ConsumerStatefulWidget {
  const RewardListScreen({super.key});

  @override
  ConsumerState<RewardListScreen> createState() => _RewardListScreenState();
}

class _RewardListScreenState extends ConsumerState<RewardListScreen> {
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
    final rewardsAsync = ref.watch(filteredRewardsStreamProvider(_filterId));

    return Scaffold(
      appBar: AppBar(title: const Text('Loja de Prêmios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-reward'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Prêmio'),
      ),
      body: Column(
        children: [
          childrenAsync.when(
            data: (children) => _buildFilterBar(children),
            loading: () => const SizedBox(height: 60),
            error: (_, _) => const SizedBox.shrink(),
          ),
          Expanded(
            child: rewardsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
              data: (rewards) {
                if (rewards.isEmpty)
                  return const Center(child: Text('Nenhum prêmio cadastrado.'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
                    return _buildRewardCard(reward);
                  },
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
            label: const Text('Todas as Lojas'),
            selected: _filterId == 'all',
            onSelected: (val) => setState(() => _filterId = 'all'),
          ),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
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

  Widget _buildRewardCard(RewardModel reward) {
    final children = ref.watch(parentChildrenStreamProvider).value ?? [];
    final child = children.firstWhere(
      (c) => c.id == reward.childId,
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

    final durationText = reward.durationMinutes != null
        ? '${reward.durationMinutes} min • '
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber[100],
          child: Icon(
            _getIconForType(reward.rewardType),
            color: Colors.amber[900],
          ),
        ),
        title: Text(
          reward.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$durationText${child.name}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${reward.xpCost} XP',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => context.push('/create-reward', extra: reward),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              onPressed: () => _deleteReward(reward),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteReward(RewardModel reward) {
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
              ref.read(rewardServiceProvider).deleteReward(reward.id);
              Navigator.pop(ctx);
            },
            child: const Text('Sim', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Tempo de app':
        return Icons.smartphone;
      case 'Tempo livre':
        return Icons.timer;
      case 'Presente':
        return Icons.card_giftcard;
      case 'Atividade em família':
        return Icons.family_restroom;
      case 'Acessório do avatar':
        return Icons.checkroom;
      default:
        return Icons.star;
    }
  }
}
