import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:avatar_maker/avatar_maker.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/firestore_providers.dart';
import '../../../data/services/reward_providers.dart';
import '../../../data/services/child_action_providers.dart';
import '../../../data/services/child_providers.dart'; // IMPORTANTE: Gaveta correta
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
    with TickerProviderStateMixin {
  late TabController _tabController;

  String _lastAvatarTimestamp = '';
  late PersistentAvatarMakerController _avatarController;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // OS OUVINTES ANTIGOS FORAM REMOVIDOS DAQUI, POIS O APP.DART JÁ FAZ ISSO!

    _tabController = TabController(length: 3, vsync: this);
    _avatarController = PersistentAvatarMakerController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _renderAvatar(String avatarData, {double size = 40}) {
    if (avatarData.startsWith('custom_')) {
      if (_lastAvatarTimestamp != avatarData) {
        _lastAvatarTimestamp = avatarData;
        _avatarController = PersistentAvatarMakerController();
      }
      return AvatarMakerAvatar(
        key: ValueKey(avatarData),
        controller: _avatarController,
        radius: size / 2,
      );
    }
    return Icon(
      _getFallbackIcon(avatarData),
      size: size * 0.6,
      color: Theme.of(context).colorScheme.primary,
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

  void _showParentPinDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            contentPadding: EdgeInsets.zero,
            content: ParentPinPad(
              onSuccess: () {
                Navigator.of(context).pop();
                context.go('/parent-home');
              },
            ),
          ),
        );
      },
    );
  }

  void _showSuccessAnimation(BuildContext context, int xp) {
    HapticFeedback.heavyImpact();
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
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showTimePurchaseAnimation(BuildContext context, int minutes) {
    HapticFeedback.heavyImpact();
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
                const Icon(Icons.timer, color: Colors.greenAccent, size: 120),
                const SizedBox(height: 20),
                const Text(
                  'TEMPO LIBERADO!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '+$minutes MINUTOS NA CONTA',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
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

  void _showPurchaseAnimation(BuildContext context) {
    HapticFeedback.mediumImpact();
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
                Icon(
                  Icons.card_giftcard_rounded,
                  color: Theme.of(context).colorScheme.primary,
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
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO: Lendo a "gaveta" correta onde a tela de login guardou a criança!
    final activeSession = ref.watch(selectedChildProvider);
    final ttsService = ref.read(ttsServiceProvider);

    if (activeSession == null) {
      return const Scaffold(
        body: Center(child: Text('Nenhuma criança selecionada.')),
      );
    }

    final liveChildAsync = ref.watch(liveActiveChildProvider(activeSession.id));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.group, size: 30),
          tooltip: 'Trocar Perfil',
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go('/child-selection');
          },
        ),
        title: liveChildAsync.when(
          data: (child) => Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                radius: 16,
                child: ClipOval(
                  child: _renderAvatar(child?.avatarId ?? '', size: 32),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Olá, ${child?.name ?? ''}!',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          loading: () => const Text('A carregar...'),
          error: (_, _) => const Text('Erro'),
        ),
        actions: [
          liveChildAsync.when(
            data: (child) => ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
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
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.lock, size: 28),
            tooltip: 'Área dos Pais',
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showParentPinDialog(context);
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 5,
          tabs: const [
            Tab(icon: Icon(Icons.star, size: 30), text: 'Missões'),
            Tab(icon: Icon(Icons.storefront, size: 30), text: 'Prêmios'),
            Tab(
              icon: Icon(Icons.face_retouching_natural, size: 30),
              text: 'Avatar',
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
                Text(
                  'Uhuu! Todas as missões completas!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
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
            return TweenAnimationBuilder(
              tween: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero),
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, offset, child) {
                return FractionalTranslation(translation: offset, child: child);
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: IconButton(
                    icon: Icon(
                      Icons.volume_up,
                      color: Theme.of(context).colorScheme.primary,
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStoreTab(ChildModel child) {
    final int xpCostToBuy = 1;
    final int minutesGained = child.xpToMinutesRate;
    final bool canBuyTime = child.currentXp >= xpCostToBuy;
    final bool isTimeStoreEnabled = minutesGained > 0;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEU SALDO DE TEMPO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${child.timeBalance ~/ 60}h ${child.timeBalance % 60}m',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.timer,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (isTimeStoreEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: canBuyTime ? 8 : 2,
                shadowColor: canBuyTime ? Colors.green.withOpacity(0.4) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: canBuyTime ? Colors.green[50] : Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: canBuyTime ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sports_esports,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COMPRAR TEMPO',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: canBuyTime
                                    ? Colors.green[800]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Desbloqueie os seus jogos!',
                              style: TextStyle(
                                color: canBuyTime
                                    ? Colors.green[700]
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canBuyTime
                                    ? Colors.amber
                                    : Colors.grey[400],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              icon: const Icon(Icons.stars),
                              label: Text(
                                'Gastar $xpCostToBuy XP  (+$minutesGained min)',
                              ),
                              onPressed: canBuyTime
                                  ? () async {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('children')
                                            .doc(child.id)
                                            .update({
                                              'currentXp': FieldValue.increment(
                                                -xpCostToBuy,
                                              ),
                                              'timeBalance':
                                                  FieldValue.increment(
                                                    minutesGained,
                                                  ),
                                            });
                                        if (mounted) {
                                          _showTimePurchaseAnimation(
                                            context,
                                            minutesGained,
                                          );
                                        }
                                      } catch (e) {
                                        debugPrint('Erro ao comprar tempo: $e');
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'OUTROS PRÊMIOS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          _buildExtraRewardsGrid(child),
        ],
      ),
    );
  }

  Widget _buildExtraRewardsGrid(ChildModel child) {
    final rewardsAsync = ref.watch(filteredRewardsStreamProvider(child.id));

    return rewardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (rewards) {
        if (rewards.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              'Nenhum outro prémio disponível.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              color: canAfford ? Theme.of(context).cardColor : Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 60,
                      color: canAfford
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reward.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: canAfford ? null : Colors.grey,
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
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        foregroundColor: Colors.white,
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
                        style: TextStyle(fontWeight: FontWeight.bold),
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
    final hasCustomAvatar = child.avatarId.startsWith('custom_');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 300,
          width: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 5),
            ],
          ),
          child: ClipOval(
            child: hasCustomAvatar
                ? _renderAvatar(child.avatarId, size: 300)
                : Icon(
                    _getFallbackIcon(child.avatarId),
                    size: 150,
                    color: Theme.of(context).colorScheme.primary,
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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

class ParentPinPad extends StatefulWidget {
  final VoidCallback onSuccess;
  const ParentPinPad({super.key, required this.onSuccess});

  @override
  State<ParentPinPad> createState() => _ParentPinPadState();
}

class _ParentPinPadState extends State<ParentPinPad> {
  String _pin = '';
  final String _correctPin = '1234';
  bool _hasError = false;

  void _onKeyPressed(String number) {
    if (_pin.length < 4) {
      HapticFeedback.selectionClick();
      setState(() {
        _pin += number;
        _hasError = false;
      });

      if (_pin.length == 4) {
        _validatePin();
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _hasError = false;
      });
    }
  }

  void _validatePin() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_pin == _correctPin) {
      HapticFeedback.heavyImpact();
      widget.onSuccess();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _hasError = true;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 50,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Área dos Pais',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            _hasError ? 'Senha incorreta!' : 'Digite o código de 4 dígitos',
            style: TextStyle(
              fontSize: 16,
              color: _hasError
                  ? Theme.of(context).colorScheme.error
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300],
                  border: Border.all(
                    color: _hasError
                        ? Theme.of(context).colorScheme.error
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 1; i <= 9; i++) _buildKey(i.toString()),
              _buildKey(''),
              _buildKey('0'),
              _buildKey('X', isDelete: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value, {bool isDelete = false}) {
    if (value.isEmpty) return const SizedBox(width: 70, height: 70);

    return InkWell(
      onTap: () => isDelete ? _onDeletePressed() : _onKeyPressed(value),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isDelete
              ? Icon(
                  Icons.backspace_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
        ),
      ),
    );
  }
}
