import SwiftUI

/// A calm, tappable 5-point Disagree↔Agree scale with full VoiceOver labels.
struct LikertScale: View {
    let selected: Int?
    let onSelect: (Int) -> Void

    private let labels: [Int: String] = [
        1: "Strongly disagree",
        2: "Disagree",
        3: "Neutral",
        4: "Agree",
        5: "Strongly agree"
    ]

    // Sizes grow toward the agree/disagree ends for a familiar semantic-differential look.
    private func diameter(for value: Int) -> CGFloat {
        switch value {
        case 1, 5: return 56
        case 2, 4: return 46
        default: return 38
        }
    }

    private func tint(for value: Int) -> Color {
        switch value {
        case 1, 2: return Theme.bad
        case 4, 5: return Theme.good
        default: return Theme.inkFaint
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ForEach(1...5, id: \.self) { value in
                    circle(for: value)
                }
            }
            HStack {
                Text("Disagree")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.bad)
                Spacer()
                Text("Agree")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.good)
            }
            .accessibilityHidden(true)
        }
    }

    private func circle(for value: Int) -> some View {
        let isSelected = selected == value
        let color = tint(for: value)
        let d = diameter(for: value)
        return Button {
            onSelect(value)
        } label: {
            Circle()
                .strokeBorder(color, lineWidth: 2.5)
                .background(
                    Circle().fill(isSelected ? color : Color.clear)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: d * 0.32, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(isSelected ? 1 : 0)
                )
                .frame(width: d, height: d)
        }
        .buttonStyle(PressableScale())
        .accessibilityLabel(labels[value] ?? "Option \(value)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Tap to choose this answer")
    }
}
