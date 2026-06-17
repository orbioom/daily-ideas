import SwiftUI
import SwiftData

struct JournalView: View {
    @Query(sort: \Reading.date, order: .reverse) private var readings: [Reading]
    @Query(sort: \DailyDraw.date, order: .reverse) private var dailies: [DailyDraw]
    @Environment(\.modelContext) private var context

    @State private var search = ""
    @State private var scope: Scope = .all

    private enum Scope: String, CaseIterable, Identifiable {
        case all = "All", spreads = "Spreads", daily = "Daily"
        var id: String { rawValue }
    }

    /// Unified, searchable, date-sorted feed of journal entries.
    private var entries: [JournalEntry] {
        var items: [JournalEntry] = []
        if scope != .daily {
            items += readings.map { .reading($0) }
        }
        if scope != .spreads {
            items += dailies.map { .daily($0) }
        }
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            items = items.filter { $0.matches(q) }
        }
        return items.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if readings.isEmpty && dailies.isEmpty {
                    EmptyStateView(icon: "book.closed",
                                   title: "Your journal is empty",
                                   message: "Reveal a daily card or save a spread reading and it will appear here for you to revisit.")
                } else if entries.isEmpty {
                    EmptyStateView(icon: "magnifyingglass",
                                   title: "No entries match",
                                   message: "Try a different search or scope.")
                } else {
                    List {
                        Section {
                            ForEach(entries) { entry in
                                NavigationLink {
                                    entry.destination
                                } label: {
                                    JournalRow(entry: entry)
                                }
                                .listRowBackground(Theme.surface)
                            }
                            .onDelete(perform: delete)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Journal")
            .searchable(text: $search, prompt: "Search readings & notes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Scope", selection: $scope) {
                        ForEach(Scope.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let toDelete = offsets.compactMap { entries[safe: $0] }
        for entry in toDelete {
            switch entry {
            case .reading(let r): context.delete(r)
            case .daily(let d): context.delete(d)
            }
        }
        try? context.save()
    }
}

/// A unified journal entry — either a saved spread reading or a daily draw.
enum JournalEntry: Identifiable {
    case reading(Reading)
    case daily(DailyDraw)

    var id: String {
        switch self {
        case .reading(let r): return "r-\(r.id.uuidString)"
        case .daily(let d): return "d-\(d.dayKey)"
        }
    }

    var date: Date {
        switch self {
        case .reading(let r): return r.date
        case .daily(let d): return d.date
        }
    }

    func matches(_ q: String) -> Bool {
        switch self {
        case .reading(let r):
            if r.spreadType.rawValue.lowercased().contains(q) { return true }
            if (r.question ?? "").lowercased().contains(q) { return true }
            if r.reflection.lowercased().contains(q) { return true }
            return r.cards.contains { Deck.card(id: $0.cardId)?.name.lowercased().contains(q) ?? false }
        case .daily(let d):
            if d.reflection.lowercased().contains(q) { return true }
            return Deck.card(id: d.cardId)?.name.lowercased().contains(q) ?? false
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .reading(let r): ReadingDetailView(reading: r)
        case .daily(let d): DailyDrawDetailView(draw: d)
        }
    }
}

private struct JournalRow: View {
    let entry: JournalEntry

    var body: some View {
        switch entry {
        case .reading(let r):
            row(icon: r.spreadType.icon,
                title: r.spreadType.rawValue,
                subtitle: r.question ?? "\(r.cards.count) cards",
                date: r.date,
                accessory: r.mood)
        case .daily(let d):
            row(icon: "sun.max",
                title: "Daily — \(d.card?.name ?? "Card")",
                subtitle: d.reflection.isEmpty ? (d.reversed ? "Reversed" : "Upright") : d.reflection,
                date: d.date,
                accessory: nil)
        }
    }

    private func row(icon: String, title: String, subtitle: String, date: Date, accessory: Int?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.accentDeep)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(Theme.ink).lineLimit(1)
                Text(subtitle).font(.subheadline).foregroundStyle(Theme.inkSoft).lineLimit(1)
                Text(date, format: .dateTime.month().day().year().hour().minute())
                    .font(.caption).foregroundStyle(Theme.inkFaint)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(date.formatted(.dateTime.month().day().year()))")
    }
}
