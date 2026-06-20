import SwiftUI
import SwiftData

struct GameSummaryView: View {
    let engine: GameEngine
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var saved = false
    
    var isATie: Bool { engine.scoreA == engine.scoreB }
    var winnerName: String {
        if engine.scoreA > engine.scoreB { return engine.teamAName }
        if engine.scoreB > engine.scoreA { return engine.teamBName }
        return "Tie"
    }
    var winnerColor: Color {
        if engine.scoreA > engine.scoreB { return HoopTheme.teamA }
        if engine.scoreB > engine.scoreA { return HoopTheme.teamB }
        return HoopTheme.orange
    }
    
    var allQuarterScoresA: [Int] {
        var scores = engine.quarterScoresA
        if scores.count < engine.totalQuarters {
            scores.append(engine.currentQScoreA)
        }
        return scores
    }
    var allQuarterScoresB: [Int] {
        var scores = engine.quarterScoresB
        if scores.count < engine.totalQuarters {
            scores.append(engine.currentQScoreB)
        }
        return scores
    }
    
    var body: some View {
        ZStack {
            HoopTheme.darkBg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Winner banner
                    VStack(spacing: 8) {
                        if !isATie {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(HoopTheme.orange)
                        }
                        Text(isATie ? "It's a Tie!" : "\(winnerName) Wins!")
                            .font(.largeTitle.bold())
                            .foregroundStyle(winnerColor)
                    }
                    .padding(.top, 32)
                    
                    // Final scores
                    HStack(spacing: 0) {
                        VStack {
                            Text(engine.teamAName)
                                .font(.headline)
                                .foregroundStyle(HoopTheme.teamA)
                            Text("\(engine.scoreA)")
                                .font(.system(size: 72, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Text("–")
                            .font(.title.bold())
                            .foregroundStyle(HoopTheme.subtleText)
                        
                        VStack {
                            Text(engine.teamBName)
                                .font(.headline)
                                .foregroundStyle(HoopTheme.teamB)
                            Text("\(engine.scoreB)")
                                .font(.system(size: 72, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(HoopTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    
                    // Quarter breakdown
                    quarterBreakdownView
                        .padding(.horizontal)
                    
                    // Player stats - Team A
                    if !engine.teamAPlayers.isEmpty {
                        playerStatsTable(
                            teamName: engine.teamAName,
                            teamColor: HoopTheme.teamA,
                            players: engine.teamAPlayers
                        )
                        .padding(.horizontal)
                    }
                    
                    // Player stats - Team B
                    if !engine.teamBPlayers.isEmpty {
                        playerStatsTable(
                            teamName: engine.teamBName,
                            teamColor: HoopTheme.teamB,
                            players: engine.teamBPlayers
                        )
                        .padding(.horizontal)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        if !saved {
                            Button {
                                engine.saveGame(ctx: modelContext)
                                saved = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text("Save Game")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(HoopTheme.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Game Saved!")
                            }
                            .font(.headline)
                            .foregroundStyle(HoopTheme.correctGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(HoopTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        Button {
                            dismiss()
                            onDismiss()
                        } label: {
                            Text("New Game")
                                .font(.headline)
                                .foregroundStyle(HoopTheme.orange)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(HoopTheme.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    var quarterBreakdownView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUARTER BREAKDOWN")
                .font(.caption.bold())
                .foregroundStyle(HoopTheme.subtleText)
            
            Grid(alignment: .center, horizontalSpacing: 8, verticalSpacing: 8) {
                // Header
                GridRow {
                    Text("Period")
                        .font(.caption.bold())
                        .foregroundStyle(HoopTheme.subtleText)
                        .gridCellAnchor(.leading)
                    Text(engine.teamAName)
                        .font(.caption.bold())
                        .foregroundStyle(HoopTheme.teamA)
                        .lineLimit(1)
                    Text(engine.teamBName)
                        .font(.caption.bold())
                        .foregroundStyle(HoopTheme.teamB)
                        .lineLimit(1)
                }
                
                Divider()
                    .gridCellUnsizedAxes(.horizontal)
                
                // Quarter rows
                ForEach(0..<max(allQuarterScoresA.count, allQuarterScoresB.count), id: \.self) { q in
                    GridRow {
                        Text("Q\(q + 1)")
                            .font(.subheadline)
                            .foregroundStyle(HoopTheme.subtleText)
                            .gridCellAnchor(.leading)
                        Text("\(q < allQuarterScoresA.count ? allQuarterScoresA[q] : 0)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Text("\(q < allQuarterScoresB.count ? allQuarterScoresB[q] : 0)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                }
                
                Divider()
                    .gridCellUnsizedAxes(.horizontal)
                
                // Total
                GridRow {
                    Text("Total")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .gridCellAnchor(.leading)
                    Text("\(engine.scoreA)")
                        .font(.headline.bold())
                        .foregroundStyle(engine.scoreA > engine.scoreB ? HoopTheme.teamA : .white)
                    Text("\(engine.scoreB)")
                        .font(.headline.bold())
                        .foregroundStyle(engine.scoreB > engine.scoreA ? HoopTheme.teamB : .white)
                }
            }
            .padding()
            .background(HoopTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    func playerStatsTable(teamName: String, teamColor: Color, players: [PlayerState]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(teamName.uppercased())
                .font(.caption.bold())
                .foregroundStyle(teamColor)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Player")
                        .font(.caption.bold())
                        .foregroundStyle(HoopTheme.subtleText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("PTS")
                        .font(.caption.bold())
                        .foregroundStyle(HoopTheme.subtleText)
                        .frame(width: 36)
                    Text("2PM")
                        .font(.caption.bold())
                        .foregroundStyle(HoopTheme.subtleText)
                        .frame(width: 36)
                    Text("3PM")
                        .font(.caption.bold())
                        .foregroundStyle(HoopTheme.subtleText)
                        .frame(width: 36)
                    Text("FT")
                        .font(.caption.bold())
                        .foregroundStyle(HoopTheme.subtleText)
                        .frame(width: 42)
                    Text("PF")
                        .font(.caption.bold())
                        .foregroundStyle(HoopTheme.subtleText)
                        .frame(width: 28)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))
                
                ForEach(players.sorted(by: { $0.totalPoints > $1.totalPoints })) { player in
                    Divider().background(Color.white.opacity(0.05))
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.name)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            if !player.number.isEmpty {
                                Text("#\(player.number)")
                                    .font(.caption2)
                                    .foregroundStyle(HoopTheme.subtleText)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(player.totalPoints)")
                            .font(.subheadline.bold())
                            .foregroundStyle(teamColor)
                            .frame(width: 36)
                        Text("\(player.points2)")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(width: 36)
                        Text("\(player.points3)")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(width: 36)
                        Text("\(player.ftMade)/\(player.ftAttempted)")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .frame(width: 42)
                        Text("\(player.fouls)")
                            .font(.subheadline)
                            .foregroundStyle(player.fouls >= 5 ? .red : .white)
                            .frame(width: 28)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .background(HoopTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
