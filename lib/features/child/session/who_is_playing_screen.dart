import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/child_providers.dart';
import '../../../data/services/child_action_providers.dart';
import '../../child/blocker/services/screen_monitoring_service.dart';

class WhoIsPlayingScreen extends ConsumerStatefulWidget {
  const WhoIsPlayingScreen({super.key});

  @override
  ConsumerState<WhoIsPlayingScreen> createState() => _WhoIsPlayingScreenState();
}

class _WhoIsPlayingScreenState extends ConsumerState<WhoIsPlayingScreen> {
  final ScreenMonitoringService _monitoringService = ScreenMonitoringService();

  void _showChildPinDialog(ChildModel child) {
    if (child.pinCode == null || child.pinCode!.isEmpty) {
      _startSession(child);
      return;
    }

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
                _startSession(child);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _startSession(ChildModel child) async {
    // =========================================================
    // MÁGICA 1: Mostra o pop-up "Carregando Perfil..."
    // =========================================================
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
      // =========================================================
      // MÁGICA 2: Fecha o pop-up
      // =========================================================
      Navigator.pop(context);

      if (timeToSync > 0) {
        await _monitoringService.syncRulesToEngine(
          deviceMode: 'shared',
          timeBalance: timeToSync,
          blockedApps: child.blockedApps,
          isSessionActive: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Acesso liberado, ${child.name}! Bom jogo!'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(milliseconds: 1000), () {
          SystemNavigator.pop();
        });
      } else {
        await _monitoringService.syncRulesToEngine(
          deviceMode: 'shared',
          timeBalance: 0,
          blockedApps: child.blockedApps,
          isSessionActive: false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você não tem saldo de tempo! Compre fichas.'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/child-home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenStreamProvider);

    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_esports, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            const Text(
              'Quem vai jogar agora?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Selecione o seu perfil para gastar as suas fichas.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            childrenAsync.when(
              loading: () =>
                  const CircularProgressIndicator(color: Colors.white),
              error: (e, _) =>
                  Text('Erro: $e', style: const TextStyle(color: Colors.red)),
              data: (children) {
                if (children.isEmpty)
                  return const Text(
                    'Nenhuma criança cadastrada.',
                    style: TextStyle(color: Colors.white),
                  );
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: children.map((child) {
                    return GestureDetector(
                      onTap: () => _showChildPinDialog(child),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getAvatarIcon(child.avatarId),
                              size: 60,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            child.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
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
                  _buildKey(''), // Espaço invisível para alinhar
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
