import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var reflections: [Reflection]
    @Query private var saved: [SavedQuote]

    @State private var presentedKind: Reflection.Kind?

    private let today = Date()

    private var quote: StoicQuote? { StoicEngine.quoteOfDay(for: today) }
    private var virtue: Virtue { StoicEngine.virtueOfDay(for: today) }
    private var stats: PracticeStats { PracticeStats.from(reflections) }

    private func todays(_ kind: Reflection.Kind) -> Reflection? {
        let cal = Calendar.current
        return reflections.first { cal.isDateInToday($0.date) && $0.kind == kind }
    }

    private func isSaved(_ q: StoicQuote) -> Bool {
        saved.contains { $0.quoteID == q.id }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        if let quote {
                            QuoteCard(quote: quote, isSaved: isSaved(quote), large: true) {
                                toggleSave(quote)
                            }
                        }
                        virtueCard
                        ritualTiles
                        if stats.currentStreak > 0 { streakBadge }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $presentedKind) { kind in
                ReflectFlowView(kind: kind, existing: todays(kind))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Fmt.longDate(today))
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.inkSoft)
            Text("Meet the day well.")
                .font(Theme.serif(22, .bold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var virtueCard: some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: virtue.icon)
                    .font(.system(size: 30))
                    .foregroundStyle(virtue.tint)
                    .frame(width: 44)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Today's virtue · \(virtue.greek)")
                        .font(Theme.rounded(12, .bold))
                        .foregroundStyle(Theme.inkSoft)
                    Text(virtue.rawValue)
                        .font(Theme.serif(20, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(virtue.definition)
                        .font(Theme.rounded(13, .regular))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's virtue: \(virtue.rawValue). \(virtue.definition)")
    }

    private var ritualTiles: some View {
        HStack(spacing: 12) {
            RitualTile(kind: .morning, done: todays(.morning) != nil) {
                presentedKind = .morning
            }
            RitualTile(kind: .evening, done: todays(.evening) != nil) {
                presentedKind = .evening
            }
        }
    }

    private var streakBadge: some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("\(stats.currentStreak)-day reflection streak")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current streak: \(stats.currentStreak) days")
    }

    private func toggleSave(_ q: StoicQuote) {
        if let existing = saved.first(where: { $0.quoteID == q.id }) {
            context.delete(existing)
        } else {
            context.insert(SavedQuote(quoteID: q.id))
        }
        try? context.save()
    }
}

private struct RitualTile: View {
    let kind: Reflection.Kind
    let done: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: kind.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    if done {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.good)
                    }
                }
                Text(kind == .morning ? "Morning" : "Evening")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Text(done ? "Done — tap to view" : "Begin")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(done ? Theme.good : Theme.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(kind.title), \(done ? "completed today, tap to view" : "not yet done, tap to begin")")
    }
}
