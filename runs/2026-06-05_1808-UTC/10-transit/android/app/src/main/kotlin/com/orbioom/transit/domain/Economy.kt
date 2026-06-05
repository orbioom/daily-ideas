package com.orbioom.transit.domain

import kotlin.math.abs

/**
 * Pure fuel-economy engine. No Android imports, fully unit-testable by reading.
 *
 * The central idea: economy can only be computed *between two full tanks*. Distance is the
 * odometer delta between consecutive full fills; the fuel that distance consumed is the sum
 * of every fill added *after* the earlier full fill, up to and including the later full fill
 * (so partial top-ups in between are correctly counted). Segments are skipped — and clearly
 * labelled — when data is insufficient or inconsistent, never silently miscomputed.
 */
object Economy {

    /** Why a segment between two full fills could not yield a number. */
    enum class SkipReason(val label: String) {
        PARTIAL_IN_BETWEEN("partial fills between full tanks are counted, not skipped"),
        MISSED_FILL("a previous fill was missed — distance can't be trusted"),
        NON_INCREASING_ODOMETER("odometer did not increase"),
        NON_POSITIVE_VOLUME("no fuel recorded for this segment"),
        FIRST_FULL("first full tank — nothing before it to measure from")
    }

    /**
     * One computed (or skipped) leg between the previous full tank and a full tank.
     * [economy] is in the vehicle's economy unit (L/100km or mpg) when [computable] is true.
     */
    data class Segment(
        val endFillId: String,
        val endDate: Long,
        val startOdometer: Double,
        val endOdometer: Double,
        val distance: Double,
        val volume: Double,
        val cost: Double,
        val economy: Double?,
        val computable: Boolean,
        val skipReason: SkipReason?
    ) {
        val costPerDistance: Double?
            get() = if (computable && distance > 0.0) cost / distance else null
    }

    /**
     * Walk the fills in chronological order and build the segment list. Each full tank closes
     * the running segment that began at the previous full tank.
     */
    fun segments(vehicle: Vehicle, fillsUnsorted: List<FillUp>): List<Segment> {
        val fills = fillsUnsorted.sortedWith(compareBy({ it.date }, { it.odometer }))
        val result = mutableListOf<Segment>()

        // The most recent full fill that can anchor the next segment, and the fuel/cost
        // accumulated since it (excluding that anchor fill's own volume).
        var anchor: FillUp? = null
        var accumulatedVolume = 0.0
        var accumulatedCost = 0.0
        var sawMissedSinceAnchor = false
        var seenFirstFull = false

        for (fill in fills) {
            if (anchor != null) {
                // Fuel added after the anchor contributes to the current segment.
                accumulatedVolume += fill.volume.coerceAtLeast(0.0)
                accumulatedCost += fill.totalCost.coerceAtLeast(0.0)
                if (fill.isMissedPrevious) sawMissedSinceAnchor = true
            }

            if (fill.isFullTank) {
                val start = anchor
                if (start == null) {
                    // First full tank establishes the baseline; nothing to compute yet.
                    if (!seenFirstFull) {
                        result.add(
                            Segment(
                                endFillId = fill.id,
                                endDate = fill.date,
                                startOdometer = fill.odometer,
                                endOdometer = fill.odometer,
                                distance = 0.0,
                                volume = 0.0,
                                cost = 0.0,
                                economy = null,
                                computable = false,
                                skipReason = SkipReason.FIRST_FULL
                            )
                        )
                    }
                    seenFirstFull = true
                } else {
                    val distance = fill.odometer - start.odometer
                    val volume = accumulatedVolume
                    val cost = accumulatedCost
                    val skip = when {
                        sawMissedSinceAnchor || fill.isMissedPrevious -> SkipReason.MISSED_FILL
                        distance <= 0.0 -> SkipReason.NON_INCREASING_ODOMETER
                        volume <= 0.0 -> SkipReason.NON_POSITIVE_VOLUME
                        else -> null
                    }
                    val economy = if (skip == null) economyFor(vehicle.unitSystem, distance, volume) else null
                    result.add(
                        Segment(
                            endFillId = fill.id,
                            endDate = fill.date,
                            startOdometer = start.odometer,
                            endOdometer = fill.odometer,
                            distance = distance,
                            volume = volume,
                            cost = cost,
                            economy = economy,
                            computable = skip == null,
                            skipReason = skip
                        )
                    )
                }

                // This full fill becomes the new anchor; reset the running tallies.
                anchor = fill
                accumulatedVolume = 0.0
                accumulatedCost = 0.0
                sawMissedSinceAnchor = false
            }
        }
        return result
    }

    /** Convert a distance/volume pair into the unit system's economy figure. Guarded. */
    fun economyFor(system: UnitSystem, distance: Double, volume: Double): Double? {
        if (distance <= 0.0 || volume <= 0.0) return null
        return when (system) {
            UnitSystem.METRIC -> volume / distance * 100.0   // L/100km
            UnitSystem.US -> distance / volume               // mpg
        }
    }

    /**
     * For L/100km a *lower* number is better; for mpg a *higher* number is better. This lets
     * the UI label "best" and "worst" correctly regardless of unit system.
     */
    fun isLowerBetter(system: UnitSystem): Boolean = system == UnitSystem.METRIC
}

/** Rolled-up statistics for a single vehicle. All fields safe for an empty/partial log. */
data class VehicleStats(
    val vehicle: Vehicle,
    val fillCount: Int,
    val totalDistance: Double,
    val totalVolume: Double,
    val totalSpend: Double,
    val averagePrice: Double?,
    val averageEconomy: Double?,
    val bestEconomy: Double?,
    val worstEconomy: Double?,
    val costPerDistance: Double?,
    val lastFill: FillUp?,
    val computableSegments: List<Economy.Segment>,
    val allSegments: List<Economy.Segment>,
    /** This vehicle's fills, sorted chronologically. Source of truth for history/charts. */
    val sourceFills: List<FillUp>
) {
    val hasComputedEconomy: Boolean get() = averageEconomy != null
}

object Stats {

    fun forVehicle(vehicle: Vehicle, fills: List<FillUp>): VehicleStats {
        val sorted = fills.sortedWith(compareBy({ it.date }, { it.odometer }))
        val segments = Economy.segments(vehicle, sorted)
        val computable = segments.filter { it.computable && it.economy != null }

        val totalSpend = sorted.sumOf { it.totalCost.coerceAtLeast(0.0) }
        val totalVolume = sorted.sumOf { it.volume.coerceAtLeast(0.0) }

        // Total distance from the spread of odometer readings (robust to partials).
        val odos = sorted.map { it.odometer }
        val totalDistance = if (odos.size >= 2) (odos.max() - odos.min()).coerceAtLeast(0.0) else 0.0

        val averagePrice = if (totalVolume > 0.0) totalSpend / totalVolume else null

        // Distance-weighted average economy across computable segments (the correct mean),
        // derived from total computable distance and fuel rather than averaging ratios.
        val compDistance = computable.sumOf { it.distance }
        val compVolume = computable.sumOf { it.volume }
        val averageEconomy = Economy.economyFor(vehicle.unitSystem, compDistance, compVolume)

        val economies = computable.mapNotNull { it.economy }
        val lowerBetter = Economy.isLowerBetter(vehicle.unitSystem)
        val best = if (economies.isEmpty()) null else if (lowerBetter) economies.min() else economies.max()
        val worst = if (economies.isEmpty()) null else if (lowerBetter) economies.max() else economies.min()

        val compCost = computable.sumOf { it.cost }
        val costPerDistance = if (compDistance > 0.0) compCost / compDistance else null

        return VehicleStats(
            vehicle = vehicle,
            fillCount = sorted.size,
            totalDistance = totalDistance,
            totalVolume = totalVolume,
            totalSpend = totalSpend,
            averagePrice = averagePrice,
            averageEconomy = averageEconomy,
            bestEconomy = best,
            worstEconomy = worst,
            costPerDistance = costPerDistance,
            lastFill = sorted.lastOrNull(),
            computableSegments = computable,
            allSegments = segments,
            sourceFills = sorted
        )
    }
}
