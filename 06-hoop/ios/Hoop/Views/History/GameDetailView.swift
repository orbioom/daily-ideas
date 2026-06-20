import SwiftUI

struct GameDetailView: View {
    let game: HoopGame
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        return df
    }()
    
    var scoresA: [Int] { game.decodeScoresA() }
    var scoresB: [Int] { game.decodeScoresB() }
    
    var playersA: [HoopPlayer] { game.players.filter { $0.team == "A" }.sorted { $0.totalPoints > $1.totalPoints } }
    var playersB: [HoopPlayer] { game.players.filter { $0.team == "B" }.sorted { $0.totalPoints > $1.totalPoints } }
    
    var body: some View {
        ZStack {
            HoopTheme.darkBg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Date
                    Text(dateFormatter.string(from: game.date))
                        .font(.subheadline)
                        .foregroundStyle(HoopTheme.subtleText)
                    
                    // Final scores
                    HStack(spacing: 0) {
                        VStack {
                            Text(game.teamAName)
                                .font(.headline.bold())
                                .foregroundStyle(HoopTheme.teamA)
                            Text("\(game.finalScoreA)")
                                .font(.system(size: 64, weight: .black, design: .rounded))
                                .foregroundStyle(game.finalScoreA > game.finalScoreB ? HoopTheme.orange : .white)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Text("FINAL")
                                .font(.caption2.bold())
                                .foregroundStyle(HoopTheme.subtleText)
                            Text("–")
                                .font(.title.bold())
                                .foregroundStyle(HoopTheme.subtleText)
                        }
                        .frame(width: 60)
                        
                        VStack {
                            Text(game.teamBName)
                                .font(.headline.bold())
                                .foregroundStyle(HoopTheme.teamB)
                            Text("\(game.finalScoreB)")
                                .font(.system(size: 64, weight: .black, design: .rounded))
                                .foregroundStyle(game.finalScoreB > game.finalScoreA ? HoopTheme.orange : .white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(HoopTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    
                    // Winner
                    if game.winnerName != "Tie" {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(HoopTheme.orange)
                            Text("\(game.winnerName) wins!")
                                .font(.headline.bold())
                                .foregroundStyle(HoopTheme.orange)
                        }
                    }
                    
                    // Quarter breakdown
                    quarterBreakdown
                        .padding(.horizontal)
                    
                    // Player stats
                    if !playersA.isEmpty {
                        playerTable(teamName: game.teamAName, color: HoopTheme.teamA, players: playersA)
                            .padding(.horizontal)
                    }
                    if !playersB.isEmpty {
                        playerTable(teamName: game.teamBName, color: HoopTheme.teamB, players: playersB)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("\(game.teamAName) vs \(game.teamBName)")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    var quarterBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUARTER BREAKDOWN")
                .font(.caption.bold())
                .foregroundStyle(HoopTheme.subtleText)
            
            Grid(alignment: .center, horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    Text("Period")
                        .font(.caption.bold())
                        .foregroundStyle(HoopTheme.subtleText)
                        .gridCellAnchor(.leading)
                    Text(game.teamAName)
                        .font(.caption.bold())
                        .foregroundStyle(HoopTheme.teamA)
                        .lineLimit(1)
                    Text(game.teamBName)
                        .font(.caption.bold())
                        .foregroundStyle(HoopTheme.teamB)
                        .lineLimit(1)
                }
                
                Divider().gridCellUnsizedAxes(.horizontal)
                
                ForEach(0..<max(scoresA.count, scoresB.count), id: \.self) { q in
                    GridRow {
                        Text("Q\(q + 1)")
                            .font(.subheadline)
                            .foregroundStyle(HoopTheme.subtleText)
                            .gridCellAnchor(.leading)
                        Text("\(q < scoresA.count ? scoresA[q] : 0)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Text("\(q < scoresB.count ? scoresB[q] : 0)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                }
                
                Divider().gridCellUnsizedAxes(.horizontal)
                
                GridRow {
                    Text("Total")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .gridCellAnchor(.leading)
                    Text("\(game.finalScoreA)")
                        .font(.headline.bold())
                        .foregroundStyle(game.finalScoreA >= game.finalScoreB ? HoopTheme.teamA : .white)
                    Text("\(game.finalScoreB)")
                        .font(.headline.bold())
                        .foregroundStyle(game.finalScoreB >= game.finalScoreA ? HoopTheme.teamB : .white)
                }
            }
            .padding()
            .background(HoopTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    func playerTable(teamName: String, color: Color, players: [HoopPlayer]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(teamName.uppercased())
                .font(.caption.bold())
                .foregroundStyle(color)
            
            VStack(spacing: 0) {
                HStack {
                    Text("Player").font(.caption.bold()).foregroundStyle(HoopTheme.subtleText).frame(maxWidth: .infinity, alignment: .leading)
                    Text("PTS").font(.caption.bold()).foregroundStyle(HoopTheme.subtleText).frame(width: 36)
                    Text("2PM").font(.caption.bold()).foregroundStyle(HoopTheme.subtleText).frame(width: 36)
                    Text("3PM").font(.caption.bold()).foregroundStyle(HoopTheme.subtleText).frame(width: 36)
                    Text("FT").font(.caption.bold()).foregroundStyle(HoopTheme.subtleText).frame(width: 42)
                    Text("PF").font(.caption.bold()).foregroundStyle(HoopTheme.subtleText).frame(width: 28)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))
                
                ForEach(players) { player in
                    Divider().background(Color.white.opacity(0.05))
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.name).font(.subheadline).foregroundStyle(.white)
                            if !player.number.isEmpty {
                                Text("#\(player.number)").font(.caption2).foregroundStyle(HoopTheme.subtleText)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(player.totalPoints)").font(.subheadline.bold()).foregroundStyle(color).frame(width: 36)
                        Text("\(player.points2)").font(.subheadline).foregroundStyle(.white).frame(width: 36)
                        Text("\(player.points3)").font(.subheadline).foregroundStyle(.white).frame(width: 36)
                        Text("\(player.freeThrowsMade)/\(player.freeThrowsAttempted)").font(.caption).foregroundStyle(.white).frame(width: 42)
                        Text("\(player.fouls)").font(.subheadline).foregroundStyle(player.fouls >= 5 ? .red : .white).frame(width: 28)
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
