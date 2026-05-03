import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'features/child/blocker/services/screen_monitoring_service.dart';
import 'data/services/child_action_providers.dart';
import 'data/services/child_providers.dart';

class RotinaKidsApp extends ConsumerStatefulWidget {
  const RotinaKidsApp({super.key});

  @override
  ConsumerState<RotinaKidsApp> createState() => _RotinaKidsAppState();
}

class _RotinaKidsAppState extends ConsumerState<RotinaKidsApp>
    with WidgetsBindingObserver {
  final ScreenMonitoringService _monitoring = ScreenMonitoringService();

  bool _isCheckingPermissions = true;
  bool _hasAllPermissions = false;
  bool _hasUsagePerm = false;
  bool _hasOverlayPerm = false;
  bool _monitoringStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      _syncTimeFromEngineToFirebase();
    }
  }

  Future<void> _syncTimeFromEngineToFirebase() async {
    if (!_monitoringStarted) return;
    try {
      final remainingTime = await _monitoring.getRemainingTimeFromEngine();
      if (remainingTime >= 0) {
        final activeChild = ref.read(activeChildSessionProvider);
        if (activeChild != null) {
          await FirebaseFirestore.instance
              .collection('children')
              .doc(activeChild.id)
              .update({'timeBalance': remainingTime});
        }
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar: $e');
    }
  }

  Future<void> _checkPermissions() async {
    final hasUsage = await _monitoring.checkUsagePermission();
    final hasOverlay = await _monitoring.checkOverlayPermission();

    if (mounted) {
      setState(() {
        _hasUsagePerm = hasUsage;
        _hasOverlayPerm = hasOverlay;
        _hasAllPermissions = hasUsage && hasOverlay;
        _isCheckingPermissions = false;
      });

      if (_hasAllPermissions && !_monitoringStarted) {
        _startGlobalMonitoring();
      }
    }
  }

  Future<void> _startGlobalMonitoring() async {
    _monitoringStarted = true;
    await _monitoring.startBlockerService();

    final requiresLogin = await _monitoring.checkRequireLogin();
    if (requiresLogin && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appRouter.go('/who-is-playing');
      });
    }

    _monitoring.setupGlobalListeners(
      onRequireLogin: () {
        if (mounted) appRouter.go('/who-is-playing');
      },
      onOutOfTime: () async {
        if (mounted) {
          final activeChild = ref.read(activeChildSessionProvider);
          if (activeChild != null) {
            await FirebaseFirestore.instance
                .collection('children')
                .doc(activeChild.id)
                .update({'timeBalance': 0});
          }

          appRouter.go('/who-is-playing');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'TEMPO ESGOTADO! O seu aplicativo foi bloqueado.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // =========================================================================
    // BLINDAGEM CONTRA ROUBO DE FICHAS: Escuta compras em tempo real!
    // =========================================================================
    ref.listen(parentChildrenStreamProvider, (previous, next) {
      final activeChild = ref.read(activeChildSessionProvider);
      if (activeChild != null && next.value != null && _monitoringStarted) {
        try {
          final updatedChild = next.value!.firstWhere(
            (c) => c.id == activeChild.id,
          );
          _monitoring.syncRulesToEngine(
            deviceMode: 'shared',
            timeBalance: updatedChild.timeBalance,
            blockedApps: updatedChild.blockedApps,
            isSessionActive: true,
          );
        } catch (e) {
          // Ignora se não achar a criança
        }
      }
    });

    if (_isCheckingPermissions) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.deepPurple,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    if (!_hasAllPermissions) {
      return MaterialApp(
        title: 'Rotina Kids+',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.deepPurple,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, size: 80, color: Colors.amber),
                  const SizedBox(height: 24),
                  const Text(
                    'Acesso Necessário',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Para que o controle de tempo e o bloqueio de jogos funcionem, o Rotina Kids+ precisa de duas permissões essenciais do seu aparelho.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  Card(
                    color: _hasUsagePerm ? Colors.green : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: _hasUsagePerm ? 0 : 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Icon(
                        Icons.data_usage,
                        size: 30,
                        color: _hasUsagePerm ? Colors.white : Colors.deepPurple,
                      ),
                      title: Text(
                        'Acesso de Uso',
                        style: TextStyle(
                          color: _hasUsagePerm ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: _hasUsagePerm
                          ? const Icon(Icons.check_circle, color: Colors.white)
                          : const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.deepPurple,
                            ),
                      onTap: () => _monitoring.requestUsagePermission(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    color: _hasOverlayPerm ? Colors.green : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: _hasOverlayPerm ? 0 : 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Icon(
                        Icons.layers,
                        size: 30,
                        color: _hasOverlayPerm
                            ? Colors.white
                            : Colors.deepPurple,
                      ),
                      title: Text(
                        'Sobreposição de Tela',
                        style: TextStyle(
                          color: _hasOverlayPerm ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: _hasOverlayPerm
                          ? const Icon(Icons.check_circle, color: Colors.white)
                          : const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.deepPurple,
                            ),
                      onTap: () => _monitoring.requestOverlayPermission(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Rotina Kids+',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
