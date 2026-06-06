package com.orbioom.meeple.data

import com.orbioom.meeple.domain.Game
import com.orbioom.meeple.domain.Play
import com.orbioom.meeple.domain.Player
import com.orbioom.meeple.domain.PlayerResult
import com.orbioom.meeple.domain.ScoringType
import com.orbioom.meeple.domain.Stats
import java.util.Calendar

/**
 * A real, populated starter collection so first launch shows live stats: 7 games,
 * 5 players, and 24 play sessions spread across several months. Winner flags are computed
 * via [Stats.resolvedResults] so the seed data is always internally consistent.
 */
object SampleData {

    data class Seed(val games: List<Game>, val players: List<Player>, val plays: List<Play>)

    private fun daysAgo(days: Int): Long {
        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_YEAR, -days)
        return cal.timeInMillis
    }

    fun starter(): Seed {
        // ---- Players ----
        val ada = Player("p-ada", "Ada", colorArgb = 0xFF86C79A, createdAt = daysAgo(200))
        val ben = Player("p-ben", "Ben", colorArgb = 0xFF6E8BD6, createdAt = daysAgo(199))
        val cleo = Player("p-cleo", "Cleo", colorArgb = 0xFFD68B6E, createdAt = daysAgo(198))
        val dev = Player("p-dev", "Dev", colorArgb = 0xFFB08BD6, createdAt = daysAgo(197))
        val eli = Player("p-eli", "Eli", colorArgb = 0xFFD6C36E, createdAt = daysAgo(150))
        val players = listOf(ada, ben, cleo, dev, eli)

        // ---- Games ----
        val wingspan = Game(
            "g-wingspan", "Wingspan", "Elizabeth Hargrave",
            minPlayers = 1, maxPlayers = 5, playTimeMinutes = 70,
            scoringType = ScoringType.HIGHEST_WINS,
            notes = "Engine-building about birds. Calm and lovely.", createdAt = daysAgo(200)
        )
        val catan = Game(
            "g-catan", "Catan", "Klaus Teuber",
            minPlayers = 3, maxPlayers = 4, playTimeMinutes = 90,
            scoringType = ScoringType.HIGHEST_WINS,
            notes = "First to 10 victory points.", createdAt = daysAgo(195)
        )
        val azul = Game(
            "g-azul", "Azul", "Michael Kiesling",
            minPlayers = 2, maxPlayers = 4, playTimeMinutes = 40,
            scoringType = ScoringType.HIGHEST_WINS,
            notes = "Tile drafting; mind the floor line.", createdAt = daysAgo(180)
        )
        val pandemic = Game(
            "g-pandemic", "Pandemic", "Matt Leacock",
            minPlayers = 2, maxPlayers = 4, playTimeMinutes = 45,
            scoringType = ScoringType.COOPERATIVE,
            notes = "Beat the diseases together — or lose together.", createdAt = daysAgo(175)
        )
        val golf = Game(
            "g-golf", "Six-Card Golf", "Traditional",
            minPlayers = 2, maxPlayers = 6, playTimeMinutes = 30,
            scoringType = ScoringType.LOWEST_WINS,
            notes = "Lowest total across nine deals wins.", createdAt = daysAgo(160)
        )
        val splendor = Game(
            "g-splendor", "Splendor", "Marc André",
            minPlayers = 2, maxPlayers = 4, playTimeMinutes = 30,
            scoringType = ScoringType.HIGHEST_WINS,
            notes = "Gem engine race to 15 prestige.", createdAt = daysAgo(140)
        )
        val spirit = Game(
            "g-spirit", "Spirit Island", "R. Eric Reuss",
            minPlayers = 1, maxPlayers = 4, playTimeMinutes = 120,
            scoringType = ScoringType.COOPERATIVE,
            notes = "Heavy co-op; defend the island.", createdAt = daysAgo(120)
        )
        val games = listOf(wingspan, catan, azul, pandemic, golf, splendor, spirit)
        val gameById = games.associateBy { it.id }

        // ---- Plays ----
        // Helper to build a competitive play and resolve winners from scores.
        var seq = 0
        fun play(
            game: Game,
            daysAgo: Int,
            duration: Int?,
            location: String,
            scores: List<Pair<Player, Double?>>,
            coopWon: Boolean = false,
            notes: String = ""
        ): Play {
            val raw = Play(
                id = "play-${seq++}",
                gameId = game.id,
                date = daysAgo(daysAgo),
                durationMinutes = duration,
                location = location,
                notes = notes,
                coopGroupWon = coopWon,
                results = scores.map { (p, s) -> PlayerResult(playerId = p.id, score = s) }
            )
            return raw.copy(results = Stats.resolvedResults(game, raw))
        }

        val plays = listOf(
            // Wingspan — Ada is strong here.
            play(wingspan, 190, 75, "Ada's place", listOf(ada to 78.0, ben to 71.0, cleo to 66.0)),
            play(wingspan, 172, 80, "Ada's place", listOf(ada to 82.0, dev to 74.0, ben to 69.0)),
            play(wingspan, 150, 72, "Cafe Meeple", listOf(cleo to 88.0, ada to 84.0, eli to 70.0)),
            play(wingspan, 95, 78, "Ada's place", listOf(ada to 91.0, ben to 80.0, cleo to 77.0, dev to 72.0)),
            play(wingspan, 40, 70, "Cafe Meeple", listOf(ada to 86.0, eli to 83.0, ben to 79.0)),

            // Catan — Ben's specialty.
            play(catan, 188, 95, "Ben's place", listOf(ben to 10.0, ada to 8.0, cleo to 7.0)),
            play(catan, 160, 100, "Ben's place", listOf(ben to 10.0, dev to 9.0, ada to 6.0, cleo to 5.0)),
            play(catan, 120, 88, "Ben's place", listOf(cleo to 10.0, ben to 9.0, ada to 7.0)),
            play(catan, 60, 92, "Game night", listOf(ben to 10.0, eli to 8.0, dev to 7.0, ada to 6.0)),

            // Azul — Cleo and Dev trade wins.
            play(azul, 178, 42, "Cafe Meeple", listOf(cleo to 64.0, dev to 58.0, ada to 51.0)),
            play(azul, 130, 38, "Cafe Meeple", listOf(dev to 70.0, cleo to 62.0, ben to 55.0)),
            play(azul, 88, 40, "Game night", listOf(cleo to 67.0, ada to 60.0, dev to 59.0, ben to 52.0)),
            play(azul, 30, 41, "Cafe Meeple", listOf(dev to 72.0, eli to 64.0, cleo to 61.0)),

            // Pandemic — cooperative; the group sometimes loses.
            play(pandemic, 170, 50, "Ada's place", emptyScores(ada, ben, cleo), coopWon = true,
                notes = "Cured all four with one card to spare."),
            play(pandemic, 110, 48, "Ben's place", emptyScores(ben, dev, ada, cleo), coopWon = false,
                notes = "Outbreak cascade in Asia. Brutal."),
            play(pandemic, 55, 52, "Ada's place", emptyScores(ada, eli, dev), coopWon = true),
            play(pandemic, 20, 46, "Game night", emptyScores(ada, ben, cleo, dev), coopWon = false),

            // Six-Card Golf — LOWEST wins.
            play(golf, 158, 28, "Cafe Meeple", listOf(eli to 12.0, ada to 18.0, ben to 21.0)),
            play(golf, 100, 30, "Game night", listOf(ada to 9.0, eli to 14.0, cleo to 20.0, dev to 25.0)),
            play(golf, 45, 27, "Cafe Meeple", listOf(eli to 11.0, ben to 16.0, ada to 19.0)),

            // Splendor — quick filler, Dev does well.
            play(splendor, 138, 32, "Game night", listOf(dev to 15.0, ada to 13.0, ben to 11.0)),
            play(splendor, 70, 28, "Cafe Meeple", listOf(dev to 16.0, cleo to 14.0, eli to 12.0)),
            play(splendor, 15, 30, "Game night", listOf(ada to 15.0, dev to 15.0, ben to 13.0),
                notes = "Ada and Dev tied at 15 — shared win."),

            // Spirit Island — heavy co-op.
            play(spirit, 118, 130, "Ada's place", emptyScores(ada, dev), coopWon = true,
                notes = "England, level 2. Close call."),
            play(spirit, 35, 125, "Ada's place", emptyScores(ada, dev, ben), coopWon = false)
        )

        return Seed(games, players, plays)
    }

    private fun emptyScores(vararg ps: Player): List<Pair<Player, Double?>> =
        ps.map { it to null }
}
