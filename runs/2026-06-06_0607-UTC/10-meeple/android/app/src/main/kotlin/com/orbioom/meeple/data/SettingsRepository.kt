package com.orbioom.meeple.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.orbioom.meeple.domain.ScoringType
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/** Theme choices persisted via DataStore Preferences. */
enum class ThemeMode(val title: String) {
    SYSTEM("System"), LIGHT("Light"), DARK("Dark")
}

data class MeepleSettings(
    val theme: ThemeMode = ThemeMode.SYSTEM,
    /** The scoring type pre-selected when adding a new game. */
    val defaultScoringType: ScoringType = ScoringType.HIGHEST_WINS,
    /** Pre-filled location for a new play (e.g. "Game night"). Empty = no default. */
    val defaultLocation: String = "",
    /** When on, new plays start with last session's players pre-selected (convenience). */
    val rememberLastPlayers: Boolean = true
)

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "meeple_settings")

/** Small key/value preferences store. Reads/writes are suspend + off the main thread. */
class SettingsRepository(private val context: Context) {

    private object Keys {
        val THEME = stringPreferencesKey("theme")
        val SCORING = stringPreferencesKey("default_scoring")
        val LOCATION = stringPreferencesKey("default_location")
        val REMEMBER_PLAYERS = booleanPreferencesKey("remember_last_players")
    }

    val settings: Flow<MeepleSettings> = context.dataStore.data.map { prefs ->
        MeepleSettings(
            theme = runCatching { ThemeMode.valueOf(prefs[Keys.THEME] ?: "") }
                .getOrDefault(ThemeMode.SYSTEM),
            defaultScoringType = ScoringType.fromNameOrDefault(prefs[Keys.SCORING]),
            defaultLocation = prefs[Keys.LOCATION].orEmpty(),
            rememberLastPlayers = prefs[Keys.REMEMBER_PLAYERS] ?: true
        )
    }

    suspend fun setTheme(mode: ThemeMode) {
        context.dataStore.edit { it[Keys.THEME] = mode.name }
    }

    suspend fun setDefaultScoringType(type: ScoringType) {
        context.dataStore.edit { it[Keys.SCORING] = type.name }
    }

    suspend fun setDefaultLocation(location: String) {
        context.dataStore.edit { it[Keys.LOCATION] = location }
    }

    suspend fun setRememberLastPlayers(enabled: Boolean) {
        context.dataStore.edit { it[Keys.REMEMBER_PLAYERS] = enabled }
    }
}
