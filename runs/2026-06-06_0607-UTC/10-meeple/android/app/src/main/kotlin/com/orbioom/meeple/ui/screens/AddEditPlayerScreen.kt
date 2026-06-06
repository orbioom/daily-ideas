package com.orbioom.meeple.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.ui.unit.dp
import com.orbioom.meeple.domain.Player
import com.orbioom.meeple.ui.components.InkButton
import com.orbioom.meeple.ui.components.PlayerToken
import com.orbioom.meeple.ui.theme.LocalBrand
import com.orbioom.meeple.viewmodel.MeepleViewModel
import java.util.UUID

/** A curated, accessible palette of player token colors. */
private val playerPalette: List<Long> = listOf(
    0xFF86C79A, // green
    0xFF6E8BD6, // blue
    0xFFD68B6E, // clay
    0xFFB08BD6, // violet
    0xFFD6C36E, // gold
    0xFF6EC7C7, // teal
    0xFFD67E9E, // rose
    0xFF8B93A8  // slate
)

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun AddEditPlayerScreen(
    playerId: String?,
    viewModel: MeepleViewModel,
    onDone: () -> Unit,
    onCancel: () -> Unit
) {
    val brand = LocalBrand.current
    val existing = remember(playerId) { playerId?.let { viewModel.player(it) } }
    val isEditing = existing != null

    var name by rememberSaveable { mutableStateOf(existing?.name ?: "") }
    var colorArgb by rememberSaveable { mutableStateOf(existing?.colorArgb) }
    var attempted by rememberSaveable { mutableStateOf(false) }

    val nameError = name.isBlank()

    fun save() {
        attempted = true
        if (nameError) return
        val player = Player(
            id = existing?.id ?: "player-${UUID.randomUUID()}",
            name = name.trim(),
            colorArgb = colorArgb,
            createdAt = existing?.createdAt ?: System.currentTimeMillis()
        )
        viewModel.savePlayer(player)
        onDone()
    }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text(if (isEditing) "Edit player" else "New player", fontWeight = FontWeight.Bold) },
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
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Spacer(Modifier.height(2.dp))

            Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                PlayerToken(
                    name = name.ifBlank { "?" },
                    colorArgb = colorArgb,
                    sizeDp = 72
                )
            }

            OutlinedTextField(
                value = name,
                onValueChange = { name = it.take(40) },
                label = { Text("Name") },
                singleLine = true,
                isError = attempted && nameError,
                supportingText = { if (attempted && nameError) Text("Enter the player's name.") },
                modifier = Modifier.fillMaxWidth()
            )

            Text(
                "Token color (optional)",
                style = MaterialTheme.typography.labelMedium,
                color = brand.textTertiary,
                fontWeight = FontWeight.SemiBold
            )
            FlowRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                ColorSwatch(
                    color = null,
                    selected = colorArgb == null,
                    label = "Default",
                    onClick = { colorArgb = null }
                )
                playerPalette.forEach { c ->
                    ColorSwatch(
                        color = c,
                        selected = colorArgb == c,
                        label = "Color",
                        onClick = { colorArgb = c }
                    )
                }
            }

            Spacer(Modifier.height(2.dp))
            InkButton(
                text = if (isEditing) "Save changes" else "Add player",
                onClick = { save() },
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Composable
private fun ColorSwatch(
    color: Long?,
    selected: Boolean,
    label: String,
    onClick: () -> Unit
) {
    val brand = LocalBrand.current
    val fill = color?.let { Color(it) } ?: brand.textTertiary
    Box(
        modifier = Modifier
            .size(48.dp)
            .clip(RoundedCornerShape(50))
            .background(fill)
            .border(
                width = if (selected) 3.dp else 0.dp,
                color = if (selected) MaterialTheme.colorScheme.onBackground else Color.Transparent,
                shape = RoundedCornerShape(50)
            )
            .clickable(role = Role.RadioButton, onClick = onClick)
            .semantics { contentDescription = if (selected) "$label, selected" else label },
        contentAlignment = Alignment.Center
    ) {
        if (selected) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White)
        }
    }
}
