import SwiftUI
import SwiftData

struct MediaDetailView: View {
    @Bindable var entry: MediaEntry
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal)
                    .padding(.top)

                Divider()
                    .padding(.vertical, 16)
                    .padding(.horizontal)

                details
                    .padding(.horizontal)

                if entry.mediaType == .show && !entry.seasons.isEmpty {
                    Divider()
                        .padding(.vertical, 16)
                        .padding(.horizontal)
                    seasonsSection
                }

                Divider()
                    .padding(.vertical, 16)
                    .padding(.horizontal)

                notesSection
                    .padding(.horizontal)
                    .padding(.bottom, 32)
            }
        }
        .background(Theme.bgPrimary)
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Divider()
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("More options")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditMediaView(entry: entry)
        }
        .confirmationDialog("Delete \"\(entry.title)\"?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                ctx.delete(entry)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.bgSecondary)
                    .frame(width: 90, height: 130)
                Text(entry.posterEmoji)
                    .font(.system(size: 48))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(entry.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 6) {
                    Text(String(entry.year))
                        .font(.subheadline)
                        .foregroundStyle(Theme.silver)
                    Text("·")
                        .foregroundStyle(Theme.silver)
                    Text(entry.genre.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(Theme.genreColor(entry.genre))
                    Text("·")
                        .foregroundStyle(Theme.silver)
                    Text(entry.mediaType.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(Theme.silver)
                }

                Label(entry.status.rawValue, systemImage: entry.status.icon)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.statusColor(entry.status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.statusColor(entry.status).opacity(0.15))
                    .clipShape(Capsule())

                if entry.rating > 0 {
                    RatingStarsView(rating: .constant(entry.rating), editable: false, starSize: 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var details: some View {
        VStack(spacing: 0) {
            DetailRow(label: "Status") {
                Picker("Status", selection: Binding(
                    get: { entry.statusRaw },
                    set: { entry.statusRaw = $0 }
                )) {
                    ForEach(WatchStatus.allCases, id: \.self) {
                        Text($0.rawValue).tag($0.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.statusColor(entry.status))
            }
            Divider()
            DetailRow(label: "Rating") {
                RatingStarsView(
                    rating: Binding(get: { entry.rating }, set: { entry.rating = $0 }),
                    starSize: 18
                )
            }
            if entry.mediaType == .movie {
                Divider()
                DetailRow(label: "Runtime") {
                    Text(entry.displayRuntime)
                        .foregroundStyle(Theme.silver)
                }
            }
            if entry.mediaType == .show {
                Divider()
                DetailRow(label: "Progress") {
                    Text("\(entry.watchedEpisodes) / \(entry.totalEpisodes) episodes")
                        .foregroundStyle(Theme.silver)
                }
            }
        }
        .background(Theme.bgSecondary, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var seasonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seasons")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(entry.seasons.sorted(by: { $0.seasonNumber < $1.seasonNumber })) { season in
                    NavigationLink(value: season) {
                        SeasonRowView(season: season)
                    }
                    .buttonStyle(.plain)
                    if season.seasonNumber != entry.seasons.map(\.seasonNumber).max() {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Theme.bgSecondary, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
        .navigationDestination(for: Season.self) { season in
            EpisodesView(season: season)
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            TextField("Add notes, thoughts, recommendations…", text: Binding(
                get: { entry.notes },
                set: { entry.notes = $0 }
            ), axis: .vertical)
            .lineLimit(3...8)
            .padding()
            .background(Theme.bgSecondary, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(Theme.textPrimary)
        }
    }
}

private struct DetailRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.silver)
            Spacer()
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
