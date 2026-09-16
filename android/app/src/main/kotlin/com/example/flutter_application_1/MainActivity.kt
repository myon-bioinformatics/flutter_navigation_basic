package com.example.flutter_application_1

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.graphics.Matrix
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Photo Studio image_normalize channel: HEIC/HEIF (and other platform-decodable
 * formats) → orientation-baked PNG, with pixel budget enforced **before** a
 * full-size bitmap is allocated.
 */
class MainActivity : FlutterActivity() {
    private val normalizeChannel = "com.example.flutter_application_1/image_normalize"
    private val normalizeExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, normalizeChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "normalizeToPng") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val args = call.arguments as? Map<*, *>
                val bytes = args?.get("bytes") as? ByteArray
                val maxPixels = (args?.get("maxPixels") as? Number)?.toLong()
                    ?: (40L * 1000L * 1000L)
                val maxLongEdge = (args?.get("maxLongEdge") as? Number)?.toInt() ?: 4096
                if (bytes == null || bytes.isEmpty()) {
                    result.success(null)
                    return@setMethodCallHandler
                }
                normalizeExecutor.execute {
                    try {
                        val png = normalizeToPng(bytes, maxPixels, maxLongEdge)
                        mainHandler.post { result.success(png) }
                    } catch (error: TooManyPixelsException) {
                        mainHandler.post {
                            result.error("too_many_pixels", error.message, null)
                        }
                    } catch (error: Exception) {
                        mainHandler.post {
                            result.error("normalize_failed", error.message, null)
                        }
                    }
                }
            }
    }

    private fun normalizeToPng(
        bytes: ByteArray,
        maxPixels: Long,
        maxLongEdge: Int,
    ): ByteArray? {
        val bitmap = decodeBoundedBitmap(bytes, maxPixels, maxLongEdge) ?: return null
        return try {
            val stream = ByteArrayOutputStream()
            if (!bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)) {
                null
            } else {
                stream.toByteArray()
            }
        } finally {
            bitmap.recycle()
        }
    }

    private fun decodeBoundedBitmap(
        bytes: ByteArray,
        maxPixels: Long,
        maxLongEdge: Int,
    ): Bitmap? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            decodeWithImageDecoder(bytes, maxPixels, maxLongEdge)
        } else {
            decodeWithBitmapFactory(bytes, maxPixels, maxLongEdge)
        }
    }

    private fun decodeWithImageDecoder(
        bytes: ByteArray,
        maxPixels: Long,
        maxLongEdge: Int,
    ): Bitmap? {
        val source = ImageDecoder.createSource(ByteBuffer.wrap(bytes))
        return ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
            val width = info.size.width
            val height = info.size.height
            rejectIfTooManyPixels(width, height, maxPixels)
            val target = targetSize(width, height, maxLongEdge)
            decoder.setTargetSize(target.first, target.second)
            // ImageDecoder applies EXIF/HEIF orientation by default.
        }
    }

    private fun decodeWithBitmapFactory(
        bytes: ByteArray,
        maxPixels: Long,
        maxLongEdge: Int,
    ): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        val width = bounds.outWidth
        val height = bounds.outHeight
        if (width <= 0 || height <= 0) return null
        rejectIfTooManyPixels(width, height, maxPixels)

        val sample = sampleSizeForMaxEdge(width, height, maxLongEdge)
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, opts)
            ?: return null
        val oriented = applyExifOrientation(bytes, decoded)
        return scaleToMaxLongEdge(oriented, maxLongEdge)
    }

    private fun rejectIfTooManyPixels(width: Int, height: Int, maxPixels: Long) {
        val pixels = width.toLong() * height.toLong()
        if (pixels > maxPixels) {
            throw TooManyPixelsException(
                "Image is ${width}x$height ($pixels px) which exceeds $maxPixels",
            )
        }
    }

    private fun targetSize(width: Int, height: Int, maxLongEdge: Int): Pair<Int, Int> {
        val longEdge = max(width, height)
        if (longEdge <= maxLongEdge) return width to height
        val scale = maxLongEdge.toDouble() / longEdge.toDouble()
        val tw = max(1, (width * scale).roundToInt())
        val th = max(1, (height * scale).roundToInt())
        return tw to th
    }

    private fun sampleSizeForMaxEdge(width: Int, height: Int, maxLongEdge: Int): Int {
        var sample = 1
        var w = width
        var h = height
        while (max(w / 2, h / 2) >= maxLongEdge) {
            sample *= 2
            w /= 2
            h /= 2
        }
        return sample.coerceAtLeast(1)
    }

    private fun scaleToMaxLongEdge(bitmap: Bitmap, maxLongEdge: Int): Bitmap {
        val longEdge = max(bitmap.width, bitmap.height)
        if (longEdge <= maxLongEdge) return bitmap
        val target = targetSize(bitmap.width, bitmap.height, maxLongEdge)
        val scaled = Bitmap.createScaledBitmap(bitmap, target.first, target.second, true)
        if (scaled !== bitmap) {
            bitmap.recycle()
        }
        return scaled
    }

    /**
     * BitmapFactory does not honor JPEG/HEIF EXIF orientation on API ≤27.
     * Orientation values 1–8 are mapped to rotate/flip matrices.
     */
    internal fun applyExifOrientation(bytes: ByteArray, bitmap: Bitmap): Bitmap {
        val orientation = try {
            ExifInterface(ByteArrayInputStream(bytes)).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
        } catch (_: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }
        val matrix = orientationMatrix(orientation) ?: return bitmap
        val transformed = Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true,
        )
        if (transformed !== bitmap) {
            bitmap.recycle()
        }
        return transformed
    }

    companion object {
        /** Exposed for JVM unit tests of orientation 1–8 matrices. */
        fun orientationMatrix(orientation: Int): Matrix? {
            val matrix = Matrix()
            when (orientation) {
                ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
                ExifInterface.ORIENTATION_ROTATE_180 -> matrix.setRotate(180f)
                ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.setScale(1f, -1f)
                ExifInterface.ORIENTATION_TRANSPOSE -> {
                    matrix.setRotate(90f)
                    matrix.postScale(-1f, 1f)
                }
                ExifInterface.ORIENTATION_ROTATE_90 -> matrix.setRotate(90f)
                ExifInterface.ORIENTATION_TRANSVERSE -> {
                    matrix.setRotate(-90f)
                    matrix.postScale(-1f, 1f)
                }
                ExifInterface.ORIENTATION_ROTATE_270 -> matrix.setRotate(-90f)
                ExifInterface.ORIENTATION_NORMAL,
                ExifInterface.ORIENTATION_UNDEFINED,
                -> return null
                else -> return null
            }
            return matrix
        }
    }

    private class TooManyPixelsException(message: String) : Exception(message)
}
