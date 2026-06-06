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
import androidx.compose.material.icons.filled.Casino
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.EmojiEvents
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
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.orbioom.meeple.domain.Format
import com.orbioom.meeple.domain.Game
import com.orbioom.meeple.domain.Play
import com.orbioom.meeple.domain.PlayerResult
import com.orbioom.meeple.domain.ScoringType
import com.orbioom.meeple.domain.Stats
import com.orbioom.meeple.ui.components.EmptyState
import com.orbioom.meeple.ui.components.GlassCard
import com.orbioom.meeple.ui.components.OutcomeDot
import com.orbioom.meeple.ui.components.PlayerToken
import com.orbioom.meeple.ui.theme.LocalBrand
import com.orbioom.meeple.viewmodel.MeepleViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlayDetailScreen(
    playId: String,
    viewModel: MeepleViewModel,
    onBack: () -> Unit,
    onEdit: () -> Unit,
    onOpenGame: (String) -> Unit,
    onOpenPlayer: (String) -> Unit
) {
    // A play is immutable once shown; re-read on entry. Deletion pops back.
    val play = remember(playId) { viewModel.play(playId) }
    val game = remember(playId) { play?.let { viewModel.game(it.gameId) } }
    var showDelete by rememberSaveable { mutableStateOf(false) }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        game?.title ?: "Play",
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
                    if (play != null) {
                        IconButton(onClick = onEdit) {
                            Icon(Icons.Filled.Edit, contentDescription = "Edit play")
                        }
                        IconButton(onClick = { showDelete = true }) {
                            Icon(Icons.Filled.Delete, contentDescription = "Delete play")
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
            if (play == null || game == null) {
                EmptyState(
                    icon = Icons.Filled.Casino,
                    title = "Play unavailable",
                    body = "This play is no longer in your log.",
                    actionLabel = "Go back",
                    onAction = onBack
                )
                return@Box
            }
            PlayDetailContent(
                play = play,
                game = game,
                playerName = { id -> viewModel.playerName(id) ?: "Unknown" },
                playerColor = { id -> viewModel.player(id)?.colorArgb },
                onOpenGame = onOpenGame,
                onOpenPlayer = onOpenPlayer
            )
        }
    }

    if (showDelete && play != null) {
        ConfirmDialog(
            title = "Delete this play?",
            body = "This removes the play from your log and updates every affected stat. This cannot be undone.",
            confirmLabel = "Delete play",
            onConfirm = {
                showDelete = false
                viewModel.deletePlay(playId)
                onBack()
            },
            onDismiss = { showDelete = false }
        )
    }
}

@Composable
private fun PlayDetailContent(
    play: Play,
    game: Game,
    playerName: (String) -> String,
    playerColor: (String) -> Long?,
    onOpenGame: (String) -> Unit,
    onOpenPlayer: (String) -> Unit
) {
    val brand = LocalBrand.current
    val winnerIds = Stats.winners(game, play)
    val isCoop = game.scoringType == ScoringType.COOPERATIVE

    // Order results: for competitive, by score per scoring type; co-op keeps seating order.
    val ordered = if (isCoop) play.results
    else play.results.sortedWith(
        compareByDescending<PlayerResult> { it.score ?: Double.NEGATIVE_INFINITY }
            .let { cmp -> if (game.scoringType == ScoringType.LOWEST_WINS) cmp.reversed() else cmp }
    )

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item(key = "summary") {
            GlassCard(modifier = Modifier.fillMaxWidth(), onClick = { onOpenGame(game.id) }, onClickLabel = "Open ${game.title}") {
                Column {
                    Text(
                        game.title,
                        style = MaterialTheme.typography.titleLarge,
                        color = MaterialTheme.colorScheme.onBackground,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        Format.date(play.date) + (if (play.location.isNotBlank()) "  ·  ${play.location}" else "") +
                            (if ((play.durationMinutes ?: 0) > 0) "  ·  ${Format.duration(play.durationMinutes)}" else ""),
                        style = MaterialTheme.typography.bodyMedium,
                        color = brand.textSecondary
                    )
                    if (isCoop) {
                        Spacer(Modifier.height(10.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Filled.EmojiEvents,
                                contentDescription = null,
                                tint = if (play.coopGroupWon) brand.win else brand.loss,
                                modifier = Modifier.width(20.dp)
                            )
                            Spacer(Modifier.width(8.dp))
                            Text(
                                if (play.coopGroupWon) "The group won together" else "The group lost together",
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onBackground,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                    if (play.notes.isNotBlank()) {
                        Spacer(Modifier.height(10.dp))
                        Text(play.notes, style = MaterialTheme.typography.bodyMedium, color = brand.textSecondary)
                    }
                }
            }
        }

        item(key = "results-header") {
            Text(
                if (isCoop) "Players" else "Results",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold
            )
        }

        items(ordered, key = { "r-${it.playerId}" }) { result ->
            val won = winnerIds.contains(result.playerId)
            ResultRow(
                name = playerName(result.playerId),
                color = playerColor(result.playerId),
                score = result.score,
                won = won,
                isCoop = isCoop,
                onClick = { onOpenPlayer(result.playerId) }
            )
        }
    }
}

@Composable
private fun ResultRow(
    name: String,
    color: Long?,
    score: Double?,
    won: Boolean,
    isCoop: Boolean,
    onClick: () -> Unit
) {
    val brand = LocalBrand.current
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = onClick,
        onClickLabel = "Open $name"
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            PlayerToken(name = name, colorArgb = color, sizeDp = 36)
            Spacer(Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    name,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Row(verticalAlignment = Alignment.CenterVertically) {
                    OutcomeDot(won = won)
                    Spacer(Modifier.width(6.dp))
                    Text(
                        if (won) (if (isCoop) "Won" else "Winner") else (if (isCoop) "Lost" else "—"),
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (won) brand.win else brand.textSecondary
                    )
                }
            }
            if (!isCoop) {
                Spacer(Modifier.width(8.dp))
                Text(
                    Format.score(score),
                    style = MaterialTheme.typography.titleLarge,
                    color = if (won) brand.win else MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
