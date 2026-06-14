import Foundation
import SwiftData

/// A single mind map document: a title plus a tree of `MapNode`s (one root).
@Model
final class MindMap {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    /// Raw value of `MapTheme` (stored as String per SwiftData guidance).
    var themeRaw: String = MapTheme.mist.rawValue

    @Relationship(deleteRule: .cascade, inverse: \MapNode.map)
    var nodes: [MapNode] = []

    init(title: String = "",
         theme: MapTheme = .mist) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.themeRaw = theme.rawValue
    }

    // MARK: - Derived

    var theme: MapTheme {
        get { MapTheme.from(themeRaw) }
        set { themeRaw = newValue.rawValue }
    }

    /// The root node (parent == nil). If somehow missing, returns nil.
    var root: MapNode? {
        nodes.first(where: { $0.parent == nil })
    }

    /// Total node count (whole tree, including root).
    var nodeCount: Int { nodes.count }

    // MARK: - Lifecycle helpers

    func touch() {
        updatedAt = Date()
    }

    /// Ensure a root node exists; create one titled from the map if absent. Returns the root.
    @discardableResult
    func ensureRoot(context: ModelContext) -> MapNode {
        if let existing = root { return existing }
        let r = MapNode(text: title.isEmpty ? "Central Idea" : title,
                        colorTag: 0,
                        order: 0,
                        depth: 0,
                        parent: nil)
        r.map = self
        context.insert(r)
        nodes.append(r)
        return r
    }
}
