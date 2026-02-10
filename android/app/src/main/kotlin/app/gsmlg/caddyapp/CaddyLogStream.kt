package app.gsmlg.caddyapp

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

class CaddyLogStream(messenger: BinaryMessenger) :
    EventChannel.StreamHandler {

    private val channel = EventChannel(messenger, "com.caddy_app/caddy/logs")
    private var eventSink: EventChannel.EventSink? = null

    init {
        channel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun sendLog(message: String) {
        eventSink?.success(message)
    }

    fun dispose() {
        channel.setStreamHandler(null)
    }
}
