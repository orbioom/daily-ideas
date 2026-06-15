import PencilKit
import SwiftData
import SwiftUI
import UIKit

/// Full-screen PencilKit editor. Operates on a notebook's ordered pages with a
/// current index, supporting swipe/arrow navigation, autosave, thumbnail
/// regeneration, template switching, and favorite toggling.
struct PageEditorView: View {
    @Bindable var notebook: Notebook
    @State var currentIndex: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("isPro") private var isPro: Bool = false

    @StateObject private var vm = EditorViewModel()

    @State private var liveDrawingData = Data()
    @State private var showClearConfirm = false
    @State private var showTemplateSheet = false
    @State private var paywallReason: PaywallReason?
    @State private var didConfigure = false

    private var pages: [Page] { notebook.orderedPages }

    private var currentPage: Page? {
        guard currentIndex >= 0, currentIndex < pages.count else { return nil }
        return pages[currentIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let page = currentPage {
                canvasArea(for: page)
                EditorToolbar(
                    vm: vm,
                    isPro: isPro,
                    onLockedColor: { paywallReason = .lockedColor },
                    onClear: { showClearConfirm = true }
                )
            } else {
                EmptyStateView(
                    icon: "doc",
                    title: "No page",
                    message: "This page is no longer available."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bg)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(pageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { editorToolbarItems }
        .toolbarBackground(Theme.surface, for: .navigationBar)
        .onAppear(perform: configureIfNeeded)
        .onChange(of: vm.toolKind) { _, _ in syncCanvasTool() }
        .onChange(of: vm.inkColorHex) { _, _ in syncCanvasTool() }
        .onChange(of: vm.width) { _, _ in syncCanvasTool() }
        .confirmationDialog(
            "Clear this page?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear Page", role: .destructive) { clearPage() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all strokes on the current page. This cannot be undone.")
        }
        .sheet(isPresented: $showTemplateSheet) {
            templateSheet
        }
        .sheet(item: $paywallReason) { reason in
            PaywallView(reason: reason)
        }
    }

    // MARK: - Canvas

    private func canvasArea(for page: Page) -> some View {
        GeometryReader { geo in
            ZStack {
                PaperBackground(template: page.template)
                CanvasView(
                    drawingData: $liveDrawingData,
                    tool: vm.currentTool,
                    drawingPolicy: settings.inputPolicy == .pencilOnly ? .pencilOnly : .anyInput,
                    isInteractive: true,
                    onDrawingChange: { data in
                        handleDrawingChange(data, for: page)
                    },
                    onCanvasReady: { canvas in
                        vm.attach(canvas)
                    }
                )
                .accessibilityLabel("Drawing canvas, page \(currentIndex + 1) of \(pages.count)")
                .accessibilityHint("Draw with \(vm.toolKind.title). Swipe with two fingers is reserved for navigation.")
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            // Edge swipe navigation (does not interfere with drawing).
            .gesture(
                DragGesture(minimumDistance: 60)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                        if value.translation.width < -80 { goToPage(currentIndex + 1) }
                        else if value.translation.width > 80 { goToPage(currentIndex - 1) }
                    }
            )
        }
        .id(currentPage?.id)
    }

    // MARK: - Toolbar items

    @ToolbarContentBuilder
    private var editorToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                toggleFavorite()
            } label: {
                Image(systemName: notebook.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(notebook.isFavorite ? Theme.warn : Theme.inkSoft)
            }
            .accessibilityLabel(notebook.isFavorite ? "Remove from favorites" : "Add to favorites")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    showTemplateSheet = true
                } label: {
                    Label("Page Template", systemImage: "square.grid.2x2")
                }
                Button {
                    addPage()
                } label: {
                    Label("Add Page After", systemImage: "plus.rectangle.on.rectangle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Page options")
        }
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                goToPage(currentIndex - 1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(currentIndex <= 0)
            .accessibilityLabel("Previous page")

            Spacer()
            Text("Page \(min(currentIndex + 1, max(pages.count, 1))) of \(pages.count)")
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.inkSoft)
            Spacer()

            Button {
                if currentIndex >= pages.count - 1 {
                    addPage()
                } else {
                    goToPage(currentIndex + 1)
                }
            } label: {
                Image(systemName: currentIndex >= pages.count - 1 ? "plus" : "chevron.right")
            }
            .accessibilityLabel(currentIndex >= pages.count - 1 ? "Add page" : "Next page")
        }
    }

    private var templateSheet: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(PaperTemplate.allCases) { template in
                        templateRow(template)
                    }
                } footer: {
                    Text("Grid and dotted paper are part of Quill Pro.")
                }
            }
            .navigationTitle("Page Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showTemplateSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func templateRow(_ template: PaperTemplate) -> some View {
        let locked = template.requiresPro && !isPro
        let isCurrent = currentPage?.template == template
        return Button {
            if locked {
                showTemplateSheet = false
                paywallReason = .lockedTemplate(template)
            } else {
                setTemplate(template)
                showTemplateSheet = false
            }
        } label: {
            HStack {
                Image(systemName: template.systemImage)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 28)
                Text(template.title)
                    .foregroundStyle(Theme.ink)
                Spacer()
                if locked {
                    Image(systemName: "lock.fill").foregroundStyle(Theme.inkFaint)
                } else if isCurrent {
                    Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                }
            }
        }
        .accessibilityLabel("\(template.title)\(locked ? ", locked" : "")\(isCurrent ? ", selected" : "")")
    }

    private var pageTitle: String {
        notebook.title
    }

    // MARK: - Actions

    private func syncCanvasTool() {
        vm.canvas?.tool = vm.currentTool
    }

    private func configureIfNeeded() {
        guard !didConfigure else { return }
        didConfigure = true
        vm.configureInitialColor(from: settings.defaultPenColorHex)
        if let page = currentPage {
            liveDrawingData = page.drawingData
        }
    }

    private func handleDrawingChange(_ data: Data, for page: Page) {
        liveDrawingData = data
        page.drawingData = data
        page.updatedAt = .now
        notebook.updatedAt = .now
        vm.refreshUndoState()
        regenerateThumbnail(for: page, data: data)
        try? context.save()
    }

    private func regenerateThumbnail(for page: Page, data: Data) {
        let template = page.template
        let paperColor = UIColor(Theme.paperColor)
        let lineColor = UIColor(Theme.paperLine)
        let pageID = page.id
        Task.detached(priority: .utility) {
            let thumb = ThumbnailRenderer.makeThumbnail(
                drawingData: data,
                template: template,
                paperColor: paperColor,
                lineColor: lineColor
            )
            await MainActor.run {
                // Re-resolve the page by id to avoid stale references.
                if let target = notebook.pages.first(where: { $0.id == pageID }) {
                    target.thumbnailData = thumb
                    try? context.save()
                }
            }
        }
    }

    private func goToPage(_ index: Int) {
        guard index >= 0, index < pages.count, index != currentIndex else { return }
        // Persist current before moving.
        if let page = currentPage {
            page.drawingData = liveDrawingData
            try? context.save()
        }
        Haptics.select(settings.hapticsEnabled)
        let animation: Animation? = reduceMotion ? nil : .easeInOut(duration: 0.2)
        withAnimation(animation) {
            currentIndex = index
        }
        if let page = currentPage {
            liveDrawingData = page.drawingData
        }
        vm.refreshUndoState()
    }

    private func addPage() {
        let template = currentPage?.template ?? notebook.defaultTemplate
        let nextOrder = (notebook.pages.map { $0.orderIndex }.max() ?? -1) + 1
        let page = Page(
            orderIndex: nextOrder,
            template: template,
            notebook: notebook
        )
        context.insert(page)
        notebook.updatedAt = .now
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        // Navigate to the newly created page (it sorts last).
        let newPages = notebook.orderedPages
        if let idx = newPages.firstIndex(where: { $0.id == page.id }) {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                currentIndex = idx
            }
            liveDrawingData = Data()
            vm.refreshUndoState()
        }
    }

    private func setTemplate(_ template: PaperTemplate) {
        guard let page = currentPage else { return }
        page.template = template
        page.updatedAt = .now
        try? context.save()
        regenerateThumbnail(for: page, data: page.drawingData)
        Haptics.tap(settings.hapticsEnabled)
    }

    private func clearPage() {
        guard let page = currentPage else { return }
        vm.clear()
        liveDrawingData = Data()
        page.drawingData = Data()
        page.thumbnailData = nil
        page.updatedAt = .now
        try? context.save()
        Haptics.warning(settings.hapticsEnabled)
    }

    private func toggleFavorite() {
        notebook.isFavorite.toggle()
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }
}
