import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/screen_time_models.dart';
import '../../../data/services/child_providers.dart';
import '../../../data/services/screen_time_providers.dart';

class ScreenTimeDashboardScreen extends ConsumerStatefulWidget {
  const ScreenTimeDashboardScreen({super.key});

  @override
  ConsumerState<ScreenTimeDashboardScreen> createState() =>
      _ScreenTimeDashboardScreenState();
}

class _ScreenTimeDashboardScreenState
    extends ConsumerState<ScreenTimeDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentChild = ref.watch(selectedChildProvider);

    if (currentChild == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tempo de Tela')),
        body: const Center(child: Text('Selecione uma criança.')),
      );
    }

    final appUsage = ref.watch(todayAppUsageProvider(currentChild.id));
    final rulesAsync = ref.watch(childScreenRulesProvider(currentChild.id));

    // Calcula tempo total
    final totalMinutes = appUsage.fold<int>(
      0,
      (sum, item) => sum + item.durationMinutes,
    );
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tempo de Tela: ${currentChild.name}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: 'Uso de Hoje'),
            Tab(icon: Icon(Icons.rule), text: 'Regras de Uso'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsageTab(appUsage, hours, minutes),
          _buildRulesTab(rulesAsync, currentChild.id),
        ],
      ),
    );
  }

  // --- ABA 1: GRÁFICO DE USO ---
  Widget _buildUsageTab(List<AppUsageModel> appUsage, int hours, int minutes) {
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Tempo Total Hoje',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Text(
            '${hours}h ${minutes}m',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          // Gráfico PieChart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: List.generate(appUsage.length, (i) {
                  final app = appUsage[i];
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: app.durationMinutes.toDouble(),
                    title: '${app.durationMinutes}m',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Lista de Apps
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Apps mais usados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(appUsage.length, (i) {
            final app = appUsage[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: colors[i % colors.length],
                child: const Icon(Icons.android, color: Colors.white),
              ),
              title: Text(
                app.appName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(app.category),
              trailing: Text(
                '${app.durationMinutes} min',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- ABA 2: REGRAS E LIMITES ---
  Widget _buildRulesTab(
    AsyncValue<List<ScreenRuleModel>> rulesAsync,
    String childId,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddRuleDialog(childId),
            icon: const Icon(Icons.add),
            label: const Text('Criar Nova Regra'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: rulesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (rules) {
              if (rules.isEmpty)
                return const Center(child: Text('Nenhuma regra configurada.'));
              return ListView.builder(
                itemCount: rules.length,
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: SwitchListTile(
                      title: Text(
                        rule.appName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        rule.ruleType == 'block'
                            ? 'Bloqueado sempre'
                            : 'Limite: ${rule.maxMinutes} min/dia',
                      ),
                      value: rule.active,
                      onChanged: (val) => ref
                          .read(screenRuleServiceProvider)
                          .toggleRuleState(rule.id, val),
                      secondary: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => ref
                            .read(screenRuleServiceProvider)
                            .deleteRule(rule.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Dialog simples para adicionar uma regra
  void _showAddRuleDialog(String childId) {
    String selectedApp = 'YouTube';
    String ruleType = 'limit';
    final timeController = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nova Regra de Tela'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedApp,
                items:
                    [
                          'YouTube',
                          'Roblox',
                          'TikTok',
                          'Instagram',
                          'Todos os Jogos',
                        ]
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                onChanged: (v) => setState(() => selectedApp = v!),
                decoration: const InputDecoration(labelText: 'Aplicativo'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: ruleType,
                items: const [
                  DropdownMenuItem(
                    value: 'limit',
                    child: Text('Limite de Tempo'),
                  ),
                  DropdownMenuItem(
                    value: 'block',
                    child: Text('Bloquear Totalmente'),
                  ),
                ],
                onChanged: (v) => setState(() => ruleType = v!),
                decoration: const InputDecoration(labelText: 'Tipo de Regra'),
              ),
              if (ruleType == 'limit') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: timeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minutos por dia',
                    suffixText: 'min',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final newRule = ScreenRuleModel(
                  id: '',
                  childId: childId,
                  appName: selectedApp,
                  packageName: 'com.example.$selectedApp'.toLowerCase(),
                  ruleType: ruleType,
                  maxMinutes: ruleType == 'limit'
                      ? int.tryParse(timeController.text)
                      : null,
                );
                ref.read(screenRuleServiceProvider).addRule(newRule);
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
