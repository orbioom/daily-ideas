package com.orbioom.transit.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.orbioom.transit.data.SettingsRepository
import com.orbioom.transit.data.ThemeMode
import com.orbioom.transit.data.TransitSettings
import com.orbioom.transit.domain.UnitSystem
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class SettingsViewModel(app: Application) : AndroidViewModel(app) {

    private val repository = SettingsRepository(app.applicationContext)

    val settings: StateFlow<TransitSettings> = repository.settings.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = TransitSettings()
    )

    fun setTheme(mode: ThemeMode) {
        viewModelScope.launch { repository.setTheme(mode) }
    }

    fun setDefaultUnitSystem(system: UnitSystem) {
        viewModelScope.launch { repository.setDefaultUnitSystem(system) }
    }

    fun setDefaultVehicle(id: String) {
        viewModelScope.launch { repository.setDefaultVehicle(id) }
    }
}
