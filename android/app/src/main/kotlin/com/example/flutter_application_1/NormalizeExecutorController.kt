package com.example.flutter_application_1

import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicLong

/**
 * Tracks the normalize background executor + generation so FlutterEngine /
 * Activity cleanup can invalidate in-flight work without blocking the UI thread.
 *
 * Pure JVM — unit-tested without Android instrumentation.
 */
class NormalizeExecutorController(
    private val factory: () -> ExecutorService = { Executors.newSingleThreadExecutor() },
) {
    private val generation = AtomicLong(0)
    @Volatile
    private var executor: ExecutorService? = null

    fun currentGeneration(): Long = generation.get()

    @Synchronized
    fun ensureExecutor(): ExecutorService {
        val existing = executor
        if (existing != null && !existing.isShutdown) {
            return existing
        }
        return factory().also { executor = it }
    }

    /**
     * Bumps generation and shuts down the executor without waiting.
     * Safe to call repeatedly from engine cleanup and onDestroy.
     */
    @Synchronized
    fun tearDown() {
        generation.incrementAndGet()
        val running = executor
        executor = null
        running?.shutdownNow()
    }

    fun isActive(capturedGeneration: Long): Boolean =
        capturedGeneration == generation.get()
}
