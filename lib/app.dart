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

class _RotinaKidsAppState extends ConsumerState<RotinaKidsApp> {
  final ScreenMonitoringService _monitoring = ScreenMonitoringService();

  @override
  void initState() {
    super.initState();
    _startGlobalMonitoring();
  }

  Future<void> _startGlobalMonitoring() async {
    // 1. Liga o motor no Android
    await _monitoring.startBlockerService();

    // 2. Tenta puxar as regras do Firebase e sincronizar (Sem depender da tela Lan House!)
    _syncRulesSilently();

    // 3. Ouvintes de redirecionamento global
    final requiresLogin = await _monitoring.checkRequireLogin();
    if (requiresLogin && mounted) {
      appRouter.push('/who-is-playing');
    }

    _monitoring.setupGlobalListeners(
      onRequireLogin: () {
        if (mounted) appRouter.push('/who-is-playing');
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
        // Descobre se o aparelho é pai, compartilhado ou criança
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final deviceMode = userDoc.data()?['deviceMode'] ?? 'shared';

        // Pega a primeira criança que encontrar na conta para ter um "saldo base" de referência
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
            isSessionActive:
                false, // Inicia como false, esperando a criança colocar a senha
          );
        }
      }
    } catch (e) {
      debugPrint('Erro no Sync Global: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rotina Kids+',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
