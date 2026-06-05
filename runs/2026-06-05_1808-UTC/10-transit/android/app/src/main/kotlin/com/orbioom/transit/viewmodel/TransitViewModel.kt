package com.orbioom.transit.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.orbioom.transit.data.TransitRepository
import com.orbioom.transit.domain.FillUp
import com.orbioom.transit.domain.Stats
import com.orbioom.transit.domain.Vehicle
import com.orbioom.transit.domain.VehicleStats
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn

/** A vehicle paired with its rolled-up stats, for the garage list. */
data class VehicleCard(val vehicle: Vehicle, val stats: VehicleStats)

/** Immutable UI state for the garage (home) screen. */
sealed interface GarageUiState {
    data object Loading : GarageUiState
    data object Empty : GarageUiState
    data class Content(val cards: List<VehicleCard>) : GarageUiState
}

/** Cross-vehicle records for the Insights screen. */
data class InsightsState(
    val totalSpend: Double,
    val totalDistance: Double,
    val totalVolume: Double,
    val vehicleCount: Int,
    val fillCount: Int,
    val mostEfficient: VehicleStats?,
    val leastEfficient: VehicleStats?,
    val cheapestPerDistance: VehicleStats?,
    val perVehicle: List<VehicleStats>
)

class TransitViewModel(app: Application) : AndroidViewModel(app) {

    private val repository = TransitRepository(app.applicationContext, viewModelScope)

    val garageState: StateFlow<GarageUiState> =
        combine(repository.vehicles, repository.fills, repository.loaded) { vehicles, fills, loaded ->
            when {
                !loaded -> GarageUiState.Loading
                vehicles.isEmpty() -> GarageUiState.Empty
                else -> GarageUiState.Content(
                    cards = vehicles
                        .sortedBy { it.createdAt }
                        .map { v -> VehicleCard(v, Stats.forVehicle(v, fills.filter { it.vehicleId == v.id })) }
                )
            }
        }.stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = GarageUiState.Loading
        )

    val loaded: StateFlow<Boolean> = repository.loaded

    val insights: StateFlow<InsightsState?> =
        combine(repository.vehicles, repository.fills, repository.loaded) { vehicles, fills, loaded ->
            if (!loaded || vehicles.isEmpty()) return@combine null
            val perVehicle = vehicles.map { v -> Stats.forVehicle(v, fills.filter { it.vehicleId == v.id }) }
            val withEconomy = perVehicle.filter { it.averageEconomy != null }
            InsightsState(
                totalSpend = perVehicle.sumOf { it.totalSpend },
                totalDistance = perVehicle.sumOf { it.totalDistance },
                totalVolume = perVehicle.sumOf { it.totalVolume },
                vehicleCount = vehicles.size,
                fillCount = perVehicle.sumOf { it.fillCount },
                mostEfficient = bestByEconomy(withEconomy, mostEfficient = true),
                leastEfficient = bestByEconomy(withEconomy, mostEfficient = false),
                cheapestPerDistance = perVehicle
                    .filter { it.costPerDistance != null }
                    .minByOrNull { it.costPerDistance!! },
                perVehicle = perVehicle
            )
        }.stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = null
        )

    /**
     * Compare across vehicles even when unit systems differ. We normalize each vehicle's
     * average economy to L/100km equivalent so "most efficient" is meaningful fleet-wide:
     * metric is already L/100km; mpg converts via 235.215 / mpg.
     */
    private fun bestByEconomy(list: List<VehicleStats>, mostEfficient: Boolean): VehicleStats? {
        if (list.isEmpty()) return null
        fun normalized(s: VehicleStats): Double {
            val e = s.averageEconomy ?: return Double.MAX_VALUE
            return if (s.vehicle.unitSystem == com.orbioom.transit.domain.UnitSystem.METRIC) e
            else if (e > 0) 235.215 / e else Double.MAX_VALUE
        }
        // Lower normalized L/100km is more efficient.
        return if (mostEfficient) list.minByOrNull { normalized(it) }
        else list.maxByOrNull { normalized(it) }
    }

    // ---- Per-vehicle reads for detail/edit screens ----

    fun vehicle(id: String): Vehicle? = repository.vehicle(id)
    fun fill(id: String): FillUp? = repository.fill(id)
    fun fillsFor(vehicleId: String): List<FillUp> = repository.fillsFor(vehicleId)

    /**
     * A live stats stream for one vehicle, recomputed whenever its vehicle or fills change.
     * Emits null once the vehicle no longer exists (e.g. just deleted) so the detail screen
     * can pop back cleanly instead of showing stale data.
     */
    fun vehicleStatsFlow(id: String): StateFlow<VehicleStats?> =
        combine(repository.vehicles, repository.fills) { vehicles, fills ->
            val v = vehicles.firstOrNull { it.id == id } ?: return@combine null
            Stats.forVehicle(v, fills.filter { it.vehicleId == id })
        }.stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = vehicle(id)?.let { Stats.forVehicle(it, repository.fillsFor(id)) }
        )

    // ---- Intents ----

    fun saveVehicle(vehicle: Vehicle) = repository.upsertVehicle(vehicle)
    fun deleteVehicle(id: String) = repository.deleteVehicle(id)
    fun saveFill(fill: FillUp) = repository.upsertFill(fill)
    fun deleteFill(id: String) = repository.deleteFill(id)
    fun resetToSample() = repository.resetToSample()
    fun clearAll() = repository.clearAll()
}
