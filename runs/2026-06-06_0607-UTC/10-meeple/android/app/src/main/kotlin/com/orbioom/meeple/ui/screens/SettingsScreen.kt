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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
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
import androidx.compose.runtime.mutableStateOf
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
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.orbioom.meeple.data.ThemeMode
import com.orbioom.meeple.domain.ScoringType
import com.orbioom.meeple.ui.components.GlassCard
import com.orbioom.meeple.ui.components.InkButton
import com.orbioom.meeple.ui.theme.LocalBrand
import com.orbioom.meeple.viewmodel.MeepleViewModel
import com.orbioom.meeple.viewmodel.SettingsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    settingsViewModel: SettingsViewModel,
    meepleViewModel: MeepleViewModel,
    onBack: () -> Unit
) {
    val brand = LocalBrand.current
    val settings by settingsViewModel.settings.collectAsStateWithLifecycle()
    var showClear by rememberSaveable { mutableStateOf(false) }
    var showReset by rememberSaveable { mutableStateOf(false) }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text("Settings", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
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
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Spacer(Modifier.height(2.dp))

            Section("Appearance") {
                SettingLabel("Theme")
                ThemeMode.entries.forEach { mode ->
                    OptionRow(
                        label = mode.title,
                        selected = settings.theme == mode,
                        onClick = { settingsViewModel.setTheme(mode) }
                    )
                }
            }

            Section("Logging defaults") {
                SettingLabel("Default scoring type for new games")
                ScoringType.entries.forEach { type ->
                    OptionRow(
                        label = type.title,
                        selected = settings.defaultScoringType == type,
                        onClick = { settingsViewModel.setDefaultScoringType(type) }
                    )
                }

                Spacer(Modifier.height(8.dp))
                SettingLabel("Default location for new plays")
                OutlinedTextField(
                    value = settings.defaultLocation,
                    onValueChange = { settingsViewModel.setDefaultLocation(it.take(60)) },
                    label = { Text("Location") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(Modifier.height(12.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            "Pre-select last session's players",
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onBackground,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            "New plays start with the same players as your most recent one.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = brand.textSecondary
                        )
                    }
                    Switch(
                        checked = settings.rememberLastPlayers,
                        onCheckedChange = { settingsViewModel.setRememberLastPlayers(it) },
                        colors = SwitchDefaults.colors(
                            checkedTrackColor = brand.win,
                            checkedThumbColor = Color.White
                        )
                    )
                }
            }

            Section("Data") {
                Text(
                    "Restore the sample collection, or clear everything and start from scratch.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textSecondary
                )
                Spacer(Modifier.height(10.dp))
                InkButton(
                    text = "Reset to sample data",
                    onClick = { showReset = true },
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(8.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(brand.glass)
                        .clickable(role = Role.Button) { showClear = true },
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "Clear all data",
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }

            Section("About") {
                InfoRow("App", "Meeple")
                InfoRow("Version", "1.0 (1)")
                InfoRow("Studio", "Orbioom")
                Spacer(Modifier.height(4.dp))
                Text(
                    "A calm log for your board-game plays — turning game nights into win rates, streaks, and head-to-head records.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textSecondary
                )
            }

            Spacer(Modifier.height(24.dp))
        }
    }

    if (showClear) {
        ConfirmDialog(
            title = "Clear all data?",
            body = "This permanently removes every game, player, and play. The app returns to an empty collection.",
            confirmLabel = "Clear everything",
            onConfirm = {
                showClear = false
                meepleViewModel.clearAll()
            },
            onDismiss = { showClear = false }
        )
    }
    if (showReset) {
        ConfirmDialog(
            title = "Reset to sample data?",
            body = "This replaces your current collection with the sample games, players, and plays. Your existing data will be lost.",
            confirmLabel = "Reset",
            onConfirm = {
                showReset = false
                meepleViewModel.resetToSample()
            },
            onDismiss = { showReset = false }
        )
    }
}

@Composable
private fun Section(title: String, content: @Composable () -> Unit) {
    val brand = LocalBrand.current
    Column {
        Text(
            title.uppercase(),
            style = MaterialTheme.typography.labelMedium,
            color = brand.textTertiary,
            fontWeight = FontWeight.SemiBold
        )
        Spacer(Modifier.height(8.dp))
        GlassCard(modifier = Modifier.fillMaxWidth()) {
            Column { content() }
        }
    }
}

@Composable
private fun SettingLabel(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.bodyMedium,
        color = LocalBrand.current.textSecondary,
        fontWeight = FontWeight.Medium,
        modifier = Modifier.padding(bottom = 4.dp)
    )
}

@Composable
private fun OptionRow(label: String, selected: Boolean, onClick: () -> Unit) {
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

@Composable
private fun InfoRow(label: String, value: String) {
    val brand = LocalBrand.current
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            label,
            style = MaterialTheme.typography.bodyLarge,
            color = brand.textSecondary,
            modifier = Modifier.weight(1f)
        )
        Text(
            value,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.Medium
        )
    }
}
