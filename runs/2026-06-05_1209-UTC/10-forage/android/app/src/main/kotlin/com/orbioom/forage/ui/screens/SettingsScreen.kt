package com.orbioom.forage.ui.screens

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
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.orbioom.forage.data.ForageSettings
import com.orbioom.forage.data.ThemeMode
import com.orbioom.forage.domain.SortOrder
import com.orbioom.forage.ui.components.GlassCard
import com.orbioom.forage.ui.components.LiveDot
import com.orbioom.forage.ui.components.MistBackground
import com.orbioom.forage.ui.theme.LocalBrand

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    settings: ForageSettings,
    onSetTheme: (ThemeMode) -> Unit,
    onSetSort: (SortOrder) -> Unit,
    onResetSample: () -> Unit,
    onClearAll: () -> Unit,
    onBack: () -> Unit
) {
    val brand = LocalBrand.current
    var showReset by remember { mutableStateOf(false) }
    var showClear by remember { mutableStateOf(false) }

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
                // Appearance
                SettingGroup("Appearance") {
                    SegmentedRow(
                        options = ThemeMode.entries.map { it.title },
                        selectedIndex = ThemeMode.entries.indexOf(settings.theme),
                        onSelect = { onSetTheme(ThemeMode.entries[it]) }
                    )
                }

                // Default sort
                SettingGroup("Default sort") {
                    Column {
                        SortOrder.entries.forEach { order ->
                            ChoiceRow(
                                label = order.title,
                                selected = settings.sort == order,
                                onClick = { onSetSort(order) }
                            )
                        }
                    }
                }

                // Data management
                SettingGroup("Your recipes") {
                    Column {
                        ActionRow("Reset to sample recipes") { showReset = true }
                        ActionRow("Clear all recipes", destructive = true) { showClear = true }
                    }
                }

                // About
                SettingGroup("About") {
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        InfoRow("Version", "1.0")
                        InfoRow("Made by", "Orbioom")
                        Text(
                            "Forage — conjured, not just coded. Everything stays on this device.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = brand.textTertiary
                        )
                    }
                }
            }
        }
    }

    if (showReset) {
        AlertDialog(
            onDismissRequest = { showReset = false },
            title = { Text("Reset to sample recipes?") },
            text = { Text("This replaces everything in your box with the original sample recipes.") },
            confirmButton = {
                TextButton(onClick = { onResetSample(); showReset = false }) { Text("Reset") }
            },
            dismissButton = { TextButton(onClick = { showReset = false }) { Text("Cancel") } }
        )
    }
    if (showClear) {
        AlertDialog(
            onDismissRequest = { showClear = false },
            title = { Text("Clear all recipes?") },
            text = { Text("Every recipe will be permanently removed. This can't be undone.") },
            confirmButton = {
                TextButton(onClick = { onClearAll(); showClear = false }) { Text("Delete everything") }
            },
            dismissButton = { TextButton(onClick = { showClear = false }) { Text("Cancel") } }
        )
    }
}

@Composable
private fun SettingGroup(title: String, content: @Composable () -> Unit) {
    val brand = LocalBrand.current
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            title.uppercase(),
            style = MaterialTheme.typography.labelMedium,
            color = brand.textTertiary,
            fontWeight = FontWeight.SemiBold
        )
        GlassCard(modifier = Modifier.fillMaxWidth()) { content() }
    }
}

@Composable
private fun SegmentedRow(options: List<String>, selectedIndex: Int, onSelect: (Int) -> Unit) {
    val brand = LocalBrand.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(brand.glass)
            .padding(4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        options.forEachIndexed { index, label ->
            val selected = index == selectedIndex
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(9.dp))
                    .background(if (selected) MaterialTheme.colorScheme.primary else Color.Transparent)
                    .clickable(role = Role.RadioButton, onClick = { onSelect(index) })
                    .padding(vertical = 10.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    label,
                    color = if (selected) MaterialTheme.colorScheme.onPrimary else brand.textSecondary,
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

@Composable
private fun ChoiceRow(label: String, selected: Boolean, onClick: () -> Unit) {
    val brand = LocalBrand.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .clickable(role = Role.RadioButton, onClick = onClick)
            .padding(vertical = 12.dp, horizontal = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, color = MaterialTheme.colorScheme.onBackground,
            style = MaterialTheme.typography.bodyLarge)
        if (selected) {
            LiveDot()
        }
    }
}

@Composable
private fun ActionRow(label: String, destructive: Boolean = false, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .clickable(role = Role.Button, onClick = onClick)
            .padding(vertical = 12.dp, horizontal = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            label,
            color = if (destructive) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onBackground,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = if (destructive) FontWeight.Medium else FontWeight.Normal
        )
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    val brand = LocalBrand.current
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, color = brand.textSecondary, style = MaterialTheme.typography.bodyMedium)
        Text(value, color = MaterialTheme.colorScheme.onBackground,
            style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
    }
}
