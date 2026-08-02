package com.nammaroute.nr_etm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import com.nammaroute.nr_etm.service.EtmForegroundService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.nammaroute.etm/background_service"
    private val LOCATION_EVENT_CHANNEL = "com.nammaroute.etm/location_stream"

    private var locationReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel for controlling Background Foreground Service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    startNativeService()
                    result.success(true)
                }
                "stopForegroundService" -> {
                    stopNativeService()
                    result.success(true)
                }
                "isServiceRunning" -> {
                    result.success(EtmForegroundService.isRunning)
                }
                else -> result.notImplemented()
            }
        }

        // EventChannel for streaming location pings to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    locationReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            if (intent?.action == EtmForegroundService.ACTION_LOCATION_BROADCAST) {
                                val map = HashMap<String, Any>()
                                map["latitude"] = intent.getDoubleExtra("latitude", 0.0)
                                map["longitude"] = intent.getDoubleExtra("longitude", 0.0)
                                map["speed"] = intent.getFloatExtra("speed", 0.0f).toDouble()
                                map["bearing"] = intent.getFloatExtra("bearing", 0.0f).toDouble()
                                map["accuracy"] = intent.getFloatExtra("accuracy", 0.0f).toDouble()
                                map["timestamp"] = intent.getLongExtra("timestamp", System.currentTimeMillis())
                                events?.success(map)
                            }
                        }
                    }
                    val filter = IntentFilter(EtmForegroundService.ACTION_LOCATION_BROADCAST)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(locationReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
                    } else {
                        registerReceiver(locationReceiver, filter)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    locationReceiver?.let {
                        unregisterReceiver(it)
                        locationReceiver = null
                    }
                }
            }
        )
    }

    private fun startNativeService() {
        val intent = Intent(this, EtmForegroundService::class.java).apply {
            action = EtmForegroundService.ACTION_START_SERVICE
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopNativeService() {
        val intent = Intent(this, EtmForegroundService::class.java).apply {
            action = EtmForegroundService.ACTION_STOP_SERVICE
        }
        startService(intent)
    }
}
