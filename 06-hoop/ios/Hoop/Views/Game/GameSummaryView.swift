import SwiftUI

struct GameSummaryView: View {
    let engine: GameEngine
    let onSave: () -> Void
    let onNewGame: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var saved = false

    private var winnerName: String {
        if engine.scoreA > engine.scoreB { return engine.teamAName }
        if engine.scoreB > engine.scoreA { return engine.teamBName }
        return "Tie Game"
    }

    private var winnerColor: Color {
        if engine.scoreA > engine.scoreB { return HoopTheme.teamAColor }
        if engine.scoreB > engine.scoreA { return HoopTheme.teamBColor }
        return HoopTheme.orange
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HoopTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Winner Banner
                        VStack(spacing: 8) {
                            Image(systemName: engine.scoreA == engine.scoreB ? "equal.circle.fill" : "trophy.fill")
                                .font(.system(size: 48))
                                .foregroundColor(winnerColor)

                            if engine.scoreA != engine.scoreB {
                                Text("Winner")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(HoopTheme.subtleText)
                            }

                            Text(winnerName)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(winnerColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .hoopCard()
                        .padding(.horizontal, 16)

                        // Final Score
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                Text(engine.teamAName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(HoopTheme.teamAColor)
                                    .lineLimit(1)
                                Text("\(engine.scoreA)")
                                    .font(.system(size: 64, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)

                            Text("–")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(HoopTheme.subtleText)

                            VStack(spacing: 4) {
                                Text(engine.teamBName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(HoopTheme.teamBColor)
                                    .lineLimit(1)
                                Text("\(engine.scoreB)")
                                    .font(.system(size: 64, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                        .hoopCard()
                        .padding(.horizontal, 16)

                        // Quarter Scores
                        if !engine.quarterScoresA.isEmpty {
                            quarterScoreGrid
                                .padding(.horizontal, 16)
                        }

                        // Player Stats
                        if !engine.teamAPlayers.isEmpty || !engine.teamBPlayers.isEmpty {
                            playerStatsTable
                                .padding(.horizontal, 16)
                        }

                        // Buttons
                        VStack(spacing: 12) {
                            if !saved {
                                Button {
                                    onSave()
                                    saved = true
                                } label: {
                                    Label("Save Game", systemImage: "square.and.arrow.down")
                                        .font(HoopTheme.buttonFont)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(HoopTheme.orange)
                                        .cornerRadius(14)
                                }
                            } else {
                                Label("Game Saved", systemImage: "checkmark.circle.fill")
                                    .font(HoopTheme.buttonFont)
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(HoopTheme.cardBg)
                                    .cornerRadius(14)
                            }

                            Button {
                                dismiss()
                                onNewGame()
                            } label: {
                                Label("New Game", systemImage: "plus.circle")
                                    .font(HoopTheme.buttonFont)
                                    .foregroundColor(HoopTheme.orange)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(HoopTheme.cardBg)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(HoopTheme.orange.opacity(0.4), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Game Summary")
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

    private var quarterScoreGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quarter Scores")
                .font(HoopTheme.labelFont)
                .foregroundColor(HoopTheme.subtleText)

            let quarterLabels: [String] = {
                if engine.totalQuarters == 2 {
                    return ["1H", "2H", "T"]
                } else {
                    return ["Q1", "Q2", "Q3", "Q4", "T"]
                }
            }()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    Text("Team")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(HoopTheme.subtleText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(quarterLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(HoopTheme.subtleText)
                            .frame(width: 36)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider().background(HoopTheme.subtleText.opacity(0.3))

                // Team A row
                HStack(spacing: 0) {
                    Text(engine.teamAName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(HoopTheme.teamAColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)

                    ForEach(0..<engine.quarterScoresA.count, id: \.self) { i in
                        Text("\(engine.quarterScoresA[i])")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 36)
                    }
                    Text("\(engine.scoreA)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider().background(HoopTheme.subtleText.opacity(0.2))

                // Team B row
                HStack(spacing: 0) {
                    Text(engine.teamBName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(HoopTheme.teamBColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)

                    ForEach(0..<engine.quarterScoresB.count, id: \.self) { i in
                        Text("\(engine.quarterScoresB[i])")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 36)
                    }
                    Text("\(engine.scoreB)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .hoopCard()
        }
    }

    // MARK: - Player Stats Table

    private var playerStatsTable: some View {
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
                if !engine.teamAPlayers.isEmpty {
                    teamSectionHeader(name: engine.teamAName, color: HoopTheme.teamAColor)
                    ForEach(engine.teamAPlayers.sorted(by: { $0.totalPoints > $1.totalPoints })) { player in
                        playerStatRow(player: player, color: HoopTheme.teamAColor)
                    }
                }

                if !engine.teamAPlayers.isEmpty && !engine.teamBPlayers.isEmpty {
                    Divider().background(HoopTheme.subtleText.opacity(0.3))
                }

                // Team B
                if !engine.teamBPlayers.isEmpty {
                    teamSectionHeader(name: engine.teamBName, color: HoopTheme.teamBColor)
                    ForEach(engine.teamBPlayers.sorted(by: { $0.totalPoints > $1.totalPoints })) { player in
                        playerStatRow(player: player, color: HoopTheme.teamBColor)
                    }
                }
            }
            .hoopCard()
        }
    }

    private func statHeader(_ text: String) -> some View {
        Text(text)
            .frame(width: 32, alignment: .center)
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

    private func playerStatRow(player: PlayerState, color: Color) -> some View {
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

            statCell("\(player.totalPoints)", bold: true)
            statCell("\(player.points2)")
            statCell("\(player.points3)")
            statCell("\(player.ftMade)/\(player.ftAttempted)", small: true)
            statCell("\(player.fouls)", color: player.fouls >= 5 ? .red : nil)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func statCell(_ text: String, bold: Bool = false, small: Bool = false, color: Color? = nil) -> some View {
        Text(text)
            .font(.system(size: small ? 10 : 12, weight: bold ? .bold : .medium))
            .foregroundColor(color ?? .white)
            .frame(width: 32, alignment: .center)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

#Preview {
    var setup = GameSetup()
    setup.teamAName = "Lakers"
    setup.teamBName = "Celtics"
    setup.teamAPlayers = [("LeBron", "23"), ("AD", "3")]
    setup.teamBPlayers = [("Tatum", "0"), ("Brown", "7")]
    let engine = GameEngine(setup: setup)
    engine.scoreA = 98
    engine.scoreB = 92
    return GameSummaryView(engine: engine, onSave: {}, onNewGame: {})
        .preferredColorScheme(.dark)
}
