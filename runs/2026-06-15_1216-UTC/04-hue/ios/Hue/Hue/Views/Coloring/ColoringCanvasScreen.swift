import SwiftUI
import SwiftData

struct ColoringCanvasScreen: View {
    let page: ColoringPage
    @Bindable var artwork: Artwork
    let customPalettes: [Palette]

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    @StateObject private var model: ColoringViewModel
    @State private var showCelebration = false
    @State private var showRegionList = false
    @State private var saveWorkItem: DispatchWorkItem?

    init(page: ColoringPage, artwork: Artwork, customPalettes: [Palette]) {
        self.page = page
        self.artwork = artwork
        self.customPalettes = customPalettes
        let palette = PaletteLibrary.resolve(id: artwork.paletteId, custom: customPalettes)
        _model = StateObject(wrappedValue:
            ColoringViewModel(page: page, palette: palette,
                              fills: artwork.fills, byNumberMode: artwork.byNumberMode)
        )
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar
                ZoomableCanvas(model: model, showOutlines: settings.showOutlines,
                               hapticsEnabled: settings.hapticsEnabled)
                    .padding(.horizontal, 12)
                if let nudge = model.nudge {
                    nudgeBanner(nudge)
                }
                controlBar
                PaletteBar(model: model)
            }
        }
        .navigationTitle(artwork.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showRegionList = true
                    } label: {
                        Label("Region list (accessible)", systemImage: "list.bullet")
                    }
                    Toggle(isOn: byNumberBinding) {
                        Label("Color by number", systemImage: "number.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More options")
            }
        }
        .sheet(isPresented: $showRegionList) {
            RegionListView(model: model, hapticsEnabled: settings.hapticsEnabled)
        }
        .overlay {
            if showCelebration {
                CelebrationOverlay(reduceMotion: reduceMotion) {
                    showCelebration = false
                }
            }
        }
        .onChange(of: model.fills) { _, _ in scheduleSave() }
        .onChange(of: model.justCompleted) { _, done in
            if done {
                markCompleted()
                showCelebration = true
                model.justCompleted = false
            }
        }
        .onChange(of: model.byNumberMode) { _, newValue in
            artwork.byNumberMode = newValue
        }
        .onDisappear { saveNow() }
    }

    private var byNumberBinding: Binding<Bool> {
        Binding(get: { model.byNumberMode }, set: { model.byNumberMode = $0 })
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(Int(model.progress * 100))% complete")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(model.filledCount) / \(model.totalRegions)")
                    .font(Theme.mono(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.hairline)
                    Capsule().fill(Theme.accent)
                        .frame(width: max(0, geo.size.width * model.progress))
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: model.progress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(model.progress * 100)) percent, \(model.filledCount) of \(model.totalRegions) regions filled")
    }

    // MARK: - Control bar

    private var controlBar: some View {
        HStack(spacing: 12) {
            controlButton("arrow.uturn.backward", label: "Undo", enabled: model.canUndo) {
                model.undo(hapticsEnabled: settings.hapticsEnabled)
            }
            controlButton("paintbrush.pointed.fill",
                          label: "Fill all #\(model.selectedColorIndex + 1)", enabled: true) {
                model.fillAllMatching(hapticsEnabled: settings.hapticsEnabled)
            }
            Spacer()
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(model.selectedColor)
                    .frame(width: 26, height: 26)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.hairline))
                Text("#\(model.selectedColorIndex + 1)")
                    .font(Theme.mono(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Selected color number \(model.selectedColorIndex + 1)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func controlButton(_ symbol: String, label: String, enabled: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: symbol)
                .font(Theme.rounded(13, .medium))
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerSmall)
                        .fill(Theme.surfaceAlt)
                )
                .foregroundStyle(enabled ? Theme.ink : Theme.inkFaint)
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func nudgeBanner(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(13, .medium))
            .foregroundStyle(Theme.warn)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.warn.opacity(0.14)))
            .padding(.top, 6)
            .transition(.opacity)
            .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Persistence

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { Task { @MainActor in saveNow() } }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: item)
    }

    @MainActor
    private func saveNow() {
        artwork.fills = model.fills
        artwork.paletteId = model.palette.id
        artwork.byNumberMode = model.byNumberMode
        artwork.updatedAt = Date()
        artwork.thumbnailData = ThumbnailRenderer.render(
            page: page, fills: model.fills, palette: model.palette)
        try? context.save()
    }

    @MainActor
    private func markCompleted() {
        if artwork.completedAt == nil {
            artwork.completedAt = Date()
        }
        saveNow()
    }
}
