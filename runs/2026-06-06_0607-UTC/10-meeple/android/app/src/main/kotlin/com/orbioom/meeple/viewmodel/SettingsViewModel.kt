package com.orbioom.meeple.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.orbioom.meeple.data.MeepleSettings
import com.orbioom.meeple.data.SettingsRepository
import com.orbioom.meeple.data.ThemeMode
import com.orbioom.meeple.domain.ScoringType
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class SettingsViewModel(app: Application) : AndroidViewModel(app) {

    private val repository = SettingsRepository(app.applicationContext)

    val settings: StateFlow<MeepleSettings> = repository.settings.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = MeepleSettings()
    )

    fun setTheme(mode: ThemeMode) {
        viewModelScope.launch { repository.setTheme(mode) }
    }

    fun setDefaultScoringType(type: ScoringType) {
        viewModelScope.launch { repository.setDefaultScoringType(type) }
    }

    fun setDefaultLocation(location: String) {
        viewModelScope.launch { repository.setDefaultLocation(location) }
    }

    fun setRememberLastPlayers(enabled: Boolean) {
        viewModelScope.launch { repository.setRememberLastPlayers(enabled) }
    }
}
