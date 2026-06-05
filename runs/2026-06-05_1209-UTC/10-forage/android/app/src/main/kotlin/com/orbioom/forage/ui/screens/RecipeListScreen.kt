package com.orbioom.forage.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.clickable
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Sort
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.orbioom.forage.domain.Recipe
import com.orbioom.forage.domain.RecipeCategory
import com.orbioom.forage.domain.SortOrder
import com.orbioom.forage.ui.components.GlassCard
import com.orbioom.forage.ui.components.InkButton
import com.orbioom.forage.ui.components.LiveDot
import com.orbioom.forage.ui.components.MistBackground
import com.orbioom.forage.ui.theme.LocalBrand
import com.orbioom.forage.viewmodel.RecipeListUiState
import com.orbioom.forage.viewmodel.RecipeViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecipeListScreen(
    viewModel: RecipeViewModel,
    onOpenRecipe: (String) -> Unit,
    onAddRecipe: () -> Unit,
    onOpenSettings: () -> Unit
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val filters by viewModel.filters.collectAsStateWithLifecycle()
    val brand = LocalBrand.current

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text("Forage", fontWeight = FontWeight.Bold) },
                actions = {
                    IconButton(onClick = onOpenSettings) {
                        Icon(Icons.Filled.Settings, contentDescription = "Settings")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    titleContentColor = MaterialTheme.colorScheme.onBackground
                )
            )
        }
    ) { padding ->
        MistBackground {
            Column(modifier = Modifier.fillMaxSize().padding(padding)) {

                SearchAndFilters(
                    query = filters.query,
                    onQuery = viewModel::setQuery,
                    selectedCategory = filters.category,
                    onCategory = viewModel::setCategory,
                    favoritesOnly = filters.favoritesOnly,
                    onToggleFavorites = viewModel::toggleFavoritesOnly,
                    sort = filters.sort,
                    onSort = viewModel::setSort
                )

                Box(modifier = Modifier.fillMaxSize()) {
                    when (val s = state) {
                        is RecipeListUiState.Loading -> LoadingState()
                        is RecipeListUiState.Empty -> EmptyLibraryState(onAddRecipe)
                        is RecipeListUiState.Content -> {
                            if (s.recipes.isEmpty()) {
                                NoMatchesState(onClear = viewModel::clearFilters)
                            } else {
                                RecipeList(
                                    recipes = s.recipes,
                                    onOpen = onOpenRecipe,
                                    onFavorite = viewModel::toggleFavorite
                                )
                            }
                        }
                    }

                    InkButton(
                        text = "New recipe",
                        icon = Icons.Filled.Add,
                        onClick = onAddRecipe,
                        modifier = Modifier
                            .align(Alignment.BottomEnd)
                            .padding(16.dp)
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SearchAndFilters(
    query: String,
    onQuery: (String) -> Unit,
    selectedCategory: RecipeCategory?,
    onCategory: (RecipeCategory?) -> Unit,
    favoritesOnly: Boolean,
    onToggleFavorites: () -> Unit,
    sort: SortOrder,
    onSort: (SortOrder) -> Unit
) {
    val brand = LocalBrand.current
    Column(modifier = Modifier.padding(horizontal = 16.dp)) {
        OutlinedTextField(
            value = query,
            onValueChange = onQuery,
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
            placeholder = { Text("Search recipes, ingredients, tags") }
        )

        Spacer(Modifier.height(10.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                modifier = Modifier
                    .weight(1f)
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    label = "Favorites",
                    selected = favoritesOnly,
                    onClick = onToggleFavorites
                )
                FilterChip(
                    label = "All",
                    selected = selectedCategory == null && !favoritesOnly,
                    onClick = { onCategory(null) }
                )
                RecipeCategory.entries.forEach { cat ->
                    FilterChip(
                        label = cat.title,
                        selected = selectedCategory == cat,
                        onClick = { onCategory(if (selectedCategory == cat) null else cat) }
                    )
                }
            }
            SortMenu(sort = sort, onSort = onSort)
        }
        Spacer(Modifier.height(6.dp))
    }
}

@Composable
private fun FilterChip(label: String, selected: Boolean, onClick: () -> Unit) {
    val brand = LocalBrand.current
    val shape = RoundedCornerShape(50)
    Box(
        modifier = Modifier
            .clip(shape)
            .background(if (selected) MaterialTheme.colorScheme.primary else brand.glass)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp)
            .semantics {
                if (selected) contentDescription = "$label, selected"
            }
    ) {
        Text(
            text = label,
            color = if (selected) MaterialTheme.colorScheme.onPrimary else brand.textSecondary,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun SortMenu(sort: SortOrder, onSort: (SortOrder) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        IconButton(onClick = { expanded = true }) {
            Icon(Icons.Filled.Sort, contentDescription = "Sort recipes")
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            SortOrder.entries.forEach { order ->
                DropdownMenuItem(
                    text = { Text(order.title) },
                    onClick = { onSort(order); expanded = false },
                    trailingIcon = {
                        if (order == sort) LiveDot()
                    }
                )
            }
        }
    }
}

@Composable
private fun RecipeList(
    recipes: List<Recipe>,
    onOpen: (String) -> Unit,
    onFavorite: (String) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 92.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(recipes, key = { it.id }) { recipe ->
            RecipeCard(recipe = recipe, onOpen = { onOpen(recipe.id) }, onFavorite = { onFavorite(recipe.id) })
        }
    }
}

@Composable
private fun RecipeCard(recipe: Recipe, onOpen: () -> Unit, onFavorite: () -> Unit) {
    val brand = LocalBrand.current
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = onOpen,
        onClickLabel = "Open ${recipe.title}"
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = recipe.category.title.uppercase(),
                        style = MaterialTheme.typography.labelMedium,
                        color = brand.textTertiary,
                        fontWeight = FontWeight.SemiBold
                    )
                    if (recipe.favorite) {
                        Spacer(Modifier.width(8.dp))
                        LiveDot()
                    }
                }
                Spacer(Modifier.height(2.dp))
                Text(
                    text = recipe.title,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    text = "${recipe.totalMinutes} min · ${recipe.servings} serving${if (recipe.servings == 1) "" else "s"} · ${recipe.ingredients.size} ingredients",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            IconButton(onClick = onFavorite) {
                Icon(
                    imageVector = Icons.Filled.Favorite,
                    contentDescription = if (recipe.favorite) "Remove ${recipe.title} from favorites"
                    else "Add ${recipe.title} to favorites",
                    tint = if (recipe.favorite) brand.live else brand.textTertiary
                )
            }
        }
    }
}

@Composable
private fun LoadingState() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
    }
}

@Composable
private fun EmptyLibraryState(onAdd: () -> Unit) {
    val brand = LocalBrand.current
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            Icons.Filled.Restaurant,
            contentDescription = null,
            tint = brand.textTertiary,
            modifier = Modifier.size(56.dp)
        )
        Spacer(Modifier.height(14.dp))
        Text(
            "Your recipe box is empty",
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.SemiBold
        )
        Spacer(Modifier.height(6.dp))
        Text(
            "Add the recipes you actually cook — then scale, search and favorite them.",
            style = MaterialTheme.typography.bodyMedium,
            color = brand.textSecondary
        )
        Spacer(Modifier.height(18.dp))
        InkButton(text = "Add your first recipe", icon = Icons.Filled.Add, onClick = onAdd)
    }
}

@Composable
private fun NoMatchesState(onClear: () -> Unit) {
    val brand = LocalBrand.current
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            Icons.Filled.Search,
            contentDescription = null,
            tint = brand.textTertiary,
            modifier = Modifier.size(48.dp)
        )
        Spacer(Modifier.height(12.dp))
        Text(
            "Nothing matches",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.SemiBold
        )
        Spacer(Modifier.height(6.dp))
        Text(
            "No recipe fits this search and filter.",
            style = MaterialTheme.typography.bodyMedium,
            color = brand.textSecondary
        )
        Spacer(Modifier.height(16.dp))
        InkButton(text = "Clear filters", onClick = onClear)
    }
}
