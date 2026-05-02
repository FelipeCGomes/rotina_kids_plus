import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/child_providers.dart';
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
    ref.read(selectedChildProvider.notifier).state = child;

    await _monitoringService.syncRulesToEngine(
      deviceMode: 'shared',
      timeBalance: child.timeBalance,
      blockedApps: child.blockedApps,
      isSessionActive: true,
    );

    if (mounted) {
      // =========================================================
      // A LÓGICA CORRETA ESTÁ AQUI
      // =========================================================
      if (child.timeBalance > 0) {
        // TEM SALDO? Mostra a mensagem e MINIMIZA o Rotina Kids! O YouTube volta pra tela na hora.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Acesso liberado, ${child.name}! Bom jogo!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(milliseconds: 1000), () {
          SystemNavigator.pop(); // Isso fecha o Rotina Kids e devolve a tela pro YouTube
        });
      } else {
        // NÃO TEM SALDO? Aí sim manda pra Lan House pra ela comprar tempo.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você não tem saldo de tempo! Compre fichas.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        context.go('/child-dashboard');
      }
      // =========================================================
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
                if (children.isEmpty) {
                  return const Text(
                    'Nenhuma criança cadastrada.',
                    style: TextStyle(color: Colors.white),
                  );
                }
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
                            child: const Icon(
                              Icons.face,
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
