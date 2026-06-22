import SwiftUI

// MARK: - Color Palette

extension Color {
    static let surgeBackground = Color(red: 0.039, green: 0.039, blue: 0.059)     // #0A0A0F
    static let surgeAccent = Color(red: 0.290, green: 0.565, blue: 0.851)          // #4A90D9
    static let surgeHighlight = Color(red: 0.961, green: 0.510, blue: 0.122)      // #F5821F
    static let surgeTextPrimary = Color(red: 0.784, green: 0.784, blue: 0.816)    // #C8C8D0
    static let surgeTextSecondary = Color(red: 0.5, green: 0.5, blue: 0.55)
    static let surgeSurface = Color(red: 0.102, green: 0.102, blue: 0.180)        // #1A1A2E
    static let surgeSurfaceElevated = Color(red: 0.086, green: 0.129, blue: 0.243) // #16213E
    static let surgeSuccess = Color(red: 0.298, green: 0.686, blue: 0.314)        // #4CAF50
    static let surgeWarning = Color(red: 1.0, green: 0.596, blue: 0.0)            // #FF9800
    static let surgeDivider = Color(white: 1.0, opacity: 0.08)
}

// MARK: - Run Type Colors

struct RunTypeColor {
    static func color(for runType: RunType) -> Color {
        switch runType {
        case .easy:       return .surgeAccent
        case .long:       return Color(red: 0.502, green: 0.263, blue: 0.796)    // Purple
        case .tempo:      return .surgeHighlight
        case .interval:   return Color(red: 0.957, green: 0.263, blue: 0.212)   // Red
        case .racePace:   return Color(red: 0.129, green: 0.588, blue: 0.953)   // Bright blue
        case .crossTrain: return .surgeSuccess
        case .rest:       return .surgeTextSecondary
        }
    }

    static func backgroundColor(for runType: RunType) -> Color {
        return color(for: runType).opacity(0.15)
    }
}

// MARK: - Typography

extension Font {
    static var surgeTitle: Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    static var surgeHeadline: Font {
        .system(size: 18, weight: .semibold, design: .rounded)
    }

    static var surgeBody: Font {
        .system(size: 15, weight: .regular, design: .default)
    }

    static var surgeCaption: Font {
        .system(size: 12, weight: .medium, design: .default)
    }

    static var surgeMonospace: Font {
        .system(size: 16, weight: .semibold, design: .monospaced)
    }

    static var surgeLargeNumber: Font {
        .system(size: 40, weight: .bold, design: .rounded)
    }
}

// MARK: - View Modifiers

struct SurgeCardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.surgeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.surgeDivider, lineWidth: 1)
            )
    }
}

struct SurgeButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.surgeAccent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct SurgeHighlightButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.surgeHighlight)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct SurgeSecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.surgeAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.surgeAccent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.surgeAccent.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - View Extensions

extension View {
    func surgeCard(padding: CGFloat = 16) -> some View {
        modifier(SurgeCardModifier(padding: padding))
    }

    func surgeButton() -> some View {
        modifier(SurgeButtonModifier())
    }

    func surgeHighlightButton() -> some View {
        modifier(SurgeHighlightButtonModifier())
    }

    func surgeSecondaryButton() -> some View {
        modifier(SurgeSecondaryButtonModifier())
    }

    func surgeBackground() -> some View {
        self.background(Color.surgeBackground.ignoresSafeArea())
    }
}

// MARK: - Reusable Components

struct SurgeSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.surgeHeadline)
                    .foregroundColor(.surgeTextPrimary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.surgeCaption)
                        .foregroundColor(.surgeTextSecondary)
                }
            }
            Spacer()
            if let action = action {
                Button(actionLabel, action: action)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.surgeAccent)
            }
        }
    }
}

struct StatBadge: View {
    let label: String
    let value: String
    var color: Color = .surgeAccent

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.surgeCaption)
                .foregroundColor(.surgeTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
