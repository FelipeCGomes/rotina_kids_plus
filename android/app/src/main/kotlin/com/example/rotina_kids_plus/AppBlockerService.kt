package com.example.rotina_kids_plus

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

class AppBlockerService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var prefs: SharedPreferences

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences("RotinaKidsPrefs", Context.MODE_PRIVATE)
        
        createNotificationChannel()
        val notification = Notification.Builder(this, "blocker_channel")
            .setContentTitle("Rotina Kids+")
            .setContentText("Monitoramento Global Ativo")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .build()
        startForeground(1, notification)

        handler.post(monitoringRunnable)
    }

    private val monitoringRunnable = object : Runnable {
        override fun run() {
            checkRulesAndBlock()
            handler.postDelayed(this, 2000)
        }
    }

    private fun checkRulesAndBlock() {
        val deviceMode = prefs.getString("deviceMode", "parent") ?: "parent"
        val isSessionActive = prefs.getBoolean("isSessionActive", false)
        val timeBalance = prefs.getInt("timeBalance", 0)
        
        val blockedApps = prefs.getString("blockedApps", "") ?: ""
        val blockedList = blockedApps.split(",").filter { it.isNotEmpty() }
        val topApp = getTopApp()

        if (topApp == packageName) return

        if (blockedList.contains(topApp)) {
            // Regra 1: Celular do Pai
            if (deviceMode == "parent" && !isSessionActive) return

            // Regra 2: Compartilhado e ninguém logou
            if (deviceMode == "shared" && !isSessionActive) {
                launchAppWithAction("require_login")
                return
            }

            // Regra 3: Se não tem tempo
            if (timeBalance <= 0) {
                launchAppWithAction("out_of_time")
            }
        }
    }

    private fun getTopApp(): String {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val usageEvents = usageStatsManager.queryEvents(time - 5000, time)
        var topPackageName = ""
        val event = UsageEvents.Event()
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                topPackageName = event.packageName
            }
        }
        return topPackageName
    }

    // === FORÇA BRUTA PARA ABRIR O APP ===
    private fun launchAppWithAction(actionType: String) {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent != null) {
            // Estas 3 flags juntas obrigam o app a abrir por cima de qualquer jogo, mesmo com o celular recém-ligado
            launchIntent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or 
                Intent.FLAG_ACTIVITY_CLEAR_TASK or 
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            )
            launchIntent.putExtra(actionType, true)
            startActivity(launchIntent)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("blocker_channel", "Rotina Kids Monitor", NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}