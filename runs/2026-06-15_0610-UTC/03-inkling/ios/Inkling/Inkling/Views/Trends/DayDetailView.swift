import SwiftUI
import SwiftData

/// Shows every value logged on one day across all trackers, with inline editing. Editing reuses the
/// same adaptive controls as the Today screen; saving upserts/clears entries for that day.
struct DayDetailView: View {
    let day: Date
    let trackers: [Tracker]

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var drafts: [UUID: LogDraft] = [:]
    @State private var loaded = false

    private var orderedTrackers: [Tracker] {
        trackers.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Trackers that had an entry on this day (shown first), then the rest as "add" rows.
    private var loggedTrackers: [Tracker] {
        orderedTrackers.filter { t in t.sortedEntries.contains { DayMath.sameDay($0.date, day) } }
    }

    private var otherActive: [Tracker] {
        orderedTrackers.filter { t in
            t.isActive && !t.sortedEntries.contains { DayMath.sameDay($0.date, day) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if loggedTrackers.isEmpty && otherActive.isEmpty {
                        EmptyStateView(symbol: "calendar.badge.exclamationmark",
                                       title: "Nothing here",
                                       message: "No active trackers to log for this day.")
                            .padding(.top, 40)
                    } else {
                        if !loggedTrackers.isEmpty {
                            sectionLabel("Logged")
                            ForEach(loggedTrackers) { row(for: $0) }
                        }
                        if !otherActive.isEmpty {
                            sectionLabel("Add for this day")
                            ForEach(otherActive) { row(for: $0) }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(day.mediumDayLabel)
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
        }
        .onAppear(perform: load)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(13, .semibold))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(for tracker: Tracker) -> some View {
        LogRowView(tracker: tracker,
                   scale10: settings.useScale10,
                   draft: bindingFor(tracker),
                   onChange: {})
    }

    private func bindingFor(_ tracker: Tracker) -> Binding<LogDraft> {
        Binding(
            get: { drafts[tracker.id] ?? LogDraft() },
            set: { drafts[tracker.id] = $0 }
        )
    }

    private func load() {
        guard !loaded else { return }
        var newDrafts: [UUID: LogDraft] = [:]
        for tracker in orderedTrackers {
            let existing = tracker.sortedEntries.first { DayMath.sameDay($0.date, day) }
            newDrafts[tracker.id] = LogDraft.from(value: existing?.value)
        }
        drafts = newDrafts
        loaded = true
    }

    private func save() {
        for tracker in orderedTrackers {
            let draft = drafts[tracker.id] ?? LogDraft()
            let existing = tracker.sortedEntries.first { DayMath.sameDay($0.date, day) }
            if draft.isSet {
                if let existing {
                    existing.value = draft.value
                } else {
                    context.insert(LogEntry(date: day, value: draft.value, tracker: tracker))
                }
            } else if let existing {
                // Cleared a previously-logged value → remove the entry.
                context.delete(existing)
            }
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
