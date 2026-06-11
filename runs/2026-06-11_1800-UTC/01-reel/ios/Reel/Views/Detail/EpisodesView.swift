import SwiftUI
import SwiftData

struct EpisodesView: View {
    @Bindable var season: Season
    @Environment(\.modelContext) private var ctx

    private var sortedEpisodes: [Episode] {
        season.episodes.sorted { $0.episodeNumber < $1.episodeNumber }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("\(season.watchedEpisodes) / \(season.totalEpisodes) watched")
                        .font(.subheadline)
                        .foregroundStyle(Theme.silver)
                    Spacer()
                    Button(season.isFullyWatched ? "Mark All Unwatched" : "Mark All Watched") {
                        let newState = !season.isFullyWatched
                        for ep in season.episodes {
                            ep.watched = newState
                            ep.watchedDate = newState ? Date() : nil
                        }
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.gold)
                }
                .accessibilityElement(children: .combine)

                ProgressView(value: season.totalEpisodes > 0 ? Double(season.watchedEpisodes) / Double(season.totalEpisodes) : 0)
                    .tint(Theme.gold)
                    .accessibilityLabel("Progress: \(season.watchedEpisodes) of \(season.totalEpisodes) episodes watched")
            }

            Section("Episodes") {
                ForEach(sortedEpisodes) { ep in
                    EpisodeRow(episode: ep)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bgPrimary)
        .navigationTitle("Season \(season.seasonNumber)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EpisodeRow: View {
    @Bindable var episode: Episode

    var body: some View {
        Button {
            episode.watched.toggle()
            episode.watchedDate = episode.watched ? Date() : nil
        } label: {
            HStack(spacing: 12) {
                Image(systemName: episode.watched ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(episode.watched ? Theme.gold : Theme.silver.opacity(0.4))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(episode.title)
                        .font(.body)
                        .foregroundStyle(Theme.textPrimary)
                    if let date = episode.watchedDate {
                        Text("Watched \(date.formatted(.dateTime.month(.abbreviated).day().year()))")
                            .font(.caption)
                            .foregroundStyle(Theme.silver)
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(episode.title), \(episode.watched ? "watched" : "not watched")")
        .accessibilityHint("Double-tap to toggle watched status")
    }
}

struct SeasonRowView: View {
    let season: Season

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Season \(season.seasonNumber)")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(season.watchedEpisodes) / \(season.totalEpisodes) episodes")
                    .font(.caption)
                    .foregroundStyle(Theme.silver)
            }
            Spacer()
            if season.isFullyWatched {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.gold)
                    .accessibilityLabel("Fully watched")
            } else if season.watchedEpisodes > 0 {
                ProgressView(value: Double(season.watchedEpisodes) / Double(max(1, season.totalEpisodes)))
                    .tint(Theme.gold)
                    .frame(width: 50)
                    .accessibilityLabel("\(season.watchedEpisodes) of \(season.totalEpisodes) watched")
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.silver.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Season \(season.seasonNumber), \(season.watchedEpisodes) of \(season.totalEpisodes) episodes watched")
    }
}
