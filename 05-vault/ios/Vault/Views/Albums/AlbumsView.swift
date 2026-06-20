import SwiftUI
import SwiftData

struct AlbumsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \VaultAlbum.sortOrder) private var albums: [VaultAlbum]
    @State private var showAddAlbum = false
    @State private var editingAlbum: VaultAlbum?

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            Group {
                if albums.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(albums) { album in
                                NavigationLink(value: album) {
                                    AlbumCardView(album: album)
                                }
                                .contextMenu {
                                    Button(action: { editingAlbum = album }) {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    Button(role: .destructive, action: { deleteAlbum(album) }) {
                                        Label("Delete Album", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Vault")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: VaultAlbum.self) { PhotoGridView(album: $0) }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddAlbum = true }) {
                        Image(systemName: "folder.badge.plus")
                    }
                    .accessibilityLabel("Add album")
                }
            }
            .sheet(isPresented: $showAddAlbum) { AddAlbumView() }
            .sheet(item: $editingAlbum) { album in
                RenameAlbumView(album: album)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(VaultTheme.gold)
                .accessibilityHidden(true)
            Text("No Albums Yet").font(.title2.bold())
            Text("Create an album to start adding private photos.").foregroundColor(VaultTheme.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: { showAddAlbum = true }) {
                Label("Create Album", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Create first album")
        }
        .padding()
    }

    private func deleteAlbum(_ album: VaultAlbum) {
        for photo in album.photos { VaultPhotoStore.shared.delete(photo.fileID) }
        context.delete(album)
        try? context.save()
    }
}

struct AlbumCardView: View {
    let album: VaultAlbum
    @State private var cover: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(VaultTheme.secondary)
                    .aspectRatio(1, contentMode: .fit)
                if let img = cover {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text(album.emoji)
                        .font(.system(size: 48))
                        .accessibilityHidden(true)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(VaultTheme.label)
                    .lineLimit(1)
                Text("\(album.photoCount) photo\(album.photoCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(VaultTheme.secondaryLabel)
            }
        }
        .onAppear {
            if let id = album.coverPhotoID {
                cover = VaultPhotoStore.shared.thumbnail(id)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(album.name), \(album.photoCount) photos")
    }
}

struct AddAlbumView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = "📁"

    let emojiOptions = ["📁","📷","🌅","🎉","🏖️","🏔️","🎂","❤️","🌸","🌙","🏠","✈️","🎨","💼","👨‍👩‍👧‍👦"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Album Name") {
                    TextField("Name", text: $name)
                        .accessibilityLabel("Album name")
                }
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { e in
                                Button(action: { emoji = e }) {
                                    Text(e)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(Circle().fill(emoji == e ? VaultTheme.accent.opacity(0.2) : VaultTheme.secondary))
                                        .overlay(Circle().stroke(emoji == e ? VaultTheme.accent : Color.clear, lineWidth: 2))
                                }
                                .accessibilityLabel(e + (emoji == e ? ", selected" : ""))
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }
            }
            .navigationTitle("New Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let album = VaultAlbum(name: name.trimmingCharacters(in: .whitespaces), emoji: emoji)
        context.insert(album)
        try? context.save()
        dismiss()
    }
}

struct RenameAlbumView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var album: VaultAlbum
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Album Name", text: $name)
                    .accessibilityLabel("Album name")
            }
            .navigationTitle("Rename Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        album.name = name.trimmingCharacters(in: .whitespaces)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { name = album.name }
        }
    }
}
