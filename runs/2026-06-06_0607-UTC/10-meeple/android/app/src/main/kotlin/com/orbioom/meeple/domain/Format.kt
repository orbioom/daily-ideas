package com.orbioom.meeple.domain

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

/** Pure formatting helpers. Locale.US keeps numbers stable and dot-decimal across devices. */
object Format {

    private val dayFormat = SimpleDateFormat("d MMM yyyy", Locale.US)
    private val shortFormat = SimpleDateFormat("d MMM", Locale.US)
    private val monthFormat = SimpleDateFormat("MMM yyyy", Locale.US)

    fun date(epoch: Long): String = dayFormat.format(Date(epoch))
    fun shortDate(epoch: Long): String = shortFormat.format(Date(epoch))
    fun month(epoch: Long): String = monthFormat.format(Date(epoch))

    /** Trim trailing zeros: 12.0 -> "12", 12.50 -> "12.5", 12.345 -> "12.35". */
    fun number(value: Double, maxDecimals: Int = 2): String {
        if (value.isNaN() || value.isInfinite()) return "0"
        val rounded = String.format(Locale.US, "%.${maxDecimals}f", value)
        return rounded.trimEnd('0').trimEnd('.').ifEmpty { "0" }
    }

    fun integer(value: Double): String = String.format(Locale.US, "%,d", value.toLong())

    /** A 0..1 ratio rendered as a whole-number percent; safe on NaN. */
    fun percent(ratio: Double): String {
        if (ratio.isNaN() || ratio.isInfinite()) return "—"
        return "${(ratio * 100).roundToInt()}%"
    }

    /** A win-loss record like "12–5" (en dash). */
    fun record(wins: Int, losses: Int): String = "$wins–$losses"

    fun duration(minutes: Int?): String {
        if (minutes == null || minutes <= 0) return "—"
        val h = minutes / 60
        val m = minutes % 60
        return when {
            h <= 0 -> "${m}m"
            m == 0 -> "${h}h"
            else -> "${h}h ${m}m"
        }
    }

    /** "12 plays" / "1 play". */
    fun plays(count: Int): String = "$count play${if (count == 1) "" else "s"}"

    fun players(min: Int, max: Int): String =
        if (min == max) "$min player${if (min == 1) "" else "s"}" else "$min–$max players"

    /** "—" when no score, else trimmed number. */
    fun score(value: Double?): String = if (value == null) "—" else number(value, 1)
}
