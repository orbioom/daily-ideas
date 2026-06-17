import SwiftUI
import SwiftData

/// The core designer. Live preview + style picker + relevant controls + actions.
struct StudioView: View {
    @Environment(StudioModel.self) private var studio
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query private var saved: [SavedWallpaper]

    @State private var toast: Toast?
    @State private var showPaywall = false
    @State private var showSaveSheet = false
    @State private var pendingName = ""
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var shareImage: ShareableImage?

    var body: some View {
        @Bindable var studio = studio
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    previewCard
                    actionButtons
                    StyleSelector(selectedStyle: $studio.spec.style)
                    activePaletteCard
                    StudioControlPanel(spec: $studio.spec)
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Aspect", selection: $studio.aspect) {
                            ForEach(AspectRatioOption.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label(studio.aspect.rawValue, systemImage: "aspectratio")
                            .font(Theme.rounded(14, .medium))
                    }
                    .accessibilityLabel("Output aspect ratio")
                }
            }
            .toast($toast)
            .overlay { if isExporting { renderingOverlay } }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(item: $shareImage) { item in
                ShareSheetView(image: item.image)
            }
            .alert("Export problem", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
                Button("OK", role: .cancel) { exportError = nil }
            } message: {
                Text(exportError ?? "Something went wrong.")
            }
            .sheet(isPresented: $showSaveSheet) {
                SaveWallpaperSheet(name: $pendingName) { confirm in
                    if confirm { performSave() }
                    showSaveSheet = false
                }
                .presentationDetents([.height(220)])
            }
        }
    }

    // MARK: - Sections

    private var previewCard: some View {
        WallpaperPreview(spec: studio.spec, aspect: studio.aspect.ratio, cornerRadius: Theme.radiusLarge)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: 460)
            .shadow(color: Theme.accent.opacity(0.22), radius: 26, y: 12)
            .padding(.horizontal, studio.aspect == .phone ? 60 : 24)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SecondaryButton(title: "Shuffle", systemImage: "dice.fill") {
                    Haptics.impact(.light, enabled: settings.hapticsEnabled)
                    studio.shuffle()
                }
                SecondaryButton(title: "Save", systemImage: "square.and.arrow.down.fill") {
                    attemptSave()
                }
            }
            HStack(spacing: 10) {
                PrimaryButton(title: "Export to Photos", systemImage: "photo.fill") {
                    Task { await exportToPhotos() }
                }
                Button {
                    Task { await prepareShare() }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 52)
                        .padding(.vertical, 14)
                        .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                                .strokeBorder(Theme.hairline, lineWidth: 1)
                        )
                        .foregroundStyle(Theme.ink)
                }
                .accessibilityLabel("Share wallpaper")
            }
        }
    }

    private var activePaletteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Active palette")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(studio.spec.paletteName)
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.ink)
            }
            SwatchRow(colors: studio.spec.colors, height: 30)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var renderingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().controlSize(.large).tint(.white)
                Text("Rendering…")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .accessibilityLabel("Rendering wallpaper")
    }

    // MARK: - Actions

    private func attemptSave() {
        if !isPro && saved.count >= Pro.freeLibraryLimit {
            Haptics.warning(enabled: settings.hapticsEnabled)
            showPaywall = true
            return
        }
        pendingName = defaultName()
        showSaveSheet = true
    }

    private func defaultName() -> String {
        "\(studio.spec.style.displayName) · \(studio.spec.paletteName)"
    }

    private func performSave() {
        let trimmed = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? defaultName() : trimmed
        let model = SavedWallpaper(name: finalName, specData: SavedWallpaper.encode(studio.spec))
        modelContext.insert(model)
        do {
            try modelContext.save()
            Haptics.success(enabled: settings.hapticsEnabled)
            toast = Toast(kind: .success, message: "Saved to your library")
        } catch {
            modelContext.delete(model)
            Haptics.error(enabled: settings.hapticsEnabled)
            toast = Toast(kind: .error, message: "Couldn't save. Try again.")
        }
    }

    private func exportToPhotos() async {
        isExporting = true
        defer { isExporting = false }
        // Yield so the overlay paints before the heavy render.
        await Task.yield()
        guard let image = ExportService.renderExportImage(
            spec: studio.spec,
            aspect: studio.aspect,
            isPro: isPro,
            ultraClean: isPro
        ) else {
            Haptics.error(enabled: settings.hapticsEnabled)
            exportError = ExportError.renderFailed.localizedDescription
            return
        }
        do {
            try await ExportService.saveToPhotos(image)
            Haptics.success(enabled: settings.hapticsEnabled)
            toast = Toast(kind: .success, message: isPro ? "Saved 4K wallpaper to Photos" : "Saved to Photos")
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
            spec: studio.spec,
            aspect: studio.aspect,
            isPro: isPro,
            ultraClean: isPro
        ) else {
            Haptics.error(enabled: settings.hapticsEnabled)
            exportError = ExportError.renderFailed.localizedDescription
            return
        }
        shareImage = ShareableImage(image: image)
    }
}
