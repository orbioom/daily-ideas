import SwiftUI
import SwiftData

struct SongView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \Song.createdAt, order: .reverse) private var songs: [Song]

    @State private var toast: ToastMessage?
    @State private var newName = ""
    @State private var showNew = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if songs.isEmpty {
                    EmptyStateView(
                        symbol: "music.note.list",
                        title: "No songs yet",
                        message: "Chain your saved patterns into a full arrangement. Create a song to get started.",
                        actionTitle: "New Song"
                    ) { showNew = true }
                } else {
                    list
                }
            }
            .navigationTitle("Songs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel(Text("New song"))
                }
            }
            .toast($toast)
            .alert("New Song", isPresented: $showNew) {
                TextField("Song name", text: $newName)
                Button("Cancel", role: .cancel) { newName = "" }
                Button("Create") { createSong() }
            }
        }
    }

    private var list: some View {
        List {
            ForEach(songs) { song in
                NavigationLink {
                    SongDetailView(song: song)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                                .fill(Theme.heroGradient)
                                .frame(width: 44, height: 44)
                            Image(systemName: "music.note.list").foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.name)
                                .font(Theme.rounded(16, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("\(song.sections.count) sections · \(song.totalBars) bars")
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
                .listRowBackground(Theme.surface)
                .swipeActions {
                    Button(role: .destructive) { delete(song) } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func createSong() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        let name = trimmed.isEmpty ? "New Song" : trimmed
        let song = Song(name: name)
        context.insert(song)
        try? context.save()
        newName = ""
        Haptics.success(settings.hapticsEnabled)
        toast = ToastMessage(text: "Created “\(name)”", symbol: "checkmark.circle.fill")
    }

    private func delete(_ song: Song) {
        context.delete(song)
        try? context.save()
        Haptics.medium(settings.hapticsEnabled)
    }
}
