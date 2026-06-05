package com.orbioom.transit.domain

import kotlinx.serialization.Serializable

/**
 * Pure Kotlin domain models — no Android imports. Serialized to JSON on disk.
 *
 * Transit keeps a calm log of fuel-ups per vehicle and turns the raw numbers into
 * real efficiency insight: fuel economy between full tanks, cost per distance, and
 * spending trends.
 */

/** A vehicle's measurement system. Drives every label and computation. */
@Serializable
enum class UnitSystem(val title: String) {
    /** Litres, kilometres, and L/100km. */
    METRIC("Metric (L, km, L/100km)"),

    /** US gallons, miles, and miles per gallon. */
    US("US (gal, mi, mpg)");

    val volumeUnit: String get() = if (this == METRIC) "L" else "gal"
    val distanceUnit: String get() = if (this == METRIC) "km" else "mi"
    val economyUnit: String get() = if (this == METRIC) "L/100km" else "mpg"
    val priceUnit: String get() = if (this == METRIC) "/L" else "/gal"

    companion object {
        fun fromNameOrDefault(raw: String?): UnitSystem =
            entries.firstOrNull { it.name.equals(raw, ignoreCase = true) } ?: METRIC
    }
}

/** What the tank takes. Informational; does not affect economy maths. */
@Serializable
enum class FuelType(val title: String) {
    PETROL("Petrol"),
    DIESEL("Diesel"),
    ELECTRIC("Electric"),
    HYBRID("Hybrid"),
    LPG("LPG"),
    OTHER("Other");

    companion object {
        fun fromNameOrDefault(raw: String?): FuelType =
            entries.firstOrNull { it.name.equals(raw, ignoreCase = true) } ?: PETROL
    }
}

@Serializable
data class Vehicle(
    val id: String,
    val name: String,
    val makeModel: String = "",
    val unitSystem: UnitSystem = UnitSystem.METRIC,
    val fuelType: FuelType = FuelType.PETROL,
    val tankCapacity: Double? = null,
    val notes: String = "",
    val createdAt: Long = 0L
)

@Serializable
data class FillUp(
    val id: String,
    val vehicleId: String,
    /** Epoch millis of the fill, used for ordering and the time-series chart. */
    val date: Long,
    /** Odometer reading at the fill, in the vehicle's distance unit. */
    val odometer: Double,
    /** Fuel added, in the vehicle's volume unit. */
    val volume: Double,
    val pricePerUnit: Double,
    /** Stored total; if it disagrees with volume×price we trust the stored value. */
    val totalCost: Double,
    /** True if the tank was filled to full — required to anchor an economy segment. */
    val isFullTank: Boolean = true,
    /**
     * True when the driver knows a previous fill went unrecorded, so the volume since the
     * last logged full tank is understated. Such segments are flagged, never computed.
     */
    val isMissedPrevious: Boolean = false,
    val station: String = "",
    val notes: String = ""
)
