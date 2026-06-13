import SwiftUI
import UIKit
import SwiftData
import PhotosUI

struct EditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(ProStore.self) private var pro
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var editor = EditorModel()
    @State private var photoItem: PhotosPickerItem?
    @State private var mode = 0
    @State private var selectedField: Adjustments.Field = .exposure
    @State private var comparing = false
    @State private var presetThumbs: [String: UIImage] = [:]
    @State private var showPaywall = false
    @State private var showSaveRecipe = false
    @State private var toast: String?
    @State private var loading = false
    @AppStorage("highQualityExport") private var highQuality = true
    @AppStorage("autoSaveRecipeOnExport") private var autoSaveRecipe = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if editor.hasImage {
                    editorBody
                } else {
                    emptyState
                }
                if let toast {
                    VStack {
                        Spacer()
                        Toast(text: toast, icon: "checkmark.circle.fill").padding(.bottom, 24)
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showSaveRecipe) {
                SaveRecipeSheet(adjustments: editor.adjustments) { saved in
                    if saved { flash("Recipe saved") }
                }
            }
            .onChange(of: photoItem) { _, item in Task { await loadPhoto(item) } }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 22) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60)).foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text("Edit a photo").font(Theme.serif(26, .bold)).foregroundStyle(Theme.ink)
            Text("Pick a shot from your library to apply film looks and fine-tune every detail — all on your device.")
                .font(Theme.rounded(15, .regular)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Choose photo", systemImage: "photo.on.rectangle")
                    .font(Theme.rounded(17, .bold)).padding(.horizontal, 24).padding(.vertical, 14)
                    .background(Theme.accent, in: Capsule()).foregroundStyle(.white)
            }
            if loading { ProgressView().tint(Theme.accent) }
        }
    }

    // MARK: - Editor

    private var editorBody: some View {
        VStack(spacing: 0) {
            canvas
            controlPanel
        }
    }

    private var canvas: some View {
        ZStack {
            Theme.canvas
            if let img = comparing ? editor.originalPreview : editor.displayImage {
                Image(uiImage: img).resizable().scaledToFit().padding(8)
                    .accessibilityLabel("Edited photo preview")
            } else {
                ProgressView().tint(.white)
            }
            VStack {
                HStack {
                    if editor.isProcessing {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small).tint(.white)
                            Text("Rendering").font(Theme.rounded(12, .semibold)).foregroundStyle(.white)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.black.opacity(0.4), in: Capsule())
                    }
                    Spacer()
                    if editor.isEdited {
                        Image(systemName: comparing ? "eye.fill" : "rectangle.righthalf.inset.filled.arrow.right")
                            .font(.system(size: 18)).foregroundStyle(.white)
                            .padding(8).background(.black.opacity(0.4), in: Circle())
                            .contentShape(Circle())
                            .accessibilityLabel("Press and hold to compare with original")
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in comparing = true }
                                    .onEnded { _ in comparing = false })
                    }
                }
                .padding(12)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var controlPanel: some View {
        VStack(spacing: 12) {
            Picker("Mode", selection: $mode) {
                Text("Looks").tag(0); Text("Adjust").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16).padding(.top, 12)

            if mode == 0 { presetStrip } else { adjustControls }
        }
        .padding(.bottom, 8)
        .background(Theme.bg)
    }

    private var recipePresets: [Preset] {
        recipes.map { Preset(id: "recipe-\($0.id.uuidString)", name: $0.name, blurb: "", isPro: false, adjustments: $0.adjustments) }
    }

    private var presetStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(PresetLibrary.all) { preset in
                    let locked = preset.isPro && !pro.isPro
                    Button {
                        if locked { showPaywall = true }
                        else { editor.apply(preset: preset) }
                    } label: {
                        PresetChip(name: preset.name,
                                   image: presetThumbs[preset.id],
                                   selected: editor.activePresetName == preset.name,
                                   locked: locked)
                    }
                    .buttonStyle(.plain)
                }
                if !recipePresets.isEmpty {
                    Rectangle().fill(Theme.hairline).frame(width: 1, height: 60)
                    ForEach(recipePresets) { preset in
                        Button { editor.apply(preset: preset) } label: {
                            PresetChip(name: preset.name,
                                       image: presetThumbs[preset.id],
                                       selected: editor.activePresetName == preset.name,
                                       locked: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 4)
        }
        .frame(height: 96)
    }

    private var adjustControls: some View {
        VStack(spacing: 10) {
            AdjustSlider(field: selectedField,
                         value: Binding(get: { editor.adjustments[selectedField] },
                                        set: { _ in }),
                         onChange: { editor.setField(selectedField, $0) })
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Adjustments.Field.allCases) { field in
                        Button { selectedField = field; Haptics.soft() } label: {
                            VStack(spacing: 4) {
                                Image(systemName: field.icon).font(.system(size: 17))
                                Text(field.label).font(Theme.rounded(10, .semibold))
                            }
                            .foregroundStyle(selectedField == field ? Theme.accent : Theme.inkSoft)
                            .frame(width: 62, height: 52)
                            .background(selectedField == field ? Theme.accentSoft : Theme.surface,
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .topTrailing) {
                            if editor.adjustments[field] != 0 {
                                Circle().fill(Theme.accent).frame(width: 7, height: 7).padding(5)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if editor.hasImage {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Image(systemName: "photo.badge.plus")
                }
                .accessibilityLabel("Choose another photo")
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if editor.hasImage {
                Menu {
                    Button { editor.resetAll() } label: { Label("Reset edits", systemImage: "arrow.uturn.backward") }
                    Button { attemptSaveRecipe() } label: { Label("Save as recipe", systemImage: "wand.and.stars") }
                } label: { Image(systemName: "ellipsis.circle") }
                .disabled(!editor.hasImage)
                Button { saveToPhotos() } label: { Image(systemName: "square.and.arrow.down") }
                    .accessibilityLabel("Save to Photos")
            }
        }
    }

    // MARK: - Actions

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        loading = true
        if let data = try? await item.loadTransferable(type: Data.self) {
            await editor.load(data: data)
            presetThumbs = await editor.presetThumbnails(PresetLibrary.all + recipePresets)
        }
        loading = false
    }

    private func attemptSaveRecipe() {
        if !pro.isPro { showPaywall = true } else { showSaveRecipe = true }
    }

    private func saveToPhotos() {
        guard let rendered = editor.exportImage() else { flash("Couldn’t render", error: true); return }
        let image = highQuality ? rendered : resized(rendered, maxDimension: 2048)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        let thumb = ImageEngine.shared.thumbnailData(from: image)
        let record = EditRecord(thumbnail: thumb, adjustments: editor.adjustments, presetName: editor.activePresetName)
        context.insert(record)
        try? context.save()
        Haptics.success()
        flash("Saved to Photos")
        if autoSaveRecipe && pro.isPro && editor.isEdited {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showSaveRecipe = true }
        }
    }

    private func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
    }

    private func flash(_ text: String, error: Bool = false) {
        withAnimation { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { if toast == text { toast = nil } }
        }
    }
}
