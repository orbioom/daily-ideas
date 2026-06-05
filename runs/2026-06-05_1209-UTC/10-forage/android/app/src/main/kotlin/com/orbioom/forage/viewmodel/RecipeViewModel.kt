package com.orbioom.forage.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.orbioom.forage.data.RecipeRepository
import com.orbioom.forage.domain.Recipe
import com.orbioom.forage.domain.RecipeCategory
import com.orbioom.forage.domain.SortOrder
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn

/** Immutable UI state for the recipe list. */
sealed interface RecipeListUiState {
    data object Loading : RecipeListUiState
    data class Empty(val cleared: Boolean) : RecipeListUiState
    data class Content(
        val recipes: List<Recipe>,
        val totalCount: Int,
        val isFiltered: Boolean
    ) : RecipeListUiState
}

data class ListFilters(
    val query: String = "",
    val category: RecipeCategory? = null,
    val favoritesOnly: Boolean = false,
    val sort: SortOrder = SortOrder.RECENT
)

class RecipeViewModel(app: Application) : AndroidViewModel(app) {

    private val repository = RecipeRepository(app.applicationContext, viewModelScope)

    private val _filters = MutableStateFlow(ListFilters())
    val filters: StateFlow<ListFilters> = _filters.asStateFlow()

    val uiState: StateFlow<RecipeListUiState> =
        combine(repository.recipes, repository.loaded, _filters) { all, loaded, filters ->
            buildState(all, loaded, filters)
        }.stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = RecipeListUiState.Loading
        )

    private fun buildState(
        all: List<Recipe>,
        loaded: Boolean,
        filters: ListFilters
    ): RecipeListUiState {
        if (!loaded) return RecipeListUiState.Loading
        if (all.isEmpty()) return RecipeListUiState.Empty(cleared = true)

        val isFiltered = filters.query.isNotBlank() ||
            filters.category != null || filters.favoritesOnly
        val visible = applyFilters(all, filters)
        return RecipeListUiState.Content(
            recipes = visible,
            totalCount = all.size,
            isFiltered = isFiltered
        )
    }

    private fun applyFilters(all: List<Recipe>, f: ListFilters): List<Recipe> {
        val q = f.query.trim().lowercase()
        val filtered = all.filter { r ->
            if (f.favoritesOnly && !r.favorite) return@filter false
            if (f.category != null && r.category != f.category) return@filter false
            if (q.isEmpty()) return@filter true
            r.title.lowercase().contains(q) ||
                r.description.lowercase().contains(q) ||
                r.tags.any { it.lowercase().contains(q) } ||
                r.ingredients.any { it.name.lowercase().contains(q) }
        }
        return when (f.sort) {
            SortOrder.RECENT -> filtered.sortedByDescending { it.createdAt }
            SortOrder.TITLE -> filtered.sortedBy { it.title.lowercase() }
            SortOrder.TIME -> filtered.sortedBy { it.totalMinutes }
            SortOrder.CATEGORY -> filtered.sortedWith(
                compareBy({ it.category.ordinal }, { it.title.lowercase() })
            )
        }
    }

    // Filter intents
    fun setQuery(value: String) { _filters.value = _filters.value.copy(query = value) }
    fun setCategory(category: RecipeCategory?) {
        _filters.value = _filters.value.copy(category = category)
    }
    fun toggleFavoritesOnly() {
        _filters.value = _filters.value.copy(favoritesOnly = !_filters.value.favoritesOnly)
    }
    fun setSort(order: SortOrder) { _filters.value = _filters.value.copy(sort = order) }
    fun clearFilters() {
        _filters.value = ListFilters(sort = _filters.value.sort)
    }
    /** Apply the persisted default sort once on first load. */
    fun applyDefaultSort(order: SortOrder) { _filters.value = _filters.value.copy(sort = order) }

    // Data intents
    fun recipe(id: String): Recipe? = repository.recipe(id)
    fun save(recipe: Recipe) = repository.upsert(recipe)
    fun delete(id: String) = repository.delete(id)
    fun toggleFavorite(id: String) = repository.toggleFavorite(id)
    fun resetToSample() = repository.resetToSample()
    fun clearAll() = repository.clearAll()
}
