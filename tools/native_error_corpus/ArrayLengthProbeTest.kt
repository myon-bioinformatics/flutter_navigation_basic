package com.example.flutter_application_1

import org.junit.Assert.assertEquals
import org.junit.Ignore
import org.junit.Test

// Exceptions deliberately escape to the original Gradle JUnit report.
class ArrayLengthProbeTest {
    private fun observe(caseId: String, count: Int) {
        val items = IntArray(count)
        println("XPROBE_CASE_RESULT=" + caseId + ":" + items.size)
        assertEquals(count, items.size)
    }
    @Test fun empty() = observe("empty", 0)
    @Test fun three() = observe("three", 3)
    @Test fun negative() = observe("negative", -1)
    /* SEEDED_CASES */
    @Test fun bounds() { IntArray(1)[5] }
    @Test fun null_assert() { val value: String? = null; value!!.length }
    @Test fun bad_cast() { val value: Any = "text"; value as Int }
    @Test fun invalid_integer() { "not-an-integer".toInt() }
    @Ignore("No JSON parser in the existing JVM test dependencies")
    @Test fun invalid_json() { error("must remain unobserved") }
    @Test fun divide_zero() { 1 / listOf(0).first() }
}

