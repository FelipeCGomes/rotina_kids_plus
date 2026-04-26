import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/firestore_providers.dart';
import '../../../data/services/reward_providers.dart';
import '../../../data/services/child_action_providers.dart';
import '../../../core/utils/tts_service.dart';

// Provedor para escutar os dados atualizados da criança ativa (para o XP atualizar em tempo real)
final liveActiveChildProvider = StreamProvider.family<ChildModel?, String>((
  ref,
  childId,
) {
  return FirebaseFirestore.instance
      .collection('children')
      .doc(childId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return ChildModel.fromMap(doc.data()!, doc.id);
      });
});

class ChildDashboardScreen extends ConsumerStatefulWidget {
  const ChildDashboardScreen({super.key});

  @override
  ConsumerState<ChildDashboardScreen> createState() =>
      _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends ConsumerState<ChildDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // --- ANIMAÇÃO DE SUCESSO (MISSÕES) ---
  void _showSuccessAnimation(BuildContext context, int xp) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87, // Fundo escurecido
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
        // Cria um efeito de "mola" (bounce) ao aparecer
        final curvedValue = Curves.elasticOut.transform(a1.value);
        return Transform.scale(
          scale: curvedValue,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 150),
                const SizedBox(height: 20),
                const Text(
                  'EXCELENTE!',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '+$xp MOEDAS',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Fecha a animação automaticamente após 2.5 segundos
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  // --- ANIMAÇÃO DE COMPRA (LOJA) ---
  void _showPurchaseAnimation(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
        final curvedValue = Curves.elasticOut.transform(a1.value);
        return Transform.scale(
          scale: curvedValue,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.purpleAccent,
                  size: 120,
                ),
                const SizedBox(height: 20),
                const Text(
                  'PEDIDO ENVIADO!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'A aguardar aprovação dos pais.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeChildSessionProvider);
    final ttsService = ref.read(ttsServiceProvider);

    if (activeSession == null) {
      return const Scaffold(
        body: Center(child: Text('Nenhuma criança selecionada.')),
      );
    }

    // Escuta o perfil ao vivo para atualizar a moeda
    final liveChildAsync = ref.watch(liveActiveChildProvider(activeSession.id));

    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        title: liveChildAsync.when(
          data: (child) => Text('Olá, ${child?.name ?? ''}!'),
          loading: () => const Text('A carregar...'),
          error: (_, _) => const Text('Erro'),
        ),
        actions: [
          liveChildAsync.when(
            data: (child) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${child?.currentXp ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 4,
          tabs: const [
            Tab(icon: Icon(Icons.star, size: 30), text: 'Missões'),
            Tab(icon: Icon(Icons.storefront, size: 30), text: 'Prémios'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMissionsTab(activeSession.id, ttsService),
          liveChildAsync.when(
            data: (child) => _buildStoreTab(child!),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsTab(String childId, dynamic ttsService) {
    final tasksAsync = ref.watch(todayTasksStreamProvider(childId));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: 100,
                  color: Colors.amber[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Uhuu! Todas as missões completas!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: IconButton(
                  icon: const Icon(
                    Icons.volume_up,
                    color: Colors.blueAccent,
                    size: 36,
                  ),
                  onPressed: () => ttsService.speak(
                    'A tua missão é: ${task.title}. Vale ${task.xpReward} moedas.',
                  ),
                ),
                title: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  task.time,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    // 1. Aciona a voz de parabéns
                    ttsService.speak(
                      'Muito bem! Ganhaste ${task.xpReward} moedas.',
                    );

                    // 2. Mostra a animação da estrela gigante
                    _showSuccessAnimation(context, task.xpReward);

                    // 3. Aguarda um pequeno momento para a animação começar antes de remover do ecrã
                    await Future.delayed(const Duration(milliseconds: 500));

                    // 4. Conclui a tarefa na base de dados
                    if (mounted) {
                      ref
                          .read(childActionServiceProvider)
                          .completeTask(
                            childId,
                            task.id,
                            task.title,
                            task.xpReward,
                          );
                    }
                  },
                  child: Text(
                    'FEITO!\n+${task.xpReward}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStoreTab(ChildModel child) {
    final rewardsAsync = ref.watch(filteredRewardsStreamProvider(child.id));

    return rewardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (rewards) {
        if (rewards.isEmpty) {
          return const Center(
            child: Text(
              'A lojinha está vazia.',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            final reward = rewards[index];
            final canAfford = child.currentXp >= reward.xpCost;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: canAfford ? 6 : 1,
              color: canAfford ? Colors.white : Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 60,
                      color: canAfford ? Colors.purpleAccent : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reward.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: canAfford ? Colors.black : Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: canAfford ? Colors.amber : Colors.grey[400],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '${reward.xpCost} XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford
                            ? Colors.blueAccent
                            : Colors.grey,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: canAfford
                          ? () async {
                              // Mostra a animação visual do pedido
                              _showPurchaseAnimation(context);

                              final success = await ref
                                  .read(childActionServiceProvider)
                                  .buyReward(child, reward);
                            }
                          : null,
                      child: const Text(
                        'Comprar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
