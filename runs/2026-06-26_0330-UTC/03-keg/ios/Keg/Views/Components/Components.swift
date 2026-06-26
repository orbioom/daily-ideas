import SwiftUI

struct KegCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color

    init(title: String, value: String, subtitle: String? = nil, color: Color = .accentColor) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            if let sub = subtitle {
                Text(sub)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)\(subtitle.map { ". \($0)" } ?? "")")
    }
}

struct SRMSwatch: View {
    let srm: Double
    let size: CGFloat

    init(_ srm: Double, size: CGFloat = 32) {
        self.srm = srm
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(KegTheme.srmColor(srm))
                .frame(width: size, height: size)
            Circle()
                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                .frame(width: size, height: size)
        }
        .accessibilityLabel("Beer color SRM \(Int(srm))")
    }
}

struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(statusName(status))
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(KegTheme.statusColor(status).opacity(0.15))
            .foregroundStyle(KegTheme.statusColor(status))
            .clipShape(Capsule())
            .accessibilityLabel("Status: \(statusName(status))")
    }

    private func statusName(_ s: String) -> String {
        switch s {
        case "planned": return "Planned"
        case "fermenting": return "Fermenting"
        case "conditioning": return "Conditioning"
        case "kegged": return "Kegged"
        case "bottled": return "Bottled"
        case "complete": return "Complete"
        default: return s.capitalized
        }
    }
}
