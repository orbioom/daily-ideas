import SwiftUI
import SwiftData
import PhotosUI

struct EditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var model: EditorModel
    @State private var tool: Tool = .photo
    @State private var pickerItem: PhotosPickerItem?
    @State private var exportImage: UIImage?
    @State private var showExport = false
    @State private var saveMessage: String?
    @State private var loadingPhoto = false
    @AppStorage("exportSize") private var exportSize = 2000

    enum Tool: String, CaseIterable, Identifiable {
        case photo, layout, filter, adjust
        var id: String { rawValue }
        var icon: String {
            switch self { case .photo: "photo"; case .layout: "square.grid.2x2"
            case .filter: "camera.filters"; case .adjust: "slider.horizontal.3" }
        }
        var label: String { rawValue.capitalized }
    }

    init(project: CollageProject, context: ModelContext) {
        _model = State(initialValue: EditorModel(project: project, context: context))
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                CollageCanvas(model: model, interactive: true)
                    .id(model.revision)
                    .padding(16)
                    .frame(maxHeight: .infinity)
                toolPanel
                toolBar
            }

            if let msg = saveMessage { saveToast(msg) }
        }
        .navigationTitle(model.project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { export() } label: { Label("Export", systemImage: "square.and.arrow.up") }
                    .disabled(model.project.filledCount == 0)
            }
        }
        .sheet(isPresented: $showExport) {
            if let img = exportImage { ExportSheet(image: img, onSaved: { flash("Saved to Photos") }) }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await loadPicked(item) }
        }
    }

    // MARK: - Tool panel

    @ViewBuilder
    private var toolPanel: some View {
        Group {
            switch tool {
            case .photo: photoPanel
            case .layout: layoutPanel
            case .filter: filterPanel
            case .adjust: adjustPanel
            }
        }
        .frame(height: 132)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    private var photoPanel: some View {
        VStack(spacing: 10) {
            if let cell = model.selectedCell {
                Text(cell.imageFile == nil ? "Tap a cell, then add a photo" : "Drag to reposition · pinch to zoom")
                    .font(.caption).foregroundStyle(Brand.text2)
                HStack(spacing: 12) {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(cell.imageFile == nil ? "Add photo" : "Replace",
                              systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                    .buttonStyle(InkButtonStyle())
                    .disabled(loadingPhoto)

                    if cell.imageFile != nil {
                        Button {
                            model.removeImage(from: cell)
                        } label: {
                            Label("Remove", systemImage: "trash").frame(maxWidth: .infinity).padding(.vertical, 12)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                }
                if loadingPhoto { ProgressView().tint(Brand.text) }
            } else {
                Text("Select a cell to begin").font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    private var layoutPanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Templates.all) { t in
                    Button { model.changeTemplate(to: t) } label: {
                        VStack(spacing: 6) {
                            TemplateThumb(template: t,
                                          selected: model.project.templateID == t.id)
                                .frame(width: 56, height: 56)
                            Text(t.name).font(.caption2)
                                .foregroundStyle(model.project.templateID == t.id ? Brand.text : Brand.text3)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Layout \(t.name), \(t.cellCount) cells")
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
        }
    }

    private var filterPanel: some View {
        Group {
            if let cell = model.selectedCell, cell.imageFile != nil, let original = ImageStore.load(cell.imageFile) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(PhotoFilter.allCases) { f in
                            Button { model.setFilter(f, for: cell) } label: {
                                VStack(spacing: 5) {
                                    FilterThumb(image: original, filter: f)
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(cell.filter == f ? Brand.dynamic(0xB0653E, 0xE0A878) : .clear, lineWidth: 2.5))
                                    Text(f.label).font(.caption2)
                                        .foregroundStyle(cell.filter == f ? Brand.text : Brand.text3)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Filter \(f.label)")
                        }
                    }
                    .padding(.horizontal, 18).padding(.vertical, 14)
                }
            } else {
                Text("Add a photo to apply a filter")
                    .font(.subheadline).foregroundStyle(Brand.text2).padding()
            }
        }
    }

    private var adjustPanel: some View {
        ScrollView {
            VStack(spacing: 12) {
                slider("Spacing", value: bindingSpacing, range: 0...30)
                slider("Corners", value: bindingCorner, range: 0...40)
                slider("Border", value: bindingBorder, range: 0...24)
                HStack(spacing: 8) {
                    ForEach(CanvasAspect.allCases) { a in
                        Button { model.project.aspect = a; model.save() } label: {
                            Text(a.label).font(.caption.weight(.medium))
                                .padding(.horizontal, 10).padding(.vertical, 7)
                                .foregroundStyle(model.project.aspect == a ? .white : Brand.text2)
                                .background(model.project.aspect == a ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(.ultraThinMaterial),
                                            in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack(spacing: 10) {
                    ForEach(Self.bgColors, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().strokeBorder(
                                model.project.backgroundHex == Int(hex) ? Brand.text : Brand.hairline,
                                lineWidth: model.project.backgroundHex == Int(hex) ? 2.5 : 1))
                            .onTapGesture { model.project.backgroundHex = Int(hex); model.save(); Haptics.selection() }
                            .accessibilityLabel("Background color")
                    }
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 12)
        }
    }

    static let bgColors: [UInt32] = [0xFFFFFF, 0x000000, 0xF2EFE9, 0x1B1D2A, 0xEAD7C2, 0xCBD8D2, 0xE7C9CE, 0xC9CEE7]

    private func slider(_ label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(Brand.text2).frame(width: 64, alignment: .leading)
            Slider(value: value, in: range) { editing in if !editing { model.save() } }
                .tint(Brand.dynamic(0xB0653E, 0xE0A878))
            Text("\(Int(value.wrappedValue))").font(Brand.mono(13, weight: .medium))
                .foregroundStyle(Brand.text3).frame(width: 30, alignment: .trailing)
        }
    }

    private var bindingSpacing: Binding<Double> {
        Binding(get: { model.project.spacing }, set: { model.project.spacing = $0; model.revision += 1 })
    }
    private var bindingCorner: Binding<Double> {
        Binding(get: { model.project.cornerRadius }, set: { model.project.cornerRadius = $0; model.revision += 1 })
    }
    private var bindingBorder: Binding<Double> {
        Binding(get: { model.project.borderWidth }, set: { model.project.borderWidth = $0; model.revision += 1 })
    }

    // MARK: - Tool bar

    private var toolBar: some View {
        HStack {
            ForEach(Tool.allCases) { t in
                Button { withAnimation(Brand.ease(0.2)) { tool = t }; Haptics.selection() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: t.icon).font(.title3)
                        Text(t.label).font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(tool == t ? Brand.dynamic(0xB0653E, 0xE0A878) : Brand.text3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(t.label)
            }
        }
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func saveToast(_ msg: String) -> some View {
        VStack {
            Spacer()
            Label(msg, systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Brand.live, in: Capsule())
                .padding(.bottom, 90)
        }
        .transition(.opacity)
    }

    // MARK: - Actions

    private func loadPicked(_ item: PhotosPickerItem) async {
        guard let cell = model.selectedCell else { return }
        await MainActor.run { loadingPhoto = true }
        defer { Task { @MainActor in loadingPhoto = false; pickerItem = nil } }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run {
                model.setImage(image, for: cell)
                tool = .photo
                Haptics.success()
            }
        }
    }

    private func export() {
        let img = Exporter.render(model: model, longSide: CGFloat(exportSize))
        if let img {
            exportImage = img
            // Save a thumbnail for the gallery.
            if let thumb = ImageStore.saveThumbnail(img) {
                ImageStore.delete(model.project.thumbnailFile)
                model.project.thumbnailFile = thumb
                model.save()
            }
            showExport = true
        } else {
            flash("Couldn't render — try again")
        }
    }

    private func flash(_ msg: String) {
        withAnimation { saveMessage = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { if saveMessage == msg { saveMessage = nil } }
        }
    }
}
