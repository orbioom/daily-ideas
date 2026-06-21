import SwiftUI

struct PinEntryView: View {
    let maxPins: Int
    let onEntry: (Int) -> Void
    let currentFrame: Int
    let currentBall: Int
    let playerName: String

    @State private var lastTapped: Int? = nil

    // Build grid of available pin counts from 0 to maxPins
    private var pinCounts: [Int] {
        Array(0...maxPins)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Context label
            VStack(spacing: 4) {
                Text(playerName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Label("Frame \(currentFrame + 1)", systemImage: "rectangle.grid.1x2")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AlleyTheme.laneColor)

                    Text("·")
                        .foregroundStyle(.white.opacity(0.3))

                    let ballLabel = ballLabelText()
                    Text(ballLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AlleyTheme.laneColor)
                }
            }
            .padding(.top, 8)

            // Pin diagram (optional visual)
            PinDiagramView(maxPins: maxPins)
                .frame(height: 80)

            // Pin count grid
            let columns = [GridItem](repeating: GridItem(.flexible(), spacing: 10), count: 4)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(pinCounts, id: \.self) { count in
                    PinButton(
                        count: count,
                        maxPins: maxPins,
                        isLastTapped: lastTapped == count,
                        action: {
                            lastTapped = count
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                lastTapped = nil
                            }
                            onEntry(count)
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func ballLabelText() -> String {
        if currentFrame == 9 {
            switch currentBall {
            case 0: return "Ball 1"
            case 1: return "Ball 2"
            case 2: return "Ball 3"
            default: return "Ball"
            }
        } else {
            return currentBall == 0 ? "Ball 1" : "Ball 2"
        }
    }
}

struct PinButton: View {
    let count: Int
    let maxPins: Int
    let isLastTapped: Bool
    let action: () -> Void

    private var isStrike: Bool { count == 10 && maxPins == 10 }
    private var isGutter: Bool { count == 0 }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1.5)
                    )
                    .scaleEffect(isLastTapped ? 0.92 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isLastTapped)

                VStack(spacing: 2) {
                    Text(labelText)
                        .font(.system(size: isStrike ? 20 : 18, weight: .bold, design: .rounded))
                        .foregroundStyle(textColor)

                    if isStrike {
                        Text("STRIKE")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(AlleyTheme.strikeColor.opacity(0.8))
                    } else if isGutter {
                        Text("gutter")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .frame(height: 62)
        }
        .buttonStyle(.plain)
    }

    private var labelText: String {
        if isStrike { return "X" }
        if isGutter { return "-" }
        return "\(count)"
    }

    private var backgroundColor: Color {
        if isStrike { return AlleyTheme.strikeColor.opacity(0.18) }
        if isGutter { return Color.white.opacity(0.05) }
        return AlleyTheme.frameBackground
    }

    private var borderColor: Color {
        if isStrike { return AlleyTheme.strikeColor.opacity(0.6) }
        if isGutter { return Color.white.opacity(0.1) }
        return Color.white.opacity(0.15)
    }

    private var textColor: Color {
        if isStrike { return AlleyTheme.strikeColor }
        if isGutter { return .white.opacity(0.5) }
        return .white
    }
}

struct PinDiagramView: View {
    let maxPins: Int

    // Standard bowling pin triangle positions (1 through 10)
    // Pin 1 is front, pins 7-10 are back row
    private let pinPositions: [(CGFloat, CGFloat)] = [
        (0.5, 0.85),   // pin 1  (front)
        (0.41, 0.60),  // pin 2
        (0.59, 0.60),  // pin 3
        (0.32, 0.35),  // pin 4
        (0.50, 0.35),  // pin 5
        (0.68, 0.35),  // pin 6
        (0.23, 0.10),  // pin 7
        (0.41, 0.10),  // pin 8
        (0.59, 0.10),  // pin 9
        (0.77, 0.10),  // pin 10
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Lane color background strip
                RoundedRectangle(cornerRadius: 8)
                    .fill(AlleyTheme.laneColor.opacity(0.12))

                // Draw pins
                ForEach(Array(pinPositions.enumerated()), id: \.offset) { idx, pos in
                    let px = pos.0 * geo.size.width
                    let py = pos.1 * geo.size.height

                    Circle()
                        .fill(idx < maxPins ? AlleyTheme.pinColor : Color.white.opacity(0.15))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(idx < maxPins ? AlleyTheme.laneColor.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                        .position(x: px, y: py)
                }
            }
        }
    }
}
