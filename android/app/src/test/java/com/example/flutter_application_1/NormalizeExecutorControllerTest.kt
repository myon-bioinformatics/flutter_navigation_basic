package com.example.flutter_application_1

import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.concurrent.AbstractExecutorService
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

class NormalizeExecutorControllerTest {
    @Test
    fun tearDown_invalidatesGenerationAndSuppressesLateCallbacks() {
        val controller = NormalizeExecutorController()
        val executor = controller.ensureExecutor()
        val gen = controller.currentGeneration()
        assertTrue(controller.isActive(gen))

        controller.tearDown()
        assertFalse(controller.isActive(gen))
        assertTrue(executor.isShutdown)
    }

    @Test
    fun ensureAfterTearDown_createsFreshExecutor() {
        val created = AtomicInteger(0)
        val controller = NormalizeExecutorController {
            created.incrementAndGet()
            object : AbstractExecutorService() {
                @Volatile private var stopped = false
                override fun execute(command: Runnable) = command.run()
                override fun shutdown() {
                    stopped = true
                }
                override fun shutdownNow(): MutableList<Runnable> {
                    stopped = true
                    return mutableListOf()
                }
                override fun isShutdown(): Boolean = stopped
                override fun isTerminated(): Boolean = stopped
                override fun awaitTermination(timeout: Long, unit: TimeUnit): Boolean = true
            }
        }

        val first = controller.ensureExecutor()
        val gen1 = controller.currentGeneration()
        controller.tearDown()
        assertFalse(controller.isActive(gen1))

        val second = controller.ensureExecutor()
        val gen2 = controller.currentGeneration()
        assertNotSame(first, second)
        assertTrue(controller.isActive(gen2))
        assertSame(second, controller.ensureExecutor())
        assertTrue(created.get() >= 2)
    }

    @Test
    fun tearDown_isIdempotent() {
        val controller = NormalizeExecutorController()
        controller.ensureExecutor()
        controller.tearDown()
        controller.tearDown()
        val next = controller.ensureExecutor()
        assertFalse(next.isShutdown)
    }
}
