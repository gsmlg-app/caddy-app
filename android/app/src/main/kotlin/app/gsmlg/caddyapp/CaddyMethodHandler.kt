package app.gsmlg.caddyapp

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class CaddyMethodHandler(messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "com.caddy_app/caddy")
    private val scope = CoroutineScope(Dispatchers.IO)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        scope.launch {
            try {
                val response = when (call.method) {
                    "start" -> {
                        val config = call.argument<String>("config") ?: "{}"
                        caddy_bridge.CaddyBridge.startCaddy(config)
                    }
                    "stop" -> {
                        caddy_bridge.CaddyBridge.stopCaddy()
                    }
                    "reload" -> {
                        val config = call.argument<String>("config") ?: "{}"
                        caddy_bridge.CaddyBridge.reloadCaddy(config)
                    }
                    "status" -> {
                        caddy_bridge.CaddyBridge.getCaddyStatus()
                    }
                    else -> {
                        result.notImplemented()
                        return@launch
                    }
                }
                result.success(response)
            } catch (e: Exception) {
                result.error("CADDY_ERROR", e.message, null)
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
