package com.orbioom.meeple.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.orbioom.meeple.data.MeepleRepository
import com.orbioom.meeple.domain.Game
import com.orbioom.meeple.domain.Play
import com.orbioom.meeple.domain.Player
import com.orbioom.meeple.domain.Stats
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn

/** A game paired with its rolled-up stats, for the collection list. */
data class GameCard(val game: Game, val stats: Stats.GameStats)

/** A player paired with rolled-up stats, for the people list. */
data class PlayerCard(val stats: Stats.PlayerStats)

/** A play joined with its game's title and resolved winner names, for the feed. */
data class PlayFeedItem(
    val play: Play,
    val gameTitle: String,
    val scoringIsCoop: Boolean,
    val winnerNames: List<String>,
    val playerCount: Int
)

/** Generic three-state wrapper used by every data screen. */
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data object Empty : UiState<Nothing>
    data class Content<T>(val data: T) : UiState<T>
}

class MeepleViewModel(app: Application) : AndroidViewModel(app) {

    private val repository = MeepleRepository(app.applicationContext, viewModelScope)

    val loaded: StateFlow<Boolean> = repository.loaded

    // ---- Plays feed (home) ----
    val playsState: StateFlow<UiState<List<PlayFeedItem>>> =
        combine(repository.plays, repository.games, repository.players, repository.loaded) {
            plays, games, players, loaded ->
            val gameById = games.associateBy { it.id }
            val playerById = players.associateBy { it.id }
            when {
                !loaded -> UiState.Loading
                plays.isEmpty() -> UiState.Empty
                else -> UiState.Content(
                    plays.sortedByDescending { it.date }.map { play ->
                        val game = gameById[play.gameId]
                        val winnerIds = game?.let { Stats.winners(it, play) } ?: emptySet()
                        PlayFeedItem(
                            play = play,
                            gameTitle = game?.title ?: "Unknown game",
                            scoringIsCoop = game?.scoringType == com.orbioom.meeple.domain.ScoringType.COOPERATIVE,
                            winnerNames = winnerIds.mapNotNull { playerById[it]?.name }.sorted(),
                            playerCount = play.results.size
                        )
                    }
                )
            }
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), UiState.Loading)

    // ---- Games collection ----
    val gamesState: StateFlow<UiState<List<GameCard>>> =
        combine(repository.games, repository.plays, repository.loaded) { games, plays, loaded ->
            when {
                !loaded -> UiState.Loading
                games.isEmpty() -> UiState.Empty
                else -> UiState.Content(
                    games.map { g -> GameCard(g, Stats.forGame(g, plays)) }
                        .sortedWith(compareByDescending<GameCard> { it.stats.playCount }
                            .thenBy { it.game.title.lowercase() })
                )
            }
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), UiState.Loading)

    // ---- Players ----
    val playersState: StateFlow<UiState<List<PlayerCard>>> =
        combine(repository.players, repository.games, repository.plays, repository.loaded) {
            players, games, plays, loaded ->
            when {
                !loaded -> UiState.Loading
                players.isEmpty() -> UiState.Empty
                else -> UiState.Content(
                    players.map { p -> PlayerCard(Stats.forPlayer(p, games, plays)) }
                        .sortedWith(compareByDescending<PlayerCard> { it.stats.totalPlays }
                            .thenBy { it.stats.player.name.lowercase() })
                )
            }
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), UiState.Loading)

    // ---- Insights overview ----
    val overviewState: StateFlow<UiState<Stats.Overview>> =
        combine(repository.games, repository.players, repository.plays, repository.loaded) {
            games, players, plays, loaded ->
            when {
                !loaded -> UiState.Loading
                plays.isEmpty() && games.isEmpty() && players.isEmpty() -> UiState.Empty
                else -> UiState.Content(Stats.overview(games, players, plays))
            }
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), UiState.Loading)

    // ---- Live streams for detail screens ----

    /** Game + its stats; null once the game no longer exists so detail can pop cleanly. */
    fun gameStatsFlow(id: String): StateFlow<Stats.GameStats?> =
        combine(repository.games, repository.plays) { games, plays ->
            games.firstOrNull { it.id == id }?.let { Stats.forGame(it, plays) }
        }.stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = repository.game(id)?.let { Stats.forGame(it, repository.plays.value) }
        )

    fun playerStatsFlow(id: String): StateFlow<Stats.PlayerStats?> =
        combine(repository.players, repository.games, repository.plays) { players, games, plays ->
            players.firstOrNull { it.id == id }?.let { Stats.forPlayer(it, games, plays) }
        }.stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = repository.player(id)?.let {
                Stats.forPlayer(it, repository.games.value, repository.plays.value)
            }
        )

    /** Plays for a specific game, newest first — used on the game detail screen. */
    fun playsForGameFlow(gameId: String): StateFlow<List<PlayFeedItem>> =
        combine(repository.plays, repository.games, repository.players) { plays, games, players ->
            val gameById = games.associateBy { it.id }
            val playerById = players.associateBy { it.id }
            plays.filter { it.gameId == gameId }.sortedByDescending { it.date }.map { play ->
                val game = gameById[play.gameId]
                val winnerIds = game?.let { Stats.winners(it, play) } ?: emptySet()
                PlayFeedItem(
                    play = play,
                    gameTitle = game?.title ?: "",
                    scoringIsCoop = game?.scoringType == com.orbioom.meeple.domain.ScoringType.COOPERATIVE,
                    winnerNames = winnerIds.mapNotNull { playerById[it]?.name }.sorted(),
                    playerCount = play.results.size
                )
            }
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    // ---- Synchronous reads for edit screens ----

    fun game(id: String): Game? = repository.game(id)
    fun player(id: String): Player? = repository.player(id)
    fun play(id: String): Play? = repository.play(id)
    fun allGames(): List<Game> = repository.games.value
    fun allPlayers(): List<Player> = repository.players.value
    fun playerName(id: String): String? = repository.player(id)?.name
    fun gameTitle(id: String): String? = repository.game(id)?.title

    /** The most recently dated play, for "remember last players" convenience. */
    fun lastPlay(): Play? = repository.plays.value.maxByOrNull { it.date }

    // ---- Intents ----

    fun saveGame(game: Game) = repository.upsertGame(game)
    fun deleteGame(id: String) = repository.deleteGame(id)
    fun savePlayer(player: Player) = repository.upsertPlayer(player)
    fun deletePlayer(id: String) = repository.deletePlayer(id)

    /** Resolve winners before persisting so stored results always match the scoring rules. */
    fun savePlay(play: Play) {
        val game = repository.game(play.gameId)
        val resolved = if (game != null) play.copy(results = Stats.resolvedResults(game, play)) else play
        repository.upsertPlay(resolved)
    }

    fun deletePlay(id: String) = repository.deletePlay(id)
    fun resetToSample() = repository.resetToSample()
    fun clearAll() = repository.clearAll()
}
