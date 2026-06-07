import SwiftUI
import SwiftData

/// The Log tab: every developing session, newest first, with a small insights
/// header (most-used film, most-used developer, total rolls). Tapping a row opens
/// its detail for editing or deletion.
struct LogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DevSession.date, order: .reverse) private var sessions: [DevSession]

    @AppStorage("latent.tempUnit") private var tempUnitRaw = TempUnit.celsius.rawValue
    private var tempUnit: TempUnit { TempUnit(rawValue: tempUnitRaw) ?? .celsius }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Log")
            .navigationDestination(for: DevSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if sessions.isEmpty {
            EmptyStateView(
                icon: "book.closed",
                title: "No sessions yet",
                message: "Finish a developing run on the Develop tab and it'll appear here with all its parameters."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    insightsHeader
                    ForEach(sessions) { session in
                        NavigationLink(value: session) {
                            SessionRow(session: session, tempUnit: tempUnit)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(session)
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Insights

    private var insightsHeader: some View {
        let insights = LogInsights(sessions: sessions)
        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatTile(value: "\(insights.totalRolls)", label: "Rolls", accent: Brand.magic)
                StatTile(value: "\(sessions.count)", label: "Sessions", accent: Brand.info)
            }
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Most-used film", value: insights.topFilm)
                Divider().overlay(Brand.hairline)
                InfoRow(label: "Most-used developer", value: insights.topDeveloper)
            }
            .glassCard()
        }
        .padding(.bottom, 4)
    }

    private func delete(_ session: DevSession) {
        Haptics.warning()
        context.delete(session)
        try? context.save()
    }
}

/// One log row: date, film + developer, key chemistry, dev time, rating stars.
struct SessionRow: View {
    let session: DevSession
    let tempUnit: TempUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Format.relativeDate(session.date))
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Spacer()
                Text(DevEngine.clock(session.devSec))
                    .font(Brand.mono(15, weight: .semibold))
                    .foregroundStyle(Brand.text)
            }
            Text(session.summary)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .lineLimit(1)
            HStack(spacing: 6) {
                Badge(text: Format.tempString(session.tempC, unit: tempUnit, decimals: 1), color: Brand.info)
                Badge(text: session.pushPullLabel, color: session.pushPull == 0 ? Brand.text2 : Brand.warn)
                Badge(text: "\(session.rolls) roll\(session.rolls == 1 ? "" : "s")", color: Brand.text2)
                Spacer()
                if session.rating > 0 {
                    StarRating(value: session.rating, size: 12)
                }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Format.relativeDate(session.date)). \(session.summary). \(Format.tempString(session.tempC, unit: tempUnit, decimals: 1)). \(session.pushPullLabel). Develop time \(DevEngine.clock(session.devSec)). Rated \(session.rating) of 5.")
    }
}

/// Aggregate insights computed over all sessions, guarded against empties.
struct LogInsights {
    let totalRolls: Int
    let topFilm: String
    let topDeveloper: String

    init(sessions: [DevSession]) {
        totalRolls = sessions.reduce(0) { $0 + max(0, $1.rolls) }
        topFilm = LogInsights.mostCommon(sessions.map { $0.filmStock }) ?? "—"
        topDeveloper = LogInsights.mostCommon(sessions.map { $0.developer }) ?? "—"
    }

    /// The most frequent non-empty value, or nil if none.
    private static func mostCommon(_ values: [String]) -> String? {
        var counts: [String: Int] = [:]
        for v in values where !v.trimmingCharacters(in: .whitespaces).isEmpty {
            counts[v, default: 0] += 1
        }
        return counts.max { a, b in a.value < b.value }?.key
    }
}
