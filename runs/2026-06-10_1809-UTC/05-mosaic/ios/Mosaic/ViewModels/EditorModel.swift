import SwiftUI
import SwiftData

/// Owns the editing session: image caches, the selected cell, and the actions
/// that mutate the project. Keeps Core Image work off the render path by caching
/// filtered results per (file, filter).
@Observable
final class EditorModel {
    let project: CollageProject
    private let context: ModelContext

    var selectedCellID: UUID?
    /// Bumped whenever a cached image changes, to nudge dependent views to redraw.
    var revision = 0

    private var originals: [String: UIImage] = [:]
    private var filtered: [String: UIImage] = [:]

    init(project: CollageProject, context: ModelContext) {
        self.project = project
        self.context = context
        self.selectedCellID = project.orderedCells.first?.id
        preload()
    }

    var cells: [CollageCell] { project.orderedCells }

    var selectedCell: CollageCell? {
        cells.first { $0.id == selectedCellID }
    }

    private func preload() {
        for cell in cells {
            if let file = cell.imageFile, originals[file] == nil {
                originals[file] = ImageStore.load(file)
            }
        }
    }

    /// The display (filtered) image for a cell, computed and cached lazily.
    func displayImage(for cell: CollageCell) -> UIImage? {
        guard let file = cell.imageFile else { return nil }
        let original = originals[file] ?? {
            let img = ImageStore.load(file)
            if let img { originals[file] = img }
            return img
        }()
        guard let original else { return nil }
        if cell.filter == .none { return original }
        let key = file + "|" + cell.filterRaw
        if let cached = filtered[key] { return cached }
        let result = FilterEngine.apply(cell.filter, to: original)
        filtered[key] = result
        return result
    }

    // MARK: - Mutations

    func setImage(_ image: UIImage, for cell: CollageCell) {
        if let old = cell.imageFile {
            ImageStore.delete(old)
            originals[old] = nil
            clearFiltered(for: old)
        }
        if let name = ImageStore.save(image) {
            originals[name] = ImageStore.downscale(image)
            cell.imageFile = name
            cell.scale = 1.0; cell.offsetX = 0; cell.offsetY = 0
            cell.filter = .none
            bumpAndSave()
        }
    }

    func removeImage(from cell: CollageCell) {
        if let old = cell.imageFile {
            ImageStore.delete(old)
            originals[old] = nil
            clearFiltered(for: old)
        }
        cell.imageFile = nil
        cell.scale = 1; cell.offsetX = 0; cell.offsetY = 0
        bumpAndSave()
    }

    func setFilter(_ filter: PhotoFilter, for cell: CollageCell) {
        cell.filter = filter
        bumpAndSave()
    }

    func updateTransform(_ cell: CollageCell, scale: Double, offsetX: Double, offsetY: Double) {
        cell.scale = min(4, max(1, scale))
        cell.offsetX = offsetX
        cell.offsetY = offsetY
        revision += 1
    }

    func commitTransform() { save() }

    func changeTemplate(to template: Template) {
        let existing = project.orderedCells
        let needed = template.cellCount
        if existing.count < needed {
            for i in existing.count..<needed {
                let c = CollageCell(order: i)
                c.project = project
                project.cells.append(c)
            }
        } else if existing.count > needed {
            for cell in existing[needed...] {
                ImageStore.delete(cell.imageFile)
                project.cells.removeAll { $0.id == cell.id }
                context.delete(cell)
            }
        }
        project.templateID = template.id
        if selectedCell == nil { selectedCellID = project.orderedCells.first?.id }
        bumpAndSave()
    }

    private func clearFiltered(for file: String) {
        filtered = filtered.filter { !$0.key.hasPrefix(file + "|") }
    }

    private func bumpAndSave() {
        revision += 1
        save()
    }

    func save() {
        project.updatedAt = .now
        try? context.save()
    }
}
