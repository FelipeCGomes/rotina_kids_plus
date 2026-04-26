import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/mock_data_provider.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usamos o mock provider para simular a criança selecionada atualmente
    final child = ref.watch(currentChildProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão dos Pais'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navegar para tela de solicitações pendentes (recompensas/aprovações)
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navegar para configurações da conta/app
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Card de Resumo da Criança Selecionada
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.face, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Nível ${child.level} • ${child.currentXp} XP disponíveis',
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: child.totalXp / 1000, // Lógica base do nível
                            backgroundColor: Colors.grey[200],
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Trocar perfil da criança',
                      onPressed: () {
                        // TODO: Abrir BottomSheet para selecionar outro filho
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Resumo Rápido do Dia
            const Text(
              'Resumo de Hoje',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Tarefas',
                    value: '3/5',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Tempo de Tela',
                    value: '1h 20m',
                    icon: Icons.smartphone,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Grid de Atalhos para as Features do App
            const Text(
              'Atalhos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap:
                  true, // Necessário por estar dentro de um SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              children: [
                _buildShortcutAction(
                  context,
                  icon: Icons.list_alt,
                  label: 'Rotina',
                  onTap: () {},
                ),
                _buildShortcutAction(
                  context,
                  icon: Icons.card_giftcard,
                  label: 'Prêmios',
                  onTap: () {},
                ),
                _buildShortcutAction(
                  context,
                  icon: Icons.timer,
                  label: 'Tempo',
                  onTap: () {},
                ),
                _buildShortcutAction(
                  context,
                  icon: Icons.rule,
                  label: 'Regras',
                  onTap: () {},
                ),
                _buildShortcutAction(
                  context,
                  icon: Icons.calendar_month,
                  label: 'Agenda',
                  onTap: () {},
                ),
                _buildShortcutAction(
                  context,
                  icon: Icons.bar_chart,
                  label: 'Relatórios',
                  onTap: () {},
                ),
                _buildShortcutAction(
                  context,
                  icon: Icons.forum,
                  label: 'Fórum',
                  onTap: () {},
                ),
                _buildShortcutAction(
                  context,
                  icon: Icons.approval,
                  label: 'Aprovar',
                  hasAlert: true,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para os cards de resumo (Tarefas e Tela)
  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para os botões redondos de atalho
  Widget _buildShortcutAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool hasAlert = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 26,
                ),
              ),
              if (hasAlert)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
