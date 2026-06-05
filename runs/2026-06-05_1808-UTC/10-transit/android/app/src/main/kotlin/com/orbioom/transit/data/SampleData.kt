package com.orbioom.transit.data

import com.orbioom.transit.domain.FillUp
import com.orbioom.transit.domain.FuelType
import com.orbioom.transit.domain.UnitSystem
import com.orbioom.transit.domain.Vehicle

/**
 * A real, populated first launch: one well-used metric hatchback with a year of fills
 * (mostly full tanks, a couple of partials and one flagged missed fill so the economy
 * engine has something honest to chew on), plus a second US-unit vehicle for contrast.
 */
object SampleData {

    data class Seed(val vehicles: List<Vehicle>, val fills: List<FillUp>)

    private const val DAY = 86_400_000L

    fun starter(): Seed {
        // Anchor the timeline a year back from a fixed base so the seed is deterministic.
        val base = 1_717_000_000_000L - 365L * DAY

        val golf = Vehicle(
            id = "veh-golf",
            name = "The Golf",
            makeModel = "VW Golf 1.5 TSI",
            unitSystem = UnitSystem.METRIC,
            fuelType = FuelType.PETROL,
            tankCapacity = 50.0,
            notes = "Daily driver. Mixed town and motorway.",
            createdAt = base
        )
        val truck = Vehicle(
            id = "veh-truck",
            name = "Weekend Truck",
            makeModel = "Ford F-150",
            unitSystem = UnitSystem.US,
            fuelType = FuelType.PETROL,
            tankCapacity = 26.0,
            notes = "Trailer and trips only.",
            createdAt = base + 10 * DAY
        )

        val golfFills = mutableListOf<FillUp>()
        var odo = 41_200.0
        var day = base
        // ~12 fills, every ~21 days, ~620 km between fills, ~5.7 L/100km baseline with drift.
        val price = doubleArrayOf(1.62, 1.66, 1.71, 1.69, 1.74, 1.78, 1.81, 1.77, 1.73, 1.70, 1.68, 1.72)
        val distances = doubleArrayOf(600.0, 640.0, 590.0, 0.0, 610.0, 660.0, 580.0, 620.0, 605.0, 630.0, 0.0, 615.0)
        // index 3 and 10 are partial top-ups (their distance is absorbed by the next full segment)
        for (i in 0 until 12) {
            val full = i != 3 && i != 10
            val dist = distances[i]
            odo += dist
            // Litres roughly track distance at ~5.5 L/100km; partials are small fixed top-ups.
            val volume = if (full) (dist / 100.0 * (5.45 + (i % 5) * 0.12)) else 14.0
            val p = price[i]
            golfFills.add(
                FillUp(
                    id = "golf-$i",
                    vehicleId = golf.id,
                    date = day,
                    odometer = odo,
                    volume = round1(volume),
                    pricePerUnit = p,
                    totalCost = round2(volume * p),
                    isFullTank = full,
                    isMissedPrevious = i == 6, // honest gap: one segment can't be trusted
                    station = stations[i % stations.size],
                    notes = if (i == 0) "First logged fill." else ""
                )
            )
            day += 21 * DAY
        }

        val truckFills = mutableListOf<FillUp>()
        var truckOdo = 88_400.0
        var tday = base + 12 * DAY
        val tprice = doubleArrayOf(3.41, 3.55, 3.62, 3.49, 3.58, 3.66)
        val tmiles = doubleArrayOf(310.0, 330.0, 290.0, 340.0, 300.0, 320.0)
        for (i in 0 until 6) {
            truckOdo += tmiles[i]
            val gal = tmiles[i] / (17.5 + (i % 3) * 0.6) // ~17–18 mpg
            val p = tprice[i]
            truckFills.add(
                FillUp(
                    id = "truck-$i",
                    vehicleId = truck.id,
                    date = tday,
                    odometer = round1(truckOdo),
                    volume = round1(gal),
                    pricePerUnit = p,
                    totalCost = round2(gal * p),
                    isFullTank = true,
                    isMissedPrevious = false,
                    station = stations[(i + 2) % stations.size],
                    notes = ""
                )
            )
            tday += 35 * DAY
        }

        return Seed(
            vehicles = listOf(golf, truck),
            fills = golfFills + truckFills
        )
    }

    private val stations = listOf("Shell", "BP", "Esso", "Tesco", "Costco", "Local")

    private fun round1(v: Double) = Math.round(v * 10.0) / 10.0
    private fun round2(v: Double) = Math.round(v * 100.0) / 100.0
}
