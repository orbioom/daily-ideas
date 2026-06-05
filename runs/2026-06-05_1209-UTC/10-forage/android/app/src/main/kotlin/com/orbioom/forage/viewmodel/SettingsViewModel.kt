package com.orbioom.forage.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.orbioom.forage.data.ForageSettings
import com.orbioom.forage.data.SettingsRepository
import com.orbioom.forage.data.ThemeMode
import com.orbioom.forage.domain.SortOrder
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class SettingsViewModel(app: Application) : AndroidViewModel(app) {

    private val repository = SettingsRepository(app.applicationContext)

    val settings: StateFlow<ForageSettings> = repository.settings.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = ForageSettings()
    )

    fun setTheme(mode: ThemeMode) {
        viewModelScope.launch { repository.setTheme(mode) }
    }

    fun setSort(order: SortOrder) {
        viewModelScope.launch { repository.setSort(order) }
    }
}
