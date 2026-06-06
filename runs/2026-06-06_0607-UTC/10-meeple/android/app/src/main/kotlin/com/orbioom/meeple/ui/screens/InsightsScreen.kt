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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
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
import com.orbioom.meeple.domain.Stats
import com.orbioom.meeple.ui.components.BarPoint
import com.orbioom.meeple.ui.components.EmptyState
import com.orbioom.meeple.ui.components.GlassCard
import com.orbioom.meeple.ui.components.LoadingState
import com.orbioom.meeple.ui.components.PlaysBarChart
import com.orbioom.meeple.ui.components.StatTile
import com.orbioom.meeple.ui.theme.LocalBrand
import com.orbioom.meeple.viewmodel.MeepleViewModel
import com.orbioom.meeple.viewmodel.UiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsScreen(
    viewModel: MeepleViewModel,
    onOpenGame: (String) -> Unit,
    onOpenPlayer: (String) -> Unit,
    onOpenSettings: () -> Unit
) {
    val state by viewModel.overviewState.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text("Insights", fontWeight = FontWeight.Bold) },
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
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (val s = state) {
                is UiState.Loading -> LoadingState()
                is UiState.Empty -> EmptyState(
                    icon = Icons.Filled.BarChart,
                    title = "No insights yet",
                    body = "Add games and players, then log a few plays. Meeple turns them into collection-wide stats and trends."
                )
                is UiState.Content -> InsightsContent(s.data, onOpenGame, onOpenPlayer)
            }
        }
    }
}

@Composable
private fun InsightsContent(
    overview: Stats.Overview,
    onOpenGame: (String) -> Unit,
    onOpenPlayer: (String) -> Unit
) {
    val brand = LocalBrand.current
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item(key = "totals-1") {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile(label = "Plays", value = overview.playCount.toString(), modifier = Modifier.weight(1f))
                StatTile(label = "Games", value = overview.gameCount.toString(), modifier = Modifier.weight(1f))
                StatTile(label = "Players", value = overview.playerCount.toString(), modifier = Modifier.weight(1f))
            }
        }
        item(key = "totals-2") {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile(
                    label = "Hours played",
                    value = Format.number(overview.totalHoursPlayed, 1),
                    modifier = Modifier.weight(1f)
                )
                StatTile(
                    label = "Last played",
                    value = overview.lastPlay?.let { Format.shortDate(it.date) } ?: "—",
                    modifier = Modifier.weight(1f)
                )
            }
        }

        if (overview.lastPlayGameTitle != null) {
            item(key = "last") {
                GlassCard(modifier = Modifier.fillMaxWidth()) {
                    Text(
                        "Most recent: ${overview.lastPlayGameTitle}" +
                            (overview.lastPlay?.let { "  ·  ${Format.date(it.date)}" } ?: ""),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onBackground
                    )
                }
            }
        }

        // Plays over time.
        item(key = "trend-title") { SectionTitle("Plays over time") }
        item(key = "trend") {
            val bars = overview.playsByMonth.map { BarPoint(it.label, it.count) }
            val desc = if (bars.isEmpty()) "No plays to chart yet."
            else "Monthly play counts from ${bars.first().label} to ${bars.last().label}, " +
                "ranging ${bars.minOf { it.value }} to ${bars.maxOf { it.value }} plays per month."
            PlaysBarChart(points = bars, barColor = brand.win, contentDescription = desc)
        }

        // Most-played games.
        if (overview.mostPlayed.isNotEmpty()) {
            item(key = "mp-title") { SectionTitle("Most played games") }
            overview.mostPlayed.forEachIndexed { index, gs ->
                item(key = "mp-${gs.game.id}") {
                    RankRow(
                        rank = index + 1,
                        title = gs.game.title,
                        trailing = Format.plays(gs.playCount),
                        onClick = { onOpenGame(gs.game.id) }
                    )
                }
            }
        }

        // Top winners.
        if (overview.topWinners.isNotEmpty()) {
            item(key = "tw-title") { SectionTitle("Top win rates") }
            overview.topWinners.forEachIndexed { index, ps ->
                item(key = "tw-${ps.player.id}") {
                    RankRow(
                        rank = index + 1,
                        title = ps.player.name,
                        trailing = "${Format.percent(ps.winRate)}  ·  ${Format.record(ps.totalWins, ps.totalPlays - ps.totalWins)}",
                        accentTrailing = ps.winRate >= 0.5,
                        onClick = { onOpenPlayer(ps.player.id) }
                    )
                }
            }
        }
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleMedium,
        color = MaterialTheme.colorScheme.onBackground,
        fontWeight = FontWeight.Bold
    )
}

@Composable
private fun RankRow(
    rank: Int,
    title: String,
    trailing: String,
    accentTrailing: Boolean = false,
    onClick: () -> Unit
) {
    val brand = LocalBrand.current
    GlassCard(modifier = Modifier.fillMaxWidth(), onClick = onClick, onClickLabel = "Open $title") {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                "$rank",
                style = MaterialTheme.typography.titleLarge,
                color = brand.textTertiary,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.width(28.dp)
            )
            Spacer(Modifier.width(8.dp))
            Text(
                title,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.weight(1f),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(Modifier.width(8.dp))
            Text(
                trailing,
                style = MaterialTheme.typography.bodyMedium,
                color = if (accentTrailing) brand.win else brand.textSecondary,
                fontWeight = FontWeight.Medium
            )
        }
    }
}
