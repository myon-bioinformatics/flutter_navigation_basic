package com.example.flutter_application_1

import org.junit.Assert.assertEquals
import org.junit.Test

// The negative case deliberately escapes to JUnit. Its failure is the evidence.
class ArrayLengthProbeTest {
    private fun observe(count: Int) {
        val items = IntArray(count)
        println("XPROBE_LENGTH_RESULT=" + count + ":" + items.size)
        assertEquals(count, items.size)
    }

    @Test fun empty() = observe(0)
    @Test fun three() = observe(3)
    @Test fun negative() = observe(-1)
}
