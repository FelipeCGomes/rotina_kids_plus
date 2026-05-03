import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart'; // IMPORT NOVO: Para desenhar o Avatar!
import '../../data/models/child_model.dart';
import '../../data/services/child_providers.dart';
import '../../data/services/child_action_providers.dart'; // Importante para puxar as tarefas de hoje
import 'blocker/services/screen_monitoring_service.dart';

class ChildSelectionScreen extends ConsumerStatefulWidget {
  const ChildSelectionScreen({super.key});

  @override
  ConsumerState<ChildSelectionScreen> createState() =>
      _ChildSelectionScreenState();
}

class _ChildSelectionScreenState extends ConsumerState<ChildSelectionScreen> {
  final ScreenMonitoringService _monitoringService = ScreenMonitoringService();

  Future<void> _startSession(ChildModel child, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Row(
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(width: 20),
            Text(
              'Carregando Perfil...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );

    int timeToSync = 0;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('children')
          .doc(child.id)
          .get();
      timeToSync = doc.data()?['timeBalance'] ?? 0;

      final installedApps = await _monitoringService.getInstalledApps();
      await FirebaseFirestore.instance
          .collection('children')
          .doc(child.id)
          .update({'installedApps': installedApps});
    } catch (e) {
      timeToSync = child.timeBalance;
      debugPrint('Erro no radar ou sincronismo: $e');
    }

    ref.read(selectedChildProvider.notifier).state = child;
    ref.read(activeChildSessionProvider.notifier).state = child;

    if (mounted) {
      Navigator.pop(context);

      if (timeToSync > 0) {
        await _monitoringService.syncRulesToEngine(
          deviceMode: 'shared',
          timeBalance: timeToSync,
          blockedApps: child.blockedApps,
          isSessionActive: true,
        );
        context.go('/child-home');
      } else {
        await _monitoringService.syncRulesToEngine(
          deviceMode: 'shared',
          timeBalance: 0,
          blockedApps: child.blockedApps,
          isSessionActive: false,
        );
        context.go('/child-home');
      }
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, childWidget) {
        return Transform.scale(
          scale: Curves.elasticOut.transform(anim1.value),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            contentPadding: EdgeInsets.zero,
            content: _ChildPinPad(
              correctPin: child.pinCode!,
              childName: child.name,
              onSuccess: () {
                Navigator.pop(context);
                _startSession(child, ref);
              },
            ),
          ),
        );
      },
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Quem vai jogar?',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    alignment: WrapAlignment.center,
                    children: children.map((child) {
                      // Usamos um widget separado para que cada criança escute as suas próprias tarefas
                      return _ChildProfileCard(
                        child: child,
                        onTap: () => _handleProfileTap(child, ref),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =========================================================================
// NOVO WIDGET: O Cartão da Criança Inteligente (Puxa Avatar e Tarefas)
// =========================================================================
class _ChildProfileCard extends ConsumerWidget {
  final ChildModel child;
  final VoidCallback onTap;

  const _ChildProfileCard({required this.child, required this.onTap});

  Widget _renderAvatar(
    BuildContext context,
    String avatarData, {
    double size = 100,
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
    if (avatarData == 'avatar_dino')
      fallbackIcon = Icons.pets;
    else if (avatarData == 'avatar_girl')
      fallbackIcon = Icons.face_3;
    else if (avatarData == 'avatar_hero')
      fallbackIcon = Icons.flash_on;
    else
      fallbackIcon = Icons.face;

    return Icon(
      fallbackIcon,
      size: size * 0.6,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPin = child.pinCode != null && child.pinCode!.isNotEmpty;

    // RÁDIO: Escuta em tempo real quantas tarefas essa criança tem pendentes hoje!
    final pendingTasksAsync = ref.watch(todayTasksStreamProvider(child.id));
    final pendingCount = pendingTasksAsync.value?.length ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topRight,
            children: [
              // A FOTO DA CRIANÇA
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: _renderAvatar(context, child.avatarId, size: 100),
              ),

              // O CADEADO DE SENHA (Fica em baixo à direita)
              if (hasPin)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.lock,
                      color: Theme.of(context).colorScheme.onError,
                      size: 16,
                    ),
                  ),
                ),

              // A BOLINHA VERMELHA DE TAREFAS (Fica no topo à direita)
              if (pendingCount > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            child.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// CÓDIGO DO PIN PAD (Mantido Intacto)
// =========================================================================
class _ChildPinPad extends StatefulWidget {
  final String correctPin;
  final String childName;
  final VoidCallback onSuccess;

  const _ChildPinPad({
    required this.correctPin,
    required this.childName,
    required this.onSuccess,
  });

  @override
  State<_ChildPinPad> createState() => _ChildPinPadState();
}

class _ChildPinPadState extends State<_ChildPinPad> {
  String _pin = '';
  bool _hasError = false;

  void _onKeyPressed(String number) {
    if (_pin.length < 4) {
      HapticFeedback.selectionClick();
      setState(() {
        _pin += number;
        _hasError = false;
      });
      if (_pin.length == 4) _validatePin();
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
    if (_pin == widget.correctPin) {
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Olá, ${widget.childName}!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasError ? 'Senha incorreta!' : 'Digite o seu PIN',
            style: TextStyle(
              fontSize: 16,
              color: _hasError ? Colors.red : Colors.grey,
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
                  color: isFilled ? Colors.deepPurple : Colors.grey[300],
                  border: Border.all(
                    color: _hasError ? Colors.red : Colors.transparent,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildKey('1'),
                  const SizedBox(width: 20),
                  _buildKey('2'),
                  const SizedBox(width: 20),
                  _buildKey('3'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildKey('4'),
                  const SizedBox(width: 20),
                  _buildKey('5'),
                  const SizedBox(width: 20),
                  _buildKey('6'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildKey('7'),
                  const SizedBox(width: 20),
                  _buildKey('8'),
                  const SizedBox(width: 20),
                  _buildKey('9'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildKey(''),
                  const SizedBox(width: 20),
                  _buildKey('0'),
                  const SizedBox(width: 20),
                  _buildKey('X', isDelete: true),
                ],
              ),
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
          color: Colors.deepPurple[50],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isDelete
              ? const Icon(
                  Icons.backspace_rounded,
                  color: Colors.deepPurple,
                  size: 28,
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
        ),
      ),
    );
  }
}
