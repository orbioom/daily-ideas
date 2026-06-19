import SwiftUI
import SwiftData

struct HighScoresView: View {
    @Query(sort: \HighScore.score, order: .reverse) private var allScores: [HighScore]
    @State private var selectedMode: GameMode = .classic

    private var filteredScores: [HighScore] {
        allScores.filter { $0.mode == selectedMode.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.04).ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(GameMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                    if filteredScores.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "trophy")
                                .font(.system(size: 52))
                                .foregroundStyle(.green.opacity(0.5))
                            Text("No scores yet")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.5))
                            Text("Play a game to set your first record")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.35))
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(Array(filteredScores.prefix(20).enumerated()), id: \.element.id) { rank, hs in
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(rankColor(rank).opacity(0.18))
                                            .frame(width: 38, height: 38)
                                        Text("#\(rank + 1)")
                                            .font(.caption.bold())
                                            .foregroundStyle(rankColor(rank))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(hs.score) pts")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text("\(hs.applesEaten) apples · \(hs.date.formatted(.relative(presentation: .named)))")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    Spacer()
                                    if rank == 0 {
                                        Image(systemName: "crown.fill")
                                            .foregroundStyle(.yellow)
                                    }
                                }
                                .listRowBackground(Color.white.opacity(0.06))
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("High Scores")
            .toolbarBackground(Color(red: 0.04, green: 0.06, blue: 0.04), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 0: return .yellow
        case 1: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 2: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .green
        }
    }
}
