import SwiftUI
import SwiftData

struct EntriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TimeEntry.start, order: .reverse) private var entries: [TimeEntry]
    @AppStorage("defaultCurrency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var editing: TimeEntry?

    private let engine = TimeEngine()

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if entries.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No entries yet",
                        message: "Track time on the Timer tab, or tap + to add a past block of work manually."
                    )
                } else {
                    List {
                        Section {
                            HStack {
                                Text("This week").font(.subheadline).foregroundStyle(Brand.text2)
                                Spacer()
                                Text(DurationFormat.compact(weekSeconds))
                                    .font(Brand.mono(14, weight: .semibold)).foregroundStyle(Color.accentColor)
                            }
                            .listRowBackground(Color.clear)
                        }
                        ForEach(engine.groupedByDay(entries), id: \.day) { group in
                            Section(header: dayHeader(group.day, group.items)) {
                                ForEach(group.items) { e in
                                    Button { editing = e } label: { EntryRow(entry: e, currency: currency) }
                                        .buttonStyle(.plain)
                                        .swipeActions {
                                            Button(role: .destructive) {
                                                context.delete(e); Haptics.warning()
                                            } label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Entries")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        let now = Date()
                        let entry = TimeEntry(detail: "", start: now.addingTimeInterval(-3600), end: now)
                        context.insert(entry)
                        editing = entry
                    } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add entry")
                }
            }
            .sheet(item: $editing) { EntryEditorView(entry: $0) }
        }
    }

    private var weekSeconds: TimeInterval {
        let interval = engine.weekInterval(containing: .now)
        return engine.totalSeconds(engine.entries(entries, in: interval))
    }

    private func dayHeader(_ day: Date, _ items: [TimeEntry]) -> some View {
        HStack {
            Text(Format.relativeDay(day, relativeTo: .now, calendar: .current))
            Spacer()
            Text(DurationFormat.compact(engine.totalSeconds(items)))
                .font(Brand.mono(11, weight: .medium))
        }
    }
}
