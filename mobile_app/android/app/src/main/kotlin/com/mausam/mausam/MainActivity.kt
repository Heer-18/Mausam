package com.mausam.mausam

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mausam.app/dynamic_icon"

    private val aliasMap = mapOf(
        "default" to "com.mausam.mausam.MainActivityDefault",
        "sunny" to "com.mausam.mausam.MainActivitySunny",
        "rainy" to "com.mausam.mausam.MainActivityRainy",
        "cloudy" to "com.mausam.mausam.MainActivityCloudy",
        "night" to "com.mausam.mausam.MainActivityNight"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setIcon") {
                val iconName = call.argument<String>("icon") ?: "default"
                try {
                    val targetAlias = aliasMap[iconName] ?: aliasMap["default"]!!
                    val pm = applicationContext.packageManager

                    // Enable target alias
                    pm.setComponentEnabledSetting(
                        ComponentName(applicationContext, targetAlias),
                        PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                        PackageManager.DONT_KILL_APP
                    )

                    // Disable other aliases
                    aliasMap.values.forEach { alias ->
                        if (alias != targetAlias) {
                            pm.setComponentEnabledSetting(
                                ComponentName(applicationContext, alias),
                                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                PackageManager.DONT_KILL_APP
                            )
                        }
                    }

                    result.success("success")
                } catch (e: Exception) {
                    result.error("ICON_CHANGE_ERROR", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
