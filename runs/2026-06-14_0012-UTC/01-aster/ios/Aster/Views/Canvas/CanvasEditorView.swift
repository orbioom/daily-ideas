import SwiftUI
import SwiftData

/// The pannable, zoomable mind-map canvas. Renders connectors with `Path` and
/// node bubbles laid out by `LayoutEngine`. A contextual toolbar acts on selection.
struct CanvasEditorView: View {
    @Bindable var map: MindMap
    let editor: MapEditor
    @Binding var layoutStyle: LayoutStyle
    @Binding var selectedNodeID: UUID?
    let openDetail: (UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Pan / zoom state.
    @State private var pan: CGSize = .zero
    @State private var lastPan: CGSize = .zero
    @State private var zoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0

    // Inline edit.
    @State private var editingNodeID: UUID?
    @State private var editingText = ""
    @State private var showColorPicker = false
    @State private var pendingDelete: MapNode?
    @AppStorage("confirmDelete") private var confirmDelete = true

    private let minZoom: CGFloat = 0.4
    private let maxZoom: CGFloat = 2.4

    private var layout: MapLayout {
        guard let root = map.root else { return MapLayout() }
        let snap = LayoutEngine.snapshot(root: root)
        return LayoutEngine.layout(rootID: snap.rootID, nodes: snap.nodes, style: layoutStyle)
    }

    private var selectedNode: MapNode? {
        guard let id = selectedNodeID else { return nil }
        return map.nodes.first(where: { $0.id == id })
    }

    var body: some View {
        GeometryReader { geo in
            let lay = layout
            ZStack {
                // Backdrop dots.
                dotGrid

                canvasContent(lay, size: geo.size)
                    .scaleEffect(zoom)
                    .offset(pan)
                    .gesture(panGesture)
                    .simultaneousGesture(zoomGesture)
            }
            .contentShape(Rectangle())
            .onTapGesture { selectedNodeID = nil }
            .overlay(alignment: .bottom) {
                if selectedNode != nil { contextToolbar }
            }
            .overlay(alignment: .topTrailing) { zoomControls }
            .onAppear { recenter() }
        }
        .alert("Edit node", isPresented: Binding(
            get: { editingNodeID != nil },
            set: { if !$0 { editingNodeID = nil } })) {
            TextField("Text", text: $editingText)
            Button("Cancel", role: .cancel) { editingNodeID = nil }
            Button("Save") { commitEdit() }
        }
        .confirmationDialog("Delete this node and everything under it?",
                            isPresented: Binding(get: { pendingDelete != nil },
                                                 set: { if !$0 { pendingDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { performConfirmedDelete() }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        }
        .sheet(isPresented: $showColorPicker) { colorSheet }
    }

    // MARK: - Canvas content

    private func canvasContent(_ lay: MapLayout, size: CGSize) -> some View {
        // We translate the layout's coordinate space so its bounds sit at origin,
        // then center via the offset/zoom applied by the parent.
        ZStack {
            // Connectors.
            ForEach(lay.connectors) { c in
                ConnectorShape(from: c.from, to: c.to, style: layoutStyle)
                    .stroke(NodePalette.from(c.colorTag).accent.opacity(0.55),
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
            // Nodes.
            ForEach(visibleNodes(lay), id: \.id) { node in
                if let p = lay.positions[node.id] {
                    NodeBubble(
                        node: node,
                        isSelected: node.id == selectedNodeID,
                        isRoot: node.isRoot
                    )
                    .position(p)
                    .onTapGesture {
                        Haptics.selection()
                        selectedNodeID = node.id
                    }
                }
            }
        }
        .frame(width: max(1, lay.bounds.width), height: max(1, lay.bounds.height))
        // Shift so bounds.origin maps to (0,0) of our frame.
        .offset(x: -lay.bounds.minX, y: -lay.bounds.minY)
    }

    private func visibleNodes(_ lay: MapLayout) -> [MapNode] {
        map.nodes.filter { lay.positions[$0.id] != nil }
    }

    private var dotGrid: some View {
        Canvas { ctx, size in
            let step: CGFloat = 28
            let color = map.theme.grid
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    let rect = CGRect(x: x, y: y, width: 2, height: 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(color))
                    x += step
                }
                y += step
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Gestures

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                pan = CGSize(width: lastPan.width + v.translation.width,
                             height: lastPan.height + v.translation.height)
            }
            .onEnded { _ in lastPan = pan }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let next = lastZoom * value
                zoom = min(maxZoom, max(minZoom, next))
            }
            .onEnded { _ in lastZoom = zoom }
    }

    // MARK: - Zoom controls

    private var zoomControls: some View {
        VStack(spacing: 10) {
            zoomButton("plus.magnifyingglass") {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                    zoom = min(maxZoom, zoom + 0.2); lastZoom = zoom
                }
            }
            zoomButton("minus.magnifyingglass") {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                    zoom = max(minZoom, zoom - 0.2); lastZoom = zoom
                }
            }
            zoomButton("scope") {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                    pan = .zero; lastPan = .zero; zoom = 1; lastZoom = 1
                }
                Haptics.tap()
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(12)
    }

    private func zoomButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(width: 36, height: 36)
        }
        .accessibilityLabel(label(for: symbol))
    }

    private func label(for symbol: String) -> String {
        switch symbol {
        case "plus.magnifyingglass": return "Zoom in"
        case "minus.magnifyingglass": return "Zoom out"
        default: return "Recenter"
        }
    }

    private func recenter() {
        pan = .zero; lastPan = .zero
    }

    // MARK: - Contextual toolbar

    private var contextToolbar: some View {
        let node = selectedNode
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                toolButton("Child", "plus.circle") { if let n = node { addChild(n) } }
                toolButton("Sibling", "arrow.turn.down.right") { if let n = node { addSibling(n) } }
                toolButton("Edit", "pencil") { if let n = node { beginEdit(n) } }
                toolButton("Color", "paintpalette") { if node != nil { showColorPicker = true } }
                if let n = node, !n.children.isEmpty {
                    toolButton(n.isCollapsed ? "Expand" : "Collapse",
                               n.isCollapsed ? "chevron.down.circle" : "chevron.up.circle") {
                        Haptics.tap(); editor.toggleCollapse(n)
                    }
                }
                toolButton("Detail", "info.circle") { if let n = node { openDetail(n.id) } }
                if let n = node, !n.isRoot {
                    toolButton("Delete", "trash") { requestDelete(n) }
                        .foregroundStyle(Theme.bad)
                }
            }
            .padding(8)
        }
        .scrollClipDisabled()
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
        .padding(.bottom, 16)
        .padding(.horizontal, 12)
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }

    private func toolButton(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: symbol).font(.system(size: 17))
                Text(title).font(Theme.rounded(9, .medium))
            }
            .frame(minWidth: 44)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.ink)
        .accessibilityLabel(title)
    }

    // MARK: - Color sheet

    private var colorSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Node color")
                    .font(Theme.rounded(18, .semibold))
                    .foregroundStyle(Theme.ink)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(NodePalette.allCases) { p in
                        Button {
                            if let n = selectedNode {
                                editor.setColor(p.rawValue, on: n); Haptics.selection()
                            }
                            showColorPicker = false
                        } label: {
                            VStack(spacing: 8) {
                                ColorDot(palette: p,
                                         selected: selectedNode?.colorTag == p.rawValue,
                                         diameter: 44)
                                Text(p.name).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
            .padding(24)
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showColorPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func addChild(_ n: MapNode) {
        Haptics.tap()
        let child = editor.addChild(to: n, text: "New idea")
        selectedNodeID = child.id
    }

    private func addSibling(_ n: MapNode) {
        Haptics.tap()
        let sib = editor.addSibling(to: n, text: "New idea")
        selectedNodeID = sib.id
    }

    private func beginEdit(_ n: MapNode) {
        editingText = n.text
        editingNodeID = n.id
    }

    private func commitEdit() {
        guard let id = editingNodeID, let n = map.nodes.first(where: { $0.id == id }) else { return }
        editor.setText(editingText, on: n)
        editingNodeID = nil
        Haptics.tap()
    }

    private func requestDelete(_ n: MapNode) {
        if confirmDelete { pendingDelete = n } else { performDelete(n) }
    }

    private func performConfirmedDelete() {
        if let n = pendingDelete { performDelete(n) }
        pendingDelete = nil
    }

    private func performDelete(_ n: MapNode) {
        let parentID = n.parent?.id
        if editor.deleteSubtree(n) {
            selectedNodeID = parentID
            Haptics.warning()
        }
    }
}

// MARK: - Connector shape

/// Draws a parent->child connector. Tree mode uses a smooth horizontal curve;
/// radial mode uses a straight line.
struct ConnectorShape: Shape {
    let from: CGPoint
    let to: CGPoint
    let style: LayoutStyle

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: from)
        switch style {
        case .tree:
            let midX = (from.x + to.x) / 2
            p.addCurve(to: to,
                       control1: CGPoint(x: midX, y: from.y),
                       control2: CGPoint(x: midX, y: to.y))
        case .radial:
            p.addLine(to: to)
        }
        return p
    }
}

// MARK: - Node bubble

private struct NodeBubble: View {
    let node: MapNode
    let isSelected: Bool
    let isRoot: Bool

    private var palette: NodePalette { node.palette }

    var body: some View {
        let text = node.text.isEmpty ? "Untitled" : node.text
        HStack(spacing: 6) {
            if !node.children.isEmpty {
                Image(systemName: node.isCollapsed ? "plus.circle.fill" : "minus.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.accent)
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(Theme.rounded(isRoot ? 16 : 14, isRoot ? .bold : .semibold))
                .foregroundStyle(palette.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: LayoutEngine.nodeWidth, alignment: .leading)
        .background(palette.fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(palette.accent.opacity(isSelected ? 1 : 0.35),
                              lineWidth: isSelected ? 2.5 : 1.2)
        )
        .shadow(color: palette.accent.opacity(isRoot ? 0.18 : 0.0), radius: 8, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isRoot ? "Root node, \(text)" : "Node, \(text)")
        .accessibilityValue(node.children.isEmpty ? "" : "\(node.children.count) children, \(node.isCollapsed ? "collapsed" : "expanded")")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
