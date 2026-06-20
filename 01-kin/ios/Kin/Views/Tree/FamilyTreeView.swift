import SwiftUI
import SwiftData

struct FamilyTreeView: View {
    @Query(sort: \Person.lastName) private var people: [Person]
    @Query private var settingsQuery: [KinSettings]
    @State private var showAdd = false
    @State private var selectedPerson: Person?

    private var settings: KinSettings? { settingsQuery.first }

    var roots: [Person] {
        // People with no parents in our system
        people.filter { $0.parents.isEmpty }
    }

    var body: some View {
        NavigationStack {
            Group {
                if people.isEmpty {
                    emptyState
                } else {
                    ScrollView([.horizontal, .vertical]) {
                        TreeCanvasView(roots: roots, selectedPerson: $selectedPerson)
                            .padding(40)
                    }
                    .clipped()
                }
            }
            .navigationTitle(settings?.familyName ?? "Family Tree")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                    .accessibilityLabel("Add person")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddEditPersonView(person: nil)
            }
            .sheet(item: $selectedPerson) { p in
                NavigationStack {
                    PersonDetailView(person: p)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tree.fill")
                .font(.system(size: 72))
                .foregroundColor(KinTheme.accent)
                .accessibilityHidden(true)
            Text("Your Tree is Empty")
                .font(Font.kinTitle)
                .foregroundColor(KinTheme.label)
            Text("Add yourself and your relatives\nto watch the tree grow.")
                .font(Font.kinBody)
                .foregroundColor(KinTheme.secondaryLabel)
                .multilineTextAlignment(.center)
            Button("Add First Person") { showAdd = true }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Add first person to tree")
        }
        .padding()
    }
}

// A canvas that lays out the family tree
struct TreeCanvasView: View {
    let roots: [Person]
    @Binding var selectedPerson: Person?

    var body: some View {
        let layout = TreeLayout.compute(roots: roots)

        ZStack(alignment: .topLeading) {
            // Draw connector lines
            ForEach(layout.edges, id: \.id) { edge in
                ConnectorLine(from: edge.from, to: edge.to)
                    .stroke(KinTheme.sepia.opacity(0.6), lineWidth: 2)
            }

            // Draw person nodes
            ForEach(layout.nodes, id: \.person.id) { node in
                PersonNodeView(person: node.person, position: node.position)
                    .onTapGesture { selectedPerson = node.person }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("View \(node.person.fullName)'s profile")
            }
        }
        .frame(width: layout.totalWidth, height: layout.totalHeight)
    }
}

struct ConnectorLine: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        let mid = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
        path.addCurve(
            to: to,
            control1: CGPoint(x: from.x, y: mid.y),
            control2: CGPoint(x: to.x, y: mid.y)
        )
        return path
    }
}

struct PersonNodeView: View {
    let person: Person
    let position: CGPoint

    private let nodeW: CGFloat = 110
    private let nodeH: CGFloat = 70

    var body: some View {
        VStack(spacing: 4) {
            PersonAvatarView(person: person, size: 36)
            Text(person.firstName)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundColor(KinTheme.label)
                .lineLimit(1)
            if !person.lastName.isEmpty {
                Text(person.lastName)
                    .font(.system(size: 10, design: .serif))
                    .foregroundColor(KinTheme.secondaryLabel)
                    .lineLimit(1)
            }
        }
        .frame(width: nodeW, height: nodeH)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: KinTheme.cardShadow, radius: 4, y: 2)
        )
        .position(position)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(person.fullName)
    }
}

// Simple hierarchical layout engine
struct TreeLayout {
    struct Node { let person: Person; let position: CGPoint }
    struct Edge { let id = UUID(); let from: CGPoint; let to: CGPoint }

    let nodes: [Node]
    let edges: [Edge]
    let totalWidth: CGFloat
    let totalHeight: CGFloat

    static func compute(roots: [Person]) -> TreeLayout {
        let nodeW: CGFloat = 110
        let nodeH: CGFloat = 70
        let hGap: CGFloat = 24
        let vGap: CGFloat = 56

        var nodes: [Node] = []
        var edges: [Edge] = []
        var visited = Set<UUID>()

        func layoutSubtree(person: Person, x: inout CGFloat, level: Int) -> CGFloat {
            if visited.contains(person.id) { return x }
            visited.insert(person.id)

            let children = person.children.filter { !visited.contains($0.id) }
            var childCenters: [CGFloat] = []

            for child in children {
                let start = x
                let center = layoutSubtree(person: child, x: &x, level: level + 1)
                childCenters.append(center)
                _ = start
            }

            let selfX: CGFloat
            if childCenters.isEmpty {
                selfX = x + nodeW / 2
                x += nodeW + hGap
            } else {
                selfX = (childCenters.first! + childCenters.last!) / 2
            }

            let selfY = CGFloat(level) * (nodeH + vGap) + nodeH / 2
            let pos = CGPoint(x: selfX, y: selfY)
            nodes.append(Node(person: person, position: pos))

            for (i, child) in children.enumerated() {
                if let childNode = nodes.last(where: { $0.person.id == child.id }) {
                    let childCenter = childCenters[i]
                    let childY = CGFloat(level + 1) * (nodeH + vGap) + nodeH / 2 - nodeH / 2
                    edges.append(Edge(
                        from: CGPoint(x: selfX, y: selfY + nodeH / 2),
                        to: CGPoint(x: childCenter, y: childY)
                    ))
                    _ = childNode
                }
            }
            return selfX
        }

        var globalX: CGFloat = nodeW / 2
        for root in roots {
            _ = layoutSubtree(person: root, x: &globalX, level: 0)
            globalX += hGap * 2
        }

        let maxX = (nodes.map { $0.position.x }.max() ?? 0) + nodeW / 2 + 40
        let maxY = (nodes.map { $0.position.y }.max() ?? 0) + nodeH / 2 + 40

        return TreeLayout(nodes: nodes, edges: edges, totalWidth: max(maxX, 300), totalHeight: max(maxY, 200))
    }
}
