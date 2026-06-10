import SwiftUI
import SwiftData

struct ReflectView: View {
    @Query(sort: \GratitudeDay.date, order: .reverse) private var days: [GratitudeDay]
    @State private var shuffleSeed = 0

    private var calendar: Calendar { .current }

    /// Every (date, line) pair of recorded gratitudes and wins.
    private var moments: [(date: Date, text: String)] {
        days.flatMap { day in
            (day.filledGratitudes + day.filledWins).map { (day.date, $0) }
        }
    }

    /// A resurfaced moment — deterministic per day, re-rollable via shuffle.
    private var highlight: (date: Date, text: String)? {
        guard !moments.isEmpty else { return nil }
        let base = PlentyEngine.dayKey(.now)
        let index = abs(base &+ shuffleSeed &* 2_654_435_761) % moments.count
        return moments[index]
    }

    /// Entries from ~1 week, month, quarter, year ago (whichever exist).
    private var onThisJourney: [(label: String, day: GratitudeDay)] {
        let intervals: [(String, Int)] = [("A week ago", -7), ("A month ago", -30),
                                          ("Three months ago", -90), ("A year ago", -365)]
        return intervals.compactMap { label, offset in
            guard let target = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: .now)) else { return nil }
            let key = PlentyEngine.dayKey(target)
            if let day = days.first(where: { $0.dayKey == key && $0.hasAnyContent }) {
                return (label, day)
            }
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if moments.isEmpty {
                    EmptyStateView(icon: "sparkles",
                                   title: "Memories will gather here",
                                   message: "As you record more gratitude, Plenty will resurface good moments for you to revisit.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if let h = highlight { highlightCard(h) }
                            if !onThisJourney.isEmpty { journeySection }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Reflect")
        }
    }

    private func highlightCard(_ h: (date: Date, text: String)) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Eyebrow(text: "A moment to revisit")
                Spacer()
                Button {
                    withAnimation(Brand.ease()) { shuffleSeed += 1 }
                    Haptics.selection()
                } label: {
                    Image(systemName: "shuffle").foregroundStyle(Brand.text2)
                }
                .accessibilityLabel("Show another memory")
            }
            Text("“\(h.text)”")
                .font(.system(.title2, design: .serif).weight(.medium))
                .foregroundStyle(Brand.text)
            Text(h.date.formatted(.dateTime.weekday(.wide).month().day().year()))
                .font(Brand.mono(12)).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(Brand.magic.opacity(0.4), lineWidth: 1))
        .shadow(color: Brand.cardShadow, radius: 16, y: 8)
    }

    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "On your journey")
            ForEach(Array(onThisJourney.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.label).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                        Spacer()
                        Text(Mood(rawValue: item.day.mood)?.emoji ?? "🌱")
                    }
                    ForEach(Array((item.day.filledGratitudes + item.day.filledWins).prefix(3).enumerated()),
                            id: \.offset) { _, line in
                        Text("• \(line)").font(.subheadline).foregroundStyle(Brand.text2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()
            }
        }
    }
}
