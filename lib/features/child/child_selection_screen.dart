import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/child_model.dart';
import '../../data/services/child_providers.dart'; // Gaveta correta (selectedChildProvider)
import 'blocker/services/screen_monitoring_service.dart'; // Import do motor Android

class ChildSelectionScreen extends ConsumerStatefulWidget {
  const ChildSelectionScreen({super.key});

  @override
  ConsumerState<ChildSelectionScreen> createState() =>
      _ChildSelectionScreenState();
}

class _ChildSelectionScreenState extends ConsumerState<ChildSelectionScreen> {
  final ScreenMonitoringService _monitoringService = ScreenMonitoringService();

  // === A NOVA MÁGICA UNIFICADA ===
  Future<void> _startSession(ChildModel child, WidgetRef ref) async {
    // 1. Guarda a criança na "gaveta" correta que o Dashboard agora usa!
    ref.read(selectedChildProvider.notifier).state = child;

    // 2. Avisa o Android: "A criança entrou pela porta da frente. Aplique as regras!"
    await _monitoringService.syncRulesToEngine(
      deviceMode: 'shared',
      timeBalance: child.timeBalance,
      blockedApps: child.blockedApps,
      isSessionActive: true,
    );

    if (mounted) {
      // Usa a rota oficial que definimos no router
      context.push('/child-dashboard');
    }
  }

  void _handleProfileTap(ChildModel child, WidgetRef ref) {
    if (child.pinCode != null && child.pinCode!.isNotEmpty) {
      _showPinDialog(child, ref);
    } else {
      _startSession(child, ref);
    }
  }

  void _showPinDialog(ChildModel child, WidgetRef ref) {
    final pinController = TextEditingController();
    bool isError = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Icon(
                  _getAvatarIcon(child.avatarId),
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text('Senha do(a) ${child.name}'),
              ],
            ),
            content: TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '****',
                counterText: '',
                errorText: isError ? 'Senha incorreta!' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                if (isError) setState(() => isError = false);
              },
            ),
            actionsAlignment: MainAxisAlignment.spaceAround,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () {
                  if (pinController.text == child.pinCode) {
                    Navigator.pop(ctx);
                    // Entra usando o mesmo fluxo limpo
                    _startSession(child, ref);
                  } else {
                    setState(() => isError = true);
                    pinController.clear();
                  }
                },
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenStreamProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/mode-selection'),
        ),
      ),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (children) {
          if (children.isEmpty) {
            return const Center(
              child: Text(
                'Peça para seus pais criarem o seu perfil primeiro!',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Quem vai jogar?',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: children.map((child) {
                    final hasPin =
                        child.pinCode != null && child.pinCode!.isNotEmpty;

                    return GestureDetector(
                      onTap: () => _handleProfileTap(child, ref),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: Icon(
                                  _getAvatarIcon(child.avatarId),
                                  size: 60,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              if (hasPin)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.lock,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onError,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            child.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getAvatarIcon(String id) {
    if (id == 'avatar_dino') return Icons.pets;
    if (id == 'avatar_girl') return Icons.face_3;
    if (id == 'avatar_hero') return Icons.flash_on;
    return Icons.face;
  }
}
