import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \BowlingGame.date, order: .reverse) private var games: [BowlingGame]
    @Environment(\.modelContext) private var ctx
    @State private var selectedGame: BowlingGame? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                AlleyTheme.darkBackground.ignoresSafeArea()

                if games.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Games Yet",
                        message: "Start a new game and your history will appear here."
                    )
                } else {
                    List {
                        ForEach(games) { game in
                            Button {
                                selectedGame = game
                            } label: {
                                GameHistoryRow(game: game)
                            }
                            .listRowBackground(AlleyTheme.frameBackground)
                            .listRowSeparatorTint(Color.white.opacity(0.1))
                        }
                        .onDelete { indexSet in
                            for idx in indexSet {
                                ctx.delete(games[idx])
                            }
                            try? ctx.save()
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !games.isEmpty {
                        EditButton()
                            .foregroundStyle(AlleyTheme.accent)
                    }
                }
            }
            .sheet(item: $selectedGame) { game in
                GameDetailView(game: game)
            }
        }
    }
}

struct GameHistoryRow: View {
    let game: BowlingGame

    private var finalScores: [Int?] { game.finalScores() }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: game.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))

                    if !game.location.isEmpty {
                        Label(game.location, systemImage: "mappin.circle")
                            .font(.caption2)
                            .foregroundStyle(AlleyTheme.laneColor.opacity(0.8))
                    }
                }

                Spacer()

                if !game.isComplete {
                    Text("In Progress")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.3))
                        .clipShape(Capsule())
                }
            }

            Divider().background(Color.white.opacity(0.08))

            ForEach(Array(game.playerNames.enumerated()), id: \.offset) { idx, name in
                HStack {
                    Text(name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)

                    Spacer()

                    if let score = idx < finalScores.count ? finalScores[idx] : nil {
                        if let s = score {
                            HStack(spacing: 4) {
                                if s == 300 {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(AlleyTheme.strikeColor)
                                }
                                Text("\(s)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(s == 300 ? AlleyTheme.strikeColor : .white)
                            }
                        } else {
                            Text("—")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    } else {
                        Text("—")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
}

struct GameDetailView: View {
    let game: BowlingGame
    @Environment(\.dismiss) private var dismiss

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: game.date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AlleyTheme.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Game meta
                        VStack(spacing: 6) {
                            Text(dateText)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))

                            if !game.location.isEmpty {
                                Label(game.location, systemImage: "mappin.circle.fill")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AlleyTheme.laneColor)
                            }
                        }
                        .padding(.top, 8)

                        // Per-player scorecards
                        ForEach(Array(game.playerNames.enumerated()), id: \.offset) { playerIdx, name in
                            PlayerDetailCard(
                                playerName: name,
                                balls: playerIdx < game.decodedBalls.count ? game.decodedBalls[playerIdx] : []
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Game Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AlleyTheme.accent)
                }
            }
        }
    }
}

struct PlayerDetailCard: View {
    let playerName: String
    let balls: [Int]

    private var frameStrings: [(String, String)] {
        BowlingEngine.frameDisplayStrings(balls: balls)
    }

    private var scores: [Int?] {
        BowlingEngine.frameScores(balls: balls)
    }

    private var finalScore: Int {
        scores.compactMap { $0 }.last ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(playerName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(finalScore)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(finalScore == 300 ? AlleyTheme.strikeColor : .white)
            }

            // Frame grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(0..<10, id: \.self) { frame in
                        DetailFrameCell(
                            frame: frame,
                            displayStrings: frame < frameStrings.count ? frameStrings[frame] : nil,
                            score: frame < scores.count ? scores[frame] : nil
                        )
                        if frame < 9 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .frame(height: 48)
                        }
                    }
                }
            }
            .background(AlleyTheme.darkBackground.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(AlleyTheme.frameBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct DetailFrameCell: View {
    let frame: Int
    let displayStrings: (String, String)?
    let score: Int??

    var width: CGFloat { frame == 9 ? 58 : 44 }

    var body: some View {
        VStack(spacing: 0) {
            Text("\(frame + 1)")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.35))
                .frame(height: 14)

            if frame == 9 {
                let combined = displayStrings?.0 ?? ""
                Text(combined)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(tenthColor(combined))
                    .frame(width: width, height: 20, alignment: .center)
            } else {
                HStack(spacing: 2) {
                    let s1 = displayStrings?.0 ?? ""
                    let s2 = displayStrings?.1 ?? ""
                    Text(s1)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AlleyTheme.ballSymbolColor(for: s1))
                        .frame(width: (width / 2) - 1, alignment: .center)
                    Text(s2)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AlleyTheme.ballSymbolColor(for: s2))
                        .frame(width: (width / 2) - 1, alignment: .center)
                }
                .frame(height: 20)
            }

            Divider().background(Color.white.opacity(0.1))

            if let wrapped = score, let s = wrapped {
                Text("\(s)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: width, height: 14, alignment: .center)
            } else {
                Text("").frame(height: 14)
            }
        }
        .frame(width: width, height: 48)
    }

    func tenthColor(_ s: String) -> Color {
        if s.contains("X") { return AlleyTheme.strikeColor }
        if s.contains("/") { return AlleyTheme.spareColor }
        return .white
    }
}
