import SwiftUI
import SwiftData

struct ArtworkDetailView: View {
    @Bindable var artwork: Artwork
    let palette: Palette
    let isPro: Bool
    var onContinue: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var exportImage: ExportImage?
    @State private var isExporting = false
    @State private var showPaywall = false
    @State private var editingTitle = false
    @State private var titleDraft = ""

    private var page: ColoringPage? { PageLibrary.page(withID: artwork.pageID) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let page {
                        ArtworkThumb(artwork: artwork, page: page, palette: palette, side: 280)
                            .padding(.top, 8)

                        info(page)

                        actions(page)
                    } else {
                        Text("This page is no longer available.")
                            .foregroundStyle(Theme.inkSoft)
                            .padding()
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(artwork.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        titleDraft = artwork.title
                        editingTitle = true
                    } label: { Image(systemName: "pencil") }
                        .accessibilityLabel("Rename artwork")
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .watermarkFreeExport)
            }
            .alert("Rename", isPresented: $editingTitle) {
                TextField("Title", text: $titleDraft)
                Button("Save") {
                    let trimmed = titleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { artwork.title = trimmed; try? context.save() }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func info(_ page: ColoringPage) -> some View {
        VStack(spacing: 10) {
            HStack {
                Label(page.category.rawValue, systemImage: page.category.symbol)
                Spacer()
                Text("\(artwork.filledCount) / \(page.regionCount) filled")
                    .font(Theme.mono(13))
            }
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)

            ProgressBadge(filled: artwork.filledCount, total: page.regionCount)

            HStack {
                Text(artwork.isCompleted ? "Completed \(dateText(artwork.completedAt))"
                                         : "Last edited \(dateText(artwork.updatedAt))")
                Spacer()
            }
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
        }
        .cardSurface()
    }

    private func actions(_ page: ColoringPage) -> some View {
        VStack(spacing: 12) {
            Button {
                onContinue()
            } label: {
                Label(artwork.isCompleted ? "Keep coloring" : "Continue", systemImage: "paintbrush.fill")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: Theme.corner).fill(Theme.accent))
                    .foregroundStyle(.white)
            }

            if let img = exportImage {
                ShareLink(item: img, preview: SharePreview(artwork.title, image: img)) {
                    Label("Share image", systemImage: "square.and.arrow.up")
                        .font(Theme.rounded(16, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: Theme.corner).fill(Theme.surfaceAlt))
                        .foregroundStyle(Theme.ink)
                }
            } else {
                Button {
                    export(page)
                } label: {
                    HStack {
                        if isExporting { ProgressView().controlSize(.small) }
                        Label(isExporting ? "Rendering…" : "Export image",
                              systemImage: "square.and.arrow.up")
                            .font(Theme.rounded(16, .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: Theme.corner).fill(Theme.surfaceAlt))
                    .foregroundStyle(Theme.ink)
                }
                .disabled(isExporting)
            }

            if Pro.exportHasWatermark(isPro: isPro) {
                Button {
                    showPaywall = true
                } label: {
                    Text("Exports include a small Hue watermark • Remove with Pro")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.accent)
                }
            }

            Button(role: .destructive) {
                context.delete(artwork)
                try? context.save()
                dismiss()
            } label: {
                Label("Delete artwork", systemImage: "trash")
                    .font(Theme.rounded(15, .medium))
            }
            .padding(.top, 4)
        }
    }

    private func export(_ page: ColoringPage) {
        isExporting = true
        let watermark = Pro.exportHasWatermark(isPro: isPro)
        // Render on the main actor (ImageRenderer requirement) but after a tick so the
        // "Rendering…" state is visible for large pages.
        Task { @MainActor in
            await Task.yield()
            if let ui = ArtworkExporter.render(page: page, fills: artwork.fills,
                                               palette: palette, watermark: watermark) {
                exportImage = ExportImage(uiImage: ui)
            }
            isExporting = false
        }
    }

    private func dateText(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
