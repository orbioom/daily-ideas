package com.orbioom.transit.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.orbioom.transit.domain.UnitSystem
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/** Theme choices persisted via DataStore Preferences. */
enum class ThemeMode(val title: String) {
    SYSTEM("System"), LIGHT("Light"), DARK("Dark")
}

data class TransitSettings(
    val theme: ThemeMode = ThemeMode.SYSTEM,
    val defaultUnitSystem: UnitSystem = UnitSystem.METRIC,
    /** Empty means "no default vehicle pinned"; the Garage opens normally. */
    val defaultVehicleId: String = ""
)

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "transit_settings")

/** Small key/value preferences store. Reads/writes are suspend + off the main thread. */
class SettingsRepository(private val context: Context) {

    private object Keys {
        val THEME = stringPreferencesKey("theme")
        val UNIT = stringPreferencesKey("unit_system")
        val DEFAULT_VEHICLE = stringPreferencesKey("default_vehicle")
    }

    val settings: Flow<TransitSettings> = context.dataStore.data.map { prefs ->
        TransitSettings(
            theme = runCatching { ThemeMode.valueOf(prefs[Keys.THEME] ?: "") }
                .getOrDefault(ThemeMode.SYSTEM),
            defaultUnitSystem = UnitSystem.fromNameOrDefault(prefs[Keys.UNIT]),
            defaultVehicleId = prefs[Keys.DEFAULT_VEHICLE].orEmpty()
        )
    }

    suspend fun setTheme(mode: ThemeMode) {
        context.dataStore.edit { it[Keys.THEME] = mode.name }
    }

    suspend fun setDefaultUnitSystem(system: UnitSystem) {
        context.dataStore.edit { it[Keys.UNIT] = system.name }
    }

    suspend fun setDefaultVehicle(id: String) {
        context.dataStore.edit { it[Keys.DEFAULT_VEHICLE] = id }
    }
}
