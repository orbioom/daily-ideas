import SwiftUI
import SwiftData

/// Fast daily logging of every active tracker. Adapts each control to the tracker's scale, shows
/// what's logged vs pending, upserts one entry per tracker per day, and confirms with a success
/// state. Empty when no trackers are active.
struct TodayScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Tracker.sortOrder) private var trackers: [Tracker]

    @State private var drafts: [UUID: LogDraft] = [:]
    @State private var didSave = false
    @State private var loadedForDay: Date?

    private let today = DayMath.startOfDay(Date())

    private var activeTrackers: [Tracker] {
        trackers.filter(\.isActive).sorted { $0.sortOrder < $1.sortOrder }
    }

    private var setCount: Int {
        activeTrackers.filter { drafts[$0.id]?.isSet ?? false }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if activeTrackers.isEmpty {
                    EmptyStateView(symbol: "square.and.pencil",
                                   title: "Nothing to log yet",
                                   message: "Turn on a few trackers in the Trackers tab and they'll appear here for daily logging.")
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(today.mediumDayLabel)
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .onAppear(perform: loadDraftsIfNeeded)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 14) {
                progressHeader

                ForEach(activeTrackers) { tracker in
                    LogRowView(tracker: tracker,
                               scale10: settings.useScale10,
                               draft: bindingFor(tracker),
                               onChange: { didSave = false })
                }

                PrimaryButton(title: didSave ? "Saved" : "Save today",
                              systemImage: didSave ? "checkmark.circle.fill" : "tray.and.arrow.down",
                              enabled: setCount > 0 && !didSave) {
                    save()
                }
                .padding(.top, 4)

                if didSave {
                    Label("Logged \(setCount) for \(today.shortDayLabel). Your trends just got sharper.",
                          systemImage: "checkmark.seal.fill")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.good)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }
            }
            .padding(16)
        }
        .animation(.easeInOut(duration: 0.2), value: didSave)
        .scrollDismissesKeyboard(.interactively)
    }

    private var progressHeader: some View {
        CardView {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(Theme.hairline, lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progressFraction)
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(setCount)/\(activeTrackers.count)")
                        .font(Theme.rounded(13, .bold))
                        .foregroundStyle(Theme.ink)
                }
                .frame(width: 52, height: 52)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(setCount == activeTrackers.count ? "All caught up" : "Today's check-in")
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(setCount == 0
                         ? "Log what you can — even a couple helps."
                         : "\(setCount) of \(activeTrackers.count) logged.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(setCount) of \(activeTrackers.count) trackers logged today")
    }

    private var progressFraction: CGFloat {
        guard !activeTrackers.isEmpty else { return 0 }
        return CGFloat(setCount) / CGFloat(activeTrackers.count)
    }

    // MARK: Drafts

    private func bindingFor(_ tracker: Tracker) -> Binding<LogDraft> {
        Binding(
            get: { drafts[tracker.id] ?? LogDraft() },
            set: { drafts[tracker.id] = $0 }
        )
    }

    private func loadDraftsIfNeeded() {
        // Rebuild drafts from any entries already logged today (so re-entry pre-fills).
        if loadedForDay == today, !drafts.isEmpty { return }
        var newDrafts: [UUID: LogDraft] = [:]
        for tracker in activeTrackers {
            let existing = tracker.sortedEntries.first { DayMath.sameDay($0.date, today) }
            newDrafts[tracker.id] = LogDraft.from(value: existing?.value)
        }
        drafts = newDrafts
        loadedForDay = today
    }

    // MARK: Save (upsert)

    private func save() {
        var saved = 0
        for tracker in activeTrackers {
            guard let draft = drafts[tracker.id], draft.isSet else { continue }
            upsert(tracker: tracker, value: draft.value)
            saved += 1
        }
        guard saved > 0 else { return }
        try? context.save()
        didSave = true
        Haptics.success(settings.hapticsEnabled)
    }

    private func upsert(tracker: Tracker, value: Double) {
        if let existing = tracker.sortedEntries.first(where: { DayMath.sameDay($0.date, today) }) {
            existing.value = value
        } else {
            let entry = LogEntry(date: today, value: value, tracker: tracker)
            context.insert(entry)
        }
    }
}
