import Foundation
import CoreGraphics

/// Which way the tree fans out.
enum LayoutStyle: String, CaseIterable, Identifiable {
    case tree    // root on the left, children fan to the right in tiers
    case radial  // root at center, descendants on concentric rings

    var id: String { rawValue }
    var name: String { self == .tree ? "Tree" : "Radial" }
    var symbol: String { self == .tree ? "list.bullet.indent" : "circle.hexagongrid" }
}

/// A drawable connector between a parent node and one child.
struct Connector: Identifiable {
    let id: String          // "parentID->childID"
    let from: CGPoint
    let to: CGPoint
    let colorTag: Int       // child's color tag (used to tint the line)
}

/// The full computed geometry for a map.
struct MapLayout {
    var positions: [UUID: CGPoint] = [:]
    var connectors: [Connector] = []
    var sizes: [UUID: CGSize] = [:]
    /// Bounding rect of all node centers (with a small padding margin).
    var bounds: CGRect = .zero

    func position(_ id: UUID) -> CGPoint? { positions[id] }
}

/// A lightweight value snapshot of one node — keeps the pure layout math
/// independent of SwiftData model objects.
struct LayoutNode: Identifiable {
    let id: UUID
    let text: String
    let colorTag: Int
    let depth: Int
    let isCollapsed: Bool
    let order: Int
    let childIDs: [UUID]
    let parentID: UUID?
}

/// Pure, deterministic 2-D layout engine. Given a flattened set of nodes and the
/// chosen style, it computes positions + connectors. Collapsed subtrees are skipped.
///
/// The math is intentionally free of SwiftData / SwiftUI so it is testable and stable.
enum LayoutEngine {

    // Tunable spacing constants.
    static let nodeWidth: CGFloat = 150
    static let nodeHeight: CGFloat = 52
    static let hGap: CGFloat = 64    // horizontal gap between tiers (tree)
    static let vGap: CGFloat = 22    // vertical gap between leaves (tree)
    static let ringGap: CGFloat = 150 // radius increment per depth (radial)
    static let margin: CGFloat = 80

    /// Build the snapshot dictionary the engine consumes from model nodes.
    static func snapshot(root: MapNode) -> (rootID: UUID, nodes: [UUID: LayoutNode]) {
        var map: [UUID: LayoutNode] = [:]
        func walk(_ node: MapNode) {
            let kids = node.sortedChildren
            map[node.id] = LayoutNode(
                id: node.id,
                text: node.text,
                colorTag: node.colorTag,
                depth: node.depth,
                isCollapsed: node.isCollapsed,
                order: node.order,
                childIDs: kids.map { $0.id },
                parentID: node.parent?.id
            )
            for child in kids { walk(child) }
        }
        walk(root)
        return (root.id, map)
    }

    /// Compute geometry. `style` selects tree vs radial.
    static func layout(rootID: UUID,
                       nodes: [UUID: LayoutNode],
                       style: LayoutStyle,
                       sizes: [UUID: CGSize] = [:]) -> MapLayout {
        guard nodes[rootID] != nil else { return MapLayout() }
        switch style {
        case .tree:   return treeLayout(rootID: rootID, nodes: nodes, sizes: sizes)
        case .radial: return radialLayout(rootID: rootID, nodes: nodes, sizes: sizes)
        }
    }

    /// Visible children of a node (none if the node is collapsed).
    private static func visibleChildren(_ id: UUID, _ nodes: [UUID: LayoutNode]) -> [UUID] {
        guard let n = nodes[id], !n.isCollapsed else { return [] }
        return n.childIDs.filter { nodes[$0] != nil }
    }

    // MARK: - Horizontal tree layout

    /// Classic tidy-tree style: each tier shifts right; leaves stack vertically.
    /// We assign each visible node a "leaf slot" (its vertical band) and a tier
    /// (its horizontal column). A node's y is the average of its children's y.
    private static func treeLayout(rootID: UUID,
                                   nodes: [UUID: LayoutNode],
                                   sizes: [UUID: CGSize]) -> MapLayout {
        var result = MapLayout()
        result.sizes = sizes

        // 1. Assign Y by walking visible leaves in order (a running cursor).
        var yCursor: CGFloat = 0
        var yByID: [UUID: CGFloat] = [:]

        func rowHeight(_ id: UUID) -> CGFloat {
            (sizes[id]?.height ?? nodeHeight) + vGap
        }

        func assignY(_ id: UUID) {
            let kids = visibleChildren(id, nodes)
            if kids.isEmpty {
                yByID[id] = yCursor
                yCursor += rowHeight(id)
            } else {
                for k in kids { assignY(k) }
                // Center the parent across the span of its first..last child.
                if let first = kids.first, let last = kids.last,
                   let yf = yByID[first], let yl = yByID[last] {
                    yByID[id] = (yf + yl) / 2
                } else {
                    yByID[id] = yCursor
                    yCursor += rowHeight(id)
                }
            }
        }
        assignY(rootID)

        // 2. Assign X by depth (tier). Column width keys off the widest node per tier.
        var maxWidthByDepth: [Int: CGFloat] = [:]
        for (id, n) in nodes where yByID[id] != nil {
            let w = sizes[id]?.width ?? nodeWidth
            maxWidthByDepth[n.depth] = max(maxWidthByDepth[n.depth] ?? 0, w)
        }
        var xByDepth: [Int: CGFloat] = [0: 0]
        let maxDepth = (yByID.keys.compactMap { nodes[$0]?.depth }.max()) ?? 0
        var running: CGFloat = 0
        for d in 0...max(0, maxDepth) {
            xByDepth[d] = running
            running += (maxWidthByDepth[d] ?? nodeWidth) + hGap
        }

        // 3. Materialize positions for visible nodes.
        var visible: Set<UUID> = []
        func collectVisible(_ id: UUID) {
            visible.insert(id)
            for k in visibleChildren(id, nodes) { collectVisible(k) }
        }
        collectVisible(rootID)

        for id in visible {
            guard let n = nodes[id], let y = yByID[id] else { continue }
            let x = xByDepth[n.depth] ?? CGFloat(n.depth) * (nodeWidth + hGap)
            result.positions[id] = CGPoint(x: x, y: y)
        }

        // 4. Connectors parent -> visible child.
        for id in visible {
            guard let from = result.positions[id] else { continue }
            for k in visibleChildren(id, nodes) {
                guard let to = result.positions[k], let kn = nodes[k] else { continue }
                result.connectors.append(
                    Connector(id: "\(id.uuidString)->\(k.uuidString)",
                              from: from, to: to, colorTag: kn.colorTag)
                )
            }
        }

        result.bounds = computeBounds(result.positions, sizes: sizes)
        return result
    }

    // MARK: - Radial layout

    /// Root at origin; descendants placed on rings by depth. Each node is given an
    /// angular wedge proportional to its visible-leaf count so siblings don't overlap.
    private static func radialLayout(rootID: UUID,
                                     nodes: [UUID: LayoutNode],
                                     sizes: [UUID: CGSize]) -> MapLayout {
        var result = MapLayout()
        result.sizes = sizes
        result.positions[rootID] = .zero

        // Count visible leaves under each node (min 1) to weight angular spans.
        var leafCount: [UUID: Int] = [:]
        func countLeaves(_ id: UUID) -> Int {
            let kids = visibleChildren(id, nodes)
            if kids.isEmpty { leafCount[id] = 1; return 1 }
            let total = kids.reduce(0) { $0 + countLeaves($1) }
            leafCount[id] = max(1, total)
            return leafCount[id] ?? 1
        }
        _ = countLeaves(rootID)

        // Recursively place children across [startAngle, endAngle].
        func place(_ id: UUID, startAngle: Double, endAngle: Double) {
            let kids = visibleChildren(id, nodes)
            guard !kids.isEmpty else { return }
            let totalLeaves = max(1, kids.reduce(0) { $0 + (leafCount[$1] ?? 1) })
            var cursor = startAngle
            for k in kids {
                let share = Double(leafCount[k] ?? 1) / Double(totalLeaves)
                let span = (endAngle - startAngle) * share
                let mid = cursor + span / 2
                let depth = nodes[k]?.depth ?? 1
                let radius = CGFloat(depth) * ringGap
                result.positions[k] = CGPoint(x: radius * CGFloat(cos(mid)),
                                              y: radius * CGFloat(sin(mid)))
                place(k, startAngle: cursor, endAngle: cursor + span)
                cursor += span
            }
        }
        place(rootID, startAngle: 0, endAngle: 2 * Double.pi)

        // Connectors over visible nodes.
        var visible: Set<UUID> = []
        func collectVisible(_ id: UUID) {
            visible.insert(id)
            for k in visibleChildren(id, nodes) { collectVisible(k) }
        }
        collectVisible(rootID)

        for id in visible {
            guard let from = result.positions[id] else { continue }
            for k in visibleChildren(id, nodes) {
                guard let to = result.positions[k], let kn = nodes[k] else { continue }
                result.connectors.append(
                    Connector(id: "\(id.uuidString)->\(k.uuidString)",
                              from: from, to: to, colorTag: kn.colorTag)
                )
            }
        }

        result.bounds = computeBounds(result.positions, sizes: sizes)
        return result
    }

    // MARK: - Bounds

    private static func computeBounds(_ positions: [UUID: CGPoint],
                                      sizes: [UUID: CGSize]) -> CGRect {
        guard !positions.isEmpty else { return .zero }
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        for (id, p) in positions {
            let w = (sizes[id]?.width ?? nodeWidth) / 2
            let h = (sizes[id]?.height ?? nodeHeight) / 2
            minX = min(minX, p.x - w); maxX = max(maxX, p.x + w)
            minY = min(minY, p.y - h); maxY = max(maxY, p.y + h)
        }
        return CGRect(x: minX - margin, y: minY - margin,
                      width: (maxX - minX) + margin * 2,
                      height: (maxY - minY) + margin * 2)
    }
}
