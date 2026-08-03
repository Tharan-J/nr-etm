package com.nammaroute.nr_etm.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import com.nammaroute.nr_etm.MainActivity

class EtmForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "etm_foreground_service_channel"
        const val NOTIFICATION_ID = 8801
        const val ACTION_START_SERVICE = "ACTION_START_SERVICE"
        const val ACTION_STOP_SERVICE = "ACTION_STOP_SERVICE"
        const val ACTION_LOCATION_BROADCAST = "com.nammaroute.nr_etm.LOCATION_UPDATE"

        var isRunning = false
            private set
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                for (location in locationResult.locations) {
                    broadcastLocation(location)
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_SERVICE -> startForegroundServiceInternal()
            ACTION_STOP_SERVICE -> stopForegroundServiceInternal()
        }
        return START_STICKY
    }

    private fun startForegroundServiceInternal() {
        if (isRunning) return
        isRunning = true

        val notification = buildForegroundNotification("ETM Active — Duty & Location Engine Running")
        startForeground(NOTIFICATION_ID, notification)
        requestLocationUpdates()
    }

    private fun stopForegroundServiceInternal() {
        if (!isRunning) return
        isRunning = false
        fusedLocationClient.removeLocationUpdates(locationCallback)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun requestLocationUpdates() {
        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 5000L)
            .setMinUpdateIntervalMillis(2000L)
            .setMinUpdateDistanceMeters(3.0f)
            .build()

        try {
            fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper())
        } catch (e: SecurityException) {
            // Location permission revoked
        }
    }

    private fun broadcastLocation(location: Location) {
        val intent = Intent(ACTION_LOCATION_BROADCAST).apply {
            putExtra("latitude", location.latitude)
            putExtra("longitude", location.longitude)
            putExtra("speed", location.speed)
            putExtra("bearing", location.bearing)
            putExtra("accuracy", location.accuracy)
            putExtra("timestamp", location.time)
        }
        sendBroadcast(intent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "NammaRoute ETM Foreground Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps ETM location and offline telemetry engine active during bus duty"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(statusText: String): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("NammaRoute Conductor ETM")
            .setContentText(statusText)
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
