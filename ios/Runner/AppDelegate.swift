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
        name: "carwidget/device_identity",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "getOrCreateId" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let key = "carwidget.installation_id"
        if let existing = UserDefaults.standard.string(forKey: key) {
          result(existing)
          return
        }
        let identifier = UUID().uuidString
        UserDefaults.standard.set(identifier, forKey: key)
        result(identifier)
      }
      let iconChannel = FlutterMethodChannel(
        name: "carwidget/app_icon_preference",
        binaryMessenger: controller.binaryMessenger
      )
      iconChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "getSelectedIcon":
          let name = UIApplication.shared.alternateIconName
          let selection = name.flatMap { Int($0.replacingOccurrences(of: "AppIcon", with: "")) } ?? 0
          result(selection)
        case "setSelectedIcon":
          guard let selection = call.arguments as? Int, (0...5).contains(selection) else {
            result(FlutterError(code: "invalid_icon", message: "Invalid icon selection.", details: nil))
            return
          }
          guard UIApplication.shared.supportsAlternateIcons else {
            result(FlutterError(code: "unsupported", message: "Alternate icons are unavailable.", details: nil))
            return
          }
          let iconName: String? = selection == 0 ? nil : "AppIcon\(selection)"
          UIApplication.shared.setAlternateIconName(iconName) { error in
            DispatchQueue.main.async {
              if let error = error {
                result(FlutterError(code: "icon_change_failed", message: error.localizedDescription, details: nil))
              } else {
                result(nil)
              }
            }
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      let shareChannel = FlutterMethodChannel(
        name: "carwidget/share_app",
        binaryMessenger: controller.binaryMessenger
      )
      shareChannel.setMethodCallHandler { call, result in
        guard call.method == "share" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let sheet = UIActivityViewController(
          activityItems: ["Check out CarWidget!"],
          applicationActivities: nil
        )
        if let popover = sheet.popoverPresentationController {
          popover.sourceView = controller.view
          popover.sourceRect = CGRect(
            x: controller.view.bounds.midX,
            y: controller.view.bounds.midY,
            width: 1,
            height: 1
          )
        }
        controller.present(sheet, animated: true)
        result(nil)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
