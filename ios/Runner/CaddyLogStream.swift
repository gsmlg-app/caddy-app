import Flutter
import UIKit

class CaddyLogStream: NSObject, FlutterStreamHandler {
    private let channel: FlutterEventChannel
    private var eventSink: FlutterEventSink?

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterEventChannel(name: "com.caddy_app/caddy/logs", binaryMessenger: messenger)
        super.init()
        channel.setStreamHandler(self)
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    func sendLog(_ message: String) {
        eventSink?(message)
    }

    func dispose() {
        channel.setStreamHandler(nil)
    }
}
