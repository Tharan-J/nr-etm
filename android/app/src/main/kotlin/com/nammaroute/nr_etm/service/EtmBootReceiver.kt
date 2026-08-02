package com.nammaroute.nr_etm.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class EtmBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            
            val serviceIntent = Intent(context, EtmForegroundService::class.java).apply {
                action = EtmForegroundService.ACTION_START_SERVICE
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }
}
