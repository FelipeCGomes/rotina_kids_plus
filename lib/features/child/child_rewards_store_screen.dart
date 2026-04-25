import 'package:flutter/material.dart';

class ChildRewardsStoreScreen extends StatelessWidget {
  const ChildRewardsStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trocar Meus XP')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        children: [
          _buildReward('30min YouTube', 20, Icons.play_circle),
          _buildReward('1h de Jogo', 40, Icons.videogame_asset),
          _buildReward('Sorvete', 100, Icons.icecream),
        ],
      ),
    );
  }

  Widget _buildReward(String title, int cost, IconData icon) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.blueAccent),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Chip(label: Text('$cost XP'), backgroundColor: Colors.amber),
        ],
      ),
    );
  }
}
