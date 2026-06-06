package com.orbioom.meeple.ui.screens

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.orbioom.meeple.domain.Format
import com.orbioom.meeple.ui.components.EmptyState
import com.orbioom.meeple.ui.components.GlassCard
import com.orbioom.meeple.ui.components.InkButton
import com.orbioom.meeple.ui.components.LoadingState
import com.orbioom.meeple.ui.components.PlayerToken
import com.orbioom.meeple.ui.theme.LocalBrand
import com.orbioom.meeple.viewmodel.MeepleViewModel
import com.orbioom.meeple.viewmodel.PlayerCard
import com.orbioom.meeple.viewmodel.UiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlayersScreen(
    viewModel: MeepleViewModel,
    onOpenPlayer: (String) -> Unit,
    onAddPlayer: () -> Unit,
    onOpenSettings: () -> Unit
) {
    val state by viewModel.playersState.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text("Players", fontWeight = FontWeight.Bold) },
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
        Box(modifier = Modifier.fillMaxSize().padding(padding)) {
            when (val s = state) {
                is UiState.Loading -> LoadingState()
                is UiState.Empty -> EmptyState(
                    icon = Icons.Filled.Groups,
                    title = "No players yet",
                    body = "Add the people you play with. Meeple tracks each player's win rate, longest streak, nemesis, and head-to-head records.",
                    actionLabel = "Add a player",
                    actionIcon = Icons.Filled.Add,
                    onAction = onAddPlayer
                )
                is UiState.Content -> PlayersList(s.data, onOpenPlayer)
            }

            if (state is UiState.Content) {
                InkButton(
                    text = "Add player",
                    icon = Icons.Filled.Add,
                    onClick = onAddPlayer,
                    modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp)
                )
            }
        }
    }
}

@Composable
private fun PlayersList(cards: List<PlayerCard>, onOpen: (String) -> Unit) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 96.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(cards, key = { it.stats.player.id }) { card ->
            PlayerRow(card = card, onOpen = { onOpen(card.stats.player.id) })
        }
    }
}

@Composable
private fun PlayerRow(card: PlayerCard, onOpen: () -> Unit) {
    val brand = LocalBrand.current
    val stats = card.stats
    val p = stats.player
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = onOpen,
        onClickLabel = "Open ${p.name}"
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            PlayerToken(name = p.name, colorArgb = p.colorArgb)
            Spacer(Modifier.width(14.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = p.name,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    text = "${Format.record(stats.totalWins, stats.totalPlays - stats.totalWins)} record  ·  ${Format.plays(stats.totalPlays)}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            Spacer(Modifier.width(12.dp))
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = if (stats.totalPlays == 0) "—" else Format.percent(stats.winRate),
                    style = MaterialTheme.typography.titleLarge,
                    color = if (stats.totalPlays > 0 && stats.winRate >= 0.5) brand.win
                    else MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "win rate",
                    style = MaterialTheme.typography.labelMedium,
                    color = brand.textTertiary
                )
            }
        }
    }
}
