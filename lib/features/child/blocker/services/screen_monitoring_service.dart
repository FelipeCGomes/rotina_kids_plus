import 'package:flutter/services.dart';

class ScreenMonitoringService {
  static const platform = MethodChannel('com.rotinakids.app/monitoring');

  Future<bool> checkUsagePermission() async {
    try {
      return await platform.invokeMethod('checkUsagePermission');
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestUsagePermission() async {
    try {
      await platform.invokeMethod('requestUsagePermission');
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<Map<String, int>> getDailyAppUsage() async {
    try {
      final Map<Object?, Object?> result = await platform.invokeMethod(
        'getUsageStats',
      );
      return result.map(
        (key, value) => MapEntry(key.toString(), (value as int)),
      );
    } on PlatformException {
      return {};
    }
  }

  Future<Map<String, String>> getInstalledApps() async {
    try {
      final Map<Object?, Object?> result = await platform.invokeMethod(
        'getInstalledApps',
      );
      return result.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } on PlatformException {
      return {};
    }
  }

  Future<bool> checkOverlayPermission() async {
    try {
      return await platform.invokeMethod('checkOverlayPermission');
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await platform.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<void> startBlockerService() async {
    try {
      await platform.invokeMethod('startBlockerService');
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<void> syncRulesToEngine({
    required String deviceMode,
    required int timeBalance,
    required List<String> blockedApps,
    required bool isSessionActive,
  }) async {
    try {
      await platform.invokeMethod('syncRules', {
        'deviceMode': deviceMode,
        'timeBalance': timeBalance,
        'blockedApps': blockedApps,
        'isSessionActive': isSessionActive,
      });
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  // === NOVOS MÉTODOS GLOBAIS ===

  Future<bool> checkRequireLogin() async {
    try {
      return await platform.invokeMethod('checkRequireLogin');
    } on PlatformException {
      return false;
    }
  }

  void setupGlobalListeners({
    required Function onRequireLogin,
    required Function onOutOfTime,
  }) {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'showProfileSelector') {
        onRequireLogin();
      } else if (call.method == 'showOutOfTimeWarning') {
        onOutOfTime();
      }
    });
  }
}
