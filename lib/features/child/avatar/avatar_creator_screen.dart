import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:avatar_maker/avatar_maker.dart';
import '../../../data/models/child_model.dart';

class AvatarCreatorScreen extends StatefulWidget {
  final ChildModel child;
  const AvatarCreatorScreen({super.key, required this.child});

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  bool _isLoading = false;
  late final PersistentAvatarMakerController _controller;

  @override
  void initState() {
    super.initState();
    // O controlador carrega o último boneco salvo no aparelho automaticamente
    _controller = PersistentAvatarMakerController();
  }

  Future<void> _handleSave() async {
    // 1. Damos 300 milissegundos para o botão da biblioteca salvar os acessórios no celular
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 2. Criamos um carimbo de tempo único (ex: custom_1734567...)
      final uniqueId = 'custom_${DateTime.now().millisecondsSinceEpoch}';

      // 3. Mandamos pro Firebase. Isso vai alertar o Dashboard de que ele precisa se recarregar!
      await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.child.id)
          .update({'avatarId': uniqueId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uau! O teu visual foi guardado!')),
        );
        context.pop(); // Volta pro Dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Montar o meu Avatar'),
        backgroundColor: Colors.purpleAccent,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            // O widget oficial da biblioteca que salva na memória
            AvatarMakerSaveWidget(
              controller: _controller,
              // O nosso "espião" que detecta quando a criança levanta o dedo da tela
              child: Listener(
                onPointerUp: (_) => _handleSave(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.check, size: 32, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: AvatarMakerAvatar(controller: _controller, radius: 80),
          ),
          Expanded(child: AvatarMakerCustomizer(controller: _controller)),
        ],
      ),
    );
  }
}
