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
import kotlin.math.max

/**
 * Photo Studio image_normalize channel: HEIC/HEIF (and other platform-decodable
 * formats) → orientation-baked PNG, with pixel budget enforced **before** a
 * full-size bitmap is allocated.
 */
class MainActivity : FlutterActivity() {
    private val normalizeChannelName =
        "com.example.flutter_application_1/image_normalize"
    private var normalizeChannel: MethodChannel? = null
    private val normalizeController = NormalizeExecutorController()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Fresh engine attach: drop any prior channel/executor and start clean.
        tearDownNormalizeSession()
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            normalizeChannelName,
        )
        normalizeChannel = channel
        channel.setMethodCallHandler { call, result ->
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
            val generation = normalizeController.currentGeneration()
            val executor = try {
                normalizeController.ensureExecutor()
            } catch (_: Exception) {
                result.error("normalize_unavailable", "executor unavailable", null)
                return@setMethodCallHandler
            }
            try {
                executor.execute {
                    try {
                        val png = normalizeToPng(bytes, maxPixels, maxLongEdge)
                        mainHandler.post {
                            if (!normalizeController.isActive(generation)) return@post
                            result.success(png)
                        }
                    } catch (error: ImageNormalizeSupport.TooManyPixelsException) {
                        mainHandler.post {
                            if (!normalizeController.isActive(generation)) return@post
                            result.error("too_many_pixels", error.message, null)
                        }
                    } catch (error: Exception) {
                        mainHandler.post {
                            if (!normalizeController.isActive(generation)) return@post
                            result.error("normalize_failed", error.message, null)
                        }
                    }
                }
            } catch (_: java.util.concurrent.RejectedExecutionException) {
                result.error("normalize_unavailable", "executor shut down", null)
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        tearDownNormalizeSession()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        tearDownNormalizeSession()
        super.onDestroy()
    }

    /** Idempotent: clear channel handler + bump generation + shutdownNow (no wait). */
    private fun tearDownNormalizeSession() {
        normalizeChannel?.setMethodCallHandler(null)
        normalizeChannel = null
        normalizeController.tearDown()
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
            ImageNormalizeSupport.rejectIfTooManyPixels(width, height, maxPixels)
            val target = ImageNormalizeSupport.targetSize(width, height, maxLongEdge)
            decoder.setTargetSize(target.first, target.second)
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
        ImageNormalizeSupport.rejectIfTooManyPixels(width, height, maxPixels)

        val sample =
            ImageNormalizeSupport.sampleSizeForMaxEdge(width, height, maxLongEdge)
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, opts)
            ?: return null
        val oriented = applyExifOrientation(bytes, decoded)
        return scaleToMaxLongEdge(oriented, maxLongEdge)
    }

    private fun scaleToMaxLongEdge(bitmap: Bitmap, maxLongEdge: Int): Bitmap {
        val longEdge = max(bitmap.width, bitmap.height)
        if (longEdge <= maxLongEdge) return bitmap
        val target =
            ImageNormalizeSupport.targetSize(bitmap.width, bitmap.height, maxLongEdge)
        val scaled = Bitmap.createScaledBitmap(bitmap, target.first, target.second, true)
        if (scaled !== bitmap) {
            bitmap.recycle()
        }
        return scaled
    }

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
        fun orientationMatrix(orientation: Int): Matrix? {
            val op = ImageNormalizeSupport.orientationOp(orientation) ?: return null
            val matrix = Matrix()
            if (op.degrees != 0f) {
                matrix.setRotate(op.degrees)
            }
            if (op.flipX || op.flipY) {
                val sx = if (op.flipX) -1f else 1f
                val sy = if (op.flipY) -1f else 1f
                if (op.degrees == 0f) {
                    matrix.setScale(sx, sy)
                } else {
                    matrix.postScale(sx, sy)
                }
            }
            return matrix
        }
    }
}
