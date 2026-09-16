package com.example.flutter_application_1

import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Pure helpers for Photo Studio native normalize (pixel gate + downsample math
 * + EXIF orientation taxonomy). Kept free of Bitmap so JVM unit tests can run
 * without Robolectric.
 */
object ImageNormalizeSupport {
    class TooManyPixelsException(message: String) : Exception(message)

    fun rejectIfTooManyPixels(width: Int, height: Int, maxPixels: Long) {
        val pixels = width.toLong() * height.toLong()
        if (pixels > maxPixels) {
            throw TooManyPixelsException(
                "Image is ${width}x$height ($pixels px) which exceeds $maxPixels",
            )
        }
    }

    fun targetSize(width: Int, height: Int, maxLongEdge: Int): Pair<Int, Int> {
        val longEdge = max(width, height)
        if (longEdge <= maxLongEdge) return width to height
        val scale = maxLongEdge.toDouble() / longEdge.toDouble()
        val tw = max(1, (width * scale).roundToInt())
        val th = max(1, (height * scale).roundToInt())
        return tw to th
    }

    fun sampleSizeForMaxEdge(width: Int, height: Int, maxLongEdge: Int): Int {
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

    /**
     * EXIF orientation 1–8 → geometric ops (degrees / flips).
     * Mirrors the Matrix applied in [MainActivity.orientationMatrix].
     */
    data class OrientationOp(
        val degrees: Float,
        val flipX: Boolean,
        val flipY: Boolean,
    )

    fun orientationOp(orientation: Int): OrientationOp? {
        return when (orientation) {
            // ExifInterface.ORIENTATION_FLIP_HORIZONTAL
            2 -> OrientationOp(0f, flipX = true, flipY = false)
            // ORIENTATION_ROTATE_180
            3 -> OrientationOp(180f, flipX = false, flipY = false)
            // ORIENTATION_FLIP_VERTICAL
            4 -> OrientationOp(0f, flipX = false, flipY = true)
            // ORIENTATION_TRANSPOSE
            5 -> OrientationOp(90f, flipX = true, flipY = false)
            // ORIENTATION_ROTATE_90
            6 -> OrientationOp(90f, flipX = false, flipY = false)
            // ORIENTATION_TRANSVERSE
            7 -> OrientationOp(-90f, flipX = true, flipY = false)
            // ORIENTATION_ROTATE_270
            8 -> OrientationOp(-90f, flipX = false, flipY = false)
            // NORMAL / UNDEFINED
            1, 0 -> null
            else -> null
        }
    }
}
