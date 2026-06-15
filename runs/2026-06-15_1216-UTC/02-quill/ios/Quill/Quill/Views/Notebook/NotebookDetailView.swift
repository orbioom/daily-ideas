import SwiftData
import SwiftUI
import UIKit

/// Grid of page thumbnails for a notebook. Add / reorder / delete pages,
/// rename, recolor, export to PDF (Pro), and open the editor.
struct NotebookDetailView: View {
    @Bindable var notebook: Notebook

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro: Bool = false

    @State private var editorTarget: EditorTarget?
    @State private var showSettingsSheet = false
    @State private var showAddTemplateSheet = false
    @State private var paywallReason: PaywallReason?
    @State private var exportDocument: ExportDocument?
    @State private var isExporting = false
    @State private var exportError: String?

    private let columns = [GridItem(.adaptive(minimum: 120, maximum: 170), spacing: 18)]

    private var pages: [Page] { notebook.orderedPages }

    var body: some View {
        Group {
            if pages.isEmpty {
                emptyState
            } else {
                pageGrid
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(notebook.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .sheet(isPresented: $showSettingsSheet) {
            NotebookSettingsSheet(notebook: notebook)
        }
        .sheet(isPresented: $showAddTemplateSheet) {
            addTemplateSheet
        }
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        .sheet(item: $exportDocument) { doc in
            ShareSheet(items: [doc.url])
        }
        .navigationDestination(item: $editorTarget) { target in
            PageEditorView(notebook: notebook, currentIndex: target.index)
        }
        .overlay {
            if isExporting {
                exportingOverlay
            }
        }
        .alert("Export failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    // MARK: - Page grid

    private var pageGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 22) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    Button {
                        editorTarget = EditorTarget(index: index)
                    } label: {
                        PageThumbnail(
                            thumbnailData: page.thumbnailData,
                            template: page.template,
                            pageNumber: index + 1
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            editorTarget = EditorTarget(index: index)
                        } label: {
                            Label("Open", systemImage: "pencil")
                        }
                        if index > 0 {
                            Button {
                                movePage(from: index, to: index - 1)
                            } label: {
                                Label("Move Left", systemImage: "arrow.left")
                            }
                        }
                        if index < pages.count - 1 {
                            Button {
                                movePage(from: index, to: index + 1)
                            } label: {
                                Label("Move Right", systemImage: "arrow.right")
                            }
                        }
                        Button(role: .destructive) {
                            deletePage(page)
                        } label: {
                            Label("Delete Page", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "doc.badge.plus",
            title: "No pages yet",
            message: "Add your first page and start writing.",
            actionTitle: "Add Page",
            action: { showAddTemplateSheet = true }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var exportingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                Text("Preparing PDF…")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.ink)
            }
            .padding(28)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        }
        .accessibilityLabel("Preparing PDF")
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    showSettingsSheet = true
                } label: {
                    Label("Notebook Settings", systemImage: "slider.horizontal.3")
                }
                Button {
                    if Pro.exportUnlocked(isPro: isPro) {
                        exportPDF()
                    } else {
                        paywallReason = .export
                    }
                } label: {
                    Label("Export PDF", systemImage: "square.and.arrow.up")
                }
                .disabled(pages.isEmpty)
                Button {
                    notebook.isFavorite.toggle()
                    try? context.save()
                    Haptics.tap(settings.hapticsEnabled)
                } label: {
                    Label(
                        notebook.isFavorite ? "Unfavorite" : "Favorite",
                        systemImage: notebook.isFavorite ? "star.slash" : "star"
                    )
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Notebook options")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showAddTemplateSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add page")
        }
    }

    private var addTemplateSheet: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(PaperTemplate.allCases) { template in
                        let locked = template.requiresPro && !isPro
                        Button {
                            if locked {
                                showAddTemplateSheet = false
                                paywallReason = .lockedTemplate(template)
                            } else {
                                addPage(template: template)
                                showAddTemplateSheet = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: template.systemImage)
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 28)
                                Text(template.title).foregroundStyle(Theme.ink)
                                Spacer()
                                if locked {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(Theme.inkFaint)
                                }
                            }
                        }
                        .accessibilityLabel("Add \(template.title) page\(locked ? ", locked" : "")")
                    }
                } header: {
                    Text("Choose paper")
                } footer: {
                    Text("Grid and dotted paper are part of Quill Pro.")
                }
            }
            .navigationTitle("Add Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { showAddTemplateSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func addPage(template: PaperTemplate) {
        let nextOrder = (notebook.pages.map { $0.orderIndex }.max() ?? -1) + 1
        let page = Page(orderIndex: nextOrder, template: template, notebook: notebook)
        context.insert(page)
        notebook.updatedAt = .now
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        if let idx = notebook.orderedPages.firstIndex(where: { $0.id == page.id }) {
            editorTarget = EditorTarget(index: idx)
        }
    }

    private func deletePage(_ page: Page) {
        context.delete(page)
        // Re-pack order indices to keep them contiguous.
        for (i, p) in notebook.orderedPages.enumerated() {
            p.orderIndex = i
        }
        notebook.updatedAt = .now
        try? context.save()
        Haptics.warning(settings.hapticsEnabled)
    }

    private func movePage(from: Int, to: Int) {
        var ordered = notebook.orderedPages
        guard from >= 0, from < ordered.count, to >= 0, to < ordered.count else { return }
        let moved = ordered.remove(at: from)
        ordered.insert(moved, at: to)
        for (i, p) in ordered.enumerated() {
            p.orderIndex = i
        }
        notebook.updatedAt = .now
        try? context.save()
        Haptics.select(settings.hapticsEnabled)
    }

    private func exportPDF() {
        isExporting = true
        let inputs = pages.map {
            PDFExporter.PageInput(drawingData: $0.drawingData, template: $0.template)
        }
        let title = notebook.title
        let paperColor = UIColor(Theme.paperColor)
        let lineColor = UIColor(Theme.paperLine)
        Task.detached(priority: .userInitiated) {
            let url = PDFExporter.export(
                title: title,
                pages: inputs,
                paperColor: paperColor,
                lineColor: lineColor
            )
            await MainActor.run {
                isExporting = false
                if let url {
                    exportDocument = ExportDocument(url: url)
                    Haptics.success(settings.hapticsEnabled)
                } else {
                    exportError = "Quill couldn't build the PDF. Try again."
                }
            }
        }
    }
}

/// Identifiable wrapper so `navigationDestination(item:)` can drive the editor.
struct EditorTarget: Identifiable, Hashable {
    let index: Int
    var id: Int { index }
}

/// Lightweight identifiable wrapper for sheet(item:) when sharing a file URL.
struct ExportDocument: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
