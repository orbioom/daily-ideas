import SwiftUI

/// Maps the Stroop color names to on-brand, contrast-safe colors.
enum GameColors {
    static func color(_ name: String) -> Color {
        switch name {
        case "Red": return Brand.dynamic(0xC0392B, 0xE57368)
        case "Blue": return Brand.dynamic(0x2D6CC0, 0x6FA3E8)
        case "Green": return Brand.dynamic(0x2E8B57, 0x5FC78C)
        case "Orange": return Brand.dynamic(0xC8791F, 0xE8A24E)
        case "Purple": return Brand.dynamic(0x7A3FB0, 0xB07AE0)
        default: return Brand.text
        }
    }
}

/// Heads-up display: timer ring + score, shown atop every game.
struct GameHUD: View {
    let game: Game
    let timeRemaining: Int
    let totalTime: Int
    let score: Int
    let onQuit: () -> Void

    private var progress: Double {
        totalTime > 0 ? Double(timeRemaining) / Double(totalTime) : 0
    }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onQuit) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Brand.text3)
            }
            .accessibilityLabel("Quit game")

            ZStack {
                Circle().stroke(Brand.hairline, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(game.tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(timeRemaining)")
                    .font(Brand.mono(15, weight: .semibold))
                    .foregroundStyle(Brand.text)
            }
            .frame(width: 46, height: 46)
            .animation(.linear(duration: 0.3), value: timeRemaining)
            .accessibilityLabel("\(timeRemaining) seconds left")

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text("\(score)")
                    .font(Brand.mono(24, weight: .bold))
                    .foregroundStyle(game.tint)
                    .contentTransition(.numericText())
                Text("SCORE").font(Brand.mono(10, weight: .medium)).tracking(1.2)
                    .foregroundStyle(Brand.text3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

/// A short flash badge for correct / wrong feedback.
struct FeedbackBadge: View {
    enum Kind { case correct, wrong }
    let kind: Kind
    var body: some View {
        Image(systemName: kind == .correct ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.system(size: 54))
            .foregroundStyle(kind == .correct ? Brand.live : Brand.danger)
            .accessibilityHidden(true)
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(Brand.mono(24, weight: .semibold)).foregroundStyle(tint)
            Text(label).font(.caption).foregroundStyle(Brand.text2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
