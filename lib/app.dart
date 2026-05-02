import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'features/child/blocker/services/screen_monitoring_service.dart';
import 'data/services/auth_provider.dart';

class RotinaKidsApp extends ConsumerStatefulWidget {
  const RotinaKidsApp({super.key});

  @override
  ConsumerState<RotinaKidsApp> createState() => _RotinaKidsAppState();
}

// MÁGICA: Adicionamos o "WidgetsBindingObserver" para o app saber quando
// o usuário volta da tela de configurações do Android.
class _RotinaKidsAppState extends ConsumerState<RotinaKidsApp>
    with WidgetsBindingObserver {
  final ScreenMonitoringService _monitoring = ScreenMonitoringService();

  // === VARIÁVEIS DO ESCUDO DE PERMISSÃO ===
  bool _isCheckingPermissions = true;
  bool _hasAllPermissions = false;
  bool _hasUsagePerm = false;
  bool _hasOverlayPerm = false;
  bool _monitoringStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Começa a observar o Android
    _checkPermissions(); // Verifica no milissegundo zero
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Ouve quando o app é minimizado ou volta para a tela
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Quando o pai volta das configurações, checa as permissões de novo automaticamente!
      _checkPermissions();
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

      // Se todas as permissões foram dadas, liga o Motor do Android!
      if (_hasAllPermissions && !_monitoringStarted) {
        _startGlobalMonitoring();
      }
    }
  }

  Future<void> _startGlobalMonitoring() async {
    _monitoringStarted = true;

    await _monitoring.startBlockerService();
    _syncRulesSilently();

    final requiresLogin = await _monitoring.checkRequireLogin();
    if (requiresLogin && mounted) {
      appRouter.go('/who-is-playing');

      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) appRouter.go('/who-is-playing');
      });
    }

    _monitoring.setupGlobalListeners(
      onRequireLogin: () {
        if (mounted) appRouter.go('/who-is-playing');
      },
      onOutOfTime: () {
        if (mounted) {
          appRouter.go('/child-dashboard');
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

  Future<void> _syncRulesSilently() async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final deviceMode = userDoc.data()?['deviceMode'] ?? 'shared';

        final childrenSnap = await FirebaseFirestore.instance
            .collection('children')
            .where('parentId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (childrenSnap.docs.isNotEmpty) {
          final childData = childrenSnap.docs.first.data();
          await _monitoring.syncRulesToEngine(
            deviceMode: deviceMode,
            timeBalance: childData['timeBalance'] ?? 0,
            blockedApps: List<String>.from(childData['blockedApps'] ?? []),
            isSessionActive: false,
          );
        }
      }
    } catch (e) {
      debugPrint('Erro no Sync Global: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. TELA DE CARREGAMENTO INICIAL
    if (_isCheckingPermissions) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.deepPurple,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    // 2. O ESCUDO: SE FALTAR PERMISSÃO, TRAVA NESTA TELA!
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

                  // Botão Permissão de Uso
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
                      subtitle: Text(
                        'Permite medir o tempo dos jogos.',
                        style: TextStyle(
                          color: _hasUsagePerm
                              ? Colors.white70
                              : Colors.grey[700],
                          fontSize: 12,
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

                  // Botão Permissão de Sobreposição
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
                      subtitle: Text(
                        'Permite mostrar o cronômetro.',
                        style: TextStyle(
                          color: _hasOverlayPerm
                              ? Colors.white70
                              : Colors.grey[700],
                          fontSize: 12,
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

                  const Spacer(),
                  const Text(
                    'Após conceder as permissões no Android, basta voltar para esta tela.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. CAMINHO LIVRE: TEM TODAS AS PERMISSÕES? ABRE O APP NORMALMENTE!
    return MaterialApp.router(
      title: 'Rotina Kids+',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
