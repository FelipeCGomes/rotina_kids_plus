import 'package:flutter/material.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Recompensas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Nova Recompensa'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRewardCard(
            '30 min de YouTube',
            20,
            Icons.play_arrow_rounded,
            Colors.red,
          ),
          _buildRewardCard(
            '1 hora de Jogo',
            40,
            Icons.gamepad_rounded,
            Colors.green,
          ),
          _buildRewardCard(
            'Passeio no Parque',
            100,
            Icons.park_rounded,
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(String title, int xp, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
            Text(
              ' Custa $xp XP',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
