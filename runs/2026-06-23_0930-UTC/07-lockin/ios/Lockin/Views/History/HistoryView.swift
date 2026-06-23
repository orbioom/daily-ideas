import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]
    @Query(filter: #Predicate<Project> { !$0.isArchived }) private var projects: [Project]
    @Query private var settingsList: [AppSettings]

    @State private var filterProjectID: UUID?
    @State private var filterMode: SessionMode?
    @State private var editingSession: FocusSession?

    private var haptics: Bool { settingsList.first?.hapticsEnabled ?? true }

    private var filtered: [FocusSession] {
        sessions.filter { s in
            (filterProjectID == nil || s.project?.id == filterProjectID) &&
            (filterMode == nil || s.mode == filterMode)
        }
    }

    private var grouped: [(day: Date, items: [FocusSession])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.startedAt) }
        return dict.keys.sorted(by: >).map { ($0, dict[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Palette.appBackground.ignoresSafeArea()
                if sessions.isEmpty {
                    EmptyStateView(systemImage: "clock.arrow.circlepath",
                                   title: "No history yet",
                                   message: "Completed and ended sessions will appear here, grouped by day.")
                } else {
                    VStack(spacing: 0) {
                        filterBar
                        if filtered.isEmpty {
                            EmptyStateView(systemImage: "line.3.horizontal.decrease.circle",
                                           title: "No matches",
                                           message: "No sessions match the current filters.",
                                           actionTitle: "Clear filters") {
                                filterProjectID = nil; filterMode = nil
                            }
                        } else {
                            list
                        }
                    }
                }
            }
            .navigationTitle("History")
            .sheet(item: $editingSession) { session in
                SessionEditorView(session: session)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                FilterPill(title: "All projects", isOn: filterProjectID == nil) {
                    filterProjectID = nil
                }
                ForEach(projects) { p in
                    FilterPill(title: p.name, color: p.color, isOn: filterProjectID == p.id) {
                        filterProjectID = filterProjectID == p.id ? nil : p.id
                    }
                }
                Divider().frame(height: 24)
                ForEach(SessionMode.allCases) { mode in
                    FilterPill(title: mode.label, isOn: filterMode == mode) {
                        filterMode = filterMode == mode ? nil : mode
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    private var list: some View {
        List {
            ForEach(grouped, id: \.day) { group in
                Section {
                    ForEach(group.items) { session in
                        SessionRow(session: session)
                            .listRowBackground(Theme.Palette.surface)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Haptics.tap(haptics)
                                editingSession = session
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    delete(session)
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                    }
                } header: {
                    HStack {
                        Text(dayLabel(group.day))
                        Spacer()
                        Text(TimeFormat.duration(minutes: dayMinutes(group.items)))
                            .foregroundStyle(Theme.Palette.brand)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func dayMinutes(_ items: [FocusSession]) -> Int {
        items.filter { $0.wasCompleted }.reduce(0) { $0 + $1.focusedMinutes }
    }

    private func dayLabel(_ date: Date) -> String {
        if date.isSameDay(as: Date()) { return "Today" }
        if date.isSameDay(as: Date.daysAgo(1)) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    private func delete(_ session: FocusSession) {
        Haptics.warning(haptics)
        context.delete(session)
        try? context.save()
    }
}

struct FilterPill: View {
    let title: String
    var color: Color = Theme.Palette.brand
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 7)
                .background(isOn ? color.opacity(0.18) : Theme.Palette.surface)
                .foregroundStyle(isOn ? color : Theme.Palette.textSecondary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isOn ? color : Theme.Palette.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [Project.self, FocusSession.self, AppSettings.self], inMemory: true)
}
