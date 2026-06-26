import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color

    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color = .accentColor) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            if let sub = subtitle {
                Text(sub)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SplashTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)\(subtitle.map { ". \($0)" } ?? "")")
    }
}

struct StrokeTag: View {
    let stroke: String
    var body: some View {
        Text(stroke.strokeDisplayName)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(SplashTheme.strokeColor(stroke).opacity(0.18))
            .foregroundStyle(SplashTheme.strokeColor(stroke))
            .clipShape(Capsule())
            .accessibilityLabel("Stroke: \(stroke.strokeDisplayName)")
    }
}

struct IntensityTag: View {
    let intensity: String
    var body: some View {
        Text(intensity.intensityDisplayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(SplashTheme.intensityColor(intensity).opacity(0.15))
            .foregroundStyle(SplashTheme.intensityColor(intensity))
            .clipShape(Capsule())
            .accessibilityLabel("Intensity: \(intensity.intensityDisplayName)")
    }
}

struct RatingStars: View {
    let rating: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundStyle(i <= rating ? Color.yellow : Color.secondary.opacity(0.4))
            }
        }
        .accessibilityLabel("Feel rating: \(rating) out of 5")
    }
}
