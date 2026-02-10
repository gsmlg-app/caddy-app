import Flutter
import UIKit

class CaddyMethodHandler: NSObject {
    private let channel: FlutterMethodChannel

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "com.caddy_app/caddy", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler(handle)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            switch call.method {
            case "start":
                let args = call.arguments as? [String: Any]
                let config = args?["config"] as? String ?? "{}"
                let response = CaddyBridgeStartCaddy(config)
                DispatchQueue.main.async { result(response) }
            case "stop":
                let response = CaddyBridgeStopCaddy()
                DispatchQueue.main.async { result(response) }
            case "reload":
                let args = call.arguments as? [String: Any]
                let config = args?["config"] as? String ?? "{}"
                let response = CaddyBridgeReloadCaddy(config)
                DispatchQueue.main.async { result(response) }
            case "status":
                let response = CaddyBridgeGetCaddyStatus()
                DispatchQueue.main.async { result(response) }
            case "setEnvironment":
                let args = call.arguments as? [String: Any]
                let env = args?["env"] as? String ?? "{}"
                let response = CaddyBridgeSetEnvironment(env)
                DispatchQueue.main.async { result(response) }
            default:
                DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
            }
        }
    }

    func dispose() {
        channel.setMethodCallHandler(nil)
    }
}
