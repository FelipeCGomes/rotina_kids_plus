import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:avataaars/avataaars.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/firestore_providers.dart';
import '../../../data/services/reward_providers.dart';
import '../../../data/services/child_action_providers.dart';
import '../../../core/utils/tts_service.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  // --- Função Definitiva: Lê o JSON e desenha o boneco como Imagem (SVG) ---
  Widget _renderAvatar(String avatarData, {double size = 40}) {
    if (avatarData.startsWith('{"')) {
      try {
        final avataaar = Avataaar.fromJson(avatarData);
        return SvgPicture.string(
          avataaar.toSvg(),
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      } catch (_) {
        return Icon(Icons.face, size: size * 0.6, color: Colors.blueAccent);
      }
    }
    return Icon(
      _getFallbackIcon(avatarData),
      size: size * 0.6,
      color: Colors.blueAccent,
    );
  }

  IconData _getFallbackIcon(String id) {
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

  void _showSuccessAnimation(BuildContext context, int xp) {
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
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && Navigator.of(context).canPop())
        Navigator.of(context).pop();
    });
  }

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
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.purpleAccent,
                  size: 120,
                ),
                SizedBox(height: 20),
                Text(
                  'PEDIDO ENVIADO!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Aguardando aprovação.',
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
      if (mounted && Navigator.of(context).canPop())
        Navigator.of(context).pop();
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

    final liveChildAsync = ref.watch(liveActiveChildProvider(activeSession.id));

    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        title: liveChildAsync.when(
          data: (child) => Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 16,
                child: ClipOval(
                  child: _renderAvatar(child?.avatarId ?? '', size: 32),
                ),
              ),
              const SizedBox(width: 10),
              Text('Olá, ${child?.name ?? ''}!'),
            ],
          ),
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
            Tab(icon: Icon(Icons.storefront, size: 30), text: 'Prêmios'),
            Tab(
              icon: Icon(Icons.face_retouching_natural, size: 30),
              text: 'Meu Avatar',
            ),
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
          liveChildAsync.when(
            data: (child) => _buildAvatarTab(child!),
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
                    'Sua missão é: ${task.title}. Vale ${task.xpReward} moedas.',
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
                    ttsService.speak(
                      'Muito bem! Ganhou ${task.xpReward} moedas.',
                    );
                    _showSuccessAnimation(context, task.xpReward);
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (mounted)
                      ref
                          .read(childActionServiceProvider)
                          .completeTask(
                            childId,
                            task.id,
                            task.title,
                            task.xpReward,
                          );
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
        if (rewards.isEmpty)
          return const Center(
            child: Text(
              'A lojinha está vazia.',
              style: TextStyle(fontSize: 18),
            ),
          );
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
                              _showPurchaseAnimation(context);
                              await ref
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

  Widget _buildAvatarTab(ChildModel child) {
    final hasCustomAvatar = child.avatarId.startsWith('{"');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 300,
          width: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 5),
            ],
          ),
          child: ClipOval(
            child: hasCustomAvatar
                ? _renderAvatar(child.avatarId, size: 300)
                : Icon(
                    _getFallbackIcon(child.avatarId),
                    size: 150,
                    color: Colors.blueAccent,
                  ),
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.face_retouching_natural, size: 28),
            label: Text(
              hasCustomAvatar
                  ? 'MUDAR ROUPAS E ACESSÓRIOS'
                  : 'CRIAR O MEU AVATAR',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () {
              context.push('/avatar-creator', extra: child);
            },
          ),
        ),
      ],
    );
  }
}
