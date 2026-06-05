package com.orbioom.transit.domain

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Pure formatting helpers. Locale.US keeps numbers stable and dot-decimal across devices. */
object Format {

    private val dayFormat = SimpleDateFormat("d MMM yyyy", Locale.US)
    private val shortFormat = SimpleDateFormat("d MMM", Locale.US)

    fun date(epoch: Long): String = dayFormat.format(Date(epoch))
    fun shortDate(epoch: Long): String = shortFormat.format(Date(epoch))

    /** Trim trailing zeros: 12.0 -> "12", 12.50 -> "12.5", 12.345 -> "12.35". */
    fun number(value: Double, maxDecimals: Int = 2): String {
        if (value.isNaN() || value.isInfinite()) return "0"
        val rounded = String.format(Locale.US, "%.${maxDecimals}f", value)
        return rounded.trimEnd('0').trimEnd('.').ifEmpty { "0" }
    }

    fun integer(value: Double): String = String.format(Locale.US, "%,d", value.toLong())

    fun economy(system: UnitSystem, value: Double?): String =
        if (value == null) "—" else "${number(value, 1)} ${system.economyUnit}"

    fun distance(system: UnitSystem, value: Double): String =
        "${integer(value)} ${system.distanceUnit}"

    fun volume(system: UnitSystem, value: Double): String =
        "${number(value, 2)} ${system.volumeUnit}"

    fun money(value: Double): String = "$${String.format(Locale.US, "%,.2f", value)}"

    fun price(system: UnitSystem, value: Double?): String =
        if (value == null) "—" else "${money(value)}${system.priceUnit}"

    fun costPerDistance(system: UnitSystem, value: Double?): String =
        if (value == null) "—" else "${money(value)}/${system.distanceUnit}"
}
