import SwiftUI

struct LiveGameView: View {
    @State var engine: GameEngine
    @Environment(\.dismiss) private var dismiss
    @State private var showingSummary = false
    @State private var showingEndConfirm = false
    
    var timeString: String {
        let m = engine.secondsRemaining / 60
        let s = engine.secondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }
    
    var body: some View {
        ZStack {
            HoopTheme.darkBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    // Quarter indicator
                    Text("Q\(engine.currentQuarter)")
                        .font(.headline.bold())
                        .foregroundStyle(HoopTheme.orange)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(HoopTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                    
                    Button {
                        engine.undoLastAction()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(HoopTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button {
                        showingEndConfirm = true
                    } label: {
                        Text("End Game")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Scoreboard
                HStack(alignment: .center, spacing: 0) {
                    // Team A
                    VStack(spacing: 4) {
                        Text(engine.teamAName)
                            .font(.headline.bold())
                            .foregroundStyle(HoopTheme.teamA)
                            .lineLimit(1)
                        Text("\(engine.scoreA)")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 2) {
                        Text("VS")
                            .font(.caption.bold())
                            .foregroundStyle(HoopTheme.subtleText)
                        Text("Q\(engine.currentQuarter) of \(engine.totalQuarters)")
                            .font(.caption2)
                            .foregroundStyle(HoopTheme.subtleText)
                    }
                    .frame(width: 60)
                    
                    // Team B
                    VStack(spacing: 4) {
                        Text(engine.teamBName)
                            .font(.headline.bold())
                            .foregroundStyle(HoopTheme.teamB)
                            .lineLimit(1)
                        Text("\(engine.scoreB)")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(HoopTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Clock
                HStack(spacing: 16) {
                    Text(timeString)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    
                    Button {
                        if engine.isRunning { engine.pauseTimer() } else { engine.startTimer() }
                    } label: {
                        Image(systemName: engine.isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(HoopTheme.orange)
                    }
                    
                    Button {
                        engine.endQuarter()
                    } label: {
                        Text("End Q\(engine.currentQuarter)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(HoopTheme.orange.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.vertical, 10)
                
                // Fouls and Timeouts
                HStack(spacing: 0) {
                    teamStatusRow(
                        fouls: engine.teamAFouls,
                        timeoutsLeft: engine.teamATimeoutsLeft,
                        teamColor: HoopTheme.teamA,
                        team: "A"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.1))
                    
                    teamStatusRow(
                        fouls: engine.teamBFouls,
                        timeoutsLeft: engine.teamBTimeoutsLeft,
                        teamColor: HoopTheme.teamB,
                        team: "B"
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(HoopTheme.cardBg.opacity(0.5))
                
                // Players grid or simple scoring
                ScrollView {
                    if engine.teamAPlayers.isEmpty && engine.teamBPlayers.isEmpty {
                        // No-player simple scoring
                        HStack(alignment: .top, spacing: 16) {
                            simpleTeamScoring(team: "A", teamName: engine.teamAName, teamColor: HoopTheme.teamA)
                            simpleTeamScoring(team: "B", teamName: engine.teamBName, teamColor: HoopTheme.teamB)
                        }
                        .padding()
                    } else {
                        HStack(alignment: .top, spacing: 12) {
                            // Team A players
                            VStack(spacing: 8) {
                                Text(engine.teamAName)
                                    .font(.caption.bold())
                                    .foregroundStyle(HoopTheme.teamA)
                                ForEach(engine.teamAPlayers.indices, id: \.self) { idx in
                                    PlayerScoringRow(playerIndex: idx, team: "A", engine: engine)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Team B players
                            VStack(spacing: 8) {
                                Text(engine.teamBName)
                                    .font(.caption.bold())
                                    .foregroundStyle(HoopTheme.teamB)
                                ForEach(engine.teamBPlayers.indices, id: \.self) { idx in
                                    PlayerScoringRow(playerIndex: idx, team: "B", engine: engine)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: engine.isGameOver) { _, newValue in
            if newValue { showingSummary = true }
        }
        .fullScreenCover(isPresented: $showingSummary) {
            GameSummaryView(engine: engine) {
                dismiss()
            }
        }
        .alert("End Game?", isPresented: $showingEndConfirm) {
            Button("End Game", role: .destructive) {
                engine.endQuarter()
                showingSummary = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will end the current game and show the summary.")
        }
    }
    
    @ViewBuilder
    func teamStatusRow(fouls: Int, timeoutsLeft: Int, teamColor: Color, team: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button {
                    engine.addFoul(team: team)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill")
                            .font(.caption2)
                        Text("Foul: \(fouls)")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(fouls >= 5 ? .red : .white)
                }
                
                Spacer()
                
                Button {
                    engine.useTimeout(team: team)
                } label: {
                    Text("TO: \(timeoutsLeft)")
                        .font(.caption.bold())
                        .foregroundStyle(teamColor)
                }
            }
            
            // Timeout dots
            HStack(spacing: 4) {
                let totalTimeouts = team == "A"
                    ? (engine.teamATimeoutsLeft + (5 - engine.teamATimeoutsLeft))
                    : (engine.teamBTimeoutsLeft + (5 - engine.teamBTimeoutsLeft))
                ForEach(0..<max(totalTimeouts, 1), id: \.self) { i in
                    Circle()
                        .fill(i < timeoutsLeft ? teamColor : Color.white.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
    }
    
    @ViewBuilder
    func simpleTeamScoring(team: String, teamName: String, teamColor: Color) -> some View {
        VStack(spacing: 12) {
            Text(teamName)
                .font(.headline.bold())
                .foregroundStyle(teamColor)
            
            Button {
                engine.addDirectScore(points: 2, team: team)
            } label: {
                Text("+2")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(teamColor.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Button {
                engine.addDirectScore(points: 3, team: team)
            } label: {
                Text("+3")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(teamColor.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Button {
                engine.addDirectScore(points: 1, team: team)
            } label: {
                Text("FT +1")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity)
    }
}
