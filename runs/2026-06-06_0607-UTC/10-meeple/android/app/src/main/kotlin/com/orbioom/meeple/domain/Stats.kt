package com.orbioom.meeple.domain

/**
 * All analytics for Meeple. Pure Kotlin — no Android imports — so it is trivially testable
 * and reusable. Everything here is defensive: zero plays never divides by zero, missing
 * scores are skipped rather than guessed, and scoring type / co-op are always respected.
 */
object Stats {

    // ---- Winner resolution -------------------------------------------------

    /**
     * Resolve the winners of a single [play] for its [game], returning the set of winning
     * player ids. Respects scoring type and co-op:
     *  - HIGHEST_WINS: the top score(s) win (ties share the win).
     *  - LOWEST_WINS: the bottom score(s) win.
     *  - COOPERATIVE: everyone wins if [Play.coopGroupWon], otherwise nobody.
     * Players with a null score are excluded from competitive ranking.
     */
    fun winners(game: Game, play: Play): Set<String> {
        if (play.results.isEmpty()) return emptySet()
        return when (game.scoringType) {
            ScoringType.COOPERATIVE ->
                if (play.coopGroupWon) play.results.map { it.playerId }.toSet() else emptySet()

            ScoringType.HIGHEST_WINS, ScoringType.LOWEST_WINS -> {
                val scored = play.results.filter { it.score != null }
                if (scored.isEmpty()) {
                    // No scores recorded — fall back to any explicit winner flags.
                    play.results.filter { it.isWinner }.map { it.playerId }.toSet()
                } else {
                    val best = if (game.scoringType == ScoringType.HIGHEST_WINS) {
                        scored.maxOf { it.score!! }
                    } else {
                        scored.minOf { it.score!! }
                    }
                    scored.filter { it.score == best }.map { it.playerId }.toSet()
                }
            }
        }
    }

    /**
     * Recompute [PlayerResult.isWinner] for every row of a play so stored data stays
     * consistent with the game's scoring rules. Used at save time.
     */
    fun resolvedResults(game: Game, play: Play): List<PlayerResult> {
        val winnerIds = winners(game, play)
        return play.results.map { it.copy(isWinner = winnerIds.contains(it.playerId)) }
    }

    // ---- Per-game stats ----------------------------------------------------

    data class GameStats(
        val game: Game,
        val playCount: Int,
        val lastPlayed: Long?,
        val firstPlayed: Long?,
        val averageScore: Double?,
        val medianScore: Double?,
        val highScore: Double?,
        val highScorePlayerId: String?,
        val lowScore: Double?,
        val averageDurationMinutes: Int?,
        /** For co-op games: how often the group beat the game (0..1), else null. */
        val coopWinRate: Double?,
        /** Player-id -> (wins, plays) for this game, sorted by win rate then plays. */
        val perPlayer: List<PlayerGameRecord>
    )

    data class PlayerGameRecord(
        val playerId: String,
        val plays: Int,
        val wins: Int
    ) {
        val winRate: Double get() = if (plays == 0) 0.0 else wins.toDouble() / plays
    }

    fun forGame(game: Game, plays: List<Play>): GameStats {
        val gamePlays = plays.filter { it.gameId == game.id }
        val allScores = gamePlays.flatMap { it.results }.mapNotNull { it.score }

        // Per-player tallies.
        val playsByPlayer = HashMap<String, Int>()
        val winsByPlayer = HashMap<String, Int>()
        gamePlays.forEach { play ->
            val winnerIds = winners(game, play)
            play.results.forEach { r ->
                playsByPlayer[r.playerId] = (playsByPlayer[r.playerId] ?: 0) + 1
                if (winnerIds.contains(r.playerId)) {
                    winsByPlayer[r.playerId] = (winsByPlayer[r.playerId] ?: 0) + 1
                }
            }
        }
        val perPlayer = playsByPlayer.keys.map { pid ->
            PlayerGameRecord(pid, playsByPlayer[pid] ?: 0, winsByPlayer[pid] ?: 0)
        }.sortedWith(compareByDescending<PlayerGameRecord> { it.winRate }.thenByDescending { it.plays })

        // High score & who holds it.
        val highResult = gamePlays
            .flatMap { it.results }
            .filter { it.score != null }
            .maxByOrNull { it.score!! }

        val coopWinRate = if (game.scoringType == ScoringType.COOPERATIVE && gamePlays.isNotEmpty()) {
            gamePlays.count { it.coopGroupWon }.toDouble() / gamePlays.size
        } else null

        val durations = gamePlays.mapNotNull { it.durationMinutes }.filter { it > 0 }

        return GameStats(
            game = game,
            playCount = gamePlays.size,
            lastPlayed = gamePlays.maxByOrNull { it.date }?.date,
            firstPlayed = gamePlays.minByOrNull { it.date }?.date,
            averageScore = allScores.takeIf { it.isNotEmpty() }?.average(),
            medianScore = median(allScores),
            highScore = highResult?.score,
            highScorePlayerId = highResult?.playerId,
            lowScore = allScores.minOrNull(),
            averageDurationMinutes = durations.takeIf { it.isNotEmpty() }?.average()?.let { Math.round(it).toInt() },
            coopWinRate = coopWinRate,
            perPlayer = perPlayer
        )
    }

    // ---- Per-player stats --------------------------------------------------

    data class PlayerStats(
        val player: Player,
        val totalPlays: Int,
        val totalWins: Int,
        val lastPlayed: Long?,
        /** Longest run of consecutive wins across all plays in chronological order. */
        val longestWinStreak: Int,
        /** Current streak: positive = wins, negative = losses, 0 = no plays. */
        val currentStreak: Int,
        /** Most-played game id for this player, or null. */
        val favoriteGameId: String?,
        val favoriteGamePlays: Int,
        /** The opponent who beats this player most often (head-to-head losses). */
        val nemesisPlayerId: String?,
        val nemesisLosses: Int,
        /** Per-game breakdown sorted by plays. */
        val perGame: List<PlayerGameRecord>,
        /** Head-to-head vs every other player who shared a competitive table. */
        val headToHead: List<HeadToHead>
    ) {
        val winRate: Double get() = if (totalPlays == 0) 0.0 else totalWins.toDouble() / totalPlays
    }

    /**
     * Head-to-head between [playerId] and [opponentId] across competitive plays they both
     * sat at. A "win" is a play where this player won and the opponent did not; a "loss"
     * is the reverse. Plays where both win (co-op) or both lose are ties.
     */
    data class HeadToHead(
        val playerId: String,
        val opponentId: String,
        val wins: Int,
        val losses: Int,
        val ties: Int
    ) {
        val games: Int get() = wins + losses + ties
        val winRate: Double get() = if (wins + losses == 0) 0.0 else wins.toDouble() / (wins + losses)
    }

    fun forPlayer(player: Player, games: List<Game>, plays: List<Play>): PlayerStats {
        val gameById = games.associateBy { it.id }
        // Plays this player took part in, chronological.
        val playerPlays = plays
            .filter { play -> play.results.any { it.playerId == player.id } }
            .sortedBy { it.date }

        var totalWins = 0
        val perGamePlays = HashMap<String, Int>()
        val perGameWins = HashMap<String, Int>()
        // Chronological win/loss sequence for streaks.
        val outcomes = ArrayList<Boolean>()
        // Head-to-head accumulators.
        val h2hWins = HashMap<String, Int>()
        val h2hLosses = HashMap<String, Int>()
        val h2hTies = HashMap<String, Int>()

        playerPlays.forEach { play ->
            val game = gameById[play.gameId] ?: return@forEach
            val winnerIds = winners(game, play)
            val iWon = winnerIds.contains(player.id)
            if (iWon) totalWins++
            outcomes.add(iWon)
            perGamePlays[play.gameId] = (perGamePlays[play.gameId] ?: 0) + 1
            if (iWon) perGameWins[play.gameId] = (perGameWins[play.gameId] ?: 0) + 1

            // Head-to-head only meaningful for competitive games with other players.
            if (game.scoringType != ScoringType.COOPERATIVE) {
                play.results.forEach { r ->
                    if (r.playerId == player.id) return@forEach
                    val oppWon = winnerIds.contains(r.playerId)
                    when {
                        iWon && !oppWon -> h2hWins[r.playerId] = (h2hWins[r.playerId] ?: 0) + 1
                        !iWon && oppWon -> h2hLosses[r.playerId] = (h2hLosses[r.playerId] ?: 0) + 1
                        else -> h2hTies[r.playerId] = (h2hTies[r.playerId] ?: 0) + 1
                    }
                }
            }
        }

        val perGame = perGamePlays.keys.map { gid ->
            PlayerGameRecord(gid, perGamePlays[gid] ?: 0, perGameWins[gid] ?: 0)
        }.sortedByDescending { it.plays }

        val favorite = perGame.maxByOrNull { it.plays }

        val opponentIds = (h2hWins.keys + h2hLosses.keys + h2hTies.keys).toSet()
        val headToHead = opponentIds.map { oid ->
            HeadToHead(
                playerId = player.id,
                opponentId = oid,
                wins = h2hWins[oid] ?: 0,
                losses = h2hLosses[oid] ?: 0,
                ties = h2hTies[oid] ?: 0
            )
        }.sortedByDescending { it.games }

        // Nemesis: the opponent with the most head-to-head losses (ties broken by fewest wins).
        val nemesis = headToHead
            .filter { it.losses > 0 }
            .maxWithOrNull(compareBy<HeadToHead> { it.losses }.thenByDescending { it.losses - it.wins })

        return PlayerStats(
            player = player,
            totalPlays = playerPlays.size,
            totalWins = totalWins,
            lastPlayed = playerPlays.maxByOrNull { it.date }?.date,
            longestWinStreak = longestRun(outcomes, target = true),
            currentStreak = currentStreak(outcomes),
            favoriteGameId = favorite?.playerId,
            favoriteGamePlays = favorite?.plays ?: 0,
            nemesisPlayerId = nemesis?.opponentId,
            nemesisLosses = nemesis?.losses ?: 0,
            perGame = perGame,
            headToHead = headToHead
        )
    }

    // ---- Collection-wide insights -----------------------------------------

    data class Overview(
        val gameCount: Int,
        val playerCount: Int,
        val playCount: Int,
        val totalHoursPlayed: Double,
        val mostPlayed: List<GameStats>,
        val topWinners: List<PlayerStats>,
        val lastPlay: Play?,
        val lastPlayGameTitle: String?,
        /** Monthly play counts oldest→newest for the trend chart. */
        val playsByMonth: List<MonthCount>
    )

    data class MonthCount(val epoch: Long, val label: String, val count: Int)

    fun overview(games: List<Game>, players: List<Player>, plays: List<Play>): Overview {
        val gameStats = games.map { forGame(it, plays) }
        val playerStats = players.map { forPlayer(it, games, plays) }
        val gameById = games.associateBy { it.id }

        val totalMinutes = plays.mapNotNull { it.durationMinutes }.filter { it > 0 }.sum()
        val lastPlay = plays.maxByOrNull { it.date }

        return Overview(
            gameCount = games.size,
            playerCount = players.size,
            playCount = plays.size,
            totalHoursPlayed = totalMinutes / 60.0,
            mostPlayed = gameStats.filter { it.playCount > 0 }.sortedByDescending { it.playCount }.take(5),
            topWinners = playerStats.filter { it.totalPlays > 0 }
                .sortedWith(compareByDescending<PlayerStats> { it.winRate }.thenByDescending { it.totalPlays })
                .take(5),
            lastPlay = lastPlay,
            lastPlayGameTitle = lastPlay?.let { gameById[it.gameId]?.title },
            playsByMonth = playsByMonth(plays)
        )
    }

    // ---- Helpers -----------------------------------------------------------

    private fun median(values: List<Double>): Double? {
        if (values.isEmpty()) return null
        val sorted = values.sorted()
        val mid = sorted.size / 2
        return if (sorted.size % 2 == 1) sorted[mid]
        else (sorted[mid - 1] + sorted[mid]) / 2.0
    }

    /** Longest consecutive run of [target] in [outcomes]. */
    private fun longestRun(outcomes: List<Boolean>, target: Boolean): Int {
        var best = 0
        var run = 0
        outcomes.forEach { o ->
            if (o == target) {
                run++
                if (run > best) best = run
            } else run = 0
        }
        return best
    }

    /** Signed current streak from the end: +n wins, -n losses, 0 if empty. */
    private fun currentStreak(outcomes: List<Boolean>): Int {
        if (outcomes.isEmpty()) return 0
        val last = outcomes.last()
        var count = 0
        for (i in outcomes.indices.reversed()) {
            if (outcomes[i] == last) count++ else break
        }
        return if (last) count else -count
    }

    /** Group plays into calendar months, oldest→newest, filling gaps with zero counts. */
    private fun playsByMonth(plays: List<Play>): List<MonthCount> {
        if (plays.isEmpty()) return emptyList()
        val cal = java.util.Calendar.getInstance()
        fun monthKey(epoch: Long): Long {
            cal.timeInMillis = epoch
            cal.set(java.util.Calendar.DAY_OF_MONTH, 1)
            cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
            cal.set(java.util.Calendar.MINUTE, 0)
            cal.set(java.util.Calendar.SECOND, 0)
            cal.set(java.util.Calendar.MILLISECOND, 0)
            return cal.timeInMillis
        }

        val counts = HashMap<Long, Int>()
        plays.forEach { counts[monthKey(it.date)] = (counts[monthKey(it.date)] ?: 0) + 1 }

        val sortedKeys = counts.keys.sorted()
        val first = sortedKeys.first()
        val last = sortedKeys.last()

        // Walk month by month from first to last so the series has no gaps.
        val result = ArrayList<MonthCount>()
        cal.timeInMillis = first
        while (cal.timeInMillis <= last) {
            val key = cal.timeInMillis
            result.add(MonthCount(key, Format.month(key), counts[key] ?: 0))
            cal.add(java.util.Calendar.MONTH, 1)
        }
        // Cap to a readable window (last 12 months of activity).
        return if (result.size > 12) result.takeLast(12) else result
    }
}
