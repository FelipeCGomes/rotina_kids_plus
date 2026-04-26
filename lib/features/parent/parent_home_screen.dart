import 'package:flutter/material.dart';
import 'package:rotina_kids_plus/features/parent/calendar/parent_calendar_screen.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Rotina Kids+'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Resumo do Dia
            const Text(
              'Olá, Responsável!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Hoje é ${DateTime.now().day}/${DateTime.now().month}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // 2. Cards de Atalhos Rápidos
            Row(
              children: [
                _buildQuickAction(
                  context,
                  'Agenda',
                  Icons.calendar_month,
                  Colors.blue,
                  () {
                    // Aqui você navegará para a nova tela de agenda
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentCalendarScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildQuickAction(
                  context,
                  'Tarefas',
                  Icons.task_alt,
                  Colors.orange,
                  () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Informação Principal: Próximo Compromisso
            const Text(
              'Próximo Lembrete',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.medication, color: Colors.white),
                ),
                title: Text(
                  'Vitamina C',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Em 15 minutos'),
                trailing: Text(
                  '08:00',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Resumo de Atividades/Saúde
            const Text(
              'Resumo da Criança',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Alimentação',
                  '3/5 refeições',
                  Icons.restaurant,
                  Colors.green,
                ),
                _buildStatCard(
                  'Sono',
                  '9h total',
                  Icons.bedtime,
                  Colors.purple,
                ),
                _buildStatCard('Tela', '45 min', Icons.timer, Colors.orange),
                _buildStatCard(
                  'Exercício',
                  '30 min',
                  Icons.directions_run,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
