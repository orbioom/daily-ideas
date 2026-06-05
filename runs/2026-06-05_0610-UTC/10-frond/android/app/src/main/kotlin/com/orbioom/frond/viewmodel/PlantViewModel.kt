package com.orbioom.frond.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.orbioom.frond.data.Plant
import com.orbioom.frond.data.PlantRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class PlantViewModel(app: Application) : AndroidViewModel(app) {

    private val repo = PlantRepository(app)
    private val _plants = MutableStateFlow<List<Plant>>(emptyList())
    val plants: StateFlow<List<Plant>> = _plants.asStateFlow()

    init {
        if (repo.hasData()) {
            _plants.value = repo.load()
        } else {
            _plants.value = seed()
            persist()
        }
    }

    /** Plants sorted by urgency (most overdue first). */
    fun sorted(now: Long): List<Plant> =
        _plants.value.sortedBy { it.daysUntilDue(now) }

    fun addPlant(name: String, species: String, intervalDays: Int) {
        val p = Plant(
            name = name.trim(),
            species = species.trim(),
            intervalDays = intervalDays.coerceAtLeast(1),
            lastWatered = System.currentTimeMillis()
        )
        _plants.value = _plants.value + p
        persist()
    }

    fun water(id: String) {
        val now = System.currentTimeMillis()
        _plants.value = _plants.value.map {
            if (it.id == id) it.copy(lastWatered = now) else it
        }
        persist()
    }

    fun delete(id: String) {
        _plants.value = _plants.value.filterNot { it.id == id }
        persist()
    }

    private fun persist() = repo.save(_plants.value)

    private fun seed(): List<Plant> {
        val now = System.currentTimeMillis()
        val day = 24L * 60 * 60 * 1000
        return listOf(
            Plant(name = "Monstera", species = "Monstera deliciosa",
                intervalDays = 7, lastWatered = now - 6 * day),
            Plant(name = "Snake plant", species = "Dracaena trifasciata",
                intervalDays = 14, lastWatered = now - 3 * day),
            Plant(name = "Basil", species = "Ocimum basilicum",
                intervalDays = 2, lastWatered = now - 3 * day),
            Plant(name = "Peace lily", species = "Spathiphyllum",
                intervalDays = 5, lastWatered = now - 1 * day)
        )
    }
}
