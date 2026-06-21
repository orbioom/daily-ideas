import SwiftUI

struct PitView: View {
    let count: Int
    let isHighlighted: Bool
    let isLastMove: Bool
    let isValidMove: Bool
    var isStore: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Ellipse()
                    .fill(isStore ? PebbleTheme.woodBrown : PebbleTheme.pitFill)
                    .overlay(
                        Ellipse()
                            .stroke(
                                isLastMove ? PebbleTheme.sandGold :
                                    isValidMove ? PebbleTheme.stoneTeal.opacity(0.8) :
                                    Color.black.opacity(0.3),
                                lineWidth: isLastMove || isValidMove ? 2.5 : 1
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                if isStore {
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(PebbleTheme.sandGold)
                        Text("Store")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                } else {
                    VStack(spacing: 2) {
                        stonesGrid(count: count)
                        Text("\(count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isValidMove && !isStore)
    }

    @ViewBuilder
    private func stonesGrid(count: Int) -> some View {
        let cols = min(max(count, 1), 3)
        let rows = count == 0 ? 1 : (count + 2) / 3
        VStack(spacing: 2) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<cols, id: \.self) { col in
                        let idx = row * 3 + col
                        Circle()
                            .fill(idx < count ? PebbleTheme.stoneOrange : Color.clear)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .frame(height: 28)
    }
}
