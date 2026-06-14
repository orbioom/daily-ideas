import SwiftUI
import SwiftData

/// Hosts a single map and switches between the Canvas and Outline editors.
/// Owns the shared selection and editor so both modes stay in sync.
struct MapWorkspaceView: View {
    @Environment(\.modelContext) private var context
    @Bindable var map: MindMap

    @AppStorage("defaultLayout") private var defaultLayout = LayoutStyle.tree.rawValue
    @AppStorage("isPro") private var isPro = false

    @State private var mode: Mode = .canvas
    @State private var selectedNodeID: UUID?
    @State private var layoutStyle: LayoutStyle = .tree
    @State private var showExportPaywall = false
    @State private var nodeDetailID: UUID?

    enum Mode: String, CaseIterable { case canvas, outline }

    private var editor: MapEditor { MapEditor(map: map, context: context) }

    var body: some View {
        ZStack {
            map.theme.canvas.ignoresSafeArea()
            Group {
                switch mode {
                case .canvas:
                    CanvasEditorView(map: map,
                                     editor: editor,
                                     layoutStyle: $layoutStyle,
                                     selectedNodeID: $selectedNodeID,
                                     openDetail: { nodeDetailID = $0 })
                case .outline:
                    OutlineEditorView(map: map,
                                      editor: editor,
                                      selectedNodeID: $selectedNodeID,
                                      openDetail: { nodeDetailID = $0 })
                }
            }
        }
        .navigationTitle(map.title.isEmpty ? "Untitled Map" : map.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { modePicker }
            ToolbarItem(placement: .topBarTrailing) { menu }
        }
        .navigationDestination(item: $nodeDetailID) { id in
            if let node = node(for: id) {
                NodeDetailView(node: node, editor: editor)
            }
        }
        .sheet(isPresented: $showExportPaywall) { PaywallView() }
        .onAppear {
            // Ensure a root exists and seed the layout style.
            _ = map.ensureRoot(context: context)
            layoutStyle = LayoutStyle(rawValue: defaultLayout) ?? .tree
            if selectedNodeID == nil { selectedNodeID = map.root?.id }
        }
    }

    private func node(for id: UUID) -> MapNode? {
        map.nodes.first(where: { $0.id == id })
    }

    // MARK: - Toolbar pieces

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            Label("Canvas", systemImage: "circle.hexagongrid").tag(Mode.canvas)
            Label("Outline", systemImage: "list.bullet.indent").tag(Mode.outline)
        }
        .pickerStyle(.segmented)
        .frame(width: 200)
    }

    private var menu: some View {
        Menu {
            if mode == .canvas {
                Picker("Layout", selection: $layoutStyle) {
                    ForEach(LayoutStyle.allCases) { Label($0.name, systemImage: $0.symbol).tag($0) }
                }
            }
            Menu {
                ForEach(ProLimits.availableThemes(isPro: isPro)) { t in
                    Button {
                        map.theme = t; map.touch()
                    } label: {
                        if map.theme == t { Label(t.name, systemImage: "checkmark") }
                        else { Text(t.name) }
                    }
                }
            } label: {
                Label("Theme", systemImage: "paintpalette")
            }

            Divider()

            if isPro {
                ShareLink(item: OutlineExport.document(for: map),
                          preview: SharePreview(map.title.isEmpty ? "Aster Map" : map.title)) {
                    Label("Export outline", systemImage: "square.and.arrow.up")
                }
            } else {
                Button {
                    Haptics.warning()
                    showExportPaywall = true
                } label: {
                    Label("Export outline (Pro)", systemImage: "square.and.arrow.up")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("Map options")
    }
}
