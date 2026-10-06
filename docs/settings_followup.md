# Settings follow-up

Status checked on 2026-10-06. This file records unfinished Settings work and the information needed to complete it.

| Item | Current behavior | Work remaining |
| --- | --- | --- |
| Restore Purchase | Shows an unavailable message. The paywall also says billing is not connected. | Configure in-app purchases, implement purchase and restore flows, and update Premium access from verified store transactions. Test a purchase, reinstall, and restoration on another iPhone using the same App Store account. |
| Share App | Opens the native share sheet with the temporary text `Check out CarWidget!`. | Replace the temporary text with the app's real App Store URL once available. |
| Send a Feedback | Shows an unavailable message. | Add the company's feedback email address and open a prefilled email using the user's available mail app. Include the installation ID and app version only when appropriate. Gmail, Yahoo, and Outlook are possible sender accounts; receiving feedback by email does not require an app backend. |
| Term & Privacy | Shows an unavailable message. | Add the company's public Terms of Use and Privacy Policy URLs and open them from the app. |
| Device ID | Generates a UUID for this installation, shows it in Settings, and copies it when tapped. iOS stores it in `UserDefaults`; Android stores it in a no-backup app file. | Decide whether to retain it as a support reference. No transactions, activities, or Premium access are currently linked to this ID. It changes after reinstall and must not be used as the source of purchase entitlement. |
| Change icon | Android changes the launcher icon while the app remains open, then removes the old launcher alias when the app leaves the foreground. iOS calls `setAlternateIconName` without closing the app. | Verify the iOS behavior on a built iPhone app. iOS may show its system confirmation alert. |

## Information to provide later

- Company feedback email address.
- Public Terms of Use URL.
- Public Privacy Policy URL.
- App Store URL or app ID for this app once published.
- In-app purchase product identifiers and the intended Premium products, after they are configured for the app.

## Implementation notes

- `assets/data/settings.json` owns Settings labels and row order. `lib/features/settings/presentation/pages/settings_page.dart` maps each stable row ID to its action.
- `lib/features/settings/data/app_sharing.dart` calls the native share implementations in `ios/Runner/AppDelegate.swift` and `android/app/src/main/kotlin/com/tientrn/carwidget/MainActivity.kt`.
- `lib/features/settings/data/device_identity.dart` reads the native installation ID. The ID is currently only displayed and copied.
- Implement purchase and restore together. A new installation ID after reinstall must not remove a valid App Store purchase. Do not mark Premium active just because a local ID or flag exists.
- Do not insert the reference app's email address, website, or App Store URL into this project.
