import SwiftUI
import SwiftData

/// History of logged hard moments, grouped by month, with a gentle "log a moment"
/// flow. Editing and deleting work; the empty state is warm.
struct LogView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context

    @Query(sort: [SortDescriptor(\PanicEpisode.startedAt, order: .reverse)])
    private var episodes: [PanicEpisode]

    @State private var showLogMoment = false
    @State private var editing: PanicEpisode?

    private var grouped: [(key: String, value: [PanicEpisode])] {
        let groups = Dictionary(grouping: episodes) { ep -> String in
            let f = DateFormatter()
            f.dateFormat = "MMMM yyyy"
            return f.string(from: ep.startedAt)
        }
        // Sort sections by the newest episode within them.
        return groups
            .sorted { lhs, rhs in
                let l = lhs.value.map(\.startedAt).max() ?? .distantPast
                let r = rhs.value.map(\.startedAt).max() ?? .distantPast
                return l > r
            }
            .map { ($0.key, $0.value.sorted { $0.startedAt > $1.startedAt }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HavenBackground()
                if episodes.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Your log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showLogMoment = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Log a moment")
                }
            }
            .sheet(isPresented: $showLogMoment) { LogMomentView(episode: nil) }
            .sheet(item: $editing) { ep in LogMomentView(episode: ep) }
        }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 20) {
                EmptyStateView(
                    icon: "book.closed",
                    title: "Nothing logged yet",
                    message: "When you're ready, you can quietly note a hard moment. Over time this becomes a record of how much you've gotten through."
                )
                Button {
                    showLogMoment = true
                } label: { Text("Log a moment") }
                .havenPillButton()
                .padding(.horizontal, 40)
            }
            .padding(.top, 60)
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22, pinnedViews: [.sectionHeaders]) {
                ForEach(grouped, id: \.key) { section in
                    Section {
                        ForEach(section.value) { ep in
                            Button {
                                editing = ep
                            } label: {
                                EpisodeRow(episode: ep)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) { delete(ep) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text(section.key)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HavenTheme.secondaryText(scheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .background(HavenTheme.background(scheme).opacity(0.95))
                            .accessibilityAddTraits(.isHeader)
                    }
                }
            }
            .padding(20)
        }
    }

    private func delete(_ ep: PanicEpisode) {
        context.delete(ep)
        try? context.save()
    }
}

// MARK: - Episode row

struct EpisodeRow: View {
    @Environment(\.colorScheme) private var scheme
    let episode: PanicEpisode

    private var ctx: EpisodeContext { EpisodeContext.from(episode.context) }

    var body: some View {
        HavenCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: ctx.systemImage)
                        .foregroundStyle(HavenTheme.accentDeep)
                        .accessibilityHidden(true)
                    Text(dateText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HavenTheme.primaryText(scheme))
                    Spacer()
                    intensityBadge
                }
                if !episode.triggers.isEmpty {
                    Text(episode.triggers.map(\.name).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(HavenTheme.secondaryText(scheme))
                }
                if !episode.note.isEmpty {
                    Text(episode.note)
                        .font(.caption)
                        .foregroundStyle(HavenTheme.secondaryText(scheme))
                        .lineLimit(2)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens this entry to edit")
    }

    private var dateText: String {
        let f = DateFormatter()
        f.dateFormat = "EEE d · h:mm a"
        return f.string(from: episode.startedAt)
    }

    private var intensityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(IntensityStyle.color(for: episode.intensityBefore))
                .frame(width: 8, height: 8)
            if let after = episode.intensityAfter {
                Text("\(episode.intensityBefore) → \(after)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
            } else {
                Text("\(episode.intensityBefore)/10")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
            }
        }
    }

    private var accessibilitySummary: String {
        var parts = [dateText, ctx.label, "intensity \(episode.intensityBefore) out of 10"]
        if let after = episode.intensityAfter { parts.append("eased to \(after)") }
        if !episode.triggers.isEmpty { parts.append("triggers: " + episode.triggers.map(\.name).joined(separator: ", ")) }
        return parts.joined(separator: ", ")
    }
}
