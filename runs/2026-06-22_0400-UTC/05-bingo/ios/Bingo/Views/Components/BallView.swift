import SwiftUI

struct BallView: View {
    let text: String
    let size: CGFloat

    var letter: String {
        guard let firstChar = text.first, "BINGO".contains(firstChar) else {
            return ""
        }
        return String(firstChar)
    }

    var number: String {
        if !letter.isEmpty {
            return String(text.dropFirst())
        }
        return text
    }

    var ballColor: Color {
        switch letter {
        case "B": return Color(hex: "#3B82F6")
        case "I": return Color(hex: "#EF4444")
        case "N": return Color(hex: "#8B5CF6")
        case "G": return Color(hex: "#10B981")
        case "O": return Color(hex: "#F97316")
        default: return BingoTheme.gold
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [ballColor.opacity(0.8), ballColor],
                        center: .topLeading,
                        startRadius: size * 0.1,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: ballColor.opacity(0.5), radius: 8, x: 0, y: 4)

            VStack(spacing: 0) {
                if !letter.isEmpty {
                    Text(letter)
                        .font(.system(size: size * 0.2, weight: .black))
                        .foregroundColor(.white.opacity(0.9))
                    Text(number)
                        .font(.system(size: size * 0.32, weight: .black))
                        .foregroundColor(.white)
                } else {
                    Text(text)
                        .font(.system(size: size * 0.2, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(size * 0.1)
                }
            }
        }
    }
}

struct CalledBallChip: View {
    let text: String

    var letter: String {
        guard let firstChar = text.first, "BINGO".contains(firstChar) else {
            return ""
        }
        return String(firstChar)
    }

    var ballColor: Color {
        switch letter {
        case "B": return Color(hex: "#3B82F6")
        case "I": return Color(hex: "#EF4444")
        case "N": return Color(hex: "#8B5CF6")
        case "G": return Color(hex: "#10B981")
        case "O": return Color(hex: "#F97316")
        default: return BingoTheme.gold
        }
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ballColor)
            .cornerRadius(8)
    }
}
