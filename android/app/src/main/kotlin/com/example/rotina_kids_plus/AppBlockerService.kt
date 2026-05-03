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
import android.view.MotionEvent // IMPORTANTE: Para detectar o toque na tela
import android.view.View      // IMPORTANTE: Para gerenciar a View do cronômetro
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
        val deviceMode = prefs.getString("deviceMode", "shared") ?: "shared"
        val isSessionActive = prefs.getBoolean("isSessionActive", false)
        val savedTimeBalance = prefs.getInt("timeBalance", 0)
        
        val forceSync = prefs.getBoolean("forceSync", false)
        
        if (forceSync || lastTimeBalanceMinute != savedTimeBalance) {
            currentBalanceSeconds = savedTimeBalance * 60
            lastTimeBalanceMinute = savedTimeBalance
            prefs.edit().putBoolean("forceSync", false).apply()
        }
        
        val blockedApps = prefs.getString("blockedApps", "") ?: ""
        val blockedList = blockedApps.split(",").filter { it.isNotEmpty() }
        
        val topApp = getTopApp()

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
                prefs.edit()
                    .putInt("timeBalance", 0)
                    .putBoolean("isSessionActive", false)
                    .apply()
                lastTimeBalanceMinute = 0
                launchAppWithAction("out_of_time")
            } else {
                currentBalanceSeconds-- 
                
                if (currentBalanceSeconds % 60 == 0) {
                    val newMinutes = currentBalanceSeconds / 60
                    prefs.edit().putInt("timeBalance", newMinutes).apply()
                    lastTimeBalanceMinute = newMinutes
                }
                
                showOrUpdateTimerOverlay(currentBalanceSeconds)
            }
        } else {
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
            // Alterado para Top e Start para facilitar a matemática do arrasto na tela
            params.gravity = Gravity.TOP or Gravity.START
            params.x = 50
            params.y = 200

            timerOverlayView = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                setPadding(40, 20, 40, 20)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#CC000000")) // Fundo translúcido bonito
                    cornerRadius = 60f
                }

                timerTextView = TextView(this@AppBlockerService).apply {
                    text = timeText
                    textSize = 22f
                    setTextColor(Color.WHITE)
                    typeface = android.graphics.Typeface.DEFAULT_BOLD
                }
                addView(timerTextView)

                // ========================================================
                // MAGIA ACONTECENDO: Listener de Toque e Arrasto!
                // ========================================================
                setOnTouchListener(object : View.OnTouchListener {
                    private var initialX = 0
                    private var initialY = 0
                    private var initialTouchX = 0f
                    private var initialTouchY = 0f
                    private var isClick = false

                    override fun onTouch(v: View, event: MotionEvent): Boolean {
                        when (event.action) {
                            MotionEvent.ACTION_DOWN -> {
                                // Quando a criança encosta o dedo, salva a posição atual
                                initialX = params.x
                                initialY = params.y
                                initialTouchX = event.rawX
                                initialTouchY = event.rawY
                                isClick = true
                                return true
                            }
                            MotionEvent.ACTION_MOVE -> {
                                // Calcula o quanto o dedo se moveu
                                val dx = (event.rawX - initialTouchX).toInt()
                                val dy = (event.rawY - initialTouchY).toInt()
                                
                                // Se o dedo moveu mais de 10 pixels, não é um clique, é um arrasto
                                if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
                                    isClick = false
                                }
                                
                                // Atualiza a posição da bolha na tela
                                params.x = initialX + dx
                                params.y = initialY + dy
                                windowManager?.updateViewLayout(timerOverlayView, params)
                                return true
                            }
                            MotionEvent.ACTION_UP -> {
                                // Se o dedo soltou a tela e não arrastou (foi só um toque)
                                if (isClick) {
                                    // Pede ao Rotina Kids+ para abrir a tela de trocar perfil!
                                    launchAppWithAction("require_login")
                                }
                                return true
                            }
                        }
                        return false
                    }
                })
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
                timerTextView?.setTextColor(Color.parseColor("#FF5252")) // Vermelho no final
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

    private fun getTopApp(): String {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        
        val usageEvents = usageStatsManager.queryEvents(time - 10000, time)
        val event = UsageEvents.Event()
        
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                lastKnownApp = event.packageName
            } else if (event.eventType == UsageEvents.Event.ACTIVITY_PAUSED || 
                       event.eventType == UsageEvents.Event.ACTIVITY_STOPPED) {
                if (event.packageName == lastKnownApp) {
                    lastKnownApp = ""
                }
            }
        }
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