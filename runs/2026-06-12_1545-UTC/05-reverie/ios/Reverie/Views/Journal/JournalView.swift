import SwiftUI
import SwiftData

struct DreamMonth: Identifiable {
    let month: Date
    let dreams: [Dream]
    var id: Date { month }
}

struct JournalView: View {
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    @State private var search = ""
    @State private var showAdd = false
    @State private var filterLucidOnly = false

    private var filtered: [Dream] {
        var list = dreams
        if filterLucidOnly { list = list.filter(\.isLucid) }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.title.lowercased().contains(q) ||
                $0.narrative.lowercased().contains(q) ||
                $0.signs.contains { $0.name.lowercased().contains(q) }
            }
        }
        return list
    }

    private var grouped: [DreamMonth] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filtered) { dream -> Date in
            let comps = cal.dateComponents([.year, .month], from: dream.date)
            return cal.date(from: comps) ?? dream.date
        }
        return groups.map { DreamMonth(month: $0.key, dreams: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if dreams.isEmpty {
                    EmptyStateView(symbol: "moon.stars",
                                   title: "No dreams yet",
                                   message: "Tap + the moment you wake to capture a dream before it slips away.",
                                   actionTitle: "Record a dream") { showAdd = true }
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            if filtered.isEmpty {
                                EmptyStateView(symbol: "magnifyingglass", title: "No matches",
                                               message: "No dreams match your search or filter.")
                                    .padding(.top, 30)
                            } else {
                                ForEach(grouped) { group in
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(Fmt.monthYear(group.month))
                                            .font(.headline).foregroundStyle(Theme.textPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        ForEach(group.dreams) { dream in
                                            NavigationLink(value: dream) { DreamRow(dream: dream) }
                                                .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Dream Journal")
            .searchable(text: $search, prompt: "Search dreams & signs")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { filterLucidOnly.toggle(); Haptics.tap() } label: {
                        Image(systemName: filterLucidOnly ? "sparkles" : "sparkles")
                            .symbolVariant(filterLucidOnly ? .fill : .none)
                            .foregroundStyle(filterLucidOnly ? Theme.lucid : Theme.accent)
                    }
                    .accessibilityLabel(filterLucidOnly ? "Showing lucid only" : "Show lucid only")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Record dream")
                }
            }
            .navigationDestination(for: Dream.self) { DreamDetailView(dream: $0) }
            .sheet(isPresented: $showAdd) { DreamEditView(dream: nil) }
        }
    }
}

struct DreamRow: View {
    let dream: Dream
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: dream.mood.symbol).font(.caption).foregroundStyle(dream.mood.color)
                Text(dream.displayTitle).font(.headline).foregroundStyle(Theme.textPrimary).lineLimit(1)
                Spacer()
                if dream.isLucid { Image(systemName: "sparkles").font(.caption).foregroundStyle(Theme.lucid) }
                if dream.isNightmare { Image(systemName: "exclamationmark.triangle.fill").font(.caption2).foregroundStyle(.red.opacity(0.7)) }
            }
            if !dream.narrative.isEmpty {
                Text(dream.narrative).font(.subheadline).foregroundStyle(Theme.textSecondary).lineLimit(2)
            }
            HStack(spacing: 10) {
                Text(Fmt.relativeDay(dream.date)).font(.caption2).foregroundStyle(Theme.textSecondary)
                VividnessDots(level: dream.vividness)
                if dream.isRecurring {
                    Label("Recurring", systemImage: "repeat").font(.caption2).foregroundStyle(Theme.accent)
                }
            }
        }
        .reverieCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dream.displayTitle), \(dream.lucidity.label), \(Fmt.relativeDay(dream.date))")
    }
}
