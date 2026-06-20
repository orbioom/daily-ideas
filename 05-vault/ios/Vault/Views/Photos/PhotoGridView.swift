import SwiftUI
import SwiftData
import PhotosUI

struct PhotoGridView: View {
    @Environment(\.modelContext) private var context
    @Bindable var album: VaultAlbum
    @Query private var settingsQ: [VaultSettings]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isImporting = false
    @State private var showPhoto: VaultPhoto?

    private var columns: Int { settingsQ.first?.gridColumns ?? 3 }
    private var gridItems: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 2), count: columns) }
    private var sorted: [VaultPhoto] { album.photos.sorted { $0.addedAt > $1.addedAt } }

    var body: some View {
        Group {
            if album.photos.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: gridItems, spacing: 2) {
                        ForEach(sorted) { photo in
                            PhotoThumbnailView(photo: photo)
                                .onTapGesture { showPhoto = photo }
                        }
                    }
                }
            }
        }
        .navigationTitle(album.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 20,
                    matching: .images
                ) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Import photos")
            }
        }
        .onChange(of: selectedItems) { _, items in
            guard !items.isEmpty else { return }
            isImporting = true
            importPhotos(items)
        }
        .overlay {
            if isImporting {
                ProgressView("Importing...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(VaultTheme.secondary))
            }
        }
        .sheet(item: $showPhoto) { photo in
            PhotoViewerView(photo: photo, photos: sorted, onDelete: { deletePhoto($0) })
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 56))
                .foregroundColor(VaultTheme.secondaryLabel)
                .accessibilityHidden(true)
            Text("No Photos Yet")
                .font(.title3.bold())
                .foregroundColor(VaultTheme.label)
            Text("Tap + to import photos from your library.")
                .foregroundColor(VaultTheme.secondaryLabel)
                .multilineTextAlignment(.center)
            PhotosPicker(selection: $selectedItems, maxSelectionCount: 20, matching: .images) {
                Label("Import Photos", systemImage: "photo.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Import photos from library")
        }
        .padding()
    }

    private func importPhotos(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let fileID = VaultPhotoStore.shared.save(image) {
                    let photo = VaultPhoto(fileID: fileID, album: album)
                    photo.width = Int(image.size.width)
                    photo.height = Int(image.size.height)
                    await MainActor.run { context.insert(photo) }
                }
            }
            await MainActor.run {
                try? context.save()
                selectedItems = []
                isImporting = false
            }
        }
    }

    private func deletePhoto(_ photo: VaultPhoto) {
        VaultPhotoStore.shared.delete(photo.fileID)
        context.delete(photo)
        try? context.save()
    }
}

struct PhotoThumbnailView: View {
    let photo: VaultPhoto
    @State private var thumb: UIImage?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(VaultTheme.secondary)
                .aspectRatio(1, contentMode: .fit)
            if let img = thumb {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                ProgressView()
            }
            if photo.isFavorite {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                            .padding(4)
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            thumb = VaultPhotoStore.shared.thumbnail(photo.fileID)
        }
        .accessibilityLabel("Photo" + (photo.isFavorite ? ", favorite" : "") + (photo.caption.isEmpty ? "" : ", \(photo.caption)"))
    }
}
