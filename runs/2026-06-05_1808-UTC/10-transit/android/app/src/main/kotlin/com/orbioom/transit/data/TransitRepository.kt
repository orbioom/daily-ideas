package com.orbioom.transit.data

import android.content.Context
import com.orbioom.transit.domain.FillUp
import com.orbioom.transit.domain.Vehicle
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File

/** The whole log, serialized as one JSON document in app-internal storage. */
@Serializable
private data class TransitData(
    val vehicles: List<Vehicle> = emptyList(),
    val fills: List<FillUp> = emptyList()
)

/**
 * Local-first store for vehicles and their fill-ups. Persists everything as a single JSON
 * file (no Room, no annotation processors). All disk work runs on [Dispatchers.IO]; the UI
 * observes [vehicles] and [fills] as immutable state and reacts to [loaded].
 */
class TransitRepository(
    context: Context,
    private val scope: CoroutineScope
) {
    private val file = File(context.filesDir, "transit_log.json")
    private val mutex = Mutex()
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        encodeDefaults = true
        prettyPrint = true
    }

    private val _vehicles = MutableStateFlow<List<Vehicle>>(emptyList())
    val vehicles: StateFlow<List<Vehicle>> = _vehicles.asStateFlow()

    private val _fills = MutableStateFlow<List<FillUp>>(emptyList())
    val fills: StateFlow<List<FillUp>> = _fills.asStateFlow()

    private val _loaded = MutableStateFlow(false)
    val loaded: StateFlow<Boolean> = _loaded.asStateFlow()

    init {
        scope.launch { load() }
    }

    private suspend fun load() = withContext(Dispatchers.IO) {
        val data = mutex.withLock { readFromDisk() }
        _vehicles.value = data.vehicles
        _fills.value = data.fills
        _loaded.value = true
    }

    private fun readFromDisk(): TransitData {
        if (!file.exists()) {
            // First ever launch — seed a real, populated log.
            val seed = SampleData.starter()
            val data = TransitData(seed.vehicles, seed.fills)
            runCatching { file.writeText(json.encodeToString(data)) }
            return data
        }
        return runCatching {
            val text = file.readText()
            if (text.isBlank()) TransitData() else json.decodeFromString<TransitData>(text)
        }.getOrElse {
            // Corrupt/partial file: don't crash — start from a clean, empty log.
            TransitData()
        }
    }

    private suspend fun persist() = withContext(Dispatchers.IO) {
        val snapshot = TransitData(_vehicles.value, _fills.value)
        mutex.withLock {
            runCatching { file.writeText(json.encodeToString(snapshot)) }
        }
    }

    private fun save() { scope.launch { persist() } }

    // ---- Vehicles ----

    fun vehicle(id: String): Vehicle? = _vehicles.value.firstOrNull { it.id == id }

    fun upsertVehicle(vehicle: Vehicle) {
        val current = _vehicles.value
        val idx = current.indexOfFirst { it.id == vehicle.id }
        _vehicles.value = if (idx >= 0) {
            current.toMutableList().also { it[idx] = vehicle }
        } else current + vehicle
        save()
    }

    fun deleteVehicle(id: String) {
        _vehicles.value = _vehicles.value.filterNot { it.id == id }
        _fills.value = _fills.value.filterNot { it.vehicleId == id }
        save()
    }

    // ---- Fill-ups ----

    fun fillsFor(vehicleId: String): List<FillUp> =
        _fills.value.filter { it.vehicleId == vehicleId }

    fun fill(id: String): FillUp? = _fills.value.firstOrNull { it.id == id }

    fun upsertFill(fill: FillUp) {
        val current = _fills.value
        val idx = current.indexOfFirst { it.id == fill.id }
        _fills.value = if (idx >= 0) {
            current.toMutableList().also { it[idx] = fill }
        } else current + fill
        save()
    }

    fun deleteFill(id: String) {
        _fills.value = _fills.value.filterNot { it.id == id }
        save()
    }

    // ---- Bulk ----

    fun resetToSample() {
        val seed = SampleData.starter()
        _vehicles.value = seed.vehicles
        _fills.value = seed.fills
        save()
    }

    fun clearAll() {
        _vehicles.value = emptyList()
        _fills.value = emptyList()
        save()
    }
}
