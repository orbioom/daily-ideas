import SwiftUI
import SwiftData

struct SongsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Song.title) private var songs: [Song]
    @AppStorage("capo.confirmDeletes") private var confirmDeletes = true
    @State private var search = ""
    @State private var showingEditor = false
    @State private var pendingDelete: Song?

    private var filtered: [Song] {
        guard !search.isEmpty else { return songs }
        let q = search.lowercased()
        return songs.filter { $0.title.lowercased().contains(q) || $0.artist.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if songs.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "music.note.list", title: "No songs yet",
                                       message: "Tap + to add your first chord chart.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filtered) { song in
                                NavigationLink { SongDetailView(song: song) } label: { SongRow(song: song) }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = song } else { delete(song) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                            if filtered.isEmpty {
                                Text("No matches").foregroundStyle(Brand.text3).padding()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Songs")
            .searchable(text: $search, prompt: "Search songs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add song")
                }
            }
            .background(Brand.pageBackground)
            .sheet(isPresented: $showingEditor) { SongEditView(existing: nil) }
            .confirmationDialog("Delete this song?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let s = pendingDelete { delete(s) }; pendingDelete = nil }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func delete(_ s: Song) { context.delete(s); try? context.save(); Haptics.warning() }
}

private struct SongRow: View {
    let song: Song
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title).font(.headline).foregroundStyle(Brand.text)
                if !song.artist.isEmpty {
                    Text(song.artist).font(.caption).foregroundStyle(Brand.text3)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(song.key).font(Brand.mono(16, weight: .bold)).foregroundStyle(Brand.text)
                HStack(spacing: 4) {
                    if song.capo > 0 { Badge(text: "Capo \(song.capo)") }
                    if song.bpm > 0 { Badge(text: "\(song.bpm)bpm") }
                }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(song.title) by \(song.artist), key \(song.key)")
    }
}
