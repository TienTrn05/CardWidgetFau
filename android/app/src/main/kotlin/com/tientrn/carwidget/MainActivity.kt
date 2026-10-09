package com.tientrn.carwidget

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.MailTo
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val iconPreferences by lazy { getSharedPreferences("launcher_icon", MODE_PRIVATE) }

    override fun onStop() {
        super.onStop()
        // Disabling the alias that launched the current task can send the app to Home.
        // Wait until the user leaves the app before removing the previous launcher icon.
        val selected = iconPreferences.getInt("selected", -1)
        if (selected in 0..5) disableOtherAliases(selected)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "carwidget/device_identity")
            .setMethodCallHandler { call, result ->
                if (call.method != "getOrCreateId") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val idFile = File(noBackupFilesDir, "installation_id")
                    var identifier = if (idFile.exists()) idFile.readText().trim() else ""
                    if (identifier.isEmpty()) {
                        identifier = UUID.randomUUID().toString().uppercase()
                        idFile.writeText(identifier)
                    }
                    result.success(identifier)
                } catch (error: Exception) {
                    result.error("storage_error", "Could not access the installation ID.", null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "carwidget/app_icon_preference")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getSelectedIcon" -> result.success(getSelectedIcon())
                        "setSelectedIcon" -> {
                            val selection = call.arguments as? Int
                            if (selection == null || selection !in 0..5) {
                                result.error("invalid_icon", "Invalid icon selection.", null)
                            } else {
                                setSelectedIcon(selection)
                                result.success(null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("icon_change_failed", "Could not change the launcher icon.", null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "carwidget/share_app")
            .setMethodCallHandler { call, result ->
                if (call.method != "share") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, "Check out CarWidget!")
                }
                startActivity(Intent.createChooser(intent, "Share CarWidget"))
                result.success(null)
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "carwidget/external_links")
            .setMethodCallHandler { call, result ->
                if (call.method == "getDeviceInfo") {
                    val appVersion = try {
                        val info = packageManager.getPackageInfo(packageName, 0)
                        val build = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            info.longVersionCode
                        } else {
                            @Suppress("DEPRECATION")
                            info.versionCode.toLong()
                        }
                        "${info.versionName} ($build)"
                    } catch (error: PackageManager.NameNotFoundException) {
                        "Unknown"
                    }
                    result.success(mapOf(
                        "model" to "${Build.MANUFACTURER} ${Build.MODEL}",
                        "osVersion" to "Android ${Build.VERSION.RELEASE}",
                        "appVersion" to appVersion,
                        "bundleId" to packageName,
                        "language" to Locale.getDefault().toLanguageTag()
                    ))
                    return@setMethodCallHandler
                }
                val value = call.arguments as? String
                val uri = value?.let(Uri::parse)
                if (call.method != "open" || uri == null ||
                    uri.scheme !in listOf("mailto", "https")) {
                    result.error("invalid_url", "Invalid external link.", null)
                    return@setMethodCallHandler
                }
                try {
                    if (uri.scheme == "mailto") {
                        val mail = MailTo.parse(uri.toString())
                        val recipient = mail.to ?: ""
                        val emailIntent = Intent(Intent.ACTION_SENDTO).apply {
                            data = Uri.parse("mailto:$recipient")
                            putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
                            putExtra(Intent.EXTRA_SUBJECT, mail.subject ?: "")
                            putExtra(Intent.EXTRA_TEXT, mail.body ?: "")
                        }
                        startActivity(Intent.createChooser(emailIntent, "Send feedback"))
                    } else {
                        startActivity(Intent(Intent.ACTION_VIEW, uri))
                    }
                    result.success(null)
                } catch (error: ActivityNotFoundException) {
                    val message = if (uri.scheme == "mailto") {
                        "Install or set up a mail app to send feedback."
                    } else {
                        "Could not open the link."
                    }
                    result.error("open_failed", message, null)
                }
            }
    }

    private fun launcherAlias(index: Int): ComponentName =
        ComponentName(this, "$packageName.LauncherIcon$index")

    private fun getSelectedIcon(): Int {
        val manager = packageManager
        val saved = iconPreferences.getInt("selected", -1)
        if (saved in 0..5 && (saved == 0 ||
            manager.getComponentEnabledSetting(launcherAlias(saved)) ==
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED)) return saved
        for (index in 1..5) {
            if (manager.getComponentEnabledSetting(launcherAlias(index)) ==
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            ) {
                return index
            }
        }
        return 0
    }

    private fun setSelectedIcon(selection: Int) {
        if (getSelectedIcon() == selection) return
        packageManager.setComponentEnabledSetting(
            launcherAlias(selection),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )
        iconPreferences.edit().putInt("selected", selection).apply()
    }

    private fun disableOtherAliases(selection: Int) {
        for (index in 0..5) {
            if (index != selection && packageManager.getComponentEnabledSetting(launcherAlias(index)) !=
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED) {
                packageManager.setComponentEnabledSetting(
                    launcherAlias(index),
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
            }
        }
    }
}
