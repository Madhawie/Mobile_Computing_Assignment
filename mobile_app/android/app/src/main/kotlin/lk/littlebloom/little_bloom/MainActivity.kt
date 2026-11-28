package lk.littlebloom.little_bloom

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // "Call 1990": opens the dialler with the number filled in (ACTION_DIAL needs no
        // permission; the mother still presses call). See lib/core/platform/phone_dialer.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "little_bloom/phone")
            .setMethodCallHandler { call, result ->
                if (call.method != "dial") return@setMethodCallHandler result.notImplemented()
                val number = call.argument<String>("number") ?: return@setMethodCallHandler result.success(false)
                try {
                    startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$number")))
                    result.success(true)
                } catch (e: ActivityNotFoundException) {
                    result.success(false)
                }
            }
    }
}
