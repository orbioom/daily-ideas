import SwiftUI
import SwiftData
import PhotosUI

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ScanDocument.updatedAt, order: .reverse) private var documents: [ScanDocument]

    @AppStorage("scanQuality") private var scanQuality = 0.8
    @State private var ingestor = ScanIngestor()
    @State private var searchText = ""
    @State private var showingScanner = false
    @State private var scannerUnavailable = false
    @State private var scanError: String?
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var importingPhotos = false

    private var filtered: [ScanDocument] {
        guard !searchText.isEmpty else { return documents }
        return documents.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.fullText.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if documents.isEmpty {
                    EmptyStateView(
                        icon: "doc.viewfinder",
                        title: "Nothing scanned yet",
                        message: "Scan a receipt, a contract, a whiteboard — Docket keeps it on this device, makes the text searchable, and exports clean PDFs."
                    )
                } else if filtered.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No matches",
                        message: "No document title or recognized text contains “\(searchText)”. OCR may still be running on recent scans."
                    )
                } else {
                    List {
                        ForEach(filtered) { document in
                            NavigationLink(value: document) {
                                DocumentRowView(document: document)
                            }
                            .listRowBackground(Theme.bgElevated)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(document)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Docket")
            .searchable(text: $searchText, prompt: "Search titles and document text")
            .navigationDestination(for: ScanDocument.self) { document in
                DocumentDetailView(document: document)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            if DocumentScannerView.isSupported {
                                showingScanner = true
                            } else {
                                scannerUnavailable = true
                            }
                        } label: {
                            Label("Scan with camera", systemImage: "doc.viewfinder")
                        }
                        Button {
                            importingPhotos = true
                        } label: {
                            Label("Import from Photos", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Add a document")
                }
            }
            .overlay(alignment: .bottom) { ingestStatusBar }
            .fullScreenCover(isPresented: $showingScanner) {
                DocumentScannerView(
                    onFinish: { images in
                        showingScanner = false
                        ingest(images)
                    },
                    onCancel: { showingScanner = false },
                    onError: { message in
                        showingScanner = false
                        scanError = message
                    }
                )
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $importingPhotos, selection: $photoItems,
                          maxSelectionCount: 20, matching: .images)
            .onChange(of: photoItems) { _, items in
                guard !items.isEmpty else { return }
                Task { await importPhotos(items) }
            }
            .alert("Camera scanning unavailable", isPresented: $scannerUnavailable) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This device can't run the document camera (it's unavailable in the Simulator). You can still import pages from Photos.")
            }
            .alert("Scan failed", isPresented: Binding(
                get: { scanError != nil },
                set: { if !$0 { scanError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(scanError ?? "")
            }
        }
    }

    private var ingestStatusBar: some View {
        Group {
            switch ingestor.status {
            case .saving:
                statusPill(text: "Saving pages…", spinning: true)
            case .recognizing(let page, let of):
                statusPill(text: "Reading text · page \(page) of \(of)", spinning: true)
            case .done:
                statusPill(text: "Text recognized", spinning: false)
                    .task {
                        try? await Task.sleep(for: .seconds(2))
                        ingestor.reset()
                    }
            case .failed(let message):
                statusPill(text: message, spinning: false, isError: true)
                    .task {
                        try? await Task.sleep(for: .seconds(3))
                        ingestor.reset()
                    }
            case .idle:
                EmptyView()
            }
        }
        .animation(.easeOut(duration: 0.2), value: ingestor.status)
    }

    private func statusPill(text: String, spinning: Bool, isError: Bool = false) -> some View {
        HStack(spacing: 10) {
            if spinning {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(isError ? .red : Theme.accent)
            }
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.bgElevated, in: Capsule())
        .shadow(radius: 6, y: 3)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }

    private func ingest(_ images: [UIImage]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        let title = "Scan \(formatter.string(from: .now))"
        _ = ingestor.ingest(images: images, title: title,
                            quality: scanQuality, folder: nil, into: context)
        Haptics.success()
    }

    private func importPhotos(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        photoItems = []
        if images.isEmpty {
            scanError = "Those photos couldn't be imported."
        } else {
            ingest(images)
        }
    }

    private func delete(_ document: ScanDocument) {
        for page in document.pages {
            ImageStore.delete(page.fileName)
        }
        context.delete(document)
        Haptics.tap()
    }
}

struct DocumentRowView: View {
    let document: ScanDocument

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text("\(document.pages.count) page\(document.pages.count == 1 ? "" : "s") · \(document.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                if let folder = document.folder {
                    Label(folder.name, systemImage: folder.icon)
                        .font(.caption2)
                        .foregroundStyle(Theme.accent)
                }
            }
            Spacer()
            if document.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Favorite")
            }
        }
        .padding(.vertical, 2)
    }

    private var thumbnail: some View {
        Group {
            if let first = document.orderedPages.first,
               let image = ImageStore.load(first.fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "doc")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(width: 46, height: 60)
        .background(Theme.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(.quaternary, lineWidth: 0.5))
        .accessibilityHidden(true)
    }
}
