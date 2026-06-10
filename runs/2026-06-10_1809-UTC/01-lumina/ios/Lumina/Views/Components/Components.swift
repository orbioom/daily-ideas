import SwiftUI
import SwiftData

/// Records that the user affirmed something today, incrementing today's count.
enum PracticeLog {
    static func record(_ context: ModelContext, count: Int = 1, on date: Date = .now) {
        let day = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DayLog>(predicate: #Predicate { $0.day == day })
        if let existing = try? context.fetch(descriptor).first {
            existing.count += count
        } else {
            context.insert(DayLog(day: day, count: count))
        }
        try? context.save()
    }
}

/// The signature calm affirmation card — large, centered text on glass with a
/// soft themed glow.
struct AffirmationCardView: View {
    let affirmation: Affirmation
    var compact: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: affirmation.theme.icon)
                    .font(.footnote.weight(.semibold))
                Text(affirmation.theme.title.uppercased())
                    .font(Brand.mono(11, weight: .medium))
                    .tracking(1.4)
            }
            .foregroundStyle(affirmation.theme.tint)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Theme: \(affirmation.theme.title)")

            Text(affirmation.text)
                .font(.system(size: compact ? 22 : 28, weight: .semibold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
                .fixedSize(horizontal: false, vertical: true)

            if affirmation.isFavorite {
                Label("Favorite", systemImage: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(Brand.danger)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Favorited")
            }
        }
        .padding(.vertical, compact ? 22 : 36)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(affirmation.theme.tint.opacity(0.10))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(affirmation.theme.tint.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Brand.cardShadow, radius: 18, x: 0, y: 10)
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(26, weight: .semibold))
                .foregroundStyle(tint)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
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
