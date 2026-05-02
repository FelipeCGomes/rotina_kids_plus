package com.example.rotina_kids_plus

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.rotinakids.app/monitoring"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                // Lê se o Kotlin abriu o app exigindo login
                "checkRequireLogin" -> {
                    val req = intent.getBooleanExtra("require_login", false)
                    intent.removeExtra("require_login")
                    result.success(req)
                }
                "checkUsagePermission" -> result.success(hasUsageStatsPermission())
                "requestUsagePermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
                    }
                    result.success(true)
                }
                "startBlockerService" -> {
                    val serviceIntent = Intent(this, AppBlockerService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(true)
                }
                "syncRules" -> {
                    val deviceMode = call.argument<String>("deviceMode") ?: "parent"
                    val timeBalance = call.argument<Int>("timeBalance") ?: 0
                    val blockedAppsList = call.argument<List<String>>("blockedApps") ?: emptyList()
                    val isSessionActive = call.argument<Boolean>("isSessionActive") ?: false

                    val prefs = getSharedPreferences("RotinaKidsPrefs", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("deviceMode", deviceMode)
                        .putInt("timeBalance", timeBalance)
                        .putString("blockedApps", blockedAppsList.joinToString(","))
                        .putBoolean("isSessionActive", isSessionActive)
                        .apply()
                        
                    result.success(true)
                }
                "getUsageStats" -> {
                    if (hasUsageStatsPermission()) result.success(getAppUsage())
                    else result.error("PERMISSION_DENIED", "Sem permissão.", null)
                }
                "getInstalledApps" -> result.success(getInstalledApps())
                else -> result.notImplemented()
            }
        }
    }

    // --- A MÁGICA: QUANDO O APP É PUXADO PARA A FRENTE PELO BLOQUEADOR ---
    override fun onNewIntent(newIntent: Intent) {
        super.onNewIntent(newIntent)
        intent = newIntent 
        
        if (newIntent.getBooleanExtra("require_login", false)) {
            methodChannel?.invokeMethod("showProfileSelector", null)
            newIntent.removeExtra("require_login")
        }
        
        // NOVO: Ouve se foi expulso por falta de tempo
        if (newIntent.getBooleanExtra("out_of_time", false)) {
            methodChannel?.invokeMethod("showOutOfTimeWarning", null)
            newIntent.removeExtra("out_of_time")
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getAppUsage(): Map<String, Int> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val pm = packageManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - (1000 * 60 * 60 * 24)
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val usageMap = mutableMapOf<String, Int>()
        if (stats != null) {
            for (usageStats in stats) {
                val totalTimeInForeground = usageStats.totalTimeInForeground
                if (totalTimeInForeground > 0) {
                    val packageName = usageStats.packageName
                    if (packageName == this.packageName) continue
                    val launchIntent = pm.getLaunchIntentForPackage(packageName)
                    if (launchIntent != null) {
                        val minutes = (totalTimeInForeground / (1000 * 60)).toInt()
                        if (minutes > 0) usageMap[packageName] = usageMap.getOrDefault(packageName, 0) + minutes
                    }
                }
            }
        }
        return usageMap
    }

    private fun getInstalledApps(): Map<String, String> {
        val pm = packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val appMap = mutableMapOf<String, String>()
        for (appInfo in packages) {
            if (appInfo.packageName == this.packageName) continue
            val launchIntent = pm.getLaunchIntentForPackage(appInfo.packageName)
            if (launchIntent != null) {
                val appName = pm.getApplicationLabel(appInfo).toString()
                appMap[appInfo.packageName] = appName
            }
        }
        return appMap
    }
}