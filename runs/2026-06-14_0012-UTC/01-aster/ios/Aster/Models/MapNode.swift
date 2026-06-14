import Foundation
import SwiftData

/// A single node in a mind map's tree. Self-referential: the root has `parent == nil`.
@Model
final class MapNode {
    var id: UUID = UUID()
    var text: String = ""
    var note: String = ""
    var colorTag: Int = 0          // index into NodePalette (0...5)
    var isCollapsed: Bool = false
    var order: Int = 0             // ordering among siblings
    var createdAt: Date = Date()
    var depth: Int = 0            // 0 == root

    var parent: MapNode?

    @Relationship(deleteRule: .cascade, inverse: \MapNode.parent)
    var children: [MapNode] = []

    var map: MindMap?

    init(text: String = "",
         note: String = "",
         colorTag: Int = 0,
         order: Int = 0,
         depth: Int = 0,
         parent: MapNode? = nil) {
        self.id = UUID()
        self.text = text
        self.note = note
        self.colorTag = max(0, min(5, colorTag))
        self.isCollapsed = false
        self.order = order
        self.createdAt = Date()
        self.depth = depth
        self.parent = parent
    }

    // MARK: - Derived

    var palette: NodePalette { NodePalette.from(colorTag) }

    var isRoot: Bool { parent == nil }

    /// Children sorted by their `order` (stable, deterministic).
    var sortedChildren: [MapNode] {
        children.sorted { $0.order < $1.order }
    }

    /// Total number of descendant nodes (excluding self).
    var descendantCount: Int {
        children.reduce(0) { $0 + 1 + $1.descendantCount }
    }

    // MARK: - Mutations

    /// Append a new child node and return it.
    @discardableResult
    func addChild(text: String = "", colorTag: Int? = nil) -> MapNode {
        let nextOrder = (children.map { $0.order }.max() ?? -1) + 1
        let child = MapNode(text: text,
                            colorTag: colorTag ?? self.colorTag,
                            order: nextOrder,
                            depth: depth + 1,
                            parent: self)
        child.map = map
        children.append(child)
        return child
    }

    /// Re-number siblings so `order` is contiguous starting at 0.
    func normalizeChildOrder() {
        let sorted = children.sorted { $0.order < $1.order }
        for (idx, node) in sorted.enumerated() {
            node.order = idx
        }
    }

    /// Recompute `depth` for this node and its whole subtree from the parent chain.
    func refreshDepth() {
        depth = (parent?.depth ?? -1) + 1
        for child in children {
            child.refreshDepth()
        }
    }
}
