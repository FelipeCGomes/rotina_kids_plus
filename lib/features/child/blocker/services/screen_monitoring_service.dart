import 'package:flutter/services.dart';

class ScreenMonitoringService {
  static const platform = MethodChannel('com.rotinakids.app/monitoring');

  /// Explicação de Integração Futura:
  /// No Android (MainActivity.kt), você interceptará essa chamada e usará:
  /// `UsageStatsManager` para ler o tempo dos pacotes.
  /// Para bloqueio, você usará a permissão `SYSTEM_ALERT_WINDOW` (sobreposição)
  /// para desenhar a "Tela de Bloqueio" do Flutter por cima dos outros apps.

  Future<Map<String, int>> getDailyAppUsage() async {
    try {
      // Mock para desenvolvimento UI:
      return {
        'com.google.android.youtube': 45, // 45 minutos
        'com.roblox.client': 120,
      };

      // Chamada real futura:
      // final Map<Object?, Object?> result = await platform.invokeMethod('getUsageStats');
      // return Map<String, int>.from(result);
    } on PlatformException catch (e) {
      print("Erro ao acessar permissões nativas: '${e.message}'.");
      return {};
    }
  }
}
