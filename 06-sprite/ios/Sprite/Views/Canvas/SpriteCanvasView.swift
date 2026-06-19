import SwiftUI

struct SpriteCanvasView: View {
    @Bindable var vm: CanvasViewModel
    @Query private var allPrefs: [SpritePrefs]
    @Environment(\.modelContext) private var context

    private var prefs: SpritePrefs {
        if let p = allPrefs.first { return p }
        let p = SpritePrefs(); context.insert(p); return p
    }

    @State private var lastDragIndex: Int? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                toolBar
                canvasArea
                paletteBar
            }
            .navigationTitle(vm.artwork.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button { vm.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                        .disabled(vm.undoStack.isEmpty)
                    Button { vm.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                        .disabled(vm.redoStack.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { exportArt() } label: { Image(systemName: "square.and.arrow.up") }
                }
            }
        }
    }

    private var toolBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(SpriteTool.allCases, id: \.self) { tool in
                    Button {
                        vm.selectedTool = tool
                        if prefs.hapticsEnabled { UISelectionFeedbackGenerator().selectionChanged() }
                    } label: {
                        Image(systemName: tool.rawValue)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(vm.selectedTool == tool ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundStyle(vm.selectedTool == tool ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityLabel(tool.rawValue)
                }

                Toggle("Grid", isOn: Binding(get: { prefs.showGrid }, set: { prefs.showGrid = $0 }))
                    .toggleStyle(.button)
                    .font(.caption.weight(.semibold))
                    .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private var canvasArea: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let w = vm.artwork.width
            let cellSize = side / CGFloat(w)
            Canvas { ctx, size in
                let h = vm.artwork.height
                for r in 0..<h {
                    for c in 0..<w {
                        let idx = r * w + c
                        let rect = CGRect(x: CGFloat(c) * cellSize, y: CGFloat(r) * cellSize, width: cellSize, height: cellSize)
                        let pxColor = vm.pixels[idx]
                        if pxColor == 0 {
                            // Transparent — checkerboard
                            let light = (r + c) % 2 == 0
                            ctx.fill(Path(rect), with: .color(light ? Color(.systemGray5) : Color(.systemGray4)))
                        } else {
                            let r2 = Double((pxColor >> 16) & 0xFF) / 255
                            let g = Double((pxColor >> 8) & 0xFF) / 255
                            let b = Double(pxColor & 0xFF) / 255
                            ctx.fill(Path(rect), with: .color(Color(red: r2, green: g, blue: b)))
                        }
                        if prefs.showGrid && cellSize > 4 {
                            ctx.stroke(Path(rect), with: .color(.black.opacity(0.08)), lineWidth: 0.5)
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let c = Int(val.location.x / cellSize)
                        let r = Int(val.location.y / cellSize)
                        let idx = r * w + c
                        if idx != lastDragIndex && r >= 0 && r < vm.artwork.height && c >= 0 && c < w {
                            lastDragIndex = idx
                            if val.startLocation == val.location {
                                vm.tap(at: idx)
                            } else {
                                vm.drag(at: idx)
                            }
                            if prefs.hapticsEnabled && vm.selectedTool != .eyedropper {
                                UISelectionFeedbackGenerator().selectionChanged()
                            }
                        }
                    }
                    .onEnded { _ in
                        lastDragIndex = nil
                        vm.endDrag()
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Color(.systemGray6))
    }

    private var paletteBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.palette.indices, id: \.self) { i in
                    let hex = vm.palette[i]
                    Circle()
                        .fill(Color(hexStr: hex))
                        .overlay(Circle().stroke(i == vm.selectedColorIndex ? Color.white : Color.clear, lineWidth: 3))
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        .frame(width: 38, height: 38)
                        .scaleEffect(i == vm.selectedColorIndex ? 1.2 : 1)
                        .onTapGesture { vm.selectedColorIndex = i }
                        .accessibilityLabel("Color \(i + 1): \(hex)")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(.bar)
    }

    private func exportArt() {
        guard let img = vm.renderImage() else { return }
        let scale: CGFloat = max(1, CGFloat(512 / max(vm.artwork.width, vm.artwork.height)))
        let size = CGSize(width: CGFloat(vm.artwork.width) * scale, height: CGFloat(vm.artwork.height) * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let scaled = renderer.image { _ in
            img.draw(in: CGRect(origin: .zero, size: size))
        }
        UIImageWriteToSavedPhotosAlbum(scaled, nil, nil, nil)
        if prefs.hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    }
}

extension Color {
    init(hexStr: String) {
        let h = hexStr.hasPrefix("#") ? String(hexStr.dropFirst()) : hexStr
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        self.init(red: Double((val >> 16) & 0xFF) / 255, green: Double((val >> 8) & 0xFF) / 255, blue: Double(val & 0xFF) / 255)
    }
}
