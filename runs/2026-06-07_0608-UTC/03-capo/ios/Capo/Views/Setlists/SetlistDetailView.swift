import SwiftUI
import SwiftData

struct SetlistDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var setlist: Setlist
    @State private var showingPicker = false
    @State private var showingEdit = false

    private var items: [SetlistItem] { setlist.orderedItems }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if items.isEmpty {
                    EmptyStateView(icon: "music.note", title: "No songs",
                                   message: "Add songs to build your set.").glassCard()
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                            SetlistItemRow(item: item, index: idx + 1,
                                           canUp: idx > 0, canDown: idx < items.count - 1,
                                           onUp: { move(item, by: -1) },
                                           onDown: { move(item, by: 1) },
                                           onRemove: { remove(item) })
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(setlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingPicker = true } label: { Label("Add songs", systemImage: "plus") }
                    Button { showingEdit = true } label: { Label("Edit details", systemImage: "pencil") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !items.isEmpty {
                NavigationLink { PerformanceView(setlist: setlist) } label: {
                    Label("Start performance", systemImage: "play.fill")
                }
                .buttonStyle(InkButtonStyle())
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $showingPicker) { SongPickerSheet(setlist: setlist) }
        .sheet(isPresented: $showingEdit) { SetlistEditView(existing: setlist) }
    }

    private var headerCard: some View {
        VStack(spacing: 4) {
            Text(setlist.venue.isEmpty ? "Set" : setlist.venue)
                .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
            Text(setlist.date, format: .dateTime.weekday(.wide).month().day().year())
                .font(.caption).foregroundStyle(Brand.text3)
            HStack(spacing: 16) {
                Text("\(setlist.items.count) songs").font(.caption).foregroundStyle(Brand.text2)
                if setlist.estimatedSeconds > 0 {
                    Text("≈ \(formatDuration(setlist.estimatedSeconds))").font(.caption).foregroundStyle(Brand.text2)
                }
            }.padding(.top, 4)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16).glassCard()
    }

    private func move(_ item: SetlistItem, by delta: Int) {
        var arr = items
        guard let i = arr.firstIndex(where: { $0.id == item.id }) else { return }
        let j = i + delta
        guard j >= 0, j < arr.count else { return }
        arr.swapAt(i, j)
        for (k, it) in arr.enumerated() { it.order = k }
        try? context.save(); Haptics.selection()
    }

    private func remove(_ item: SetlistItem) {
        context.delete(item)
        for (k, it) in setlist.orderedItems.enumerated() { it.order = k }
        try? context.save(); Haptics.warning()
    }
}

struct SetlistItemRow: View {
    @Bindable var item: SetlistItem
    let index: Int
    let canUp: Bool, canDown: Bool
    var onUp: () -> Void, onDown: () -> Void, onRemove: () -> Void
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(index)").font(Brand.mono(15, weight: .bold)).foregroundStyle(Brand.text3).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.song?.title ?? "Removed song").font(.body.weight(.medium)).foregroundStyle(Brand.text)
                    HStack(spacing: 6) {
                        Text("Key \(item.performKey)").font(Brand.mono(11)).foregroundStyle(Brand.live)
                        if item.capo > 0 { Badge(text: "Capo \(item.capo)") }
                        if !item.note.isEmpty { Text(item.note).font(.caption).foregroundStyle(Brand.text3).lineLimit(1) }
                    }
                }
                Spacer()
                Button { withAnimation(Brand.ease(0.25)) { expanded.toggle() } } label: {
                    Image(systemName: expanded ? "chevron.up" : "slider.horizontal.3")
                        .foregroundStyle(Brand.text2)
                }.accessibilityLabel("Adjust \(item.song?.title ?? "song")")
            }
            if expanded {
                VStack(spacing: 10) {
                    HStack {
                        Text("Transpose").font(.caption).foregroundStyle(Brand.text2)
                        Spacer()
                        Stepper(item.transpose == 0 ? "0" : (item.transpose > 0 ? "+\(item.transpose)" : "\(item.transpose)"),
                                value: $item.transpose, in: -11...11).fixedSize()
                    }
                    HStack {
                        Text("Capo").font(.caption).foregroundStyle(Brand.text2)
                        Spacer()
                        Stepper("\(item.capo)", value: $item.capo, in: 0...11).fixedSize()
                    }
                    TextField("Slot note", text: $item.note).font(.caption).foregroundStyle(Brand.text)
                    HStack {
                        Button { onUp() } label: { Image(systemName: "arrow.up") }.disabled(!canUp)
                        Button { onDown() } label: { Image(systemName: "arrow.down") }.disabled(!canDown)
                        Spacer()
                        Button(role: .destructive) { onRemove() } label: { Label("Remove", systemImage: "trash") }
                            .font(.caption)
                    }
                }
                .padding(.top, 4)
            }
        }
        .glassCard(padding: 14)
    }
}

/// A sheet to add songs not already in the setlist.
struct SongPickerSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Song.title) private var songs: [Song]
    @Bindable var setlist: Setlist
    @State private var search = ""

    private var existingIDs: Set<UUID> { Set(setlist.items.compactMap { $0.song?.id }) }
    private var available: [Song] {
        let base = songs.filter { !existingIDs.contains($0.id) }
        guard !search.isEmpty else { return base }
        let q = search.lowercased()
        return base.filter { $0.title.lowercased().contains(q) || $0.artist.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            List {
                if available.isEmpty {
                    Text("Every song is already in this set.").foregroundStyle(Brand.text3)
                        .listRowBackground(Color.clear)
                }
                ForEach(available) { song in
                    Button { add(song) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(song.title).foregroundStyle(Brand.text)
                                Text(song.artist).font(.caption).foregroundStyle(Brand.text3)
                            }
                            Spacer()
                            Text(song.key).font(Brand.mono(14)).foregroundStyle(Brand.text2)
                            Image(systemName: "plus.circle").foregroundStyle(Brand.live)
                        }
                    }.listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .searchable(text: $search, prompt: "Search songs")
            .navigationTitle("Add Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func add(_ song: Song) {
        let order = (setlist.items.map { $0.order }.max() ?? -1) + 1
        let item = SetlistItem(order: order, song: song, capo: song.capo)
        item.setlist = setlist
        context.insert(item)
        try? context.save(); Haptics.success()
    }
}
