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
    // Iniciamos o controlador. Ele vai carregar automaticamente o que estiver na memória local do aparelho.
    _controller = PersistentAvatarMakerController();
  }

  Future<void> _saveAvatar() async {
    setState(() => _isLoading = true);
    try {
      // O SEGREDO FINAL: Usamos '.value' apenas como leitura (getter) para extrair o JSON!
      final avatarJson = _controller.value.toJson();
      
      // Gravamos na nuvem (Firebase) para que o Dashboard em qualquer aparelho consiga desenhar o SVG
      await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.child.id)
          .update({'avatarId': avatarJson});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uau! O teu visual foi guardado na nuvem!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
            IconButton(
              icon: const Icon(Icons.check, size: 32),
              onPressed: _saveAvatar,
              tooltip: 'Salvar',
            )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: AvatarMakerAvatar(
              controller: _controller,
              radius: 80,
            ),
          ),
          Expanded(
            child: AvatarMakerCustomizer(
              controller: _controller,
            ),
          ),
        ],
      ),
    );
  }
}