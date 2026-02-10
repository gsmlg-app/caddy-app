import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var caddyMethodHandler: CaddyMethodHandler?
  private var caddyLogStream: CaddyLogStream?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let messenger = controller.binaryMessenger
      caddyMethodHandler = CaddyMethodHandler(messenger: messenger)
      caddyLogStream = CaddyLogStream(messenger: messenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
