import SwiftUI

/// Renders the collage. `interactive` enables cell selection and pan/zoom of the
/// selected cell. The same view (interactive == false) is fed to ImageRenderer
/// for a clean, watermark-free export.
struct CollageCanvas: View {
    let model: EditorModel
    var interactive: Bool = true

    private var project: CollageProject { model.project }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack(alignment: .topLeading) {
                Color(hex: UInt32(project.backgroundHex))
                ForEach(Array(project.template.frames.enumerated()), id: \.offset) { idx, frame in
                    if idx < model.cells.count {
                        cellView(model.cells[idx], frame: frame, canvas: size)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .aspectRatio(project.aspect.ratio, contentMode: .fit)
    }

    private func cellView(_ cell: CollageCell, frame: CGRect, canvas: CGSize) -> some View {
        let inset = project.spacing / 2
        let w = frame.width * canvas.width - inset * 2
        let h = frame.height * canvas.height - inset * 2
        let x = frame.minX * canvas.width + inset
        let y = frame.minY * canvas.height + inset
        let selected = interactive && model.selectedCellID == cell.id

        return EditableCell(model: model, cell: cell,
                            cellSize: CGSize(width: max(1, w), height: max(1, h)),
                            cornerRadius: project.cornerRadius,
                            borderWidth: project.borderWidth,
                            interactive: interactive,
                            selected: selected)
            .frame(width: max(1, w), height: max(1, h))
            .offset(x: x, y: y)
    }
}

/// A single cell: aspect-fills its image with pan & zoom, or shows an "add"
/// placeholder. Holds live gesture state and commits to the model on end.
struct EditableCell: View {
    let model: EditorModel
    let cell: CollageCell
    let cellSize: CGSize
    let cornerRadius: Double
    let borderWidth: Double
    let interactive: Bool
    let selected: Bool

    @GestureState private var dragTranslation: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1.0

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }

    @ViewBuilder
    var body: some View {
        if interactive && selected && cell.imageFile != nil {
            visual
                .contentShape(Rectangle())
                .onTapGesture { select() }
                .gesture(combinedGesture)
        } else if interactive {
            visual
                .contentShape(Rectangle())
                .onTapGesture { select() }
        } else {
            visual
        }
    }

    private func select() {
        model.selectedCellID = cell.id
        Haptics.selection()
    }

    private var visual: some View {
        ZStack {
            if let image = model.displayImage(for: cell) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cellSize.width, height: cellSize.height)
                    .scaleEffect(currentScale)
                    .offset(x: currentOffsetX, y: currentOffsetY)
                    .frame(width: cellSize.width, height: cellSize.height)
                    .clipped()
            } else {
                ZStack {
                    Rectangle().fill(Brand.dynamic(0xE3E5EC, 0x2A2D35))
                    VStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: min(cellSize.width, cellSize.height) * 0.18))
                            .foregroundStyle(Brand.text3)
                        if min(cellSize.width, cellSize.height) > 70 {
                            Text("Add photo").font(.caption2).foregroundStyle(Brand.text3)
                        }
                    }
                }
            }
        }
        .frame(width: cellSize.width, height: cellSize.height)
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(selected ? Brand.dynamic(0xB0653E, 0xE0A878) : Color.clear,
                               lineWidth: 3)
        }
        .overlay {
            if borderWidth > 0 {
                shape.strokeBorder(Color(hex: UInt32(model.project.backgroundHex)), lineWidth: borderWidth)
            }
        }
    }

    private var currentScale: CGFloat {
        selected ? cell.scale * pinch : cell.scale
    }
    private var currentOffsetX: CGFloat {
        let base = cell.offsetX * cellSize.width
        return selected ? base + dragTranslation.width : base
    }
    private var currentOffsetY: CGFloat {
        let base = cell.offsetY * cellSize.height
        return selected ? base + dragTranslation.height : base
    }

    private var combinedGesture: some Gesture {
        let drag = DragGesture()
            .updating($dragTranslation) { value, state, _ in state = value.translation }
            .onEnded { value in
                let nx = cell.offsetX + Double(value.translation.width / cellSize.width)
                let ny = cell.offsetY + Double(value.translation.height / cellSize.height)
                model.updateTransform(cell, scale: cell.scale, offsetX: nx, offsetY: ny)
                model.commitTransform()
            }
        let magnify = MagnificationGesture()
            .updating($pinch) { value, state, _ in state = value }
            .onEnded { value in
                model.updateTransform(cell, scale: cell.scale * Double(value),
                                      offsetX: cell.offsetX, offsetY: cell.offsetY)
                model.commitTransform()
            }
        return drag.simultaneously(with: magnify)
    }
}
