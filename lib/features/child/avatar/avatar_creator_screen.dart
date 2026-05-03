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
  bool _isReady = false;
  late PersistentAvatarMakerController _controller;

  @override
  void initState() {
    super.initState();
    _prepareMaker();
  }

  Future<void> _prepareMaker() async {
    // 1. O EXORCISMO: Limpa o cofre global do aparelho ANTES da tela abrir!
    // Garante que o rosto do irmão não apareça aqui. Começamos do zero!
    await PersistentAvatarMakerController.clearAvatarMaker();

    if (mounted) {
      setState(() {
        _controller = PersistentAvatarMakerController();
        _isReady = true;
      });
    }
  }

  Future<void> _handleSave() async {
    // O botão que envolve este clique (AvatarMakerSaveWidget) acabou de ser apertado.
    // Damos 300ms para a biblioteca terminar de gravar o rosto novo no cofre do aparelho.
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 2. Agora sim! Extraímos o SVG novo e atualizado da memória local!
      final String svgData =
          await PersistentAvatarMakerController.getAvatarSVG();

      // 3. Trancamos o desenho na nuvem (Firebase) para a criança correta!
      await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.child.id)
          .update({'avatarId': svgData});

      // 4. Limpamos a memória local de novo para não deixar rastro nenhum!
      await PersistentAvatarMakerController.clearAvatarMaker();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uau! O teu visual foi guardado!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(); // Volta pro Dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          if (_isLoading || !_isReady)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            // =====================================================================
            // DE VOLTA AO JOGO: Precisamos do SaveWidget para ele jogar o SVG atualizado na memória local!
            // =====================================================================
            AvatarMakerSaveWidget(
              controller: _controller,
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
      body: !_isReady
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            )
          : Column(
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
