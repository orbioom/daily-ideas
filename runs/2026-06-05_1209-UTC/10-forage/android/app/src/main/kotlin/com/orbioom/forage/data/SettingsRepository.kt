package com.orbioom.forage.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.orbioom.forage.domain.SortOrder
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/** Theme choices persisted via DataStore Preferences. */
enum class ThemeMode(val title: String) {
    SYSTEM("System"), LIGHT("Light"), DARK("Dark")
}

data class ForageSettings(
    val theme: ThemeMode = ThemeMode.SYSTEM,
    val sort: SortOrder = SortOrder.RECENT
)

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "forage_settings")

/** Small key/value preferences store. Reads/writes are suspend + off the main thread. */
class SettingsRepository(private val context: Context) {

    private object Keys {
        val THEME = stringPreferencesKey("theme")
        val SORT = stringPreferencesKey("sort")
    }

    val settings: Flow<ForageSettings> = context.dataStore.data.map { prefs ->
        ForageSettings(
            theme = runCatching { ThemeMode.valueOf(prefs[Keys.THEME] ?: "") }
                .getOrDefault(ThemeMode.SYSTEM),
            sort = runCatching { SortOrder.valueOf(prefs[Keys.SORT] ?: "") }
                .getOrDefault(SortOrder.RECENT)
        )
    }

    suspend fun setTheme(mode: ThemeMode) {
        context.dataStore.edit { it[Keys.THEME] = mode.name }
    }

    suspend fun setSort(order: SortOrder) {
        context.dataStore.edit { it[Keys.SORT] = order.name }
    }
}
