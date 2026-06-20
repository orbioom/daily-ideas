import SwiftUI
import SwiftData

struct LiveGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var engine: GameEngine
    @State private var showingSummary = false
    @State private var gameSaved = false

    init(setup: GameSetup) {
        _engine = State(initialValue: GameEngine(setup: setup))
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            ZStack {
                HoopTheme.darkBg.ignoresSafeArea()

                if isLandscape {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingSummary) {
            GameSummaryView(
                engine: engine,
                onSave: {
                    if !gameSaved {
                        engine.saveToContext(modelContext)
                        gameSaved = true
                    }
                },
                onNewGame: {
                    dismiss()
                }
            )
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // Scoreboard
            scoreboardHeader
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            // Timer controls
            timerControls
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider()
                .background(HoopTheme.subtleText.opacity(0.3))

            // Scoring area
            ScrollView {
                HStack(alignment: .top, spacing: 12) {
                    // Team A
                    teamColumn(team: "A", players: engine.teamAPlayers, teamName: engine.teamAName, color: HoopTheme.teamAColor)
                    // Team B
                    teamColumn(team: "B", players: engine.teamBPlayers, teamName: engine.teamBName, color: HoopTheme.teamBColor)
                }
                .padding(16)
            }

            // Bottom: fouls & timeouts
            bottomBar
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        HStack(spacing: 0) {
            // Left: Team A
            VStack(spacing: 8) {
                teamColumnHeader(team: "A", teamName: engine.teamAName, score: engine.scoreA, color: HoopTheme.teamAColor)
                ScrollView {
                    VStack(spacing: 6) {
                        if engine.teamAPlayers.isEmpty {
                            teamScoringNoRoster(team: "A")
                        } else {
                            ForEach(engine.teamAPlayers) { player in
                                PlayerStatsRow(player: player, team: "A", engine: engine)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                foulTimeoutRow(team: "A", fouls: engine.teamAFouls, timeouts: engine.teamATimeouts, color: HoopTheme.teamAColor)
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)

            // Center: controls
            VStack(spacing: 16) {
                Text(engine.quarterLabel)
                    .font(HoopTheme.quarterFont)
                    .foregroundColor(HoopTheme.subtleText)

                Text(engine.timeString)
                    .font(HoopTheme.timerFont)
                    .foregroundColor(.white)
                    .monospacedDigit()

                Button {
                    engine.isRunning ? engine.pauseTimer() : engine.startTimer()
                } label: {
                    Image(systemName: engine.isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(HoopTheme.orange)
                }

                Button("End \(engine.totalQuarters == 2 ? "Half" : "Qtr")") {
                    engine.endQuarter()
                    if engine.isGameOver { showingSummary = true }
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(HoopTheme.cardBg)
                .cornerRadius(10)

                if engine.canUndo {
                    Button {
                        engine.undoLastAction()
                    } label: {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .font(.system(size: 24))
                            .foregroundColor(HoopTheme.subtleText)
                    }
                }

                Button("End Game") {
                    showingSummary = true
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.red)
            }
            .frame(width: 120)
            .padding(.vertical, 16)

            // Right: Team B
            VStack(spacing: 8) {
                teamColumnHeader(team: "B", teamName: engine.teamBName, score: engine.scoreB, color: HoopTheme.teamBColor)
                ScrollView {
                    VStack(spacing: 6) {
                        if engine.teamBPlayers.isEmpty {
                            teamScoringNoRoster(team: "B")
                        } else {
                            ForEach(engine.teamBPlayers) { player in
                                PlayerStatsRow(player: player, team: "B", engine: engine)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                foulTimeoutRow(team: "B", fouls: engine.teamBFouls, timeouts: engine.teamBTimeouts, color: HoopTheme.teamBColor)
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Components

    private var topBar: some View {
        HStack {
            Button {
                engine.pauseTimer()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(HoopTheme.orange)
            }

            Spacer()

            if engine.canUndo {
                Button {
                    engine.undoLastAction()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(HoopTheme.labelFont)
                        .foregroundColor(HoopTheme.subtleText)
                }
            }

            Button("End Game") {
                engine.pauseTimer()
                showingSummary = true
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.red)
        }
        .padding(.vertical, 8)
    }

    private var scoreboardHeader: some View {
        HStack(alignment: .center, spacing: 0) {
            // Team A
            VStack(spacing: 4) {
                Text(engine.teamAName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(HoopTheme.teamAColor)
                    .lineLimit(1)
                Text("\(engine.scoreA)")
                    .font(HoopTheme.scoreFont)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)

            // Center info
            VStack(spacing: 4) {
                Text(engine.quarterLabel)
                    .font(HoopTheme.quarterFont)
                    .foregroundColor(HoopTheme.subtleText)
                Text(engine.timeString)
                    .font(HoopTheme.timerFont)
                    .foregroundColor(engine.isRunning ? HoopTheme.orange : .white)
                    .monospacedDigit()
            }
            .frame(minWidth: 120)

            // Team B
            VStack(spacing: 4) {
                Text(engine.teamBName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(HoopTheme.teamBColor)
                    .lineLimit(1)
                Text("\(engine.scoreB)")
                    .font(HoopTheme.scoreFont)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .hoopCard()
    }

    private var timerControls: some View {
        HStack(spacing: 12) {
            // Play/Pause
            Button {
                engine.isRunning ? engine.pauseTimer() : engine.startTimer()
            } label: {
                Label(
                    engine.isRunning ? "Pause" : "Start",
                    systemImage: engine.isRunning ? "pause.fill" : "play.fill"
                )
                .font(HoopTheme.buttonFont)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(engine.isRunning ? Color.gray.opacity(0.4) : HoopTheme.orange)
                .cornerRadius(12)
            }

            // End Quarter
            Button {
                engine.endQuarter()
                if engine.isGameOver {
                    showingSummary = true
                }
            } label: {
                Label(
                    engine.totalQuarters == 2 ? "End Half" : "End Qtr",
                    systemImage: "forward.end.fill"
                )
                .font(HoopTheme.buttonFont)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(HoopTheme.cardBg)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(HoopTheme.subtleText.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            foulTimeoutRow(team: "A", fouls: engine.teamAFouls, timeouts: engine.teamATimeouts, color: HoopTheme.teamAColor)
            foulTimeoutRow(team: "B", fouls: engine.teamBFouls, timeouts: engine.teamBTimeouts, color: HoopTheme.teamBColor)
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func teamColumn(team: String, players: [PlayerState], teamName: String, color: Color) -> some View {
        VStack(spacing: 8) {
            teamColumnHeader(team: team, teamName: teamName, score: team == "A" ? engine.scoreA : engine.scoreB, color: color)

            if players.isEmpty {
                teamScoringNoRoster(team: team)
            } else {
                ForEach(players) { player in
                    PlayerStatsRow(player: player, team: team, engine: engine)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func teamColumnHeader(team: String, teamName: String, score: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(teamName)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
            Spacer()
            Text("\(score)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func teamScoringNoRoster(team: String) -> some View {
        let color = HoopTheme.teamColor(for: team)
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                noRosterButton(label: "+2", color: color) {
                    addTeamScore(team: team, pts: 2)
                }
                noRosterButton(label: "+3", color: color) {
                    addTeamScore(team: team, pts: 3)
                }
                noRosterButton(label: "+1", color: color.opacity(0.7)) {
                    addTeamScore(team: team, pts: 1)
                }
            }
        }
        .padding(8)
        .hoopCard()
    }

    private func noRosterButton(label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func addTeamScore(team: String, pts: Int) {
        // When no roster, use a synthetic player
        if team == "A" {
            if engine.teamAPlayers.isEmpty {
                engine.teamAPlayers.append(PlayerState(name: engine.teamAName, number: "–"))
            }
            let player = engine.teamAPlayers[0]
            if pts == 2 { engine.add2pt(player: player, team: "A") }
            else if pts == 3 { engine.add3pt(player: player, team: "A") }
            else { engine.addFreeThrow(player: player, team: "A", made: true) }
        } else {
            if engine.teamBPlayers.isEmpty {
                engine.teamBPlayers.append(PlayerState(name: engine.teamBName, number: "–"))
            }
            let player = engine.teamBPlayers[0]
            if pts == 2 { engine.add2pt(player: player, team: "B") }
            else if pts == 3 { engine.add3pt(player: player, team: "B") }
            else { engine.addFreeThrow(player: player, team: "B", made: true) }
        }
    }

    private func foulTimeoutRow(team: String, fouls: Int, timeouts: Int, color: Color) -> some View {
        let maxTimeouts = 5
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("Fouls:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(HoopTheme.subtleText)
                Text("\(fouls)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(fouls >= 5 ? .red : color)
                Spacer()
                Button {
                    engine.useTimeout(team: team)
                } label: {
                    Text("Timeout")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(timeouts > 0 ? color : HoopTheme.subtleText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(timeouts > 0 ? color.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(timeouts > 0 ? color.opacity(0.3) : HoopTheme.subtleText.opacity(0.2), lineWidth: 1)
                        )
                }
                .disabled(timeouts == 0)
            }
            // Timeout indicators
            HStack(spacing: 4) {
                ForEach(0..<maxTimeouts, id: \.self) { i in
                    Circle()
                        .fill(i < timeouts ? color : HoopTheme.subtleText.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .hoopCard()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    var setup = GameSetup()
    setup.teamAName = "Lakers"
    setup.teamBName = "Celtics"
    setup.teamAPlayers = [("LeBron", "23"), ("AD", "3"), ("Austin", "15")]
    setup.teamBPlayers = [("Tatum", "0"), ("Brown", "7"), ("Holiday", "4")]
    return LiveGameView(setup: setup)
        .preferredColorScheme(.dark)
}
