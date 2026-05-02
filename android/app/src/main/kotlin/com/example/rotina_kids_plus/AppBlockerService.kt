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
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView

class AppBlockerService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var prefs: SharedPreferences

    private var windowManager: WindowManager? = null
    private var timerOverlayView: LinearLayout? = null
    private var timerTextView: TextView? = null
    private var isTimerShowing = false

    private var currentBalanceSeconds = 0
    private var lastTimeBalanceMinute = -1

    // ==========================================
    // NOVA VARIÁVEL: A "Memória" do aplicativo
    // ==========================================
    private var lastKnownApp: String = ""

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences("RotinaKidsPrefs", Context.MODE_PRIVATE)
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        
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
            handler.postDelayed(this, 1000)
        }
    }

    private fun checkRulesAndBlock() {
        val deviceMode = prefs.getString("deviceMode", "parent") ?: "parent"
        val isSessionActive = prefs.getBoolean("isSessionActive", false)
        val savedTimeBalance = prefs.getInt("timeBalance", 0)
        
        if (lastTimeBalanceMinute != savedTimeBalance) {
            currentBalanceSeconds = savedTimeBalance * 60
            lastTimeBalanceMinute = savedTimeBalance
        }
        
        val blockedApps = prefs.getString("blockedApps", "") ?: ""
        val blockedList = blockedApps.split(",").filter { it.isNotEmpty() }
        
        // Puxa o aplicativo usando a nova função com "memória"
        val topApp = getTopApp()

        // Se for o nosso próprio app ou não tivermos memória (celular acabou de ligar)
        if (topApp == packageName || topApp.isEmpty()) {
            hideTimerOverlay()
            return
        }

        if (blockedList.contains(topApp)) {
            if (deviceMode == "parent" && !isSessionActive) {
                hideTimerOverlay()
                return
            }

            if (deviceMode == "shared" && !isSessionActive) {
                hideTimerOverlay()
                launchAppWithAction("require_login")
                return
            }

            if (currentBalanceSeconds <= 0) {
                hideTimerOverlay()
                prefs.edit().putInt("timeBalance", 0).apply()
                lastTimeBalanceMinute = 0
                launchAppWithAction("out_of_time")
            } else {
                currentBalanceSeconds-- // DESCONTA 1 SEGUNDO
                
                if (currentBalanceSeconds % 60 == 0) {
                    val newMinutes = currentBalanceSeconds / 60
                    prefs.edit().putInt("timeBalance", newMinutes).apply()
                    lastTimeBalanceMinute = newMinutes
                }
                
                showOrUpdateTimerOverlay(currentBalanceSeconds)
            }
        } else {
            // Abriu calculadora ou tela inicial: esconde o relógio e pausa o tempo
            hideTimerOverlay()
        }
    }

    private fun showOrUpdateTimerOverlay(secondsLeft: Int) {
        val m = secondsLeft / 60
        val s = secondsLeft % 60
        val timeText = String.format("%02d:%02d", m, s)

        if (!isTimerShowing) {
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) 
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY 
                else WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                PixelFormat.TRANSLUCENT
            )
            params.gravity = Gravity.CENTER_VERTICAL or Gravity.END
            params.x = 20

            timerOverlayView = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                setPadding(30, 15, 30, 15)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#B3000000")) 
                    cornerRadius = 50f
                }

                timerTextView = TextView(this@AppBlockerService).apply {
                    text = timeText
                    textSize = 20f
                    setTextColor(Color.WHITE)
                    typeface = android.graphics.Typeface.DEFAULT_BOLD
                }
                addView(timerTextView)
            }

            try {
                windowManager?.addView(timerOverlayView, params)
                isTimerShowing = true
            } catch (e: Exception) {
                e.printStackTrace()
            }
        } else {
            timerTextView?.text = timeText
            
            if (secondsLeft <= 60) {
                timerTextView?.setTextColor(Color.parseColor("#FF5252"))
            } else {
                timerTextView?.setTextColor(Color.WHITE)
            }
        }
    }

    private fun hideTimerOverlay() {
        if (isTimerShowing && timerOverlayView != null) {
            try {
                windowManager?.removeView(timerOverlayView)
                isTimerShowing = false
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    // ==============================================================
    // A MÁGICA DA MEMÓRIA: Evita o sumiço do relógio no YouTube
    // ==============================================================
    private fun getTopApp(): String {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        
        // Lê os eventos curtos
        val usageEvents = usageStatsManager.queryEvents(time - 2000, time)
        val event = UsageEvents.Event()
        
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            // Apenas atualiza a memória se um aplicativo for ativamente trazido para a tela
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                lastKnownApp = event.packageName
            }
        }
        
        // Se a pessoa ficou parada 10 minutos assistindo vídeo, ele não encontra "novo evento",
        // mas ele ainda lembra que o lastKnownApp era o YouTube e não esconde o relógio!
        return lastKnownApp
    }

    private fun launchAppWithAction(actionType: String) {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent != null) {
            launchIntent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or 
                Intent.FLAG_ACTIVITY_SINGLE_TOP
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