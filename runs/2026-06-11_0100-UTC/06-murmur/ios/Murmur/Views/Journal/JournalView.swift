import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VoiceEntry.date, order: .reverse) private var entries: [VoiceEntry]
    @State private var selectedEntry: VoiceEntry?
    @State private var filterMood: Mood?
    @State private var showFavoritesOnly = false

    private var filtered: [VoiceEntry] {
        entries.filter { entry in
            if showFavoritesOnly && !entry.isFavorite { return false }
            if let m = filterMood, entry.mood != m { return false }
            return true
        }
    }

    private var grouped: [(String, [VoiceEntry])] {
        let cal = Calendar.current
        var dict: [String: [VoiceEntry]] = [:]
        for entry in filtered {
            let key: String
            if cal.isDateInToday(entry.date) { key = "Today" }
            else if cal.isDateInYesterday(entry.date) { key = "Yesterday" }
            else {
                let f = DateFormatter()
                f.dateFormat = "MMMM yyyy"
                key = f.string(from: entry.date)
            }
            dict[key, default: []].append(entry)
        }
        let todayKey = "Today"
        let yesterdayKey = "Yesterday"
        let sortedKeys = dict.keys.sorted { a, b in
            if a == todayKey { return true }
            if b == todayKey { return false }
            if a == yesterdayKey { return true }
            if b == yesterdayKey { return false }
            let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
            return (f.date(from: a) ?? .distantPast) > (f.date(from: b) ?? .distantPast)
        }
        return sortedKeys.map { ($0, dict[$0]!) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    List {
                        filterBar
                            .listRowBackground(Color.clear)
                            .listRowInsets(.init())

                        ForEach(grouped, id: \.0) { section, sectionEntries in
                            Section(section) {
                                ForEach(sectionEntries) { entry in
                                    EntryRow(entry: entry)
                                        .onTapGesture { selectedEntry = entry }
                                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                                }
                                .onDelete { offsets in
                                    for i in offsets {
                                        let entry = sectionEntries[i]
                                        AudioStore.delete(entry.audioFilename)
                                        modelContext.delete(entry)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Journal")
            .sheet(item: $selectedEntry) { entry in
                EntryDetailView(entry: entry)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No entries yet")
                .font(.headline)
            Text("Tap Record to capture your first voice note.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", icon: nil, active: filterMood == nil && !showFavoritesOnly) {
                    filterMood = nil; showFavoritesOnly = false
                }
                filterChip(label: "Favorites", icon: "heart.fill", active: showFavoritesOnly) {
                    showFavoritesOnly.toggle(); filterMood = nil
                }
                ForEach(Mood.allCases, id: \.self) { mood in
                    filterChip(label: mood.emoji + " " + mood.label, icon: nil, active: filterMood == mood) {
                        filterMood = filterMood == mood ? nil : mood
                        showFavoritesOnly = false
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func filterChip(label: String, icon: String?, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.caption) }
                Text(label).font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(active ? MurmurTheme.accent : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(active ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

private struct EntryRow: View {
    let entry: VoiceEntry

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MurmurTheme.moodColor(entry.mood).opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(entry.mood.emoji)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(entry.displayTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    if entry.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                if !entry.transcript.isEmpty {
                    Text(entry.transcript)
                        .font(MurmurTheme.captionFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 6) {
                    Text(entry.formattedDuration)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    if !entry.tags.isEmpty {
                        Text(entry.tags.prefix(2).map { "#\($0)" }.joined(separator: " "))
                            .font(.caption2)
                            .foregroundStyle(MurmurTheme.accent.opacity(0.8))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
