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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.History
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
import com.orbioom.meeple.ui.components.OutcomeDot
import com.orbioom.meeple.ui.theme.LocalBrand
import com.orbioom.meeple.viewmodel.MeepleViewModel
import com.orbioom.meeple.viewmodel.PlayFeedItem
import com.orbioom.meeple.viewmodel.UiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlaysScreen(
    viewModel: MeepleViewModel,
    onOpenPlay: (String) -> Unit,
    onLogPlay: () -> Unit,
    onOpenSettings: () -> Unit
) {
    val state by viewModel.playsState.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text("Meeple", fontWeight = FontWeight.Bold) },
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
                    icon = Icons.Filled.History,
                    title = "No plays logged yet",
                    body = "Log your first game night and Meeple turns the results into win rates, streaks, and head-to-head records.",
                    actionLabel = "Log a play",
                    actionIcon = Icons.Filled.Add,
                    onAction = onLogPlay
                )
                is UiState.Content -> PlaysList(s.data, onOpenPlay)
            }

            if (state is UiState.Content) {
                InkButton(
                    text = "Log a play",
                    icon = Icons.Filled.Add,
                    onClick = onLogPlay,
                    modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp)
                )
            }
        }
    }
}

@Composable
private fun PlaysList(items: List<PlayFeedItem>, onOpen: (String) -> Unit) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 96.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(items, key = { it.play.id }) { item ->
            PlayRow(item = item, onOpen = { onOpen(item.play.id) })
        }
    }
}

@Composable
private fun PlayRow(item: PlayFeedItem, onOpen: () -> Unit) {
    val brand = LocalBrand.current
    val play = item.play
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = onOpen,
        onClickLabel = "Open ${item.gameTitle} play from ${Format.date(play.date)}"
    ) {
        Column {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = item.gameTitle,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                Text(
                    text = Format.shortDate(play.date),
                    style = MaterialTheme.typography.labelLarge,
                    color = brand.textSecondary
                )
            }
            Spacer(Modifier.height(6.dp))
            val winnerLine = when {
                item.scoringIsCoop && play.coopGroupWon -> "Group won together"
                item.scoringIsCoop && !play.coopGroupWon -> "Group lost together"
                item.winnerNames.isEmpty() -> "No winner recorded"
                item.winnerNames.size == 1 -> "${item.winnerNames.first()} won"
                else -> "Tie: ${item.winnerNames.joinToString(", ")}"
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                OutcomeDot(won = if (item.scoringIsCoop) play.coopGroupWon else item.winnerNames.isNotEmpty())
                Spacer(Modifier.width(8.dp))
                Text(
                    text = winnerLine,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            Spacer(Modifier.height(4.dp))
            val meta = buildString {
                append("${item.playerCount} player${if (item.playerCount == 1) "" else "s"}")
                if (play.location.isNotBlank()) append("  ·  ${play.location}")
                if ((play.durationMinutes ?: 0) > 0) append("  ·  ${Format.duration(play.durationMinutes)}")
            }
            Text(
                text = meta,
                style = MaterialTheme.typography.bodyMedium,
                color = brand.textSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}
