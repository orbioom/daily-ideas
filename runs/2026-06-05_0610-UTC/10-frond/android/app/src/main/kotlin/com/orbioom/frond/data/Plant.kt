package com.orbioom.frond.data

import java.util.UUID
import kotlin.math.ceil

/** A plant and its watering rhythm. Pure data — no Android dependencies. */
data class Plant(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val species: String,
    val intervalDays: Int,
    val lastWatered: Long          // epoch millis
) {
    private val dayMs = 24L * 60 * 60 * 1000

    fun nextDue(): Long = lastWatered + intervalDays * dayMs

    /** Whole days until the next watering (negative = overdue, 0 = today). */
    fun daysUntilDue(now: Long): Int =
        ceil((nextDue() - now).toDouble() / dayMs).toInt()

    /** 0.0 just watered .. 1.0 (or more) due now or overdue. */
    fun thirst(now: Long): Float {
        val span = (intervalDays * dayMs).toFloat()
        if (span <= 0f) return 1f
        return ((now - lastWatered) / span).coerceIn(0f, 1f)
    }
}
