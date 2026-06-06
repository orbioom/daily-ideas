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
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
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
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.orbioom.meeple.domain.Format
import com.orbioom.meeple.domain.ScoringType
import com.orbioom.meeple.domain.Stats
import com.orbioom.meeple.ui.components.EmptyState
import com.orbioom.meeple.ui.components.GlassCard
import com.orbioom.meeple.ui.components.InkButton
import com.orbioom.meeple.ui.components.RatioBar
import com.orbioom.meeple.ui.components.StatTile
import com.orbioom.meeple.ui.theme.LocalBrand
import com.orbioom.meeple.viewmodel.MeepleViewModel
import com.orbioom.meeple.viewmodel.PlayFeedItem

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GameDetailScreen(
    gameId: String,
    viewModel: MeepleViewModel,
    onBack: () -> Unit,
    onEdit: () -> Unit,
    onLogPlay: () -> Unit,
    onOpenPlay: (String) -> Unit,
    onOpenPlayer: (String) -> Unit
) {
    val stats by viewModel.gameStatsFlow(gameId).collectAsStateWithLifecycle()
    val plays by viewModel.playsForGameFlow(gameId).collectAsStateWithLifecycle()
    var showDelete by rememberSaveable { mutableStateOf(false) }

    val current = stats

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        current?.game?.title ?: "Game",
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (current != null) {
                        IconButton(onClick = onEdit) {
                            Icon(Icons.Filled.Edit, contentDescription = "Edit game")
                        }
                        IconButton(onClick = { showDelete = true }) {
                            Icon(Icons.Filled.Delete, contentDescription = "Delete game")
                        }
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
            if (current == null) {
                EmptyState(
                    icon = Icons.Filled.Add,
                    title = "Game unavailable",
                    body = "This game is no longer in your collection.",
                    actionLabel = "Go back",
                    onAction = onBack
                )
                return@Box
            }
            GameDetailContent(
                stats = current,
                plays = plays,
                playerName = { id -> viewModel.playerName(id) ?: "Unknown" },
                onLogPlay = onLogPlay,
                onOpenPlay = onOpenPlay,
                onOpenPlayer = onOpenPlayer
            )
        }
    }

    if (showDelete && current != null) {
        ConfirmDialog(
            title = "Delete ${current.game.title}?",
            body = "This removes the game and all ${Format.plays(current.playCount)} logged for it. This cannot be undone.",
            confirmLabel = "Delete game",
            onConfirm = {
                showDelete = false
                viewModel.deleteGame(gameId)
                onBack()
            },
            onDismiss = { showDelete = false }
        )
    }
}

@Composable
private fun GameDetailContent(
    stats: Stats.GameStats,
    plays: List<PlayFeedItem>,
    playerName: (String) -> String,
    onLogPlay: () -> Unit,
    onOpenPlay: (String) -> Unit,
    onOpenPlayer: (String) -> Unit
) {
    val brand = LocalBrand.current
    val game = stats.game
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item(key = "header") {
            GlassCard(modifier = Modifier.fillMaxWidth()) {
                Column {
                    if (game.designer.isNotBlank()) {
                        Text(
                            "Designed by ${game.designer}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = brand.textSecondary
                        )
                        Spacer(Modifier.height(6.dp))
                    }
                    Text(
                        "${Format.players(game.minPlayers, game.maxPlayers)}  ·  ${game.scoringType.title}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onBackground
                    )
                    if ((game.playTimeMinutes ?: 0) > 0) {
                        Spacer(Modifier.height(4.dp))
                        Text(
                            "Typical play time ${Format.duration(game.playTimeMinutes)}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = brand.textSecondary
                        )
                    }
                    if (game.notes.isNotBlank()) {
                        Spacer(Modifier.height(8.dp))
                        Text(
                            game.notes,
                            style = MaterialTheme.typography.bodyMedium,
                            color = brand.textSecondary
                        )
                    }
                }
            }
        }

        item(key = "stat-row-1") {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile(label = "Plays", value = stats.playCount.toString(), modifier = Modifier.weight(1f))
                StatTile(
                    label = "Last played",
                    value = stats.lastPlayed?.let { Format.shortDate(it) } ?: "—",
                    modifier = Modifier.weight(1f)
                )
            }
        }

        item(key = "stat-row-2") {
            if (game.scoringType == ScoringType.COOPERATIVE) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    StatTile(
                        label = "Group win rate",
                        value = stats.coopWinRate?.let { Format.percent(it) } ?: "—",
                        accent = true,
                        modifier = Modifier.weight(1f)
                    )
                    StatTile(
                        label = "Avg duration",
                        value = Format.duration(stats.averageDurationMinutes),
                        modifier = Modifier.weight(1f)
                    )
                }
            } else {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    StatTile(
                        label = if (game.scoringType == ScoringType.LOWEST_WINS) "Best (low) score" else "High score",
                        value = if (game.scoringType == ScoringType.LOWEST_WINS)
                            Format.score(stats.lowScore) else Format.score(stats.highScore),
                        accent = true,
                        modifier = Modifier.weight(1f)
                    )
                    StatTile(
                        label = "Median score",
                        value = Format.score(stats.medianScore),
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }

        val highHolderId = stats.highScorePlayerId
        if (game.scoringType != ScoringType.COOPERATIVE && highHolderId != null) {
            item(key = "high-holder") {
                GlassCard(modifier = Modifier.fillMaxWidth()) {
                    Text(
                        "Record holder: ${playerName(highHolderId)} with ${Format.score(stats.highScore)}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onBackground
                    )
                }
            }
        }

        // Per-player win rates at this game.
        if (stats.perPlayer.isNotEmpty()) {
            item(key = "wr-header") {
                SectionTitle(if (game.scoringType == ScoringType.COOPERATIVE) "Players (plays)" else "Win rates at this game")
            }
            items(stats.perPlayer, key = { "wr-${it.playerId}" }) { rec ->
                PlayerWinRateRow(
                    name = playerName(rec.playerId),
                    record = rec,
                    isCoop = game.scoringType == ScoringType.COOPERATIVE,
                    onClick = { onOpenPlayer(rec.playerId) }
                )
            }
        }

        // Play log for this game.
        item(key = "log-header") {
            Row(verticalAlignment = Alignment.CenterVertically) {
                SectionTitle("Play log", modifier = Modifier.weight(1f))
            }
        }
        if (plays.isEmpty()) {
            item(key = "no-plays") {
                GlassCard(modifier = Modifier.fillMaxWidth()) {
                    Text(
                        "No plays logged yet. Log one to start building this game's stats.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = brand.textSecondary
                    )
                }
            }
        } else {
            items(plays, key = { "p-${it.play.id}" }) { item ->
                GamePlayRow(item = item, onOpen = { onOpenPlay(item.play.id) })
            }
        }

        item(key = "log-cta") {
            Spacer(Modifier.height(2.dp))
            InkButton(
                text = "Log a play of ${game.title}",
                icon = Icons.Filled.Add,
                onClick = onLogPlay,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Composable
private fun SectionTitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleMedium,
        color = MaterialTheme.colorScheme.onBackground,
        fontWeight = FontWeight.Bold,
        modifier = modifier
    )
}

@Composable
private fun PlayerWinRateRow(
    name: String,
    record: Stats.PlayerGameRecord,
    isCoop: Boolean,
    onClick: () -> Unit
) {
    val brand = LocalBrand.current
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = onClick,
        onClickLabel = "Open $name"
    ) {
        Column {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    name,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f)
                )
                Text(
                    text = if (isCoop) Format.plays(record.plays)
                    else "${Format.percent(record.winRate)}  ·  ${Format.record(record.wins, record.plays - record.wins)}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textSecondary
                )
            }
            if (!isCoop) {
                Spacer(Modifier.height(8.dp))
                RatioBar(ratio = record.winRate.toFloat())
            }
        }
    }
}

@Composable
private fun GamePlayRow(item: PlayFeedItem, onOpen: () -> Unit) {
    val brand = LocalBrand.current
    val play = item.play
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = onOpen,
        onClickLabel = "Open play from ${Format.date(play.date)}"
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                val outcome = when {
                    item.scoringIsCoop && play.coopGroupWon -> "Group won"
                    item.scoringIsCoop -> "Group lost"
                    item.winnerNames.isEmpty() -> "No winner recorded"
                    item.winnerNames.size == 1 -> "${item.winnerNames.first()} won"
                    else -> "Tie: ${item.winnerNames.joinToString(", ")}"
                }
                Text(
                    outcome,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    "${Format.date(play.date)}  ·  ${item.playerCount} player${if (item.playerCount == 1) "" else "s"}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textSecondary
                )
            }
            Spacer(Modifier.width(8.dp))
            Text(
                Format.shortDate(play.date),
                style = MaterialTheme.typography.labelLarge,
                color = brand.textTertiary
            )
        }
    }
}
