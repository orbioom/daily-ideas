import SwiftUI

struct ScoreboardView: View {
    let viewModel: GameViewModel
    let showRunningTotal: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack(spacing: 0) {
                Text("Player")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 72, alignment: .leading)
                    .padding(.leading, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(1...10, id: \.self) { frame in
                            Text(frame == 10 ? "10" : "\(frame)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: frame == 10 ? 54 : 40, alignment: .center)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.vertical, 4)
            .background(AlleyTheme.darkBackground)

            Divider().background(Color.white.opacity(0.1))

            // Player rows
            ForEach(Array(viewModel.playerNames.enumerated()), id: \.offset) { idx, name in
                PlayerScoreRow(
                    playerName: name,
                    playerIndex: idx,
                    viewModel: viewModel,
                    showRunningTotal: showRunningTotal,
                    isCurrentPlayer: idx == viewModel.currentPlayer && !viewModel.isGameOver
                )

                if idx < viewModel.playerNames.count - 1 {
                    Divider().background(Color.white.opacity(0.08))
                }
            }
        }
        .background(AlleyTheme.frameBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct PlayerScoreRow: View {
    let playerName: String
    let playerIndex: Int
    let viewModel: GameViewModel
    let showRunningTotal: Bool
    let isCurrentPlayer: Bool

    private var frameStrings: [(String, String)] {
        viewModel.frameDisplayStrings(for: playerIndex)
    }

    private var scores: [Int?] {
        viewModel.frameScores(for: playerIndex)
    }

    private var currentFrame: Int {
        viewModel.currentFrame(for: playerIndex)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Player name
            VStack(alignment: .leading, spacing: 2) {
                if isCurrentPlayer {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(AlleyTheme.accent)
                }
                Text(playerName)
                    .font(.system(size: 11, weight: isCurrentPlayer ? .bold : .medium))
                    .foregroundStyle(isCurrentPlayer ? .white : .white.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: 72, alignment: .leading)
            .padding(.leading, 8)
            .background(isCurrentPlayer ? AlleyTheme.accent.opacity(0.10) : Color.clear)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(0..<10, id: \.self) { frame in
                        FrameCell(
                            frame: frame,
                            displayStrings: frame < frameStrings.count ? frameStrings[frame] : nil,
                            score: frame < scores.count ? scores[frame] : nil,
                            isActive: isCurrentPlayer && frame == currentFrame,
                            showRunningTotal: showRunningTotal
                        )
                        if frame < 9 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .frame(height: 44)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(height: 44)
        .background(isCurrentPlayer ? AlleyTheme.accent.opacity(0.05) : Color.clear)
    }
}

struct FrameCell: View {
    let frame: Int
    let displayStrings: (String, String)?
    let score: Int??
    let isActive: Bool
    let showRunningTotal: Bool

    var width: CGFloat { frame == 9 ? 54 : 40 }

    var body: some View {
        ZStack {
            if isActive {
                Rectangle()
                    .fill(AlleyTheme.accent.opacity(0.2))
            }

            VStack(spacing: 0) {
                // Ball symbols row
                if frame == 9 {
                    // 10th frame — show up to 3 symbols inline
                    let combined = displayStrings?.0 ?? ""
                    Text(combined)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(tenthFrameColor(combined))
                        .frame(width: width, height: 22, alignment: .center)
                } else {
                    HStack(spacing: 2) {
                        let s1 = displayStrings?.0 ?? ""
                        let s2 = displayStrings?.1 ?? ""
                        Text(s1)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AlleyTheme.ballSymbolColor(for: s1))
                            .frame(width: (width / 2) - 2, alignment: .center)
                        Text(s2)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AlleyTheme.ballSymbolColor(for: s2))
                            .frame(width: (width / 2) - 2, alignment: .center)
                    }
                    .frame(height: 22)
                }

                Divider().background(Color.white.opacity(0.1))

                // Score row
                if showRunningTotal, let wrappedScore = score, let s = wrappedScore {
                    Text("\(s)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: width, height: 20, alignment: .center)
                } else {
                    Text("")
                        .frame(width: width, height: 20)
                }
            }
        }
        .frame(width: width, height: 44)
    }

    func tenthFrameColor(_ s: String) -> Color {
        if s.contains("X") { return AlleyTheme.strikeColor }
        if s.contains("/") { return AlleyTheme.spareColor }
        return .white
    }
}
