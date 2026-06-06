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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
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
import com.orbioom.meeple.domain.Format
import com.orbioom.meeple.domain.Game
import com.orbioom.meeple.domain.Play
import com.orbioom.meeple.domain.PlayerResult
import com.orbioom.meeple.domain.ScoringType
import com.orbioom.meeple.ui.components.GlassCard
import com.orbioom.meeple.ui.components.InkButton
import com.orbioom.meeple.ui.components.PlayerToken
import com.orbioom.meeple.ui.theme.LocalBrand
import com.orbioom.meeple.viewmodel.MeepleViewModel
import com.orbioom.meeple.viewmodel.SettingsViewModel
import java.util.Calendar
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditPlayScreen(
    playId: String?,
    presetGameId: String?,
    viewModel: MeepleViewModel,
    settingsViewModel: SettingsViewModel,
    onDone: () -> Unit,
    onCancel: () -> Unit,
    onAddGame: () -> Unit,
    onAddPlayer: () -> Unit
) {
    val brand = LocalBrand.current
    val existing = remember(playId) { playId?.let { viewModel.play(it) } }
    val isEditing = existing != null
    val settings by settingsViewModel.settings.collectAsStateWithLifecycle()

    val allGames = remember(playId, presetGameId) { viewModel.allGames() }
    val allPlayers = remember(playId, presetGameId) { viewModel.allPlayers() }

    // Selected game.
    var gameId by rememberSaveable {
        mutableStateOf(existing?.gameId ?: presetGameId ?: allGames.firstOrNull()?.id ?: "")
    }
    val selectedGame: Game? = remember(gameId, allGames) { allGames.firstOrNull { it.id == gameId } }
    val isCoop = selectedGame?.scoringType == ScoringType.COOPERATIVE

    var dateMillis by rememberSaveable {
        mutableStateOf(existing?.date ?: System.currentTimeMillis())
    }
    var location by rememberSaveable {
        mutableStateOf(existing?.location ?: settings.defaultLocation)
    }
    var duration by rememberSaveable {
        mutableStateOf(existing?.durationMinutes?.toString() ?: "")
    }
    var notes by rememberSaveable { mutableStateOf(existing?.notes ?: "") }
    var coopWon by rememberSaveable { mutableStateOf(existing?.coopGroupWon ?: false) }
    var attempted by rememberSaveable { mutableStateOf(false) }

    // Selected players (ordered list of ids) and their score text.
    val selectedIds = remember {
        val initial = existing?.results?.map { it.playerId }
            ?: if (settings.rememberLastPlayers) viewModel.lastPlay()?.results?.map { it.playerId } ?: emptyList()
            else emptyList()
        androidx.compose.runtime.mutableStateListOf<String>().apply { addAll(initial.filter { id -> allPlayers.any { it.id == id } }) }
    }
    val scoreText = remember {
        mutableStateMapOf<String, String>().apply {
            existing?.results?.forEach { r ->
                if (r.score != null) put(r.playerId, trimNumber(r.score))
            }
        }
    }

    fun togglePlayer(id: String) {
        if (selectedIds.contains(id)) {
            selectedIds.remove(id)
            scoreText.remove(id)
        } else selectedIds.add(id)
    }

    val noGames = allGames.isEmpty()
    val noPlayers = allPlayers.isEmpty()
    val playersError = selectedIds.isEmpty()
    val canSave = selectedGame != null && !playersError

    fun save() {
        attempted = true
        val game = selectedGame ?: return
        if (selectedIds.isEmpty()) return
        val results = selectedIds.map { pid ->
            PlayerResult(
                playerId = pid,
                score = if (game.scoringType == ScoringType.COOPERATIVE) null
                else scoreText[pid]?.trim()?.toDoubleOrNull()
            )
        }
        val play = Play(
            id = existing?.id ?: "play-${UUID.randomUUID()}",
            gameId = game.id,
            date = dateMillis,
            durationMinutes = duration.toIntOrNull()?.takeIf { it > 0 },
            location = location.trim(),
            notes = notes.trim(),
            coopGroupWon = if (game.scoringType == ScoringType.COOPERATIVE) coopWon else false,
            results = results
        )
        viewModel.savePlay(play)
        onDone()
    }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text(if (isEditing) "Edit play" else "Log a play", fontWeight = FontWeight.Bold) },
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

            // ---- Game selection ----
            FieldLabel("Game")
            if (noGames) {
                GlassCard(modifier = Modifier.fillMaxWidth()) {
                    Column {
                        Text(
                            "You have no games yet. Add one to log a play.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = brand.textSecondary
                        )
                        Spacer(Modifier.height(10.dp))
                        InkButton(text = "Add a game", icon = Icons.Filled.Add, onClick = onAddGame)
                    }
                }
            } else {
                GlassCard(modifier = Modifier.fillMaxWidth()) {
                    Column {
                        allGames.forEach { g ->
                            ChoiceRow(
                                label = "${g.title}  ·  ${g.scoringType.shortLabel}",
                                selected = gameId == g.id,
                                onClick = {
                                    gameId = g.id
                                    // Clear scores when switching to/from co-op for clarity.
                                    if (g.scoringType == ScoringType.COOPERATIVE) scoreText.clear()
                                }
                            )
                        }
                    }
                }
            }

            // ---- Date ----
            DateField(dateMillis = dateMillis, onChange = { dateMillis = it })

            // ---- Players ----
            Row(verticalAlignment = Alignment.CenterVertically) {
                FieldLabel("Players", modifier = Modifier.weight(1f))
                if (!noPlayers) {
                    Text(
                        "${selectedIds.size} selected",
                        style = MaterialTheme.typography.labelMedium,
                        color = brand.textTertiary
                    )
                }
            }
            if (noPlayers) {
                GlassCard(modifier = Modifier.fillMaxWidth()) {
                    Column {
                        Text(
                            "You have no players yet. Add at least one to log a play.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = brand.textSecondary
                        )
                        Spacer(Modifier.height(10.dp))
                        InkButton(text = "Add a player", icon = Icons.Filled.Add, onClick = onAddPlayer)
                    }
                }
            } else {
                allPlayers.forEach { player ->
                    val selected = selectedIds.contains(player.id)
                    PlayerSelectRow(
                        name = player.name,
                        colorArgb = player.colorArgb,
                        selected = selected,
                        showScore = selected && !isCoop,
                        scoreValue = scoreText[player.id] ?: "",
                        onToggle = { togglePlayer(player.id) },
                        onScoreChange = { scoreText[player.id] = sanitizeDecimal(it).take(7) }
                    )
                }
                if (attempted && playersError) {
                    Text(
                        "Select at least one player.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.error
                    )
                }
            }

            // ---- Co-op outcome ----
            if (isCoop && selectedIds.isNotEmpty()) {
                GlassCard(modifier = Modifier.fillMaxWidth()) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                "The group won",
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onBackground,
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                "Cooperative games are won or lost together.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = brand.textSecondary
                            )
                        }
                        Switch(
                            checked = coopWon,
                            onCheckedChange = { coopWon = it },
                            colors = SwitchDefaults.colors(
                                checkedTrackColor = brand.win,
                                checkedThumbColor = Color.White
                            )
                        )
                    }
                }
            } else if (!isCoop && selectedIds.isNotEmpty() && selectedGame != null) {
                Text(
                    if (selectedGame.scoringType == ScoringType.LOWEST_WINS)
                        "Lowest score wins. Leave a score blank if it wasn't tracked."
                    else "Highest score wins. Leave a score blank if it wasn't tracked.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textTertiary
                )
            }

            // ---- Optional details ----
            OutlinedTextField(
                value = location,
                onValueChange = { location = it.take(60) },
                label = { Text("Location (optional)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = duration,
                onValueChange = { duration = sanitizeInt(it).take(4) },
                label = { Text("Duration in minutes (optional)") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = notes,
                onValueChange = { notes = it.take(280) },
                label = { Text("Notes (optional)") },
                modifier = Modifier.fillMaxWidth().height(100.dp)
            )

            Spacer(Modifier.height(2.dp))
            InkButton(
                text = if (isEditing) "Save changes" else "Save play",
                enabled = !noGames && !noPlayers,
                onClick = { save() },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun FieldLabel(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelMedium,
        color = LocalBrand.current.textTertiary,
        fontWeight = FontWeight.SemiBold,
        modifier = modifier
    )
}

@Composable
private fun PlayerSelectRow(
    name: String,
    colorArgb: Long?,
    selected: Boolean,
    showScore: Boolean,
    scoreValue: String,
    onToggle: () -> Unit,
    onScoreChange: (String) -> Unit
) {
    val brand = LocalBrand.current
    GlassCard(modifier = Modifier.fillMaxWidth()) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .clickable(role = Role.Checkbox, onClick = onToggle)
                    .semantics { contentDescription = if (selected) "$name, selected" else "$name, not selected" },
                verticalAlignment = Alignment.CenterVertically
            ) {
                PlayerToken(name = name, colorArgb = colorArgb, sizeDp = 32)
                Spacer(Modifier.width(12.dp))
                Text(
                    name,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f)
                )
                Box(
                    modifier = Modifier
                        .width(28.dp)
                        .height(28.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(if (selected) brand.win else brand.glass),
                    contentAlignment = Alignment.Center
                ) {
                    if (selected) {
                        Icon(
                            Icons.Filled.Check,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier
                                .height(18.dp)
                                .width(18.dp)
                        )
                    }
                }
            }
            if (showScore) {
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(
                    value = scoreValue,
                    onValueChange = onScoreChange,
                    label = { Text("Score for $name") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}

@Composable
private fun DateField(dateMillis: Long, onChange: (Long) -> Unit) {
    val brand = LocalBrand.current
    GlassCard(modifier = Modifier.fillMaxWidth()) {
        Column {
            Text(
                "Date",
                style = MaterialTheme.typography.labelMedium,
                color = brand.textTertiary,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(4.dp))
            Text(
                Format.date(dateMillis),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                StepButton("− Day") { onChange(shiftDays(dateMillis, -1)) }
                StepButton("+ Day") { onChange(shiftDays(dateMillis, 1)) }
                StepButton("Today") { onChange(System.currentTimeMillis()) }
            }
        }
    }
}

@Composable
private fun StepButton(label: String, onClick: () -> Unit) {
    val brand = LocalBrand.current
    Box(
        modifier = Modifier
            .height(40.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(brand.glass)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = 14.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            label,
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.Medium
        )
    }
}

private fun shiftDays(millis: Long, days: Int): Long {
    val cal = Calendar.getInstance()
    cal.timeInMillis = millis
    cal.add(Calendar.DAY_OF_YEAR, days)
    // Never let a play be dated in the future.
    return cal.timeInMillis.coerceAtMost(System.currentTimeMillis())
}
