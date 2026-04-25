import 'package:flutter/material.dart';

class ScreenRulesScreen extends StatelessWidget {
  const ScreenRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Regras de Tempo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Controle de Apps',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildAppItem('YouTube', '1h 20min', true),
          _buildAppItem('Roblox', '45min', false),
          const Divider(height: 40),
          const Text(
            'Limites Diários',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Bloquear após as 21h'),
            value: true,
            onChanged: (v) {},
          ),
          SwitchListTile(
            title: const Text('Exigir XP para Jogos'),
            value: false,
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }

  Widget _buildAppItem(String name, String time, bool isBlocked) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.apps),
        title: Text(name),
        subtitle: Text('Usado hoje: $time'),
        trailing: IconButton(
          icon: Icon(
            isBlocked ? Icons.lock : Icons.lock_open,
            color: isBlocked ? Colors.red : Colors.green,
          ),
          onPressed: () {},
        ),
      ),
    );
  }
}
