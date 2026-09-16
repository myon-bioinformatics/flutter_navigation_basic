package com.example.flutter_application_1

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class ImageNormalizeSupportTest {
    @Test
    fun rejectIfTooManyPixels_throwsBeforeCallerWouldDecode() {
        assertThrows(ImageNormalizeSupport.TooManyPixelsException::class.java) {
            ImageNormalizeSupport.rejectIfTooManyPixels(10000, 10000, 40_000_000L)
        }
    }

    @Test
    fun rejectIfTooManyPixels_allowsUnderBudget() {
        ImageNormalizeSupport.rejectIfTooManyPixels(4000, 3000, 40_000_000L)
    }

    @Test
    fun targetSize_downscalesLongEdgeToBudget() {
        val (w, h) = ImageNormalizeSupport.targetSize(8000, 6000, 4096)
        assertEquals(4096, maxOf(w, h))
        assertTrue(w in 1..4096)
        assertTrue(h in 1..4096)
    }

    @Test
    fun targetSize_keepsAlreadySmallImages() {
        assertEquals(1024 to 768, ImageNormalizeSupport.targetSize(1024, 768, 4096))
    }

    @Test
    fun sampleSizeForMaxEdge_powersOfTwo() {
        assertEquals(1, ImageNormalizeSupport.sampleSizeForMaxEdge(2000, 1000, 4096))
        assertTrue(ImageNormalizeSupport.sampleSizeForMaxEdge(12000, 8000, 4096) >= 2)
    }

    @Test
    fun orientationOp_coversValues1Through8() {
        assertNull(ImageNormalizeSupport.orientationOp(1))
        assertEquals(
            ImageNormalizeSupport.OrientationOp(0f, flipX = true, flipY = false),
            ImageNormalizeSupport.orientationOp(2),
        )
        assertEquals(
            ImageNormalizeSupport.OrientationOp(180f, flipX = false, flipY = false),
            ImageNormalizeSupport.orientationOp(3),
        )
        assertEquals(
            ImageNormalizeSupport.OrientationOp(0f, flipX = false, flipY = true),
            ImageNormalizeSupport.orientationOp(4),
        )
        assertEquals(
            ImageNormalizeSupport.OrientationOp(90f, flipX = true, flipY = false),
            ImageNormalizeSupport.orientationOp(5),
        )
        assertEquals(
            ImageNormalizeSupport.OrientationOp(90f, flipX = false, flipY = false),
            ImageNormalizeSupport.orientationOp(6),
        )
        assertEquals(
            ImageNormalizeSupport.OrientationOp(-90f, flipX = true, flipY = false),
            ImageNormalizeSupport.orientationOp(7),
        )
        assertEquals(
            ImageNormalizeSupport.OrientationOp(-90f, flipX = false, flipY = false),
            ImageNormalizeSupport.orientationOp(8),
        )
        assertNotNull(ImageNormalizeSupport.orientationOp(6))
    }
}
