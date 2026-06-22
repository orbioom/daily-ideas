import SwiftUI
import SwiftData

struct JournalListView: View {
    @Query(sort: \MoonJournalEntry.date, order: .reverse) private var entries: [MoonJournalEntry]
    @Environment(\.modelContext) private var context
    @State private var showingEditor = false
    @State private var editingEntry: MoonJournalEntry?

    var body: some View {
        NavigationStack {
            ZStack {
                CrescentTheme.navy.ignoresSafeArea()
                Group {
                    if entries.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(entries) { entry in
                                JournalRowView(entry: entry)
                                    .listRowBackground(CrescentTheme.cardBg)
                                    .listRowSeparatorTint(CrescentTheme.silver.opacity(0.2))
                                    .onTapGesture {
                                        editingEntry = entry
                                        showingEditor = true
                                    }
                            }
                            .onDelete(perform: delete)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { editingEntry = nil; showingEditor = true }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(CrescentTheme.gold)
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                JournalEntryEditorView(existingEntry: editingEntry)
                    .onDisappear { editingEntry = nil }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("📓").font(.system(size: 60))
            Text("No Journal Entries Yet")
                .font(.headline)
                .foregroundColor(CrescentTheme.pearl)
            Text("Tap the pencil icon to write your first moon journal entry.")
                .font(.body)
                .foregroundColor(CrescentTheme.silver)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { context.delete(entries[i]) }
    }
}

struct JournalRowView: View {
    let entry: MoonJournalEntry
    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.moonPhase.symbol + " " + entry.moonPhase.rawValue)
                    .font(.caption)
                    .foregroundColor(CrescentTheme.gold)
                Spacer()
                Text(dateString)
                    .font(.caption2)
                    .foregroundColor(CrescentTheme.silver)
            }
            Text(entry.content)
                .font(.callout)
                .foregroundColor(CrescentTheme.pearl)
                .lineLimit(2)
            HStack(spacing: 4) {
                ForEach(0..<5) { i in
                    Text(i < entry.moodRating ? "★" : "☆")
                        .font(.caption2)
                        .foregroundColor(i < entry.moodRating ? CrescentTheme.gold : CrescentTheme.silver)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
