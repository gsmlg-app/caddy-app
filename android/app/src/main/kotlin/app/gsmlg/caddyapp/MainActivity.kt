package app.gsmlg.caddyapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var caddyMethodHandler: CaddyMethodHandler? = null
    private var caddyLogStream: CaddyLogStream? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        caddyMethodHandler = CaddyMethodHandler(messenger)
        caddyLogStream = CaddyLogStream(messenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        caddyMethodHandler?.dispose()
        caddyLogStream?.dispose()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
