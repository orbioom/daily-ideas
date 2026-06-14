import Foundation
import SwiftData
import SwiftUI

/// Encapsulates mutation logic on a single map's tree so the Canvas and Outline
/// share identical, well-guarded editing behaviour. Pure model operations; views
/// own selection state.
@MainActor
final class MapEditor {
    let map: MindMap
    let context: ModelContext

    init(map: MindMap, context: ModelContext) {
        self.map = map
        self.context = context
    }

    // MARK: - Creation

    /// Add a child to `parent` and return it.
    @discardableResult
    func addChild(to parent: MapNode, text: String = "") -> MapNode {
        let nextOrder = (parent.children.map { $0.order }.max() ?? -1) + 1
        let child = MapNode(text: text,
                            colorTag: parent.colorTag,
                            order: nextOrder,
                            depth: parent.depth + 1,
                            parent: parent)
        child.map = map
        context.insert(child)
        parent.children.append(child)
        map.nodes.append(child)
        parent.isCollapsed = false
        map.touch()
        return child
    }

    /// Add a sibling after `node`. Root has no siblings, so this falls back to a child.
    @discardableResult
    func addSibling(to node: MapNode, text: String = "") -> MapNode {
        guard let parent = node.parent else {
            return addChild(to: node, text: text)
        }
        let sibling = MapNode(text: text,
                              colorTag: node.colorTag,
                              order: node.order + 1,
                              depth: node.depth,
                              parent: parent)
        sibling.map = map
        // Shift later siblings to keep order unique.
        for s in parent.children where s.order > node.order {
            s.order += 1
        }
        context.insert(sibling)
        parent.children.append(sibling)
        map.nodes.append(sibling)
        map.touch()
        return sibling
    }

    // MARK: - Editing

    func setText(_ text: String, on node: MapNode) {
        node.text = text
        map.touch()
    }

    func setNote(_ note: String, on node: MapNode) {
        node.note = note
        map.touch()
    }

    func setColor(_ tag: Int, on node: MapNode) {
        node.colorTag = max(0, min(5, tag))
        map.touch()
    }

    func toggleCollapse(_ node: MapNode) {
        // Leaves can't collapse.
        guard !node.children.isEmpty else { return }
        node.isCollapsed.toggle()
        map.touch()
    }

    // MARK: - Reordering

    /// Move a node up or down among its siblings (delta -1 / +1). Returns whether it moved.
    @discardableResult
    func move(_ node: MapNode, by delta: Int) -> Bool {
        guard let parent = node.parent else { return false }
        let sibs = parent.children.sorted { $0.order < $1.order }
        guard let idx = sibs.firstIndex(where: { $0.id == node.id }) else { return false }
        let target = idx + delta
        guard target >= 0, target < sibs.count else { return false }
        // Swap orders.
        let other = sibs[target]
        let tmp = node.order
        node.order = other.order
        other.order = tmp
        parent.normalizeChildOrder()
        map.touch()
        return true
    }

    /// Indent: make `node` a child of its preceding sibling. Returns success.
    @discardableResult
    func indent(_ node: MapNode) -> Bool {
        guard let parent = node.parent else { return false }
        let sibs = parent.children.sorted { $0.order < $1.order }
        guard let idx = sibs.firstIndex(where: { $0.id == node.id }), idx > 0 else { return false }
        let newParent = sibs[idx - 1]
        detach(node, from: parent)
        node.parent = newParent
        node.order = (newParent.children.map { $0.order }.max() ?? -1) + 1
        newParent.children.append(node)
        newParent.isCollapsed = false
        node.refreshDepth()
        map.touch()
        return true
    }

    /// Outdent: make `node` a sibling of its parent (one level up). Returns success.
    @discardableResult
    func outdent(_ node: MapNode) -> Bool {
        guard let parent = node.parent, let grand = parent.parent else { return false }
        detach(node, from: parent)
        node.parent = grand
        node.order = parent.order + 1
        for s in grand.children where s.order > parent.order {
            s.order += 1
        }
        grand.children.append(node)
        node.refreshDepth()
        grand.normalizeChildOrder()
        map.touch()
        return true
    }

    private func detach(_ node: MapNode, from parent: MapNode) {
        parent.children.removeAll { $0.id == node.id }
        parent.normalizeChildOrder()
    }

    // MARK: - Deletion

    /// Delete a node and its whole subtree. The root cannot be deleted (returns false).
    @discardableResult
    func deleteSubtree(_ node: MapNode) -> Bool {
        guard let parent = node.parent else { return false } // can't delete root
        // Gather subtree ids so we can prune map.nodes too.
        var ids: Set<UUID> = []
        func collect(_ n: MapNode) {
            ids.insert(n.id)
            for c in n.children { collect(c) }
        }
        collect(node)

        parent.children.removeAll { $0.id == node.id }
        parent.normalizeChildOrder()
        map.nodes.removeAll { ids.contains($0.id) }
        context.delete(node) // cascade removes children
        map.touch()
        return true
    }
}
