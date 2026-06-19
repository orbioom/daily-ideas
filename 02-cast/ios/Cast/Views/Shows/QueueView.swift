import SwiftUI
import SwiftData

struct QueueView: View {
    @Query private var shows: [PodcastShow]

    private var queuedEpisodes: [PodcastEpisode] {
        shows.flatMap { $0.episodes }
            .filter { $0.isInQueue && !$0.isListened }
            .sorted { ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if queuedEpisodes.isEmpty {
                    ContentUnavailableView {
                        Label("Queue is Empty", systemImage: "list.bullet")
                    } description: {
                        Text("Add episodes to your queue from any show's episode list.")
                    }
                } else {
                    List(queuedEpisodes) { ep in
                        NavigationLink(destination: EpisodeDetailView(episode: ep)) {
                            HStack(spacing: 12) {
                                ShowArtwork(show: ep.show ?? PodcastShow(title: ""), size: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ep.title)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                    Text(ep.show?.title ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(ep.durationFormatted)
                                        .font(.caption2)
                                        .foregroundStyle(CastTheme.purple)
                                }
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                ep.isListened = true
                                ep.isInQueue = false
                                ep.listenedDate = Date()
                            } label: {
                                Label("Listened", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
