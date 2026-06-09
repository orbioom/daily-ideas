import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Reading.date, order: .reverse) private var readings: [Reading]

    @State private var search = ""
    @State private var favoritesOnly = false

    private var filtered: [Reading] {
        var items = readings
        if favoritesOnly { items = items.filter { $0.isFavorite } }
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            items = items.filter {
                $0.spreadName.lowercased().contains(q)
                || $0.question.lowercased().contains(q)
                || $0.note.lowercased().contains(q)
            }
        }
        return items
    }

    var body: some View {
        Group {
            if readings.isEmpty {
                ScrollView {
                    EmptyStateView(icon: "book.closed",
                                   title: "No readings yet",
                                   message: "Draw a spread from the Draw tab and save it to start your journal.")
                        .padding(.top, 60)
                }
                .background(Brand.pageBackground)
            } else {
                List {
                    Section {
                        Toggle(isOn: $favoritesOnly) {
                            Label("Favorites only", systemImage: "star.fill")
                        }
                        .tint(Brand.magic)
                        .listRowBackground(Color.clear)
                    }

                    if filtered.isEmpty {
                        EmptyStateView(icon: "magnifyingglass",
                                       title: "Nothing matches",
                                       message: "Try a different search or turn off the favorites filter.")
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(filtered) { reading in
                            ZStack {
                                JournalRow(reading: reading)
                                NavigationLink {
                                    ReadingDetailView(reading: reading)
                                } label: { EmptyView() }
                                .opacity(0)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: delete)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Brand.pageBackground)
            }
        }
        .navigationTitle("Journal")
        .searchable(text: $search, prompt: "Search readings")
    }

    private func delete(at offsets: IndexSet) {
        Haptics.warning()
        for index in offsets where filtered.indices.contains(index) {
            context.delete(filtered[index])
        }
        try? context.save()
    }
}

private struct JournalRow: View {
    @Bindable var reading: Reading

    private var previewText: String {
        let q = reading.question.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty { return q }
        let n = reading.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !n.isEmpty { return n }
        return reading.orderedCards.compactMap { $0.card?.name }.prefix(3).joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: reading.spread?.symbol ?? "rectangle.portrait")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Brand.magic)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(reading.spreadName)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    Spacer()
                    Text(reading.date.formatted(date: .abbreviated, time: .omitted))
                        .font(Brand.mono(12))
                        .foregroundStyle(Brand.text3)
                }
                if !previewText.isEmpty {
                    Text(previewText)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .lineLimit(1)
                }
            }
            Button {
                Haptics.tap()
                reading.isFavorite.toggle()
            } label: {
                Image(systemName: reading.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(reading.isFavorite ? Brand.warn : Brand.text3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(reading.isFavorite ? "Favorited" : "Not favorited")
            .accessibilityHint("Toggles favorite")
        }
        .padding(14)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reading.spreadName), \(reading.date.formatted(date: .abbreviated, time: .omitted))")
    }
}
