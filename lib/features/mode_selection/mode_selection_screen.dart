import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORT NOVO
import '../../data/services/auth_provider.dart';

class ModeSelectionScreen extends ConsumerStatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  ConsumerState<ModeSelectionScreen> createState() =>
      _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends ConsumerState<ModeSelectionScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDeviceMode();
  }

  Future<void> _checkDeviceMode() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      try {
        final prefs = await SharedPreferences.getInstance();

        // --- INTELIGÊNCIA: CAMINHO B (Login com E-mail da Criança) ---
        if (user.email != null && user.email!.isNotEmpty) {
          final childQuery = await FirebaseFirestore.instance
              .collection('children')
              .where('childEmail', isEqualTo: user.email)
              .get();

          if (childQuery.docs.isNotEmpty) {
            // Criança detectada! Força o modo 'child' na memória física do tablet dela.
            await prefs.setString('local_device_mode', 'child');

            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go(
                  '/child-selection',
                ); // Vai para a tela onde só aparecerá ela!
              });
            }
            return;
          }
        }

        // --- CAMINHO A / COMPARTILHADO (Login do Pai) ---
        final mode = prefs.getString('local_device_mode') ?? 'shared';
        if (mode == 'child') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/child-selection');
          });
          return;
        }
      } catch (e) {
        debugPrint('Erro ao verificar o modo do aparelho: $e');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleParentLogin() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final String? savedPin = doc.data()?['pinCode'];

    if (savedPin == null || savedPin.isEmpty) {
      _showPinDialog(isCreating: true, uid: user.uid);
    } else {
      _showPinDialog(isCreating: false, uid: user.uid, correctPin: savedPin);
    }
  }

  void _showPinDialog({
    required bool isCreating,
    required String uid,
    String? correctPin,
  }) {
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
            content: _ParentPinPad(
              isCreating: isCreating,
              correctPin: correctPin,
              onComplete: (pin) async {
                Navigator.pop(context);

                if (isCreating) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({'pinCode': pin});
                  if (mounted) context.go('/parent-home');
                } else {
                  if (mounted) context.go('/parent-home');
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.deepPurple,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.family_restroom,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              const Text(
                'Como você quer usar o app?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Sou Pai/Responsável',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                onPressed: _handleParentLogin,
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.smart_toy),
                label: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Entrar na Área da Criança',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                onPressed: () => context.go('/child-selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentPinPad extends StatefulWidget {
  final bool isCreating;
  final String? correctPin;
  final Function(String) onComplete;

  const _ParentPinPad({
    required this.isCreating,
    this.correctPin,
    required this.onComplete,
  });

  @override
  State<_ParentPinPad> createState() => _ParentPinPadState();
}

class _ParentPinPadState extends State<_ParentPinPad> {
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

    if (widget.isCreating) {
      HapticFeedback.heavyImpact();
      widget.onComplete(_pin);
    } else {
      if (_pin == widget.correctPin) {
        HapticFeedback.heavyImpact();
        widget.onComplete(_pin);
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _hasError = true;
          _pin = '';
        });
      }
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
            widget.isCreating ? 'Crie uma Senha' : 'Área Restrita',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasError
                ? 'Senha incorreta!'
                : (widget.isCreating
                      ? 'Crie um PIN de 4 números para proteger o app'
                      : 'Digite a Senha dos Pais'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
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
                  _buildKey(''), // Botão invisível para manter o alinhamento
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
