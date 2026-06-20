import SwiftUI
import SwiftData

struct PhotoViewerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var photo: VaultPhoto
    let photos: [VaultPhoto]
    let onDelete: (VaultPhoto) -> Void

    @State private var currentIndex: Int = 0
    @State private var showCaption = false
    @State private var showDeleteAlert = false
    @State private var scale: CGFloat = 1.0
    @State private var fullImage: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                toolbar
                Spacer()
                photoContent
                Spacer()
                if showCaption { captionBar }
                bottomBar
            }
        }
        .onAppear {
            currentIndex = photos.firstIndex(where: { $0.id == photo.id }) ?? 0
            loadImage()
        }
        .alert("Delete Photo?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete(photos[currentIndex])
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this photo from Vault.")
        }
    }

    private var toolbar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.title3)
            }
            .accessibilityLabel("Close")
            Spacer()
            Text("\(currentIndex + 1) / \(photos.count)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Button(action: {
                photos[currentIndex].isFavorite.toggle()
                try? context.save()
            }) {
                Image(systemName: photos[currentIndex].isFavorite ? "star.fill" : "star")
                    .foregroundColor(photos[currentIndex].isFavorite ? .yellow : .white)
                    .font(.title3)
            }
            .accessibilityLabel(photos[currentIndex].isFavorite ? "Remove from favorites" : "Add to favorites")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var photoContent: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(photos.enumerated()), id: \.offset) { idx, p in
                PhotoPageView(photo: p)
                    .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: currentIndex) { _, _ in loadImage() }
    }

    private var captionBar: some View {
        HStack {
            TextField("Add caption...", text: Binding(
                get: { photos[currentIndex].caption },
                set: { photos[currentIndex].caption = $0; try? context.save() }
            ))
            .foregroundColor(.white)
            .font(.subheadline)
            .accessibilityLabel("Photo caption")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.7))
    }

    private var bottomBar: some View {
        HStack(spacing: 40) {
            Button(action: { showCaption.toggle() }) {
                VStack(spacing: 4) {
                    Image(systemName: "text.bubble").font(.title3)
                    Text("Caption").font(.caption2)
                }
                .foregroundColor(.white)
            }
            .accessibilityLabel("Add or edit caption")

            Button(action: { showDeleteAlert = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "trash").font(.title3)
                    Text("Delete").font(.caption2)
                }
                .foregroundColor(.red)
            }
            .accessibilityLabel("Delete photo")
        }
        .padding(.vertical, 16)
        .padding(.bottom, 16)
    }

    private func loadImage() {
        guard currentIndex < photos.count else { return }
        fullImage = VaultPhotoStore.shared.load(photos[currentIndex].fileID)
    }
}

struct PhotoPageView: View {
    let photo: VaultPhoto
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale = max(1.0, $0) }
                            .onEnded { _ in withAnimation { scale = 1.0 } }
                    )
            } else {
                ProgressView().tint(.white)
            }
        }
        .onAppear { image = VaultPhotoStore.shared.load(photo.fileID) }
        .accessibilityLabel("Photo" + (photo.caption.isEmpty ? "" : ": \(photo.caption)"))
    }
}
