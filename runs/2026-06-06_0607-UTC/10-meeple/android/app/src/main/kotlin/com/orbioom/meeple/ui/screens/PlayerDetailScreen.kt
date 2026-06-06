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
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Groups
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
import com.orbioom.meeple.domain.Stats
import com.orbioom.meeple.ui.components.EmptyState
import com.orbioom.meeple.ui.components.GlassCard
import com.orbioom.meeple.ui.components.PlayerToken
import com.orbioom.meeple.ui.components.RatioBar
import com.orbioom.meeple.ui.components.StatTile
import com.orbioom.meeple.ui.theme.LocalBrand
import com.orbioom.meeple.viewmodel.MeepleViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlayerDetailScreen(
    playerId: String,
    viewModel: MeepleViewModel,
    onBack: () -> Unit,
    onEdit: () -> Unit,
    onOpenGame: (String) -> Unit,
    onOpenPlayer: (String) -> Unit
) {
    val stats by viewModel.playerStatsFlow(playerId).collectAsStateWithLifecycle()
    var showDelete by rememberSaveable { mutableStateOf(false) }
    val current = stats

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        current?.player?.name ?: "Player",
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
                            Icon(Icons.Filled.Edit, contentDescription = "Edit player")
                        }
                        IconButton(onClick = { showDelete = true }) {
                            Icon(Icons.Filled.Delete, contentDescription = "Delete player")
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
                    icon = Icons.Filled.Groups,
                    title = "Player unavailable",
                    body = "This player is no longer in your list.",
                    actionLabel = "Go back",
                    onAction = onBack
                )
                return@Box
            }
            PlayerDetailContent(
                stats = current,
                gameTitle = { id -> viewModel.gameTitle(id) ?: "Unknown" },
                playerName = { id -> viewModel.playerName(id) ?: "Unknown" },
                playerColor = { id -> viewModel.player(id)?.colorArgb },
                onOpenGame = onOpenGame,
                onOpenPlayer = onOpenPlayer
            )
        }
    }

    if (showDelete && current != null) {
        ConfirmDialog(
            title = "Delete ${current.player.name}?",
            body = "This removes the player and their results from every play. Plays left with no players are removed too. This cannot be undone.",
            confirmLabel = "Delete player",
            onConfirm = {
                showDelete = false
                viewModel.deletePlayer(playerId)
                onBack()
            },
            onDismiss = { showDelete = false }
        )
    }
}

@Composable
private fun PlayerDetailContent(
    stats: Stats.PlayerStats,
    gameTitle: (String) -> String,
    playerName: (String) -> String,
    playerColor: (String) -> Long?,
    onOpenGame: (String) -> Unit,
    onOpenPlayer: (String) -> Unit
) {
    val brand = LocalBrand.current
    val p = stats.player
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item(key = "header") {
            GlassCard(modifier = Modifier.fillMaxWidth()) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    PlayerToken(name = p.name, colorArgb = p.colorArgb, sizeDp = 48)
                    Spacer(Modifier.width(14.dp))
                    Column {
                        Text(
                            "${Format.record(stats.totalWins, stats.totalPlays - stats.totalWins)} overall record",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onBackground,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            stats.lastPlayed?.let { "Last played ${Format.shortDate(it)}" } ?: "No plays yet",
                            style = MaterialTheme.typography.bodyMedium,
                            color = brand.textSecondary
                        )
                    }
                }
            }
        }

        item(key = "stat-1") {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile(
                    label = "Win rate",
                    value = if (stats.totalPlays == 0) "—" else Format.percent(stats.winRate),
                    accent = stats.totalPlays > 0 && stats.winRate >= 0.5,
                    modifier = Modifier.weight(1f)
                )
                StatTile(label = "Total plays", value = stats.totalPlays.toString(), modifier = Modifier.weight(1f))
            }
        }

        item(key = "stat-2") {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile(
                    label = "Longest streak",
                    value = if (stats.longestWinStreak == 0) "—" else "${stats.longestWinStreak}W",
                    accent = stats.longestWinStreak >= 3,
                    modifier = Modifier.weight(1f)
                )
                StatTile(
                    label = "Current streak",
                    value = streakLabel(stats.currentStreak),
                    modifier = Modifier.weight(1f)
                )
            }
        }

        // Favorite game + nemesis call-outs.
        item(key = "callouts") {
            val favId = stats.favoriteGameId
            val nemId = stats.nemesisPlayerId
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                if (favId != null) {
                    CalloutCard(
                        label = "Most played",
                        value = gameTitle(favId),
                        sub = Format.plays(stats.favoriteGamePlays),
                        onClick = { onOpenGame(favId) }
                    )
                }
                if (nemId != null) {
                    CalloutCard(
                        label = "Nemesis",
                        value = playerName(nemId),
                        sub = "beaten by them ${stats.nemesisLosses} time${if (stats.nemesisLosses == 1) "" else "s"}",
                        tokenColor = playerColor(nemId),
                        tokenName = playerName(nemId),
                        onClick = { onOpenPlayer(nemId) }
                    )
                }
            }
        }

        // Head-to-head.
        if (stats.headToHead.isNotEmpty()) {
            item(key = "h2h-header") { SectionTitle("Head-to-head") }
            items(stats.headToHead, key = { "h2h-${it.opponentId}" }) { h2h ->
                HeadToHeadRow(
                    h2h = h2h,
                    opponentName = playerName(h2h.opponentId),
                    opponentColor = playerColor(h2h.opponentId),
                    onClick = { onOpenPlayer(h2h.opponentId) }
                )
            }
        }

        // Per-game breakdown.
        if (stats.perGame.isNotEmpty()) {
            item(key = "pg-header") { SectionTitle("By game") }
            items(stats.perGame, key = { "pg-${it.playerId}" }) { rec ->
                // Here PlayerGameRecord.playerId carries the GAME id (see Stats.forPlayer).
                PerGameRow(
                    title = gameTitle(rec.playerId),
                    record = rec,
                    onClick = { onOpenGame(rec.playerId) }
                )
            }
        }
    }
}

private fun streakLabel(streak: Int): String = when {
    streak > 0 -> "${streak}W"
    streak < 0 -> "${-streak}L"
    else -> "—"
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
private fun CalloutCard(
    label: String,
    value: String,
    sub: String,
    tokenColor: Long? = null,
    tokenName: String? = null,
    onClick: () -> Unit
) {
    val brand = LocalBrand.current
    GlassCard(modifier = Modifier.fillMaxWidth(), onClick = onClick, onClickLabel = "$label $value") {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (tokenName != null) {
                PlayerToken(name = tokenName, colorArgb = tokenColor)
                Spacer(Modifier.width(12.dp))
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    label.uppercase(),
                    style = MaterialTheme.typography.labelMedium,
                    color = brand.textTertiary,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    value,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(sub, style = MaterialTheme.typography.bodyMedium, color = brand.textSecondary)
            }
        }
    }
}

@Composable
private fun HeadToHeadRow(
    h2h: Stats.HeadToHead,
    opponentName: String,
    opponentColor: Long?,
    onClick: () -> Unit
) {
    val brand = LocalBrand.current
    GlassCard(modifier = Modifier.fillMaxWidth(), onClick = onClick, onClickLabel = "Open $opponentName") {
        Column {
            Row(verticalAlignment = Alignment.CenterVertically) {
                PlayerToken(name = opponentName, colorArgb = opponentColor, sizeDp = 30)
                Spacer(Modifier.width(12.dp))
                Text(
                    opponentName,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    Format.record(h2h.wins, h2h.losses) + if (h2h.ties > 0) " (${h2h.ties}T)" else "",
                    style = MaterialTheme.typography.titleMedium,
                    color = if (h2h.wins > h2h.losses) brand.win
                    else if (h2h.losses > h2h.wins) brand.loss
                    else MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.Bold
                )
            }
            Spacer(Modifier.height(8.dp))
            RatioBar(ratio = h2h.winRate.toFloat())
        }
    }
}

@Composable
private fun PerGameRow(
    title: String,
    record: Stats.PlayerGameRecord,
    onClick: () -> Unit
) {
    val brand = LocalBrand.current
    GlassCard(modifier = Modifier.fillMaxWidth(), onClick = onClick, onClickLabel = "Open $title") {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    title,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    "${Format.plays(record.plays)}  ·  ${Format.record(record.wins, record.plays - record.wins)}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textSecondary
                )
            }
            Spacer(Modifier.width(12.dp))
            Text(
                Format.percent(record.winRate),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold
            )
        }
    }
}
