import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/task_log_model.dart';
import '../../../data/models/reward_request_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/approval_providers.dart';
import '../../../data/services/child_providers.dart';

class ApprovalScreen extends ConsumerStatefulWidget {
  const ApprovalScreen({super.key});

  @override
  ConsumerState<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends ConsumerState<ApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterId = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final selected = ref.read(selectedChildProvider);
    if (selected != null) _filterId = selected.id;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateMockData() async {
    final currentChild = ref.read(selectedChildProvider);
    if (currentChild == null) return;

    final db = FirebaseFirestore.instance;
    await db.collection('task_logs').add({
      'taskId': 'mock1',
      'taskTitle': 'Arrumar a Cama',
      'xpReward': 15,
      'childId': currentChild.id,
      'completedAt': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
    await db.collection('reward_requests').add({
      'rewardId': 'mock2',
      'rewardTitle': '1 Hora de Tablet',
      'xpCost': 50,
      'childId': currentChild.id,
      'requestedAt': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dados de teste gerados!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingTasks = ref.watch(pendingTasksStreamProvider(_filterId));
    final pendingRewards = ref.watch(pendingRewardsStreamProvider(_filterId));
    final childrenAsync = ref.watch(parentChildrenStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Aprovação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _generateMockData,
            tooltip: 'Gerar dados falsos',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Tarefas'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Prêmios'),
          ],
        ),
      ),
      body: Column(
        children: [
          childrenAsync.when(
            data: (children) => Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _filterId == 'all',
                    onSelected: (_) => setState(() => _filterId = 'all'),
                  ),
                  ...children.map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(child.name),
                        selected: _filterId == child.id,
                        onSelected: (_) => setState(() => _filterId = child.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                pendingTasks.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erro: $e')),
                  data: (tasks) => tasks.isEmpty
                      ? const Center(child: Text('Nenhuma tarefa pendente.'))
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) =>
                              _buildTaskApprovalCard(tasks[index]),
                        ),
                ),
                pendingRewards.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erro: $e')),
                  data: (reqs) => reqs.isEmpty
                      ? const Center(child: Text('Nenhum pedido de prêmio.'))
                      : ListView.builder(
                          itemCount: reqs.length,
                          itemBuilder: (context, index) =>
                              _buildRewardApprovalCard(reqs[index]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskApprovalCard(TaskLogModel log) {
    final child = _getChild(log.childId);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(_getIcon(child.avatarId))),
        title: Text(
          log.taskTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${child.name} • Feito hoje'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+${log.xpReward} XP',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () =>
                  ref.read(approvalServiceProvider).rejectTask(log.id),
            ),
            IconButton(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 30,
              ),
              onPressed: () =>
                  ref.read(approvalServiceProvider).approveTask(log),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardApprovalCard(RewardRequestModel req) {
    final child = _getChild(req.childId);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber[100],
          child: Icon(Icons.card_giftcard, color: Colors.amber[900]),
        ),
        title: Text(
          req.rewardTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${child.name} • Solicitado hoje'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '-${req.xpCost} XP',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () =>
                  ref.read(approvalServiceProvider).rejectReward(req),
            ),
            IconButton(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 30,
              ),
              onPressed: () =>
                  ref.read(approvalServiceProvider).approveReward(req.id),
            ),
          ],
        ),
      ),
    );
  }

  ChildModel _getChild(String id) {
    final children = ref.read(parentChildrenStreamProvider).value ?? [];
    return children.firstWhere(
      (c) => c.id == id,
      // AQUI ESTAVA O ERRO! Atualizado com os campos obrigatórios.
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
  }

  IconData _getIcon(String id) {
    if (id == 'avatar_dino') return Icons.pets;
    if (id == 'avatar_girl') return Icons.face_3;
    return Icons.face;
  }
}
