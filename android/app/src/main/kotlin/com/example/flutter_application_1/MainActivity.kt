package com.example.flutter_application_1

import android.graphics.Bitmap
import android.graphics.ImageDecoder
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

/**
 * Hosts the Photo Studio image_normalize channel so HEIC/HEIF (and other
 * platform-decodable formats) become orientation-aware PNG without a full
 * Dart-side HEIF codec.
 */
class MainActivity : FlutterActivity() {
    private val normalizeChannel = "com.example.flutter_application_1/image_normalize"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, normalizeChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "normalizeToPng") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.arguments as? ByteArray
                if (bytes == null || bytes.isEmpty()) {
                    result.success(null)
                    return@setMethodCallHandler
                }
                try {
                    val bitmap = decodeBitmap(bytes)
                    if (bitmap == null) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    val stream = ByteArrayOutputStream()
                    val ok = bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    bitmap.recycle()
                    if (!ok) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    result.success(stream.toByteArray())
                } catch (error: Exception) {
                    result.error("normalize_failed", error.message, null)
                }
            }
    }

    private fun decodeBitmap(bytes: ByteArray): Bitmap? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // ImageDecoder applies EXIF/HEIF orientation.
            val source = ImageDecoder.createSource(ByteBuffer.wrap(bytes))
            ImageDecoder.decodeBitmap(source)
        } else {
            android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        }
    }
}
