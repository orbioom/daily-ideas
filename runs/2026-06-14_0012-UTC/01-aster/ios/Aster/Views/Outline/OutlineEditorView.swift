import SwiftUI
import SwiftData

/// The same map shown as an indented, collapsible outline. Edits flow through the
/// shared `MapEditor`, so the canvas stays in sync.
struct OutlineEditorView: View {
    @Bindable var map: MindMap
    let editor: MapEditor
    @Binding var selectedNodeID: UUID?
    let openDetail: (UUID) -> Void

    @AppStorage("showNotePreview") private var showNotePreview = true
    @AppStorage("confirmDelete") private var confirmDelete = true

    @State private var pendingDelete: MapNode?

    /// Flattened, depth-tagged list of visible rows (respecting collapse).
    private var rows: [Row] {
        guard let root = map.root else { return [] }
        var out: [Row] = []
        func walk(_ node: MapNode) {
            out.append(Row(node: node))
            if !node.isCollapsed {
                for child in node.sortedChildren { walk(child) }
            }
        }
        walk(root)
        return out
    }

    var body: some View {
        Group {
            if map.root == nil {
                EmptyStateView(symbol: "list.bullet.indent",
                               title: "Nothing to outline",
                               message: "Add a node on the canvas to start your outline.")
            } else {
                List {
                    ForEach(rows) { row in
                        OutlineRow(
                            node: row.node,
                            isSelected: row.node.id == selectedNodeID,
                            showNote: showNotePreview,
                            onTap: { selectedNodeID = row.node.id },
                            onToggle: { Haptics.tap(); editor.toggleCollapse(row.node) },
                            onCommitText: { editor.setText($0, on: row.node) }
                        )
                        .listRowBackground(Theme.bg)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !row.node.isRoot {
                                Button(role: .destructive) { requestDelete(row.node) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            Button { openDetail(row.node.id) } label: {
                                Label("Detail", systemImage: "info.circle")
                            }.tint(Theme.accent)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button { Haptics.tap(); _ = editor.addChild(to: row.node, text: "New idea") } label: {
                                Label("Child", systemImage: "plus")
                            }.tint(Theme.good)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Theme.bg)
                .safeAreaInset(edge: .bottom) { actionBar }
            }
        }
        .confirmationDialog("Delete this node and everything under it?",
                            isPresented: Binding(get: { pendingDelete != nil },
                                                 set: { if !$0 { pendingDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { confirmDeleteNow() }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        }
    }

    private var selectedNode: MapNode? {
        guard let id = selectedNodeID else { return nil }
        return map.nodes.first(where: { $0.id == id })
    }

    // MARK: - Bottom action bar

    private var actionBar: some View {
        HStack(spacing: 10) {
            if let n = selectedNode {
                barButton("Child", "plus") { Haptics.tap(); select(editor.addChild(to: n, text: "New idea")) }
                barButton("Sibling", "arrow.turn.down.right") { Haptics.tap(); select(editor.addSibling(to: n, text: "New idea")) }
                barButton("Indent", "arrow.right.to.line") {
                    if !editor.indent(n) { Haptics.warning() } else { Haptics.tap() }
                }
                barButton("Outdent", "arrow.left.to.line") {
                    if !editor.outdent(n) { Haptics.warning() } else { Haptics.tap() }
                }
                barButton("Up", "arrow.up") { if !editor.move(n, by: -1) { Haptics.warning() } }
                barButton("Down", "arrow.down") { if !editor.move(n, by: 1) { Haptics.warning() } }
            } else {
                Text("Select a node to edit")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
        .padding(8)
        .background(.regularMaterial)
        .overlay(Divider(), alignment: .top)
    }

    private func barButton(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: symbol).font(.system(size: 16))
                Text(title).font(Theme.rounded(9, .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.ink)
        .accessibilityLabel(title)
    }

    private func select(_ n: MapNode) { selectedNodeID = n.id }

    private func requestDelete(_ n: MapNode) {
        if confirmDelete { pendingDelete = n } else { performDelete(n) }
    }
    private func confirmDeleteNow() {
        if let n = pendingDelete { performDelete(n) }
        pendingDelete = nil
    }
    private func performDelete(_ n: MapNode) {
        let parentID = n.parent?.id
        if editor.deleteSubtree(n) { selectedNodeID = parentID; Haptics.warning() }
    }

    private struct Row: Identifiable {
        let node: MapNode
        var id: UUID { node.id }
    }
}

// MARK: - Outline row

private struct OutlineRow: View {
    @Bindable var node: MapNode
    let isSelected: Bool
    let showNote: Bool
    let onTap: () -> Void
    let onToggle: () -> Void
    let onCommitText: (String) -> Void

    @FocusState private var focused: Bool
    @State private var draft: String = ""

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Indentation guide.
            Spacer().frame(width: CGFloat(node.depth) * 18)

            // Disclosure / leaf dot.
            Group {
                if node.children.isEmpty {
                    Circle().fill(node.palette.accent).frame(width: 7, height: 7)
                        .padding(.top, 8)
                        .accessibilityHidden(true)
                } else {
                    Button(action: onToggle) {
                        Image(systemName: node.isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(node.palette.accent)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(node.isCollapsed ? "Expand" : "Collapse")
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                TextField("Node", text: $draft, axis: .vertical)
                    .font(Theme.rounded(node.isRoot ? 17 : 15, node.isRoot ? .bold : .medium))
                    .foregroundStyle(Theme.ink)
                    .focused($focused)
                    .submitLabel(.done)
                    .onChange(of: focused) { _, now in
                        if !now { onCommitText(draft) }
                    }
                if showNote, !node.note.isEmpty {
                    Text(node.note)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            if !node.children.isEmpty {
                Text("\(node.descendantCount)")
                    .font(Theme.rounded(11, .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? node.palette.accent.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onAppear { draft = node.text }
        .onChange(of: node.text) { _, newValue in
            if !focused { draft = newValue }
        }
    }
}
