import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';

class ChooseModeScreen extends StatelessWidget {
  const ChooseModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração Inicial')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Como você quer usar o app neste aparelho?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildModeCard(
              context,
              title: 'Sou Pai / Responsável',
              subtitle: 'Acessar o painel de controle e gerenciar rotinas.',
              icon: Icons.admin_panel_settings_rounded,
              color: Colors.blueAccent,
              onTap: () => Navigator.pushNamed(context, AppRoutes.login),
            ),
            const SizedBox(height: 20),
            _buildModeCard(
              context,
              title: 'Aparelho da Criança',
              subtitle: 'Ativar o modo de monitoramento e tarefas.',
              icon: Icons.smartphone_rounded,
              color: Colors.orangeAccent,
              onTap: () => Navigator.pushNamed(context, AppRoutes.childHome),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.5), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
