import SwiftUI

struct PegView: View {
    let colorIndex: Int?
    let size: CGFloat
    var dimmed = false

    var body: some View {
        Circle()
            .fill(colorIndex.map { pegColor($0) } ?? Color.white.opacity(0.1))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(dimmed ? 0.15 : 0.3), lineWidth: 1.5)
            )
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: size * 0.35, height: size * 0.35)
                    .offset(x: -size * 0.12, y: -size * 0.12)
            )
            .opacity(dimmed ? 0.4 : 1.0)
    }

    func pegColor(_ index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.95, green: 0.2, blue: 0.2)
        case 1: return Color(red: 0.95, green: 0.55, blue: 0.1)
        case 2: return Color(red: 0.95, green: 0.85, blue: 0.1)
        case 3: return Color(red: 0.2, green: 0.82, blue: 0.3)
        case 4: return Color(red: 0.2, green: 0.5, blue: 0.95)
        case 5: return Color(red: 0.6, green: 0.2, blue: 0.95)
        case 6: return Color(red: 0.95, green: 0.35, blue: 0.7)
        default: return Color(red: 0.92, green: 0.92, blue: 0.92)
        }
    }
}

struct FeedbackView: View {
    let black: Int
    let white: Int
    let codeLength: Int

    var body: some View {
        let total = codeLength
        let dots = (0..<total).map { i -> Color in
            if i < black { return .white }
            if i < black + white { return .white.opacity(0.45) }
            return .white.opacity(0.12)
        }
        let cols = Int(ceil(Double(total) / 2.0))
        let rows = (total + cols - 1) / cols

        Grid(horizontalSpacing: 3, verticalSpacing: 3) {
            ForEach(0..<rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<cols, id: \.self) { col in
                        let idx = row * cols + col
                        if idx < total {
                            Circle()
                                .fill(dots[idx])
                                .frame(width: 8, height: 8)
                        } else {
                            Color.clear.frame(width: 8, height: 8)
                        }
                    }
                }
            }
        }
        .frame(width: 28, height: CGFloat(rows) * 11)
    }
}

struct GuessRowView: View {
    let guess: [Int]
    let feedback: [Int]
    let codeLength: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(0..<codeLength, id: \.self) { i in
                    PegView(colorIndex: i < guess.count ? guess[i] : nil, size: 36)
                }
            }

            Spacer()

            if feedback.count == 2 {
                FeedbackView(black: feedback[0], white: feedback[1], codeLength: codeLength)
            } else {
                FeedbackView(black: 0, white: 0, codeLength: codeLength)
                    .opacity(isActive ? 0 : 0.3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? Color.white.opacity(0.06) : Color.clear)
        )
    }
}
