package com.example.rotina_kids_plus

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        // Abrange todos os tipos de reinicialização (Samsung, Motorola, Xiaomi, etc)
        if (action == Intent.ACTION_BOOT_COMPLETED || 
            action == "android.intent.action.QUICKBOOT_POWERON" || 
            action == "com.htc.intent.action.QUICKBOOT_POWERON" ||
            action == Intent.ACTION_LOCKED_BOOT_COMPLETED) {
            
            // 1. ZERA A SESSÃO! Se o celular reiniciou, ninguém está jogando.
            val prefs = context.getSharedPreferences("RotinaKidsPrefs", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("isSessionActive", false).apply()

            // 2. Liga o Motor de Bloqueio
            val serviceIntent = Intent(context, AppBlockerService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try {
                    context.startForegroundService(serviceIntent)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            } else {
                context.startService(serviceIntent)
            }
        }
    }
}