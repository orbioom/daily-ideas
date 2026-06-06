package com.orbioom.meeple.domain

import kotlinx.serialization.Serializable

/**
 * Pure Kotlin domain models — no Android imports. Serialized to JSON on disk.
 *
 * Meeple keeps a calm relational log of your board-game collection, the people you play
 * with, and every play session — then turns the raw results into real analytics: win rates,
 * head-to-head records, nemeses, streaks, and score distributions.
 *
 * The relational shape:
 *   Game 1 ── * Play ── * PlayerResult * ── 1 Player
 * A [Play] references a [Game] by id and holds an ordered list of [PlayerResult] rows; each
 * result references a [Player] by id. Stats join these together.
 */

/** How a game decides who won. Drives every winner computation. */
@Serializable
enum class ScoringType(val title: String, val shortLabel: String) {
    /** Most points wins (Catan, Wingspan). */
    HIGHEST_WINS("Highest score wins", "High"),

    /** Fewest points wins (golf-style, some racing/penalty games). */
    LOWEST_WINS("Lowest score wins", "Low"),

    /** Players win or lose together against the game (Pandemic, Spirit Island). */
    COOPERATIVE("Cooperative (win together)", "Co-op");

    companion object {
        fun fromNameOrDefault(raw: String?): ScoringType =
            entries.firstOrNull { it.name.equals(raw, ignoreCase = true) } ?: HIGHEST_WINS
    }
}

/** A game in your collection. */
@Serializable
data class Game(
    val id: String,
    val title: String,
    val designer: String = "",
    val minPlayers: Int = 1,
    val maxPlayers: Int = 4,
    /** Typical play time in minutes; null when unknown. */
    val playTimeMinutes: Int? = null,
    val scoringType: ScoringType = ScoringType.HIGHEST_WINS,
    val notes: String = "",
    val createdAt: Long = 0L
)

/** A person you play with. */
@Serializable
data class Player(
    val id: String,
    val name: String,
    /** Optional ARGB color (e.g. 0xFF86C79A) for the player's token; null = themed default. */
    val colorArgb: Long? = null,
    val createdAt: Long = 0L
)

/**
 * One player's outcome within a [Play]. For competitive games [score] ranks players and the
 * winner is derived per the game's [ScoringType]; [isWinner] is computed and stored for the
 * record. For cooperative games every result shares the same group outcome.
 */
@Serializable
data class PlayerResult(
    val playerId: String,
    /** Null when the game is scoreless (pure co-op or a game tracked by win/loss only). */
    val score: Double? = null,
    /** The recorded winner flag, already resolved for scoring type and co-op. */
    val isWinner: Boolean = false
)

/** A single play session of a [Game]. */
@Serializable
data class Play(
    val id: String,
    val gameId: String,
    /** Epoch millis of the session, used for ordering and the plays-over-time series. */
    val date: Long,
    /** Duration in minutes; null when not recorded. */
    val durationMinutes: Int? = null,
    val location: String = "",
    val notes: String = "",
    /** For cooperative games: did the group beat the game? Ignored for competitive games. */
    val coopGroupWon: Boolean = false,
    /** Ordered seating/turn order. At least one result is required to save a play. */
    val results: List<PlayerResult> = emptyList()
)
