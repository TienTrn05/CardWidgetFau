import Flutter
import UIKit
import Darwin
import Contacts
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if Bundle.main.object(forInfoDictionaryKey: "UIApplicationSceneManifest") == nil {
      registerAppPlugins(with: self)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    registerAppPlugins(with: engineBridge.pluginRegistry)
  }

  private func registerAppPlugins(with registry: FlutterPluginRegistry) {
    guard !registry.hasPlugin("CarWidgetAppChannels") else { return }
    GeneratedPluginRegistrant.register(with: registry)
    if let registrar = registry.registrar(forPlugin: "DrivingMap") {
      registrar.register(
        DrivingMapViewFactory(messenger: registrar.messenger()),
        withId: "carwidget/driving_map_v1"
      )
    }
    if let registrar = registry.registrar(forPlugin: "CarWidgetAppChannels") {
      let networkSettingsChannel = FlutterMethodChannel(
        name: "carwidget/network_settings_v1",
        binaryMessenger: registrar.messenger()
      )
      networkSettingsChannel.setMethodCallHandler { call, result in
        guard call.method == "openWifiSettings" else {
          result(FlutterMethodNotImplemented)
          return
        }
        // iOS has no public URL for the Wi-Fi settings pane.
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
          result(FlutterError(
            code: "settings_unavailable", message: "Could not open Settings.", details: nil
          ))
          return
        }
        UIApplication.shared.open(url, options: [:]) { opened in
          DispatchQueue.main.async {
            if opened {
              result(nil)
            } else {
              result(FlutterError(
                code: "settings_unavailable", message: "Could not open Settings.", details: nil
              ))
            }
          }
        }
      }
      let storageChannel = FlutterMethodChannel(
        name: "carwidget/local_storage_v1",
        binaryMessenger: registrar.messenger()
      )
      storageChannel.setMethodCallHandler { call, result in
        guard call.method == "getSupportDirectory" else {
          result(FlutterMethodNotImplemented)
          return
        }
        do {
          let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
          ).appendingPathComponent("CarWidget", isDirectory: true)
          try FileManager.default.createDirectory(
            at: support, withIntermediateDirectories: true, attributes: nil
          )
          result(support.path)
        } catch {
          result(FlutterError(
            code: "storage_error", message: "Could not open local storage.", details: nil
          ))
        }
      }
      let channel = FlutterMethodChannel(
        name: "carwidget/device_identity",
        binaryMessenger: registrar.messenger()
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
        binaryMessenger: registrar.messenger()
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
        binaryMessenger: registrar.messenger()
      )
      shareChannel.setMethodCallHandler { [weak registrar] call, result in
        guard call.method == "share" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let controller = registrar?.viewController,
              controller.viewIfLoaded?.window != nil else {
          result(FlutterError(code: "share_unavailable", message: "Sharing is unavailable while the app is not visible.", details: nil))
          return
        }
        var presenter = controller
        while let presented = presenter.presentedViewController {
          presenter = presented
        }
        let sheet = UIActivityViewController(
          activityItems: ["Check out CarWidget!"],
          applicationActivities: nil
        )
        if let popover = sheet.popoverPresentationController {
          popover.sourceView = presenter.view
          popover.sourceRect = CGRect(
            x: presenter.view.bounds.midX,
            y: presenter.view.bounds.midY,
            width: 1,
            height: 1
          )
        }
        presenter.present(sheet, animated: true)
        result(nil)
      }
      let drivingAppsChannel = FlutterMethodChannel(
        name: "carwidget/driving_apps",
        binaryMessenger: registrar.messenger()
      )
      drivingAppsChannel.setMethodCallHandler { call, result in
        guard call.method == "open", let app = call.arguments as? String else {
          result(FlutterMethodNotImplemented)
          return
        }
        let urlString: String
        switch app {
        case "calendar":
          urlString = "calshow://"
        case "maps":
          urlString = "maps://"
        case "findMy":
          urlString = "findmy://"
        case "messages":
          urlString = "sms:"
        case "music":
          urlString = "music://"
        case "weather":
          urlString = "weather://"
        case "settings":
          urlString = UIApplication.openSettingsURLString
        default:
          result(FlutterError(code: "invalid_app", message: "This app cannot be opened.", details: nil))
          return
        }
        guard let url = URL(string: urlString) else {
          result(FlutterError(code: "invalid_url", message: "Could not create the app URL.", details: nil))
          return
        }
        UIApplication.shared.open(url, options: [:]) { opened in
          DispatchQueue.main.async {
            if opened {
              result(nil)
            } else {
              result(FlutterError(code: "app_unavailable", message: "The app is unavailable.", details: app))
            }
          }
        }
      }
      let musicPlayerChannel = FlutterMethodChannel(
        name: "carwidget/music_player_v1",
        binaryMessenger: registrar.messenger()
      )
      musicPlayerChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "openSpotify":
          guard let url = URL(string: "spotify://") else {
            result(FlutterError(code: "invalid_url", message: "Could not open Spotify.", details: nil))
            return
          }
          guard UIApplication.shared.canOpenURL(url) else {
            result(false)
            return
          }
          UIApplication.shared.open(url, options: [:]) { opened in
            DispatchQueue.main.async {
              result(opened)
            }
          }
        case "openAppleMusic":
          let openMusicApp = {
            guard let url = URL(string: "music://") else {
              result(FlutterError(code: "invalid_url", message: "Could not open Apple Music.", details: nil))
              return
            }
            UIApplication.shared.open(url, options: [:]) { opened in
              DispatchQueue.main.async {
                result(["opened": opened])
              }
            }
          }
          if MPMediaLibrary.authorizationStatus() == .notDetermined {
            MPMediaLibrary.requestAuthorization { _ in
              DispatchQueue.main.async(execute: openMusicApp)
            }
          } else {
            openMusicApp()
          }
        case "getNowPlaying":
          let status = MPMediaLibrary.authorizationStatus()
          guard status == .authorized else {
            result(["authorized": false, "isPlaying": false])
            return
          }
          let player = MPMusicPlayerController.systemMusicPlayer
          let item = player.nowPlayingItem
          let artworkImage = item?.artwork?.image(at: CGSize(width: 512, height: 512))
          let artwork = artworkImage?.jpegData(compressionQuality: 0.85)
          var payload: [String: Any] = [
            "authorized": true,
            "isPlaying": player.playbackState == .playing,
            "title": item?.title ?? "",
            "artist": item?.artist ?? "",
            "album": item?.albumTitle ?? "",
            "duration": item?.playbackDuration ?? 0,
            "position": player.currentPlaybackTime,
          ]
          if let artwork {
            payload["artwork"] = FlutterStandardTypedData(bytes: artwork)
          }
          result(payload)
        case "play", "pause", "next", "previous", "seek":
          guard MPMediaLibrary.authorizationStatus() == .authorized else {
            result(FlutterError(code: "media_access_denied", message: "Allow media library access to control Apple Music.", details: nil))
            return
          }
          let player = MPMusicPlayerController.systemMusicPlayer
          switch call.method {
          case "play": player.play()
          case "pause": player.pause()
          case "next": player.skipToNextItem()
          case "previous": player.skipToPreviousItem()
          case "seek":
            if let position = call.arguments as? Double {
              player.currentPlaybackTime = position
            }
          default: break
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      let contactsChannel = FlutterMethodChannel(
        name: "carwidget/contacts",
        binaryMessenger: registrar.messenger()
      )
      contactsChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "loadContacts":
          self.loadDrivingContacts(result: result)
        case "openSettings":
          guard let url = URL(string: UIApplication.openSettingsURLString) else {
            result(FlutterError(code: "settings_unavailable", message: "Could not open iPhone Settings.", details: nil))
            return
          }
          UIApplication.shared.open(url, options: [:]) { opened in
            DispatchQueue.main.async {
              if opened {
                result(nil)
              } else {
                result(FlutterError(code: "settings_unavailable", message: "Could not open iPhone Settings.", details: nil))
              }
            }
          }
        case "call":
          guard let rawNumber = call.arguments as? String else {
            result(FlutterError(code: "invalid_number", message: "A phone number is required.", details: nil))
            return
          }
          self.callPhoneNumber(rawNumber, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      // Temporarily disabled until the Apple Developer team provisions App Groups.
      #if false
      let widgetKitChannel = FlutterMethodChannel(
        name: "carwidget/widgetkit_v1",
        binaryMessenger: registrar.messenger()
      )
      widgetKitChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "setSelectedWidgets":
          guard let ids = call.arguments as? [String], ids.count == 2 else {
            result(FlutterError(code: "invalid_selection", message: "Two widget selection slots are required.", details: nil))
            return
          }
          do {
            try SharedWidgetStore.setSelectedWidgets(
              firstId: ids[0].isEmpty ? nil : ids[0],
              secondId: ids[1].isEmpty ? nil : ids[1]
            )
            if #available(iOS 14.0, *) {
              WidgetCenter.shared.reloadAllTimelines()
            }
            result(nil)
          } catch {
            result(FlutterError(code: "widget_selection_failed", message: error.localizedDescription, details: nil))
          }
        case "saveWidget":
          guard let arguments = call.arguments as? [String: Any],
                let id = arguments["id"] as? String,
                let name = arguments["name"] as? String,
                let imageData = (arguments["imageBytes"] as? FlutterStandardTypedData)?.data else {
            result(FlutterError(code: "invalid_widget", message: "Widget data is incomplete.", details: nil))
            return
          }
          do {
            try SharedWidgetStore.saveImage(imageData, id: id, name: name)
            if #available(iOS 14.0, *) {
              WidgetCenter.shared.reloadAllTimelines()
            }
            result(nil)
          } catch {
            result(FlutterError(code: "widget_save_failed", message: error.localizedDescription, details: nil))
          }
        case "deleteWidget":
          guard let id = call.arguments as? String else {
            result(FlutterError(code: "invalid_widget", message: "A widget ID is required.", details: nil))
            return
          }
          do {
            try SharedWidgetStore.removeWidget(id: id)
            if #available(iOS 14.0, *) {
              WidgetCenter.shared.reloadAllTimelines()
            }
            result(nil)
          } catch {
            result(FlutterError(code: "widget_delete_failed", message: error.localizedDescription, details: nil))
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      #endif
      let externalLinksChannel = FlutterMethodChannel(
        name: "carwidget/external_links",
        binaryMessenger: registrar.messenger()
      )
      externalLinksChannel.setMethodCallHandler { call, result in
        if call.method == "getDeviceInfo" {
          var systemInfo = utsname()
          uname(&systemInfo)
          let model = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
              String(cString: $0)
            }
          }
          let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
          let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
          result([
            "model": model,
            "osVersion": "iOS \(UIDevice.current.systemVersion)",
            "appVersion": "\(version) (\(build))",
            "bundleId": Bundle.main.bundleIdentifier ?? "Unknown",
            "language": Locale.preferredLanguages.first ?? "Unknown"
          ])
          return
        }
        guard call.method == "open", let value = call.arguments as? String,
              let url = URL(string: value), ["mailto", "https"].contains(url.scheme ?? "") else {
          result(FlutterError(code: "invalid_url", message: "Invalid external link.", details: nil))
          return
        }
        UIApplication.shared.open(url, options: [:]) { opened in
          if opened {
            result(nil)
          } else {
            let message = url.scheme == "mailto"
              ? "Set up a mail account or install a mail app to send feedback."
              : "Could not open the link."
            result(FlutterError(code: "open_failed", message: message, details: nil))
          }
        }
      }
    }
  }

  private func loadDrivingContacts(result: @escaping FlutterResult) {
    let store = CNContactStore()
    let status = CNContactStore.authorizationStatus(for: .contacts)

    switch status {
    case .authorized:
      fetchDrivingContacts(from: store, permission: "authorized", result: result)
    case .notDetermined:
      store.requestAccess(for: .contacts) { granted, error in
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(code: "contacts_read_failed", message: error.localizedDescription, details: nil))
          }
        } else if granted {
          self.fetchDrivingContacts(from: store, permission: "authorized", result: result)
        } else {
          DispatchQueue.main.async {
            result(["status": "denied", "contacts": []])
          }
        }
      }
    default:
      // CNAuthorizationStatus.limited is available on iOS 18; checking its raw
      // value keeps this code buildable with the project's iOS 17 SDK.
      if #available(iOS 18.0, *), status.rawValue == 4 {
        fetchDrivingContacts(from: store, permission: "limited", result: result)
      } else {
        let permission = status == .restricted ? "restricted" : "denied"
        DispatchQueue.main.async {
          result(["status": permission, "contacts": []])
        }
      }
    }
  }

  private func fetchDrivingContacts(
    from store: CNContactStore,
    permission: String,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      let keys: [CNKeyDescriptor] = [
        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
        CNContactPhoneNumbersKey as CNKeyDescriptor
      ]
      let request = CNContactFetchRequest(keysToFetch: keys)
      var contacts: [[String: Any]] = []

      do {
        try store.enumerateContacts(with: request) { contact, _ in
          let formattedName = CNContactFormatter.string(from: contact, style: .fullName)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
          let firstPhone = contact.phoneNumbers.first?.value.stringValue ?? ""
          let name = formattedName.isEmpty ? (firstPhone.isEmpty ? "Unknown" : firstPhone) : formattedName
          let initial = String(name.prefix(1)).uppercased()
          contacts.append([
            "name": name,
            "initial": initial,
            "phoneNumbers": contact.phoneNumbers.map { $0.value.stringValue }
          ])
        }
        contacts.sort {
          let left = $0["name"] as? String ?? ""
          let right = $1["name"] as? String ?? ""
          return left.localizedStandardCompare(right) == .orderedAscending
        }
        DispatchQueue.main.async {
          result(["status": permission, "contacts": contacts])
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "contacts_read_failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func callPhoneNumber(_ rawNumber: String, result: @escaping FlutterResult) {
    let number = rawNumber.filter { $0.isNumber || $0 == "+" || $0 == "*" || $0 == "#" }
    guard number.contains(where: \.isNumber),
          let encodedNumber = number.addingPercentEncoding(
            withAllowedCharacters: CharacterSet(charactersIn: "0123456789+*")
          ),
          let url = URL(string: "tel:\(encodedNumber)") else {
      result(FlutterError(code: "invalid_number", message: "Enter a valid phone number.", details: nil))
      return
    }

    // iOS presents its native Call/Cancel confirmation for a tel: URL.
    UIApplication.shared.open(url, options: [:]) { opened in
      DispatchQueue.main.async {
        if opened {
          result(nil)
        } else {
          result(FlutterError(code: "call_unavailable", message: "Calls are unavailable on this device.", details: nil))
        }
      }
    }
  }
}
