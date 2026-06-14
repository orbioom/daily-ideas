import Foundation
import SwiftData

/// A starter template that, when chosen, builds a fully-populated `MindMap`.
struct MapTemplate: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let theme: MapTheme
    /// Tree spec: root text + nested children (text, colorTag, children…).
    let spec: NodeSpec

    /// Materialize this template into the given context and return the new map.
    @discardableResult
    func build(in context: ModelContext) -> MindMap {
        let map = MindMap(title: title, theme: theme)
        context.insert(map)
        let root = MapNode(text: spec.text, colorTag: spec.colorTag, order: 0, depth: 0)
        root.map = map
        context.insert(root)
        map.nodes.append(root)
        attach(children: spec.children, to: root, map: map, context: context)
        root.refreshDepth()
        map.touch()
        return map
    }

    private func attach(children: [NodeSpec],
                        to parent: MapNode,
                        map: MindMap,
                        context: ModelContext) {
        for (idx, child) in children.enumerated() {
            let node = MapNode(text: child.text,
                               colorTag: child.colorTag,
                               order: idx,
                               depth: parent.depth + 1,
                               parent: parent)
            node.note = child.note
            node.map = map
            context.insert(node)
            parent.children.append(node)
            map.nodes.append(node)
            if !child.children.isEmpty {
                attach(children: child.children, to: node, map: map, context: context)
            }
        }
    }
}

/// Recursive value spec for building a template tree.
struct NodeSpec {
    let text: String
    var note: String = ""
    var colorTag: Int = 0
    var children: [NodeSpec] = []
}

enum MapTemplates {
    static let all: [MapTemplate] = [projectPlan, weeklyReview, brainstorm, decisionTree, bookNotes]

    static let projectPlan = MapTemplate(
        id: "project-plan",
        title: "Project Plan",
        subtitle: "Goals, milestones, tasks & risks",
        symbol: "flag.checkered",
        theme: .dusk,
        spec: NodeSpec(text: "Project Plan", colorTag: 0, children: [
            NodeSpec(text: "Goals", colorTag: 4, children: [
                NodeSpec(text: "Primary outcome"),
                NodeSpec(text: "Success metric")
            ]),
            NodeSpec(text: "Milestones", colorTag: 1, children: [
                NodeSpec(text: "Kickoff"),
                NodeSpec(text: "Beta"),
                NodeSpec(text: "Launch")
            ]),
            NodeSpec(text: "Tasks", colorTag: 2, children: [
                NodeSpec(text: "Research"),
                NodeSpec(text: "Build"),
                NodeSpec(text: "Test")
            ]),
            NodeSpec(text: "Risks", colorTag: 3, children: [
                NodeSpec(text: "Scope creep"),
                NodeSpec(text: "Timeline")
            ])
        ])
    )

    static let weeklyReview = MapTemplate(
        id: "weekly-review",
        title: "Weekly Review",
        subtitle: "Reflect, learn, plan ahead",
        symbol: "calendar",
        theme: .mist,
        spec: NodeSpec(text: "Weekly Review", colorTag: 0, children: [
            NodeSpec(text: "Wins", colorTag: 4, children: [
                NodeSpec(text: "What went well")
            ]),
            NodeSpec(text: "Challenges", colorTag: 3, children: [
                NodeSpec(text: "What was hard")
            ]),
            NodeSpec(text: "Lessons", colorTag: 2, children: [
                NodeSpec(text: "What I learned")
            ]),
            NodeSpec(text: "Next Week", colorTag: 1, children: [
                NodeSpec(text: "Top 3 priorities")
            ])
        ])
    )

    static let brainstorm = MapTemplate(
        id: "brainstorm",
        title: "Brainstorm",
        subtitle: "Diverge wide, then cluster",
        symbol: "sparkles",
        theme: .meadow,
        spec: NodeSpec(text: "Big Idea", colorTag: 0, children: [
            NodeSpec(text: "Theme A", colorTag: 1, children: [
                NodeSpec(text: "Idea"),
                NodeSpec(text: "Idea")
            ]),
            NodeSpec(text: "Theme B", colorTag: 2, children: [
                NodeSpec(text: "Idea"),
                NodeSpec(text: "Idea")
            ]),
            NodeSpec(text: "Theme C", colorTag: 4, children: [
                NodeSpec(text: "Idea")
            ]),
            NodeSpec(text: "Wild Cards", colorTag: 3, children: [
                NodeSpec(text: "What if…?")
            ])
        ])
    )

    static let decisionTree = MapTemplate(
        id: "decision-tree",
        title: "Decision Tree",
        subtitle: "Weigh options & outcomes",
        symbol: "arrow.triangle.branch",
        theme: .slate,
        spec: NodeSpec(text: "The Decision", colorTag: 0, children: [
            NodeSpec(text: "Option A", colorTag: 4, children: [
                NodeSpec(text: "Pros", colorTag: 4),
                NodeSpec(text: "Cons", colorTag: 3)
            ]),
            NodeSpec(text: "Option B", colorTag: 1, children: [
                NodeSpec(text: "Pros", colorTag: 4),
                NodeSpec(text: "Cons", colorTag: 3)
            ]),
            NodeSpec(text: "Criteria", colorTag: 5, children: [
                NodeSpec(text: "Cost"),
                NodeSpec(text: "Time"),
                NodeSpec(text: "Impact")
            ])
        ])
    )

    static let bookNotes = MapTemplate(
        id: "book-notes",
        title: "Book Notes",
        subtitle: "Capture key ideas & quotes",
        symbol: "book",
        theme: .dusk,
        spec: NodeSpec(text: "Book Title", colorTag: 0, children: [
            NodeSpec(text: "Big Ideas", colorTag: 1, children: [
                NodeSpec(text: "Idea one")
            ]),
            NodeSpec(text: "Key Quotes", colorTag: 2, children: [
                NodeSpec(text: "\u{201C}…\u{201D}")
            ]),
            NodeSpec(text: "Chapters", colorTag: 5, children: [
                NodeSpec(text: "Chapter 1")
            ]),
            NodeSpec(text: "Takeaways", colorTag: 4, children: [
                NodeSpec(text: "Apply this")
            ])
        ])
    )
}
