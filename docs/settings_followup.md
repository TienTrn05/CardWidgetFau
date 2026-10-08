# Settings follow-up

Status checked on 2026-10-07. This file records unfinished Settings work and the information needed to complete it.

| Item | Current behavior | Work remaining |
| --- | --- | --- |
| Restore Purchase | Shows an unavailable message. The paywall also says billing is not connected. | Configure in-app purchases, implement purchase and restore flows, and update Premium access from verified store transactions. Test a purchase, reinstall, and restoration on another iPhone using the same App Store account. |
| Share App | Opens the native share sheet with the temporary text `Check out CarWidget!`. | Replace the temporary text with the app's real App Store URL once available. |
| Send a Feedback | Prefills a support email to `maixuantruongcvdev@gmail.com` with the installation ID, device model, OS version, app version, bundle ID, language, and a content prompt. iOS opens a `mailto:` URL in the system mail app; Android shows an email app chooser and passes recipient, subject, and body separately. Missing diagnostics are marked `Unknown`; Premium is always `Unknown` until billing is connected. | Verify the Mail setup and compose flow on an iPhone, and the chooser and compose flow on Android with multiple mail apps installed. |
| Term & Privacy | Opens `https://mxtapp.website/` in the device browser. | Replace the home page URL with direct Terms of Use and Privacy Policy URLs when they are available. Verify the legal content on the published site. |
| Device ID | Generates a UUID for this installation, shows it in Settings, and copies it when tapped. iOS stores it in `UserDefaults`; Android stores it in a no-backup app file. | Decide whether to retain it as a support reference. No transactions, activities, or Premium access are currently linked to this ID. It changes after reinstall and must not be used as the source of purchase entitlement. |
| Change icon | Android changes the launcher icon while the app remains open, then removes the old launcher alias when the app leaves the foreground. iOS calls `setAlternateIconName` without closing the app. | Verify the iOS behavior on a built iPhone app. iOS may show its system confirmation alert. |

## Information to provide later

- Direct public Terms of Use URL.
- Direct public Privacy Policy URL.
- App Store URL or app ID for this app once published.
- In-app purchase product identifiers and the intended Premium products, after they are configured for the app.

## Implementation notes

- `assets/data/settings.json` owns Settings labels and row order. `lib/features/settings/presentation/pages/settings_page.dart` maps each stable row ID to its action.
- `lib/features/settings/data/app_sharing.dart` calls the native share implementations in `ios/Runner/AppDelegate.swift` and `android/app/src/main/kotlin/com/tientrn/carwidget/MainActivity.kt`.
- `lib/features/settings/data/device_identity.dart` reads the native installation ID. Settings displays and copies it, and the feedback draft includes it as a support reference. It does not identify a purchase or entitlement.
- `lib/features/settings/data/external_links.dart` opens the feedback email and legal website through native iOS and Android URL handlers.
- Implement purchase and restore together. A new installation ID after reinstall must not remove a valid App Store purchase. Do not mark Premium active just because a local ID or flag exists.
- Do not insert the reference app's email address, website, or App Store URL into this project.
