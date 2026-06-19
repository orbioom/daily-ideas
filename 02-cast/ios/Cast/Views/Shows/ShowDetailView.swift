import SwiftUI
import SwiftData

struct ShowDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var show: PodcastShow
    @State private var showAddEp = false
    @State private var showEdit = false
    @State private var filterListened: Bool? = nil

    private var filteredEpisodes: [PodcastEpisode] {
        let sorted = show.episodes.sorted { ep1, ep2 in
            (ep1.publishedDate ?? .distantPast) > (ep2.publishedDate ?? .distantPast)
        }
        guard let f = filterListened else { return sorted }
        return sorted.filter { $0.isListened == f }
    }

    var body: some View {
        List {
            Section {
                showHeader
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)

            Section {
                HStack(spacing: 0) {
                    filterButton("All", tag: nil)
                    filterButton("Listened", tag: true)
                    filterButton("Queued", tag: false)
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            } header: {
                HStack {
                    Text("Episodes")
                    Spacer()
                    Button { showAddEp = true } label: {
                        Text("Add Episode").font(.caption.weight(.semibold))
                            .foregroundStyle(CastTheme.purple)
                    }
                }
            }
            .listRowBackground(Color.clear)

            if filteredEpisodes.isEmpty {
                ContentUnavailableView {
                    Label("No Episodes", systemImage: "headphones")
                } description: {
                    Text("Add episodes to start tracking your listening.")
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredEpisodes) { ep in
                    NavigationLink(destination: EpisodeDetailView(episode: ep)) {
                        EpisodeRow(episode: ep)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            ep.isListened.toggle()
                            if ep.isListened { ep.listenedDate = Date() }
                            else { ep.listenedDate = nil }
                        } label: {
                            Label(ep.isListened ? "Mark Unlistened" : "Mark Listened",
                                  systemImage: ep.isListened ? "headphones.slash" : "headphones")
                        }
                        .tint(ep.isListened ? .gray : .green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { context.delete(ep) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle(show.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showEdit = true } label: {
                    Image(systemName: "pencil").accessibilityLabel("Edit show")
                }
            }
        }
        .sheet(isPresented: $showAddEp) { AddEpisodeView(show: show) }
        .sheet(isPresented: $showEdit) { AddShowView(showToEdit: show) }
    }

    private func filterButton(_ label: String, tag: Bool?) -> some View {
        Button {
            filterListened = tag
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(filterListened == tag ? CastTheme.purple : Color.clear,
                            in: RoundedRectangle(cornerRadius: 7))
                .foregroundStyle(filterListened == tag ? .white : .secondary)
        }
        .accessibilityAddTraits(filterListened == tag ? .isSelected : [])
    }

    private var showHeader: some View {
        HStack(spacing: 16) {
            ShowArtwork(show: show, size: 88)

            VStack(alignment: .leading, spacing: 6) {
                if !show.host.isEmpty {
                    Text(show.host).font(.subheadline).foregroundStyle(.secondary)
                }
                Text(show.genre.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(CastTheme.genreColor(show.genre).opacity(0.15), in: Capsule())
                    .foregroundStyle(CastTheme.genreColor(show.genre))
                HStack(spacing: 16) {
                    Label("\(show.listenedCount)/\(show.totalEpisodes)", systemImage: "headphones")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if show.rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= show.rating ? "star.fill" : "star")
                                    .font(.system(size: 9))
                                    .foregroundStyle(i <= show.rating ? .yellow : .tertiary)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
    }
}

struct EpisodeRow: View {
    @Bindable var episode: PodcastEpisode

    var body: some View {
        HStack(spacing: 12) {
            Button {
                episode.isListened.toggle()
                if episode.isListened { episode.listenedDate = Date() }
                else { episode.listenedDate = nil }
            } label: {
                Image(systemName: episode.isListened ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(episode.isListened ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(episode.isListened ? "Mark as unlistened" : "Mark as listened")

            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title)
                    .font(.subheadline)
                    .foregroundStyle(episode.isListened ? .secondary : .primary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if !episode.episodeLabel.isEmpty {
                        Text(episode.episodeLabel)
                            .font(.caption2)
                            .foregroundStyle(CastTheme.purple)
                    }
                    Text(episode.durationFormatted)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if episode.isInQueue && !episode.isListened {
                        Image(systemName: "clock.badge")
                            .font(.caption2)
                            .foregroundStyle(CastTheme.amber)
                            .accessibilityLabel("In queue")
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(episode.title)\(episode.episodeLabel.isEmpty ? "" : ", \(episode.episodeLabel)"), \(episode.durationFormatted), \(episode.isListened ? "listened" : "not listened")"
        )
    }
}
