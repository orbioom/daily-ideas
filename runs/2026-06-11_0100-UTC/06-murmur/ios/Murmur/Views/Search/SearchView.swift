import SwiftUI
import SwiftData

struct SearchView: View {
    @Query(sort: \VoiceEntry.date, order: .reverse) private var entries: [VoiceEntry]
    @Query(sort: \JournalTag.usageCount, order: .reverse) private var topTags: [JournalTag]
    @State private var query = ""
    @State private var selectedEntry: VoiceEntry?

    private var results: [VoiceEntry] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return entries.filter { entry in
            entry.transcript.lowercased().contains(q)
            || entry.title.lowercased().contains(q)
            || entry.tags.contains { $0.lowercased().contains(q) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if query.isEmpty {
                    suggestionsView
                } else if results.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search transcripts, tags…")
            .sheet(item: $selectedEntry) { EntryDetailView(entry: $0) }
        }
    }

    private var suggestionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statsRow
                if !topTags.isEmpty {
                    tagsSection
                }
                recentSection
            }
            .padding()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(value: "\(entries.count)", label: "Entries")
            statTile(value: totalMinutes, label: "Minutes")
            statTile(value: "\(totalWords)", label: "Words")
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(MurmurTheme.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var totalMinutes: String {
        let total = entries.reduce(0.0) { $0 + $1.durationSeconds }
        return String(format: "%.0f", total / 60)
    }

    private var totalWords: Int { entries.reduce(0) { $0 + $1.wordCount } }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Popular Tags")
                .font(.system(size: 15, weight: .bold, design: .rounded))
            FlowLayout(spacing: 8) {
                ForEach(topTags.prefix(15)) { tag in
                    Button { query = tag.name } label: {
                        Text("#\(tag.name)")
                            .font(MurmurTheme.captionFont)
                            .foregroundStyle(MurmurTheme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(MurmurTheme.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Entries")
                .font(.system(size: 15, weight: .bold, design: .rounded))
            ForEach(entries.prefix(5)) { entry in
                entryRow(entry)
            }
        }
    }

    private var resultsList: some View {
        List(results) { entry in
            entryRowListItem(entry)
                .onTapGesture { selectedEntry = entry }
                .listRowBackground(Color(.secondarySystemGroupedBackground))
        }
        .listStyle(.insetGrouped)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No results for "\(query)"")
                .font(.headline)
            Text("Try a different word or tag.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }

    private func entryRow(_ entry: VoiceEntry) -> some View {
        Button { selectedEntry = entry } label: {
            HStack(spacing: 10) {
                Text(entry.mood.emoji).font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.displayTitle).font(.subheadline.bold()).lineLimit(1)
                    Text(entry.formattedDuration).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func entryRowListItem(_ entry: VoiceEntry) -> some View {
        HStack(spacing: 10) {
            Text(entry.mood.emoji).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayTitle).font(.subheadline.bold()).lineLimit(1)
                if !entry.transcript.isEmpty {
                    Text(highlightedText(entry.transcript, query: query))
                        .font(MurmurTheme.captionFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private func highlightedText(_ text: String, query: String) -> AttributedString {
        var attr = AttributedString(text)
        let lower = text.lowercased()
        let q = query.lowercased()
        var searchStart = lower.startIndex
        while let range = lower.range(of: q, range: searchStart..<lower.endIndex) {
            let offset = lower.distance(from: lower.startIndex, to: range.lowerBound)
            let length = lower.distance(from: range.lowerBound, to: range.upperBound)
            let start = attr.index(attr.startIndex, offsetByCharacters: offset)
            let end   = attr.index(start, offsetByCharacters: length)
            attr[start..<end].foregroundColor = MurmurTheme.accent
            searchStart = range.upperBound
        }
        return attr
    }
}
