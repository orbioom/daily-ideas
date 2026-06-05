package com.orbioom.forage.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.orbioom.forage.domain.Recipe
import com.orbioom.forage.domain.RecipeScaler
import com.orbioom.forage.ui.components.GlassCard
import com.orbioom.forage.ui.components.MistBackground
import com.orbioom.forage.ui.theme.LocalBrand
import com.orbioom.forage.viewmodel.RecipeViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecipeDetailScreen(
    recipeId: String,
    viewModel: RecipeViewModel,
    onBack: () -> Unit,
    onEdit: () -> Unit
) {
    // Observe the collection so favorite/edit changes reflect live.
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val recipe = remember(state, recipeId) { viewModel.recipe(recipeId) }
    val brand = LocalBrand.current

    var showDelete by remember { mutableStateOf(false) }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text(recipe?.title ?: "Recipe", fontWeight = FontWeight.Bold, maxLines = 1) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (recipe != null) {
                        IconButton(onClick = { viewModel.toggleFavorite(recipe.id) }) {
                            Icon(
                                Icons.Filled.Favorite,
                                contentDescription = if (recipe.favorite) "Remove from favorites" else "Add to favorites",
                                tint = if (recipe.favorite) brand.live else brand.textTertiary
                            )
                        }
                        IconButton(onClick = onEdit) {
                            Icon(Icons.Filled.Edit, contentDescription = "Edit recipe")
                        }
                        IconButton(onClick = { showDelete = true }) {
                            Icon(Icons.Filled.Delete, contentDescription = "Delete recipe")
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    titleContentColor = MaterialTheme.colorScheme.onBackground,
                    navigationIconContentColor = MaterialTheme.colorScheme.onBackground,
                    actionIconContentColor = MaterialTheme.colorScheme.onBackground
                )
            )
        }
    ) { padding ->
        MistBackground {
            if (recipe == null) {
                MissingRecipe(onBack = onBack, modifier = Modifier.padding(padding))
            } else {
                RecipeBody(recipe = recipe, modifier = Modifier.padding(padding))
            }
        }
    }

    if (showDelete && recipe != null) {
        AlertDialog(
            onDismissRequest = { showDelete = false },
            title = { Text("Delete this recipe?") },
            text = { Text("“${recipe.title}” will be permanently removed. This can't be undone.") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.delete(recipe.id)
                    showDelete = false
                    onBack()
                }) { Text("Delete") }
            },
            dismissButton = {
                TextButton(onClick = { showDelete = false }) { Text("Cancel") }
            }
        )
    }
}

@Composable
private fun RecipeBody(recipe: Recipe, modifier: Modifier = Modifier) {
    val brand = LocalBrand.current
    var servings by remember(recipe.id) { mutableStateOf(recipe.servings.coerceAtLeast(1)) }
    val checkedIngredients = remember(recipe.id) { mutableStateMapOf<Int, Boolean>() }
    val checkedSteps = remember(recipe.id) { mutableStateMapOf<Int, Boolean>() }

    val scaled = remember(recipe, servings) {
        RecipeScaler.scaledIngredients(recipe, servings)
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        if (recipe.description.isNotBlank()) {
            Text(
                recipe.description,
                style = MaterialTheme.typography.bodyLarge,
                color = brand.textSecondary
            )
        }

        // Quick facts
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Fact(label = "Prep", value = "${recipe.prepMinutes}m", modifier = Modifier.weight(1f))
            Fact(label = "Cook", value = "${recipe.cookMinutes}m", modifier = Modifier.weight(1f))
            Fact(label = "Total", value = "${recipe.totalMinutes}m", modifier = Modifier.weight(1f))
        }

        // Serving scaler — the heart of the box.
        GlassCard(modifier = Modifier.fillMaxWidth()) {
            Column {
                Text(
                    "Scale the recipe",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(Modifier.height(10.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Stepper(
                        onMinus = { if (servings > 1) servings-- },
                        onPlus = { if (servings < 99) servings++ },
                        minusEnabled = servings > 1,
                        plusEnabled = servings < 99
                    )
                    Spacer(Modifier.width(16.dp))
                    Column {
                        Text(
                            "$servings serving${if (servings == 1) "" else "s"}",
                            style = MaterialTheme.typography.titleLarge,
                            color = MaterialTheme.colorScheme.onBackground,
                            fontWeight = FontWeight.Bold
                        )
                        if (servings != recipe.servings) {
                            Text(
                                "from ${recipe.servings}",
                                style = MaterialTheme.typography.labelMedium,
                                color = brand.textTertiary
                            )
                        }
                    }
                }
            }
        }

        // Ingredients
        SectionTitle("Ingredients")
        GlassCard(modifier = Modifier.fillMaxWidth()) {
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                if (scaled.isEmpty()) {
                    Text("No ingredients listed.", color = brand.textTertiary,
                        style = MaterialTheme.typography.bodyMedium)
                }
                scaled.forEachIndexed { index, ing ->
                    val checked = checkedIngredients[index] == true
                    CheckRow(
                        text = ing.line.ifBlank { ing.name },
                        checked = checked,
                        onToggle = { checkedIngredients[index] = !checked }
                    )
                }
            }
        }

        // Steps
        SectionTitle("Method")
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            if (recipe.steps.isEmpty()) {
                GlassCard(modifier = Modifier.fillMaxWidth()) {
                    Text("No method steps yet.", color = brand.textTertiary,
                        style = MaterialTheme.typography.bodyMedium)
                }
            }
            recipe.steps.forEachIndexed { index, step ->
                val done = checkedSteps[index] == true
                GlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    onClick = { checkedSteps[index] = !done },
                    onClickLabel = if (done) "Mark step ${index + 1} not done" else "Mark step ${index + 1} done"
                ) {
                    Row(verticalAlignment = Alignment.Top) {
                        StepNumber(index + 1, done)
                        Spacer(Modifier.width(12.dp))
                        Text(
                            text = step,
                            style = MaterialTheme.typography.bodyLarge,
                            color = if (done) brand.textTertiary else MaterialTheme.colorScheme.onBackground
                        )
                    }
                }
            }
        }

        if (recipe.tags.isNotEmpty()) {
            SectionTitle("Tags")
            Text(
                recipe.tags.joinToString(" · "),
                style = MaterialTheme.typography.bodyMedium,
                color = brand.textSecondary
            )
        }
        Spacer(Modifier.height(8.dp))
    }
}

@Composable
private fun Fact(label: String, value: String, modifier: Modifier = Modifier) {
    val brand = LocalBrand.current
    GlassCard(modifier = modifier) {
        Column(horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth()) {
            Text(value, style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onBackground, fontWeight = FontWeight.Bold)
            Text(label, style = MaterialTheme.typography.labelMedium, color = brand.textTertiary)
        }
    }
}

@Composable
private fun Stepper(
    onMinus: () -> Unit,
    onPlus: () -> Unit,
    minusEnabled: Boolean,
    plusEnabled: Boolean
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        StepperButton(Icons.Filled.Remove, "Fewer servings", minusEnabled, onMinus)
        StepperButton(Icons.Filled.Add, "More servings", plusEnabled, onPlus)
    }
}

@Composable
private fun StepperButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    description: String,
    enabled: Boolean,
    onClick: () -> Unit
) {
    val brand = LocalBrand.current
    Box(
        modifier = Modifier
            .size(44.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(brand.glass)
            .clickable(enabled = enabled, role = Role.Button, onClickLabel = description, onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            icon,
            contentDescription = description,
            tint = if (enabled) MaterialTheme.colorScheme.onBackground else brand.textTertiary
        )
    }
}

@Composable
private fun CheckRow(text: String, checked: Boolean, onToggle: () -> Unit) {
    val brand = LocalBrand.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .clickable(role = Role.Checkbox, onClick = onToggle)
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = if (checked) Icons.Filled.CheckCircle else Icons.Filled.RadioButtonUnchecked,
            contentDescription = if (checked) "$text, checked" else "$text, not checked",
            tint = if (checked) brand.live else brand.textTertiary,
            modifier = Modifier.size(22.dp)
        )
        Spacer(Modifier.width(12.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.bodyLarge,
            color = if (checked) brand.textTertiary else MaterialTheme.colorScheme.onBackground
        )
    }
}

@Composable
private fun StepNumber(number: Int, done: Boolean) {
    val brand = LocalBrand.current
    Box(
        modifier = Modifier
            .size(26.dp)
            .clip(RoundedCornerShape(50))
            .background(if (done) brand.live else MaterialTheme.colorScheme.primary),
        contentAlignment = Alignment.Center
    ) {
        Text(
            number.toString(),
            color = MaterialTheme.colorScheme.onPrimary,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleMedium,
        color = MaterialTheme.colorScheme.onBackground,
        fontWeight = FontWeight.SemiBold
    )
}

@Composable
private fun MissingRecipe(onBack: () -> Unit, modifier: Modifier = Modifier) {
    val brand = LocalBrand.current
    Column(
        modifier = modifier.fillMaxSize().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            "This recipe is no longer here",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.SemiBold
        )
        Spacer(Modifier.height(8.dp))
        Text(
            "It may have been deleted.",
            style = MaterialTheme.typography.bodyMedium,
            color = brand.textSecondary
        )
        Spacer(Modifier.height(16.dp))
        TextButton(onClick = onBack) { Text("Go back") }
    }
}
