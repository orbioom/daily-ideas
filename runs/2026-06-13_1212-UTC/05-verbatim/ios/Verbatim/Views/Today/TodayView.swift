import SwiftUI
import SwiftData

/// The due-for-review queue: passages whose next review has arrived, sorted by
/// how overdue they are, with a one-tap "Review next" entry into the player.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var passages: [Passage]

    @State private var studyPassage: Passage?

    private var due: [Passage] {
        passages
            .filter { $0.isDue() }
            .sorted { $0.nextDue < $1.nextDue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Passage.self) { PassageDetailView(passage: $0) }
            .sheet(item: $studyPassage) { StudyPlayerView(passage: $0) }
        }
    }

    @ViewBuilder private var content: some View {
        if passages.isEmpty {
            EmptyStateView(icon: "calendar.badge.clock",
                           title: "Nothing to review yet",
                           message: "Add a passage in the Library and your daily reviews will appear here.")
        } else if due.isEmpty {
            EmptyStateView(icon: "checkmark.circle.fill",
                           title: "All caught up",
                           message: nudge)
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    nudgeCard
                    LazyVStack(spacing: 12) {
                        ForEach(due) { passage in
                            DueRow(passage: passage) {
                                Haptics.tap(); studyPassage = passage
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
    }

    /// A deterministic daily encouragement that changes by day-of-year.
    private var nudge: String {
        let lines = [
            "Your memory is rested — check back tomorrow for the next round.",
            "Everything’s reviewed. Add a new passage to keep building.",
            "No reviews due. Consistency is what makes it stick.",
            "You’re ahead of the curve. See you tomorrow."
        ]
        let day = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return lines[day % lines.count]
    }

    private var nudgeCard: some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24)).foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(due.count) passage\(due.count == 1 ? "" : "s") to review")
                        .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                    Text("Tap Review next to start with the most overdue.")
                        .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, 16)
        .overlay(alignment: .bottomTrailing) {
            if let first = due.first {
                Button {
                    Haptics.tap(); studyPassage = first
                } label: {
                    Text("Review next")
                        .font(Theme.rounded(14, .bold))
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(Theme.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(20)
            }
        }
    }
}

private struct DueRow: View {
    let passage: Passage
    let study: () -> Void
    var body: some View {
        Card {
            HStack(spacing: 14) {
                MasteryRing(level: passage.masteryLevel, size: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(passage.title)
                        .font(Theme.serif(17, .bold)).foregroundStyle(Theme.ink)
                        .lineLimit(2)
                    Text("\(passage.currentMaskLevel.displayName) · \(passage.wordCount) words")
                        .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Button(action: study) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 34)).foregroundStyle(Theme.accent)
                }
                .accessibilityLabel("Study \(passage.title)")
            }
        }
    }
}
