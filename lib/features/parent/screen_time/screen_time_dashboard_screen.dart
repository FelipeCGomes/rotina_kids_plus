import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/child_providers.dart';
import '../../child/blocker/services/screen_monitoring_service.dart';
import '../../../data/services/auth_provider.dart';
// IMPORTANTE: Importar o motor de notificações
import '../../../core/utils/notification_service.dart';

class ScreenTimeDashboardScreen extends ConsumerStatefulWidget {
  const ScreenTimeDashboardScreen({super.key});

  @override
  ConsumerState<ScreenTimeDashboardScreen> createState() =>
      _ScreenTimeDashboardScreenState();
}

class _ScreenTimeDashboardScreenState
    extends ConsumerState<ScreenTimeDashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ScreenMonitoringService _monitoringService = ScreenMonitoringService();
  late TabController _tabController;

  bool _isLoading = true;

  bool _hasUsagePerm = false;
  bool _hasOverlayPerm = false;
  bool get _hasAllPermissions => _hasUsagePerm && _hasOverlayPerm;

  bool _autoPromptFired = false;

  Map<String, int> _appUsage = {};
  Map<String, String> _installedApps = {};
  int _totalMinutes = 0;

  String _selectedChildId = '';
  String _currentDeviceMode = 'shared'; // Guarda o modo atual do aparelho

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final children = await ref.read(parentChildrenStreamProvider.future);
      if (children.isNotEmpty) {
        final selected = ref.read(selectedChildProvider);
        setState(() {
          _selectedChildId = selected?.id ?? children.first.id;
        });
      }
      _checkPermissionsAndLoadData(autoPrompt: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndLoadData(autoPrompt: false);
    }
  }

  // =====================================================================
  // O RADAR INTELIGENTE (Prioridade Máxima para a Nuvem)
  // =====================================================================
  Future<void> _loadAppsIntelligently(String childId) async {
    // 1. PRIMEIRO: Tenta sempre baixar a lista de aplicativos do Firebase!
    // (Porque quando a criança faz login no tablet, o app envia a lista pra cá)
    try {
      final doc = await FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .get();
      final data = doc.data();

      if (data != null && data.containsKey('installedApps')) {
        final Map<String, dynamic> rawApps = data['installedApps'];
        if (rawApps.isNotEmpty) {
          setState(() {
            _installedApps = Map.fromEntries(
              rawApps.map((k, v) => MapEntry(k, v.toString())).entries.toList()
                ..sort((a, b) => a.value.compareTo(b.value)),
            );
          });
          return; // SUCCESSO! Sai da função aqui e não tenta ler do celular do pai.
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar o radar de apps na nuvem: $e');
    }

    // 2. SEGUNDO (Plano B): Se a nuvem estiver vazia ou offline, só então lê local
    try {
      final apps = await _monitoringService.getInstalledApps();
      setState(() {
        _installedApps = Map.fromEntries(
          apps.entries.toList()..sort((a, b) => a.value.compareTo(b.value)),
        );
      });
    } catch (e) {
      debugPrint('Erro ao ler apps locais: $e');
    }
  }

  Future<void> _checkPermissionsAndLoadData({bool autoPrompt = false}) async {
    setState(() => _isLoading = true);

    _hasUsagePerm = await _monitoringService.checkUsagePermission();
    _hasOverlayPerm = await _monitoringService.checkOverlayPermission();

    if (_hasAllPermissions) {
      await _monitoringService.startBlockerService();

      try {
        final authUser = ref.read(authStateProvider).value;
        if (authUser != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(authUser.uid)
              .get();

          // Salva o modo de dispositivo para o Radar Inteligente poder tomar a decisão
          _currentDeviceMode = userDoc.data()?['deviceMode'] ?? 'shared';

          final children = await ref.read(parentChildrenStreamProvider.future);
          if (children.isNotEmpty) {
            final liveChild = children.firstWhere(
              (c) => c.id == _selectedChildId,
              orElse: () => children.first,
            );

            await _monitoringService.syncRulesToEngine(
              deviceMode: _currentDeviceMode,
              timeBalance: liveChild.timeBalance,
              blockedApps: liveChild.blockedApps,
              isSessionActive: false,
            );

            // Chama o Radar Inteligente!
            await _loadAppsIntelligently(_selectedChildId);
          }
        }
      } catch (e) {
        debugPrint('Erro na sincronização: $e');
      }

      final usage = await _monitoringService.getDailyAppUsage();
      usage.removeWhere((key, value) => value <= 0);
      final sortedUsage = Map.fromEntries(
        usage.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)),
      );

      int total = 0;
      for (var min in sortedUsage.values) total += min;

      setState(() {
        _appUsage = sortedUsage;
        _totalMinutes = total;
      });
    } else if (autoPrompt && !_autoPromptFired) {
      _autoPromptFired = true;
      if (!_hasUsagePerm) {
        await _monitoringService.requestUsagePermission();
      } else if (!_hasOverlayPerm) {
        await _monitoringService.requestOverlayPermission();
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _getAppName(String pkg) {
    return _installedApps[pkg] ?? pkg.split('.').last.toUpperCase();
  }

  Future<void> _updateChildRules(
    ChildModel child, {
    int? newXpRate,
    List<String>? newBlockedList,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (newXpRate != null) updates['xpToMinutesRate'] = newXpRate;
      if (newBlockedList != null) updates['blockedApps'] = newBlockedList;

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(child.id)
            .update(updates);

        await _monitoringService.syncRulesToEngine(
          deviceMode: _currentDeviceMode,
          timeBalance: child.timeBalance,
          blockedApps: newBlockedList ?? child.blockedApps,
          isSessionActive: false,
        );
      }
    } catch (e) {
      debugPrint('Erro ao atualizar regras: $e');
    }
  }

  Future<void> _addBonusTime(ChildModel child, int bonusMinutes) async {
    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(child.id)
          .update({'timeBalance': FieldValue.increment(bonusMinutes)});

      await FirebaseFirestore.instance.collection('notifications').add({
        'childId': child.id,
        'title': '🎁 Presente Surpresa!',
        'body': 'Você ganhou +$bonusMinutes minutos de tela dos seus pais!',
        'type': 'bonus_time',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _monitoringService.syncRulesToEngine(
        deviceMode: _currentDeviceMode,
        timeBalance: child.timeBalance + bonusMinutes,
        blockedApps: child.blockedApps,
        isSessionActive: false,
      );

      // =================================================================
      // DISPARO DE NOTIFICAÇÃO: Avisar a criança do presente!
      // =================================================================
      if (_currentDeviceMode == 'shared') {
        NotificationService().showNotification(
          id: DateTime.now().millisecond,
          title: '🎁 Presente Surpresa!',
          body:
              'Ganhaste +$bonusMinutes minutos de ecrã dos teus pais! Aproveita!',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+$bonusMinutes minutos injetados com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao dar bônus: $e');
    }
  }

  void _showBonusDialog(ChildModel child) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.volunteer_activism, color: Colors.green),
            SizedBox(width: 10),
            Text('Dar Bônus'),
          ],
        ),
        content: const Text(
          'Deseja injetar minutos extras diretamente no saldo da criança, sem precisar descontar XP?',
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[100],
              foregroundColor: Colors.green[800],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _addBonusTime(child, 15);
            },
            child: const Text('+15 min'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[300],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _addBonusTime(child, 30);
            },
            child: const Text('+30 min'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _addBonusTime(child, 60);
            },
            child: const Text('+1 hora'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Controle de Tela'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _checkPermissionsAndLoadData(autoPrompt: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 4,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: 'Uso de Hoje'),
            Tab(icon: Icon(Icons.security), text: 'Lan House'),
          ],
        ),
      ),
      body: Column(
        children: [
          childrenAsync.when(
            data: (children) {
              if (children.isEmpty) return const SizedBox.shrink();
              if (_selectedChildId.isEmpty) {
                _selectedChildId = children.first.id;
              }

              return Container(
                height: 70,
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    final isSelected = _selectedChildId == child.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.face,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        label: Text(
                          child.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedChildId = child.id);
                            // === CHAMA O RADAR INTELIGENTE AO TROCAR DE PERFIL ===
                            _loadAppsIntelligently(child.id);
                          }
                        },
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 70,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasAllPermissions
                ? _buildPermissionFallback()
                : TabBarView(
                    controller: _tabController,
                    children: [_buildUsageDashboard(), _buildRulesTab()],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionFallback() {
    return Center(
      // PROTEÇÃO DE ROLAGEM AQUI (caso o ecrã seja pequeno e a mensagem seja grande)
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Ação Necessária',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                !_hasUsagePerm
                    ? 'Precisamos de acesso aos dados de uso para monitorar o tempo.'
                    : 'Precisamos de permissão para desenhar a tela de bloqueio sobre os jogos.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.settings),
                label: const Text(
                  'Resolver Agora',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  if (!_hasUsagePerm) {
                    await _monitoringService.requestUsagePermission();
                  } else if (!_hasOverlayPerm) {
                    await _monitoringService.requestOverlayPermission();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageDashboard() {
    final int hours = _totalMinutes ~/ 60;
    final int minutes = _totalMinutes % 60;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Tempo Gasto Hoje',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hours > 0) ...[
                    Text(
                      '$hours',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0, right: 8.0),
                      child: Text(
                        'h',
                        style: TextStyle(color: Colors.white70, fontSize: 20),
                      ),
                    ),
                  ],
                  Text(
                    '$minutes',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'm',
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _appUsage.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum aplicativo foi usado hoje.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _appUsage.length,
                  itemBuilder: (context, index) {
                    final packageName = _appUsage.keys.elementAt(index);
                    final appMinutes = _appUsage.values.elementAt(index);
                    final percentage = _totalMinutes > 0
                        ? appMinutes / _totalMinutes
                        : 0.0;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                          child: const Icon(
                            Icons.android,
                            color: Colors.blueAccent,
                          ),
                        ),
                        title: Text(
                          _getAppName(packageName),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 6,
                            color: Colors.blueAccent,
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                        trailing: Text(
                          '${appMinutes}m',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRulesTab() {
    final childrenAsync = ref.watch(parentChildrenStreamProvider);

    return childrenAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
      data: (children) {
        if (children.isEmpty) return const SizedBox.shrink();

        final liveChild = children.firstWhere(
          (c) => c.id == _selectedChildId,
          orElse: () => children.first,
        );

        final int timeBalance = liveChild.timeBalance;
        final int xpRate = liveChild.xpToMinutesRate;
        final List<String> blockedApps = liveChild.blockedApps;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fichas Disponíveis (Saldo)',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          '${timeBalance ~/ 60}h ${timeBalance % 60}m',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: timeBalance > 0
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text(
                      'Dar Bônus',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showBonusDialog(liveChild),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Taxa de Câmbio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '1 XP = $xpRate min',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: xpRate.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    activeColor: Colors.amber,
                    label: '$xpRate min',
                    onChanged: (val) =>
                        _updateChildRules(liveChild, newXpRate: val.toInt()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Aplicativos Controlados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _installedApps.length,
                itemBuilder: (context, index) {
                  final pkg = _installedApps.keys.elementAt(index);
                  final appName = _installedApps.values.elementAt(index);
                  final isBlocked = blockedApps.contains(pkg);

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      activeTrackColor: Colors.red[200],
                      activeThumbColor: Colors.redAccent,
                      inactiveTrackColor: Colors.green[200],
                      inactiveThumbColor: Colors.green,
                      title: Text(
                        appName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isBlocked
                            ? 'Bloqueado quando o tempo acaba'
                            : 'Sempre liberado',
                        style: TextStyle(
                          color: isBlocked ? Colors.red : Colors.green,
                          fontSize: 12,
                        ),
                      ),
                      value: isBlocked,
                      onChanged: (bool value) {
                        final newList = List<String>.from(blockedApps);
                        if (value) {
                          newList.add(pkg);
                        } else {
                          newList.remove(pkg);
                        }
                        _updateChildRules(liveChild, newBlockedList: newList);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
