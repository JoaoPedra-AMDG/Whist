package com.whist.whist

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val store = getSharedPreferences("whist_game", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.whist.scorekeeper/storage")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadGame" -> result.success(store.getString("game", null))
                    "saveGame" -> {
                        val value = call.arguments as? String
                        if (value == null) {
                            result.error("invalid_game", "Game data is missing", null)
                        } else {
                            val saved = store.edit().putString("game", value).commit()
                            if (saved) result.success(null)
                            else result.error("save_failed", "Could not save game", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
