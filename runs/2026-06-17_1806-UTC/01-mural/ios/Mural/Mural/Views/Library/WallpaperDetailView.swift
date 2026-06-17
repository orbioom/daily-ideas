import SwiftUI
import SwiftData

struct WallpaperDetailView: View {
    let wallpaper: SavedWallpaper
    @Binding var selectedTab: Int

    @Environment(StudioModel.self) private var studio
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var toast: Toast?
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var shareImage: ShareableImage?
    @State private var showRename = false
    @State private var renameText = ""
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                WallpaperPreview(spec: wallpaper.spec, aspect: AspectRatioOption.phone.ratio, cornerRadius: Theme.radiusLarge)
                    .frame(maxHeight: 480)
                    .shadow(color: Theme.accent.opacity(0.22), radius: 26, y: 12)
                    .padding(.horizontal, 50)

                metaCard
                actionGrid
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(wallpaper.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { startRename() } label: { Label("Rename", systemImage: "pencil") }
                    Button { duplicate() } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More actions")
            }
        }
        .toast($toast)
        .overlay { if isExporting { renderingOverlay } }
        .sheet(item: $shareImage) { item in ShareSheetView(image: item.image) }
        .alert("Export problem", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "Something went wrong.")
        }
        .alert("Rename wallpaper", isPresented: $showRename) {
            TextField("Name", text: $renameText)
            Button("Save") { commitRename() }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Delete this wallpaper?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This can't be undone.")
        }
    }

    private var metaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(wallpaper.spec.style.displayName, systemImage: wallpaper.spec.style.systemImage)
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: wallpaper.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(wallpaper.isFavorite ? Theme.bad : Theme.inkSoft)
                        .font(.system(size: 18, weight: .semibold))
                }
                .accessibilityLabel(wallpaper.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
            SwatchRow(colors: wallpaper.spec.colors, height: 26)
            Text("Created \(wallpaper.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var actionGrid: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Open in Studio", systemImage: "wand.and.stars") {
                openInStudio()
            }
            HStack(spacing: 10) {
                SecondaryButton(title: "Export", systemImage: "photo.fill") {
                    Task { await exportToPhotos() }
                }
                SecondaryButton(title: "Share", systemImage: "square.and.arrow.up") {
                    Task { await prepareShare() }
                }
            }
            HStack(spacing: 10) {
                SecondaryButton(title: "Duplicate", systemImage: "plus.square.on.square") { duplicate() }
                SecondaryButton(title: "Rename", systemImage: "pencil") { startRename() }
            }
        }
    }

    private var renderingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().controlSize(.large).tint(.white)
                Text("Rendering…").font(Theme.rounded(15, .medium)).foregroundStyle(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .accessibilityLabel("Rendering wallpaper")
    }

    // MARK: - Actions

    private func toggleFavorite() {
        wallpaper.isFavorite.toggle()
        try? modelContext.save()
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
    }

    private func openInStudio() {
        studio.load(wallpaper.spec, editingID: wallpaper.id)
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
        selectedTab = 0
        dismiss()
    }

    private func duplicate() {
        var copy = wallpaper.spec
        copy.id = UUID()
        let model = SavedWallpaper(name: "\(wallpaper.name) copy", specData: SavedWallpaper.encode(copy))
        modelContext.insert(model)
        if (try? modelContext.save()) != nil {
            Haptics.success(enabled: settings.hapticsEnabled)
            toast = Toast(kind: .success, message: "Duplicated")
        } else {
            modelContext.delete(model)
            toast = Toast(kind: .error, message: "Couldn't duplicate")
        }
    }

    private func startRename() {
        renameText = wallpaper.name
        showRename = true
    }

    private func commitRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        wallpaper.name = trimmed
        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        toast = Toast(kind: .success, message: "Renamed")
    }

    private func performDelete() {
        modelContext.delete(wallpaper)
        try? modelContext.save()
        Haptics.warning(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func exportToPhotos() async {
        isExporting = true
        defer { isExporting = false }
        await Task.yield()
        guard let image = ExportService.renderExportImage(
            spec: wallpaper.spec, aspect: settings.defaultAspect, isPro: isPro, ultraClean: isPro
        ) else {
            Haptics.error(enabled: settings.hapticsEnabled)
            exportError = ExportError.renderFailed.localizedDescription
            return
        }
        do {
            try await ExportService.saveToPhotos(image)
            Haptics.success(enabled: settings.hapticsEnabled)
            toast = Toast(kind: .success, message: "Saved to Photos")
        } catch {
            Haptics.error(enabled: settings.hapticsEnabled)
            exportError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func prepareShare() async {
        isExporting = true
        defer { isExporting = false }
        await Task.yield()
        guard let image = ExportService.renderExportImage(
            spec: wallpaper.spec, aspect: settings.defaultAspect, isPro: isPro, ultraClean: isPro
        ) else {
            Haptics.error(enabled: settings.hapticsEnabled)
            exportError = ExportError.renderFailed.localizedDescription
            return
        }
        shareImage = ShareableImage(image: image)
    }
}
