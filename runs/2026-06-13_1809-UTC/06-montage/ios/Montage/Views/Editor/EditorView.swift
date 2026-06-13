import SwiftUI
import UIKit
import SwiftData
import PhotosUI

struct ExportResult: Identifiable { let id = UUID(); let image: UIImage }

struct EditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(ProStore.self) private var pro

    let template: MontageTemplate
    @State private var design: DesignVM

    @State private var tool = 0
    @State private var targetSlot: Int?
    @State private var slotPickerItem: PhotosPickerItem?
    @State private var showSlotPicker = false
    @State private var showPaywall = false
    @State private var exportResult: ExportResult?
    @State private var toast: String?
    @AppStorage("favoriteBackgrounds") private var favoriteBackgroundsRaw = ""

    private var orderedBackgrounds: [BackgroundStyle] {
        let favs = Set(favoriteBackgroundsRaw.split(separator: ",").map(String.init))
        return BackgroundLibrary.all.sorted {
            (favs.contains($0.id) ? 0 : 1) < (favs.contains($1.id) ? 0 : 1)
        }
    }

    init(template: MontageTemplate) {
        self.template = template
        _design = State(initialValue: DesignVM(template: template))
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                canvasArea
                toolDock
            }
            if let toast {
                VStack { Spacer(); Toast(text: toast, icon: "checkmark.circle.fill").padding(.bottom, 20) }
                    .transition(.opacity)
            }
        }
        .navigationTitle("Editor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { export() } label: { Label("Export", systemImage: "square.and.arrow.up") }
                    .font(Theme.rounded(15, .bold))
            }
        }
        .photosPicker(isPresented: $showSlotPicker, selection: $slotPickerItem, matching: .images)
        .onChange(of: slotPickerItem) { _, item in Task { await loadSlot(item) } }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(item: $exportResult) { r in ExportResultSheet(image: r.image) }
    }

    // MARK: - Canvas

    private var canvasArea: some View {
        GeometryReader { geo in
            let size = fittedSize(in: geo.size)
            ZStack {
                DesignCanvas(design: design, size: size, interactive: true, renderText: false,
                             onTapSlot: { slot in pickPhoto(for: slot) })
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                textLayer(size: size)
            }
            .frame(width: size.width, height: size.height)
            .coordinateSpace(name: "canvas")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { design.selectedTextID = nil }
        }
        .padding(16)
    }

    private func fittedSize(in available: CGSize) -> CGSize {
        let a = template.aspect
        var w = available.width, h = w / a
        if h > available.height { h = available.height; w = h * a }
        return CGSize(width: max(1, w), height: max(1, h))
    }

    private func textLayer(size: CGSize) -> some View {
        ForEach(design.texts) { overlay in
            let selected = design.selectedTextID == overlay.id
            Text(overlay.text.isEmpty ? " " : overlay.text)
                .font(overlay.weight.font(size: overlay.fontScale * size.height))
                .foregroundStyle(overlay.color)
                .multilineTextAlignment(.center)
                .shadow(color: overlay.hasShadow ? .black.opacity(0.35) : .clear, radius: 3, y: 1)
                .frame(maxWidth: size.width * 0.92)
                .fixedSize(horizontal: false, vertical: true)
                .padding(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .opacity(selected ? 1 : 0))
                .position(x: overlay.x * size.width, y: overlay.y * size.height)
                .gesture(
                    DragGesture(coordinateSpace: .named("canvas"))
                        .onChanged { value in
                            design.selectedTextID = overlay.id
                            design.moveText(overlay.id, to: CGPoint(x: value.location.x / size.width,
                                                                    y: value.location.y / size.height))
                        })
                .onTapGesture { design.selectedTextID = overlay.id; tool = 2 }
        }
    }

    // MARK: - Tools

    private var toolDock: some View {
        VStack(spacing: 10) {
            Picker("Tool", selection: $tool) {
                Label("Photos", systemImage: "photo").tag(0)
                Label("Style", systemImage: "paintpalette").tag(1)
                Label("Text", systemImage: "textformat").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            Group {
                switch tool {
                case 0: photosTool
                case 1: backgroundTool
                default: textTool
                }
            }
            .frame(height: 132)
        }
        .padding(.top, 10).padding(.bottom, 8)
        .background(Theme.surface.shadow(.drop(color: .black.opacity(0.06), radius: 8, y: -2)))
    }

    private var photosTool: some View {
        VStack(spacing: 10) {
            Text("Tap a frame to add a photo")
                .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
            HStack(spacing: 12) {
                ForEach(0..<template.slotCount, id: \.self) { i in
                    Button { pickPhoto(for: i) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(design.photos[i] != nil ? Theme.accentSoft : Theme.surfaceAlt)
                                .frame(width: 50, height: 50)
                            if let img = design.photos[i] {
                                Image(uiImage: img).resizable().scaledToFill().frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            } else {
                                Image(systemName: "plus").foregroundStyle(Theme.accent)
                            }
                            Text("\(i + 1)").font(Theme.rounded(10, .bold)).foregroundStyle(.white)
                                .padding(3).background(Theme.ink.opacity(0.6), in: Circle())
                                .frame(maxWidth: 50, maxHeight: 50, alignment: .bottomTrailing)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Frame \(i + 1)\(design.photos[i] != nil ? ", filled" : ", empty")")
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var backgroundTool: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(orderedBackgrounds) { bg in
                    let locked = bg.isPro && !pro.isPro
                    Button {
                        if locked { showPaywall = true } else { design.backgroundID = bg.id; Haptics.tap() }
                    } label: {
                        VStack(spacing: 5) {
                            ZStack {
                                bg.fill
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(design.backgroundID == bg.id ? Theme.accent : Theme.hairline,
                                                lineWidth: design.backgroundID == bg.id ? 2.5 : 1))
                                if locked {
                                    Image(systemName: "lock.fill").font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white).padding(5).background(.black.opacity(0.4), in: Circle())
                                }
                            }
                            Text(bg.name).font(Theme.rounded(10, .semibold)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.top, 4)
        }
    }

    private var textTool: some View {
        Group {
            if let selected = design.selectedText {
                textControls(selected)
            } else {
                VStack(spacing: 12) {
                    Button { design.addText() } label: {
                        Label("Add text", systemImage: "plus")
                            .font(Theme.rounded(16, .bold)).padding(.horizontal, 22).padding(.vertical, 12)
                            .background(Theme.accent, in: Capsule()).foregroundStyle(.white)
                    }
                    if design.texts.isEmpty {
                        Text("Add a caption, then drag it anywhere on your canvas.")
                            .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Tap any text on the canvas to edit it.")
                            .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func textControls(_ overlay: TextOverlay) -> some View {
        VStack(spacing: 10) {
            HStack {
                TextField("Text", text: Binding(
                    get: { overlay.text },
                    set: { v in design.updateSelected { $0.text = v } }))
                    .textFieldStyle(.roundedBorder)
                Button { design.removeText(overlay.id) } label: {
                    Image(systemName: "trash").foregroundStyle(Theme.bad)
                }
                .accessibilityLabel("Delete text")
            }
            HStack(spacing: 10) {
                ForEach(TextOverlay.palette, id: \.self) { hex in
                    Circle().fill(Color(hex: hex)).frame(width: 26, height: 26)
                        .overlay(Circle().stroke(Theme.ink, lineWidth: overlay.colorHex == hex ? 2.5 : 0.5))
                        .onTapGesture { design.updateSelected { $0.colorHex = hex }; Haptics.soft() }
                }
                Spacer()
                Picker("Weight", selection: Binding(
                    get: { overlay.weight },
                    set: { w in design.updateSelected { $0.weight = w } })) {
                    ForEach(TextWeight.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.menu).tint(Theme.accent)
            }
            HStack(spacing: 10) {
                Image(systemName: "textformat.size.smaller").foregroundStyle(Theme.inkSoft)
                Slider(value: Binding(
                    get: { overlay.fontScale },
                    set: { s in design.updateSelected { $0.fontScale = s } }), in: 0.02...0.12)
                    .tint(Theme.accent)
                Image(systemName: "textformat.size.larger").foregroundStyle(Theme.inkSoft)
                Toggle("", isOn: Binding(
                    get: { overlay.hasShadow },
                    set: { v in design.updateSelected { $0.hasShadow = v } })).labelsHidden()
                    .accessibilityLabel("Text shadow")
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Actions

    private func pickPhoto(for slot: Int) {
        targetSlot = slot
        slotPickerItem = nil
        showSlotPicker = true
    }

    private func loadSlot(_ item: PhotosPickerItem?) async {
        guard let item, let slot = targetSlot else { return }
        if let data = try? await item.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
            design.assign(ui, to: slot)
        }
    }

    @MainActor private func export() {
        let exportSize = exportPixelSize()
        let canvas = DesignCanvas(design: design, size: exportSize, interactive: false, renderText: true)
            .frame(width: exportSize.width, height: exportSize.height)
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(exportSize)
        guard let ui = renderer.uiImage else { flash("Couldn’t export"); return }
        UIImageWriteToSavedPhotosAlbum(ui, nil, nil, nil)
        let thumb = ImageEngineThumb.thumbnail(ui, maxDimension: 500)
        context.insert(Creation(image: thumb, templateName: template.name, category: template.category))
        try? context.save()
        Haptics.success()
        exportResult = ExportResult(image: ui)
    }

    private func exportPixelSize() -> CGSize {
        let w: CGFloat = 1080
        return CGSize(width: w, height: (w / template.aspect).rounded())
    }

    private func flash(_ text: String) {
        withAnimation { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { if toast == text { toast = nil } }
        }
    }
}

/// Small JPEG thumbnail helper for saved creations.
enum ImageEngineThumb {
    static func thumbnail(_ image: UIImage, maxDimension: CGFloat) -> Data {
        let size = image.size
        let longest = max(size.width, size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
        return resized.jpegData(compressionQuality: 0.8) ?? Data()
    }
}

struct ExportResultSheet: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 18) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 44)).foregroundStyle(Theme.good)
                        .padding(.top, 20)
                    Text("Saved to your Photos").font(Theme.rounded(19, .bold)).foregroundStyle(Theme.ink)
                    Image(uiImage: image).resizable().scaledToFit()
                        .frame(maxHeight: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                    ShareLink(item: Image(uiImage: image), preview: SharePreview("My Montage", image: Image(uiImage: image))) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(Theme.rounded(17, .bold)).frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Exported")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
