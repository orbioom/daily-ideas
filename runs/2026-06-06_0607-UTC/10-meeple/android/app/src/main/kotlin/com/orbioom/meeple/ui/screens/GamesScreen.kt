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
import androidx.compose.material.icons.filled.Casino
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
import com.orbioom.meeple.ui.theme.LocalBrand
import com.orbioom.meeple.viewmodel.GameCard
import com.orbioom.meeple.viewmodel.MeepleViewModel
import com.orbioom.meeple.viewmodel.UiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GamesScreen(
    viewModel: MeepleViewModel,
    onOpenGame: (String) -> Unit,
    onAddGame: () -> Unit,
    onOpenSettings: () -> Unit
) {
    val state by viewModel.gamesState.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text("Games", fontWeight = FontWeight.Bold) },
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
                    icon = Icons.Filled.Casino,
                    title = "No games yet",
                    body = "Add the games in your collection, then log plays to see per-game stats: win rates, high scores, and how often each game hits the table.",
                    actionLabel = "Add a game",
                    actionIcon = Icons.Filled.Add,
                    onAction = onAddGame
                )
                is UiState.Content -> GamesList(s.data, onOpenGame)
            }

            if (state is UiState.Content) {
                InkButton(
                    text = "Add game",
                    icon = Icons.Filled.Add,
                    onClick = onAddGame,
                    modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp)
                )
            }
        }
    }
}

@Composable
private fun GamesList(cards: List<GameCard>, onOpen: (String) -> Unit) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 96.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(cards, key = { it.game.id }) { card ->
            GameRow(card = card, onOpen = { onOpen(card.game.id) })
        }
    }
}

@Composable
private fun GameRow(card: GameCard, onOpen: () -> Unit) {
    val brand = LocalBrand.current
    val g = card.game
    val stats = card.stats
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = onOpen,
        onClickLabel = "Open ${g.title}"
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = g.title,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                if (g.designer.isNotBlank()) {
                    Text(
                        text = g.designer,
                        style = MaterialTheme.typography.bodyMedium,
                        color = brand.textSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                Spacer(Modifier.height(6.dp))
                val last = stats.lastPlayed?.let { "Last ${Format.shortDate(it)}" } ?: "Never played"
                Text(
                    text = "${Format.plays(stats.playCount)}  ·  $last  ·  ${g.scoringType.shortLabel}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            Spacer(Modifier.width(12.dp))
            // Play-count chip.
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = stats.playCount.toString(),
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "plays",
                    style = MaterialTheme.typography.labelMedium,
                    color = brand.textTertiary
                )
            }
        }
    }
}
