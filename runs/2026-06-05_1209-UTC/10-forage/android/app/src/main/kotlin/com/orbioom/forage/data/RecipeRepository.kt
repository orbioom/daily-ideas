package com.orbioom.forage.data

import android.content.Context
import com.orbioom.forage.domain.Recipe
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File

/**
 * Local-first recipe store. Persists the whole collection as a JSON file in app-internal
 * storage (no Room, no annotation processors). All disk work runs on [Dispatchers.IO];
 * the UI observes [recipes] as immutable state.
 */
class RecipeRepository(
    context: Context,
    private val scope: CoroutineScope
) {
    private val file = File(context.filesDir, "recipes.json")
    private val mutex = Mutex()
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        encodeDefaults = true
        prettyPrint = true
    }

    private val _recipes = MutableStateFlow<List<Recipe>>(emptyList())
    val recipes: StateFlow<List<Recipe>> = _recipes.asStateFlow()

    private val _loaded = MutableStateFlow(false)
    val loaded: StateFlow<Boolean> = _loaded.asStateFlow()

    init {
        scope.launch { load() }
    }

    private suspend fun load() = withContext(Dispatchers.IO) {
        val list = mutex.withLock { readFromDisk() }
        _recipes.value = list
        _loaded.value = true
    }

    private fun readFromDisk(): List<Recipe> {
        if (!file.exists()) {
            // First ever launch — seed a real, populated recipe box.
            val seed = SampleRecipes.starter()
            runCatching { file.writeText(json.encodeToString(seed)) }
            return seed
        }
        return runCatching {
            val text = file.readText()
            if (text.isBlank()) emptyList() else json.decodeFromString<List<Recipe>>(text)
        }.getOrElse {
            // Corrupt/partial file: don't crash — start from a clean, empty box.
            emptyList()
        }
    }

    private suspend fun persist(list: List<Recipe>) = withContext(Dispatchers.IO) {
        mutex.withLock {
            runCatching { file.writeText(json.encodeToString(list)) }
        }
    }

    fun recipe(id: String): Recipe? = _recipes.value.firstOrNull { it.id == id }

    fun upsert(recipe: Recipe) {
        val current = _recipes.value
        val idx = current.indexOfFirst { it.id == recipe.id }
        val updated = if (idx >= 0) {
            current.toMutableList().also { it[idx] = recipe }
        } else {
            current + recipe
        }
        _recipes.value = updated
        scope.launch { persist(updated) }
    }

    fun delete(id: String) {
        val updated = _recipes.value.filterNot { it.id == id }
        _recipes.value = updated
        scope.launch { persist(updated) }
    }

    fun toggleFavorite(id: String) {
        val current = _recipes.value
        val idx = current.indexOfFirst { it.id == id }
        if (idx < 0) return
        val updated = current.toMutableList()
        updated[idx] = updated[idx].copy(favorite = !updated[idx].favorite)
        _recipes.value = updated
        scope.launch { persist(updated) }
    }

    fun resetToSample() {
        val seed = SampleRecipes.starter()
        _recipes.value = seed
        scope.launch { persist(seed) }
    }

    fun clearAll() {
        _recipes.value = emptyList()
        scope.launch { persist(emptyList()) }
    }
}
