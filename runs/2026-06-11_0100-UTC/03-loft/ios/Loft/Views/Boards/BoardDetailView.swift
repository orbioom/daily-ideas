import SwiftUI
import PhotosUI

struct BoardDetailView: View {
    @Bindable var board: VisionBoard
    @Environment(\.modelContext) private var modelContext
    @State private var showAddItem = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var editCaption: BoardItem? = nil
    @State private var captionText = ""

    private var sortedItems: [BoardItem] {
        board.items.sorted { $0.sortIndex < $1.sortIndex }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Affirmation header
                if !board.affirmation.isEmpty {
                    Text("\"\(board.affirmation)\"")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(LoftTheme.categoryColor(board.category))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .accessibilityAddTraits(.isHeader)
                }

                if sortedItems.isEmpty {
                    emptyState
                } else {
                    photoGrid
                }

                addPhotoButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
        }
        .navigationTitle(board.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: BoardEditView(board: board)) {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Edit board")
            }
        }
        .photosPicker(isPresented: $showAddItem, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data),
                   let fn = ImageStore.save(uiImage) {
                    let boardItem = BoardItem(imageFilename: fn, sortIndex: board.items.count)
                    boardItem.board = board
                    modelContext.insert(boardItem)
                    board.items.append(boardItem)
                }
                selectedItem = nil
            }
        }
        .sheet(item: $editCaption) { item in
            CaptionEditView(item: item)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            Text("Add photos to bring your vision to life")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private var photoGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 4) {
            ForEach(sortedItems) { item in
                BoardItemView(item: item)
                    .contextMenu {
                        Button("Edit Caption") { editCaption = item }
                        Button("Remove Photo", role: .destructive) {
                            removeItem(item)
                        }
                    }
            }
        }
        .padding(.horizontal, 4)
    }

    private var addPhotoButton: some View {
        Button {
            showAddItem = true
        } label: {
            Label("Add Photo", systemImage: "photo.badge.plus")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LoftTheme.categoryColor(board.category))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add photo to vision board")
    }

    private func removeItem(_ item: BoardItem) {
        if let fn = item.imageFilename { ImageStore.delete(fn) }
        board.items.removeAll { $0.id == item.id }
        modelContext.delete(item)
    }
}

private struct BoardItemView: View {
    let item: BoardItem
    @State private var image: UIImage? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .overlay(
                            ProgressView()
                        )
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .clipped()

            if !item.caption.isEmpty {
                Text(item.caption)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.5))
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
        .task {
            if let fn = item.imageFilename {
                image = await Task.detached { ImageStore.load(fn) }.value
            }
        }
        .accessibilityLabel(item.caption.isEmpty ? "Board photo" : "Board photo: \(item.caption)")
    }
}

private struct CaptionEditView: View {
    @Bindable var item: BoardItem
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Caption") {
                    TextField("Add a caption…", text: $text, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Edit Caption")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        item.caption = text
                        dismiss()
                    }
                }
            }
            .onAppear { text = item.caption }
        }
    }
}
