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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.orbioom.forage.domain.Ingredient
import com.orbioom.forage.domain.Recipe
import com.orbioom.forage.domain.RecipeCategory
import com.orbioom.forage.ui.components.GlassCard
import com.orbioom.forage.ui.components.InkButton
import com.orbioom.forage.ui.components.MistBackground
import com.orbioom.forage.ui.theme.LocalBrand
import com.orbioom.forage.viewmodel.RecipeViewModel
import java.util.UUID

private class IngredientDraft(name: String = "", quantity: String = "", unit: String = "") {
    var name by mutableStateOf(name)
    var quantity by mutableStateOf(quantity)
    var unit by mutableStateOf(unit)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecipeEditScreen(
    recipeId: String?,
    viewModel: RecipeViewModel,
    onDone: () -> Unit,
    onCancel: () -> Unit
) {
    val brand = LocalBrand.current
    val existing = remember(recipeId) { recipeId?.let { viewModel.recipe(it) } }
    val isEditing = existing != null

    var title by remember { mutableStateOf(existing?.title ?: "") }
    var description by remember { mutableStateOf(existing?.description ?: "") }
    var category by remember { mutableStateOf(existing?.category ?: RecipeCategory.MAIN) }
    var servings by remember { mutableStateOf((existing?.servings ?: 2).toString()) }
    var prep by remember { mutableStateOf((existing?.prepMinutes ?: 0).toString()) }
    var cook by remember { mutableStateOf((existing?.cookMinutes ?: 0).toString()) }
    var tags by remember { mutableStateOf(existing?.tags?.joinToString(", ") ?: "") }

    val ingredients = remember {
        mutableStateListOf<IngredientDraft>().apply {
            existing?.ingredients?.forEach {
                add(IngredientDraft(it.name, if (it.quantity > 0) trimNumber(it.quantity) else "", it.unit))
            }
            if (isEmpty()) add(IngredientDraft())
        }
    }
    val steps = remember {
        mutableStateListOf<String>().apply {
            existing?.steps?.forEach { add(it) }
            if (isEmpty()) add("")
        }
    }

    var titleError by remember { mutableStateOf<String?>(null) }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text(if (isEditing) "Edit recipe" else "New recipe", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onCancel) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Cancel")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    titleContentColor = MaterialTheme.colorScheme.onBackground,
                    navigationIconContentColor = MaterialTheme.colorScheme.onBackground
                )
            )
        }
    ) { padding ->
        MistBackground {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it; titleError = null },
                    label = { Text("Title") },
                    singleLine = true,
                    isError = titleError != null,
                    supportingText = { titleError?.let { Text(it) } },
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("Description") },
                    modifier = Modifier.fillMaxWidth()
                )

                // Category chips
                Text("Category", style = MaterialTheme.typography.labelLarge, color = brand.textSecondary)
                Row(
                    modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    RecipeCategory.entries.forEach { cat ->
                        CategorySelectChip(
                            label = cat.title,
                            selected = category == cat,
                            onClick = { category = cat }
                        )
                    }
                }

                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    NumberField("Servings", servings, { servings = sanitizeInt(it) }, Modifier.weight(1f))
                    NumberField("Prep (min)", prep, { prep = sanitizeInt(it) }, Modifier.weight(1f))
                    NumberField("Cook (min)", cook, { cook = sanitizeInt(it) }, Modifier.weight(1f))
                }

                // Ingredients editor
                EditorSection(
                    title = "Ingredients",
                    onAdd = { ingredients.add(IngredientDraft()) },
                    addLabel = "Add ingredient"
                ) {
                    ingredients.forEachIndexed { index, draft ->
                        IngredientRow(
                            draft = draft,
                            canRemove = ingredients.size > 1,
                            onRemove = { ingredients.removeAt(index) }
                        )
                    }
                }

                // Steps editor
                EditorSection(
                    title = "Method",
                    onAdd = { steps.add("") },
                    addLabel = "Add step"
                ) {
                    steps.forEachIndexed { index, step ->
                        StepRow(
                            number = index + 1,
                            value = step,
                            onChange = { steps[index] = it },
                            canRemove = steps.size > 1,
                            onRemove = { steps.removeAt(index) }
                        )
                    }
                }

                OutlinedTextField(
                    value = tags,
                    onValueChange = { tags = it },
                    label = { Text("Tags (comma separated)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                InkButton(
                    text = if (isEditing) "Save changes" else "Save recipe",
                    modifier = Modifier.fillMaxWidth(),
                    onClick = {
                        val cleanTitle = title.trim()
                        if (cleanTitle.isEmpty()) {
                            titleError = "A recipe needs a title."
                            return@InkButton
                        }
                        val recipe = Recipe(
                            id = existing?.id ?: UUID.randomUUID().toString(),
                            title = cleanTitle,
                            description = description.trim(),
                            category = category,
                            servings = servings.toIntOrNull()?.coerceIn(1, 99) ?: 1,
                            prepMinutes = prep.toIntOrNull()?.coerceIn(0, 6000) ?: 0,
                            cookMinutes = cook.toIntOrNull()?.coerceIn(0, 6000) ?: 0,
                            ingredients = ingredients.mapNotNull { it.toIngredientOrNull() },
                            steps = steps.map { it.trim() }.filter { it.isNotEmpty() },
                            tags = tags.split(",").map { it.trim() }.filter { it.isNotEmpty() },
                            favorite = existing?.favorite ?: false,
                            createdAt = existing?.createdAt ?: System.currentTimeMillis()
                        )
                        viewModel.save(recipe)
                        onDone()
                    }
                )
                Spacer(Modifier.height(8.dp))
            }
        }
    }
}

private fun IngredientDraft.toIngredientOrNull(): Ingredient? {
    val cleanName = name.trim()
    if (cleanName.isEmpty()) return null
    val qty = quantity.trim().replace(",", ".").toDoubleOrNull()?.coerceIn(0.0, 100000.0) ?: 0.0
    return Ingredient(name = cleanName, quantity = qty, unit = unit.trim())
}

private fun sanitizeInt(raw: String): String = raw.filter { it.isDigit() }.take(4)

private fun trimNumber(value: Double): String {
    return if (value % 1.0 == 0.0) value.toLong().toString()
    else value.toString().trimEnd('0').trimEnd('.')
}

@Composable
private fun CategorySelectChip(label: String, selected: Boolean, onClick: () -> Unit) {
    val brand = LocalBrand.current
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(if (selected) MaterialTheme.colorScheme.primary else brand.glass)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp)
    ) {
        Text(
            label,
            color = if (selected) MaterialTheme.colorScheme.onPrimary else brand.textSecondary,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun NumberField(label: String, value: String, onChange: (String) -> Unit, modifier: Modifier) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        modifier = modifier
    )
}

@Composable
private fun EditorSection(
    title: String,
    onAdd: () -> Unit,
    addLabel: String,
    content: @Composable () -> Unit
) {
    val brand = LocalBrand.current
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(title, style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground, fontWeight = FontWeight.SemiBold)
            TextButton(onClick = onAdd) {
                Icon(Icons.Filled.Add, contentDescription = null)
                Spacer(Modifier.width(4.dp))
                Text(addLabel)
            }
        }
        content()
    }
}

@Composable
private fun IngredientRow(draft: IngredientDraft, canRemove: Boolean, onRemove: () -> Unit) {
    GlassCard(modifier = Modifier.fillMaxWidth()) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
                value = draft.name,
                onValueChange = { draft.name = it },
                label = { Text("Ingredient") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                OutlinedTextField(
                    value = draft.quantity,
                    onValueChange = { draft.quantity = it.filter { c -> c.isDigit() || c == '.' || c == ',' }.take(7) },
                    label = { Text("Qty") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.weight(1f)
                )
                Spacer(Modifier.width(8.dp))
                OutlinedTextField(
                    value = draft.unit,
                    onValueChange = { draft.unit = it.take(12) },
                    label = { Text("Unit") },
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )
                if (canRemove) {
                    IconButton(onClick = onRemove) {
                        Icon(Icons.Filled.Close, contentDescription = "Remove ingredient")
                    }
                }
            }
        }
    }
}

@Composable
private fun StepRow(
    number: Int,
    value: String,
    onChange: (String) -> Unit,
    canRemove: Boolean,
    onRemove: () -> Unit
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        OutlinedTextField(
            value = value,
            onValueChange = onChange,
            label = { Text("Step $number") },
            modifier = Modifier.weight(1f)
        )
        if (canRemove) {
            IconButton(onClick = onRemove) {
                Icon(Icons.Filled.Close, contentDescription = "Remove step $number")
            }
        }
    }
}
