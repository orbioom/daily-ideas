import SwiftUI

struct RunTypeBadge: View {
    let runType: RunType
    var style: BadgeStyle = .standard
    var showLabel: Bool = true

    enum BadgeStyle {
        case standard
        case compact
        case icon
    }

    var body: some View {
        switch style {
        case .standard:
            HStack(spacing: 6) {
                Image(systemName: runType.systemImage)
                    .font(.system(size: 11, weight: .semibold))
                if showLabel {
                    Text(runType.displayName)
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundColor(RunTypeColor.color(for: runType))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(RunTypeColor.backgroundColor(for: runType))
            .clipShape(Capsule())

        case .compact:
            Text(runType.shortName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(RunTypeColor.color(for: runType))
                .frame(width: 28, height: 28)
                .background(RunTypeColor.backgroundColor(for: runType))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

        case .icon:
            Image(systemName: runType.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(RunTypeColor.color(for: runType))
                .frame(width: 36, height: 36)
                .background(RunTypeColor.backgroundColor(for: runType))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(RunType.allCases, id: \.self) { type in
            HStack(spacing: 12) {
                RunTypeBadge(runType: type, style: .compact)
                RunTypeBadge(runType: type, style: .standard)
                RunTypeBadge(runType: type, style: .icon)
            }
        }
    }
    .padding()
    .background(Color.surgeBackground)
}
