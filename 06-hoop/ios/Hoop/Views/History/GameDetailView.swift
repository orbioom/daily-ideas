import SwiftUI
import SwiftData

struct GameDetailView: View {
    let game: HoopGame
    @Environment(\.dismiss) private var dismiss

    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f.string(from: game.date)
    }

    private var quarterLabels: [String] {
        if game.quarters == 2 {
            return ["1H", "2H"]
        } else {
            return ["Q1", "Q2", "Q3", "Q4"]
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HoopTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Date
                        Text(dateString)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(HoopTheme.subtleText)
                            .padding(.top, 8)

                        // Final Score
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                Text(game.teamAName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(HoopTheme.teamAColor)
                                    .lineLimit(1)
                                Text("\(game.finalScoreA)")
                                    .font(.system(size: 64, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: 4) {
                                if let winner = game.winner {
                                    Image(systemName: "trophy.fill")
                                        .foregroundColor(HoopTheme.orange)
                                    Text(winner)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(HoopTheme.orange)
                                        .lineLimit(1)
                                } else {
                                    Text("–")
                                        .font(.system(size: 28, weight: .light))
                                        .foregroundColor(HoopTheme.subtleText)
                                }
                            }
                            .frame(minWidth: 80)

                            VStack(spacing: 4) {
                                Text(game.teamBName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(HoopTheme.teamBColor)
                                    .lineLimit(1)
                                Text("\(game.finalScoreB)")
                                    .font(.system(size: 64, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                        .hoopCard()
                        .padding(.horizontal, 16)

                        // Quarter Score Grid
                        let qA = game.decodeQuarterScoresA()
                        let qB = game.decodeQuarterScoresB()
                        if !qA.isEmpty {
                            quarterScoreGrid(qA: qA, qB: qB)
                                .padding(.horizontal, 16)
                        }

                        // Player Stats
                        if !game.players.isEmpty {
                            playerStatsSection
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Game Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(HoopTheme.orange)
                }
            }
        }
    }

    // MARK: - Quarter Score Grid

    private func quarterScoreGrid(qA: [Int], qB: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quarter Scores")
                .font(HoopTheme.labelFont)
                .foregroundColor(HoopTheme.subtleText)

            let labels = quarterLabels + ["T"]

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    Text("Team")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(HoopTheme.subtleText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(labels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(HoopTheme.subtleText)
                            .frame(width: 36)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider().background(HoopTheme.subtleText.opacity(0.3))

                // Team A
                HStack(spacing: 0) {
                    Text(game.teamAName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(HoopTheme.teamAColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                    ForEach(Array(qA.enumerated()), id: \.offset) { _, val in
                        Text("\(val)").frame(width: 36)
                    }
                    Text("\(game.finalScoreA)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider().background(HoopTheme.subtleText.opacity(0.2))

                // Team B
                HStack(spacing: 0) {
                    Text(game.teamBName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(HoopTheme.teamBColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                    ForEach(Array(qB.enumerated()), id: \.offset) { _, val in
                        Text("\(val)").frame(width: 36)
                    }
                    Text("\(game.finalScoreB)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .hoopCard()
        }
    }

    // MARK: - Player Stats

    private var playerStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Player Stats")
                .font(HoopTheme.labelFont)
                .foregroundColor(HoopTheme.subtleText)

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    Text("Player")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    statHeader("PTS")
                    statHeader("2PM")
                    statHeader("3PM")
                    statHeader("FT")
                    statHeader("PF")
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(HoopTheme.subtleText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

                Divider().background(HoopTheme.subtleText.opacity(0.3))

                // Team A
                if !game.playersA.isEmpty {
                    teamSectionHeader(name: game.teamAName, color: HoopTheme.teamAColor)
                    ForEach(game.playersA) { player in
                        playerRow(player: player, color: HoopTheme.teamAColor)
                    }
                }

                if !game.playersA.isEmpty && !game.playersB.isEmpty {
                    Divider().background(HoopTheme.subtleText.opacity(0.3))
                }

                // Team B
                if !game.playersB.isEmpty {
                    teamSectionHeader(name: game.teamBName, color: HoopTheme.teamBColor)
                    ForEach(game.playersB) { player in
                        playerRow(player: player, color: HoopTheme.teamBColor)
                    }
                }
            }
            .hoopCard()
        }
    }

    private func statHeader(_ text: String) -> some View {
        Text(text).frame(width: 32, alignment: .center)
    }

    private func teamSectionHeader(name: String, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(name)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
    }

    private func playerRow(player: HoopPlayer, color: Color) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                Text("#\(player.number)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                    .frame(width: 24)
                Text(player.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(player.totalPoints)")
                .font(.system(size: 12, weight: .bold))
                .frame(width: 32, alignment: .center)
            Text("\(player.points2)")
                .font(.system(size: 12))
                .frame(width: 32, alignment: .center)
            Text("\(player.points3)")
                .font(.system(size: 12))
                .frame(width: 32, alignment: .center)
            Text("\(player.freeThrowsMade)/\(player.freeThrowsAttempted)")
                .font(.system(size: 10))
                .frame(width: 32, alignment: .center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(player.fouls)")
                .font(.system(size: 12))
                .foregroundColor(player.fouls >= 5 ? .red : .white)
                .frame(width: 32, alignment: .center)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: HoopGame.self, HoopPlayer.self, configurations: config)

    let game = HoopGame(teamAName: "Lakers", teamBName: "Celtics", quarters: 4, quarterMinutes: 10)
    game.encodeQuarterScores(a: [24, 28, 22, 24], b: [26, 20, 25, 21])
    game.isComplete = true
    container.mainContext.insert(game)

    let p1 = HoopPlayer(name: "LeBron", number: "23", team: "A")
    p1.points2 = 8; p1.points3 = 3; p1.freeThrowsMade = 5; p1.freeThrowsAttempted = 6; p1.fouls = 2
    p1.game = game
    container.mainContext.insert(p1)

    return GameDetailView(game: game)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
