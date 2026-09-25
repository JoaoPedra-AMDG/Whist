import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.whist.scorekeeper/storage",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "loadGame":
          result(UserDefaults.standard.string(forKey: "whist_game"))
        case "saveGame":
          guard let value = call.arguments as? String else {
            result(FlutterError(code: "invalid_game", message: "Game data is missing", details: nil))
            return
          }
          UserDefaults.standard.set(value, forKey: "whist_game")
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
