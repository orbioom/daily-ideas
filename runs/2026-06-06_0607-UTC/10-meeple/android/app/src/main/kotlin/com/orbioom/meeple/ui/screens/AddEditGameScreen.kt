package com.orbioom.meeple.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
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
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.orbioom.meeple.domain.Game
import com.orbioom.meeple.domain.ScoringType
import com.orbioom.meeple.ui.components.GlassCard
import com.orbioom.meeple.ui.components.InkButton
import com.orbioom.meeple.ui.theme.LocalBrand
import com.orbioom.meeple.viewmodel.MeepleViewModel
import com.orbioom.meeple.viewmodel.SettingsViewModel
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditGameScreen(
    gameId: String?,
    viewModel: MeepleViewModel,
    settingsViewModel: SettingsViewModel,
    onDone: () -> Unit,
    onCancel: () -> Unit
) {
    val brand = LocalBrand.current
    val existing = remember(gameId) { gameId?.let { viewModel.game(it) } }
    val isEditing = existing != null
    val settings by settingsViewModel.settings.collectAsStateWithLifecycle()

    var title by rememberSaveable { mutableStateOf(existing?.title ?: "") }
    var designer by rememberSaveable { mutableStateOf(existing?.designer ?: "") }
    var minPlayers by rememberSaveable { mutableStateOf(existing?.minPlayers?.toString() ?: "1") }
    var maxPlayers by rememberSaveable { mutableStateOf(existing?.maxPlayers?.toString() ?: "4") }
    var playTime by rememberSaveable { mutableStateOf(existing?.playTimeMinutes?.toString() ?: "") }
    var scoring by rememberSaveable {
        mutableStateOf(existing?.scoringType ?: settings.defaultScoringType)
    }
    var notes by rememberSaveable { mutableStateOf(existing?.notes ?: "") }
    var attempted by rememberSaveable { mutableStateOf(false) }

    val titleError = title.isBlank()
    val minVal = minPlayers.toIntOrNull()
    val maxVal = maxPlayers.toIntOrNull()
    val minError = minVal == null || minVal < 1
    val maxError = maxVal == null || maxVal < 1
    val rangeError = !minError && !maxError && maxVal!! < minVal!!
    val canSave = !titleError && !minError && !maxError && !rangeError

    fun save() {
        attempted = true
        if (!canSave) return
        val game = Game(
            id = existing?.id ?: "game-${UUID.randomUUID()}",
            title = title.trim(),
            designer = designer.trim(),
            minPlayers = (minVal ?: 1).coerceAtLeast(1),
            maxPlayers = (maxVal ?: 1).coerceAtLeast(minVal ?: 1),
            playTimeMinutes = playTime.toIntOrNull()?.takeIf { it > 0 },
            scoringType = scoring,
            notes = notes.trim(),
            createdAt = existing?.createdAt ?: System.currentTimeMillis()
        )
        viewModel.saveGame(game)
        onDone()
    }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text(if (isEditing) "Edit game" else "New game", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onCancel) {
                        Icon(Icons.Filled.Close, contentDescription = "Cancel")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    titleContentColor = MaterialTheme.colorScheme.onBackground
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Spacer(Modifier.height(2.dp))

            OutlinedTextField(
                value = title,
                onValueChange = { title = it.take(80) },
                label = { Text("Title") },
                singleLine = true,
                isError = attempted && titleError,
                supportingText = { if (attempted && titleError) Text("Give the game a title.") },
                modifier = Modifier.fillMaxWidth()
            )

            OutlinedTextField(
                value = designer,
                onValueChange = { designer = it.take(80) },
                label = { Text("Designer (optional)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = minPlayers,
                    onValueChange = { minPlayers = sanitizeInt(it).take(2) },
                    label = { Text("Min players") },
                    singleLine = true,
                    isError = attempted && (minError || rangeError),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.weight(1f)
                )
                OutlinedTextField(
                    value = maxPlayers,
                    onValueChange = { maxPlayers = sanitizeInt(it).take(2) },
                    label = { Text("Max players") },
                    singleLine = true,
                    isError = attempted && (maxError || rangeError),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.weight(1f)
                )
            }
            if (attempted && rangeError) {
                Text(
                    "Max players can't be fewer than min players.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.error
                )
            }

            OutlinedTextField(
                value = playTime,
                onValueChange = { playTime = sanitizeInt(it).take(4) },
                label = { Text("Typical play time in minutes (optional)") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )

            Text(
                "Scoring",
                style = MaterialTheme.typography.labelMedium,
                color = brand.textTertiary,
                fontWeight = FontWeight.SemiBold
            )
            GlassCard(modifier = Modifier.fillMaxWidth()) {
                Column {
                    ScoringType.entries.forEach { type ->
                        ChoiceRow(
                            label = type.title,
                            selected = scoring == type,
                            onClick = { scoring = type }
                        )
                    }
                }
            }

            OutlinedTextField(
                value = notes,
                onValueChange = { notes = it.take(280) },
                label = { Text("Notes (optional)") },
                modifier = Modifier.fillMaxWidth().height(100.dp)
            )

            Spacer(Modifier.height(2.dp))
            InkButton(
                text = if (isEditing) "Save changes" else "Add game",
                onClick = { save() },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
internal fun ChoiceRow(label: String, selected: Boolean, onClick: () -> Unit) {
    val brand = LocalBrand.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .clickable(role = Role.RadioButton, onClick = onClick)
            .padding(vertical = 12.dp, horizontal = 4.dp)
            .semantics { contentDescription = if (selected) "$label, selected" else label },
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onBackground,
            modifier = Modifier.weight(1f)
        )
        if (selected) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = brand.win)
        }
    }
}
