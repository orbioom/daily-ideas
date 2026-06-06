package com.orbioom.meeple.data

import android.content.Context
import com.orbioom.meeple.domain.Game
import com.orbioom.meeple.domain.Play
import com.orbioom.meeple.domain.Player
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File

/** The whole collection, serialized as one JSON document in app-internal storage. */
@Serializable
private data class MeepleData(
    val games: List<Game> = emptyList(),
    val players: List<Player> = emptyList(),
    val plays: List<Play> = emptyList()
)

/**
 * Local-first store for games, players, and plays. Persists everything as a single JSON file
 * (no Room, no annotation processors). All disk work runs on [Dispatchers.IO]; the UI observes
 * [games], [players], and [plays] as immutable state and reacts to [loaded].
 */
class MeepleRepository(
    context: Context,
    private val scope: CoroutineScope
) {
    private val file = File(context.filesDir, "meeple_collection.json")
    private val mutex = Mutex()
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        encodeDefaults = true
        prettyPrint = true
    }

    private val _games = MutableStateFlow<List<Game>>(emptyList())
    val games: StateFlow<List<Game>> = _games.asStateFlow()

    private val _players = MutableStateFlow<List<Player>>(emptyList())
    val players: StateFlow<List<Player>> = _players.asStateFlow()

    private val _plays = MutableStateFlow<List<Play>>(emptyList())
    val plays: StateFlow<List<Play>> = _plays.asStateFlow()

    private val _loaded = MutableStateFlow(false)
    val loaded: StateFlow<Boolean> = _loaded.asStateFlow()

    init {
        scope.launch { load() }
    }

    private suspend fun load() = withContext(Dispatchers.IO) {
        val data = mutex.withLock { readFromDisk() }
        _games.value = data.games
        _players.value = data.players
        _plays.value = data.plays
        _loaded.value = true
    }

    private fun readFromDisk(): MeepleData {
        if (!file.exists()) {
            // First ever launch — seed a real, populated collection.
            val seed = SampleData.starter()
            val data = MeepleData(seed.games, seed.players, seed.plays)
            runCatching { file.writeText(json.encodeToString(data)) }
            return data
        }
        return runCatching {
            val text = file.readText()
            if (text.isBlank()) MeepleData() else json.decodeFromString<MeepleData>(text)
        }.getOrElse {
            // Corrupt/partial file: don't crash — start from a clean, empty collection.
            MeepleData()
        }
    }

    private suspend fun persist() = withContext(Dispatchers.IO) {
        val snapshot = MeepleData(_games.value, _players.value, _plays.value)
        mutex.withLock {
            runCatching { file.writeText(json.encodeToString(snapshot)) }
        }
    }

    private fun save() { scope.launch { persist() } }

    // ---- Games ----

    fun game(id: String): Game? = _games.value.firstOrNull { it.id == id }

    fun upsertGame(game: Game) {
        val current = _games.value
        val idx = current.indexOfFirst { it.id == game.id }
        _games.value = if (idx >= 0) {
            current.toMutableList().also { it[idx] = game }
        } else current + game
        save()
    }

    fun deleteGame(id: String) {
        _games.value = _games.value.filterNot { it.id == id }
        // Plays belong to a game; remove orphans.
        _plays.value = _plays.value.filterNot { it.gameId == id }
        save()
    }

    // ---- Players ----

    fun player(id: String): Player? = _players.value.firstOrNull { it.id == id }

    fun upsertPlayer(player: Player) {
        val current = _players.value
        val idx = current.indexOfFirst { it.id == player.id }
        _players.value = if (idx >= 0) {
            current.toMutableList().also { it[idx] = player }
        } else current + player
        save()
    }

    fun deletePlayer(id: String) {
        _players.value = _players.value.filterNot { it.id == id }
        // Strip this player's results from every play, dropping plays left with no players.
        _plays.value = _plays.value
            .map { play -> play.copy(results = play.results.filterNot { it.playerId == id }) }
            .filterNot { it.results.isEmpty() }
        save()
    }

    // ---- Plays ----

    fun play(id: String): Play? = _plays.value.firstOrNull { it.id == id }

    fun playsForGame(gameId: String): List<Play> = _plays.value.filter { it.gameId == gameId }

    fun upsertPlay(play: Play) {
        val current = _plays.value
        val idx = current.indexOfFirst { it.id == play.id }
        _plays.value = if (idx >= 0) {
            current.toMutableList().also { it[idx] = play }
        } else current + play
        save()
    }

    fun deletePlay(id: String) {
        _plays.value = _plays.value.filterNot { it.id == id }
        save()
    }

    // ---- Bulk ----

    fun resetToSample() {
        val seed = SampleData.starter()
        _games.value = seed.games
        _players.value = seed.players
        _plays.value = seed.plays
        save()
    }

    fun clearAll() {
        _games.value = emptyList()
        _players.value = emptyList()
        _plays.value = emptyList()
        save()
    }
}
