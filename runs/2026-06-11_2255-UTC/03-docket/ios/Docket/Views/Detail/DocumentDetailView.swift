import SwiftUI
import SwiftData
import PhotosUI

struct DocumentDetailView: View {
    @Bindable var document: ScanDocument

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Folder.name) private var folders: [Folder]
    @AppStorage("scanQuality") private var scanQuality = 0.8

    @State private var ingestor = ScanIngestor()
    @State private var renaming = false
    @State private var newTitle = ""
    @State private var pdfURL: URL?
    @State private var buildingPDF = false
    @State private var pdfFailed = false
    @State private var addingPhotos = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var confirmDelete = false

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard

                if document.orderedPages.isEmpty {
                    EmptyStateView(
                        icon: "doc",
                        title: "No pages",
                        message: "Add pages from Photos or rescan this document."
                    )
                    .frame(height: 260)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(document.orderedPages) { page in
                            NavigationLink(value: page) {
                                PageThumbnailView(page: page)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                pageMenu(page)
                            }
                        }
                    }
                }

                if case .recognizing(let p, let of) = ingestor.status {
                    HStack(spacing: 10) {
                        ProgressView().controlSize(.small)
                        Text("Reading text · page \(p) of \(of)")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bgPrimary)
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: ScanPage.self) { page in
            PageDetailView(page: page)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        newTitle = document.title
                        renaming = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button {
                        document.isFavorite.toggle()
                        Haptics.tap()
                    } label: {
                        Label(document.isFavorite ? "Remove favorite" : "Mark favorite",
                              systemImage: document.isFavorite ? "star.slash" : "star")
                    }
                    Menu {
                        Button("None") { document.folder = nil }
                        ForEach(folders) { folder in
                            Button(folder.name) { document.folder = folder }
                        }
                    } label: {
                        Label("Move to folder", systemImage: "folder")
                    }
                    Button {
                        addingPhotos = true
                    } label: {
                        Label("Add pages from Photos", systemImage: "plus.rectangle.on.rectangle")
                    }
                    Divider()
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete document", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Document actions")
            }
            ToolbarItem(placement: .bottomBar) {
                shareButton
            }
        }
        .alert("Rename document", isPresented: $renaming) {
            TextField("Title", text: $newTitle)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    document.title = trimmed
                    document.updatedAt = .now
                }
            }
        }
        .alert("Delete this document?", isPresented: $confirmDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                for page in document.pages { ImageStore.delete(page.fileName) }
                context.delete(document)
                dismiss()
            }
        } message: {
            Text("All \(document.pages.count) page\(document.pages.count == 1 ? "" : "s") will be removed from this device.")
        }
        .alert("Couldn't build the PDF", isPresented: $pdfFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No page image could be loaded. Try rescanning the document.")
        }
        .photosPicker(isPresented: $addingPhotos, selection: $photoItems,
                      maxSelectionCount: 20, matching: .images)
        .onChange(of: photoItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                var images: [UIImage] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        images.append(image)
                    }
                }
                photoItems = []
                if !images.isEmpty {
                    ingestor.append(images: images, to: document, quality: scanQuality)
                    pdfURL = nil
                    Haptics.success()
                }
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(document.pages.count) page\(document.pages.count == 1 ? "" : "s")")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("Created \(document.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                let chars = document.fullText.count
                Text(chars > 0 ? "\(chars) characters of searchable text" : "Text recognition pending…")
                    .font(.caption)
                    .foregroundStyle(chars > 0 ? Theme.accent : Theme.textSecondary)
            }
            Spacer()
            if let folder = document.folder {
                Label(folder.name, systemImage: folder.icon)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.14), in: Capsule())
                    .foregroundStyle(Theme.accent)
            }
        }
        .docketCard()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func pageMenu(_ page: ScanPage) -> some View {
        let ordered = document.orderedPages
        if let index = ordered.firstIndex(where: { $0.persistentModelID == page.persistentModelID }) {
            if index > 0 {
                Button {
                    swapOrder(page, ordered[index - 1])
                } label: {
                    Label("Move up", systemImage: "arrow.up")
                }
            }
            if index < ordered.count - 1 {
                Button {
                    swapOrder(page, ordered[index + 1])
                } label: {
                    Label("Move down", systemImage: "arrow.down")
                }
            }
        }
        Button(role: .destructive) {
            ImageStore.delete(page.fileName)
            context.delete(page)
            document.updatedAt = .now
            pdfURL = nil
        } label: {
            Label("Delete page", systemImage: "trash")
        }
    }

    private func swapOrder(_ a: ScanPage, _ b: ScanPage) {
        let tmp = a.order
        a.order = b.order
        b.order = tmp
        document.updatedAt = .now
        pdfURL = nil
        Haptics.tap()
    }

    private var shareButton: some View {
        Group {
            if let pdfURL {
                ShareLink(item: pdfURL) {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                }
            } else {
                Button {
                    buildPDF()
                } label: {
                    if buildingPDF {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("Preparing PDF…").font(.subheadline)
                        }
                    } else {
                        Label("Prepare PDF", systemImage: "doc.badge.arrow.up")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .disabled(buildingPDF || document.pages.isEmpty)
                .accessibilityHint("Builds a shareable PDF of all pages")
            }
        }
    }

    private func buildPDF() {
        buildingPDF = true
        Task { @MainActor in
            // PDFBuilder loads images synchronously; yield once so the
            // spinner renders before the work starts.
            await Task.yield()
            let url = PDFBuilder.makePDF(for: document)
            buildingPDF = false
            if let url {
                pdfURL = url
                Haptics.success()
            } else {
                pdfFailed = true
            }
        }
    }
}

struct PageThumbnailView: View {
    let page: ScanPage

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let image = ImageStore.load(page.fileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(Theme.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.quaternary, lineWidth: 0.5))

            HStack(spacing: 4) {
                Text("p. \(page.order + 1)")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
                if !page.ocrText.isEmpty {
                    Image(systemName: "text.viewfinder")
                        .font(.caption2)
                        .foregroundStyle(Theme.accent)
                        .accessibilityLabel("Text recognized")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Page \(page.order + 1)\(page.ocrText.isEmpty ? "" : ", text recognized")")
    }
}
