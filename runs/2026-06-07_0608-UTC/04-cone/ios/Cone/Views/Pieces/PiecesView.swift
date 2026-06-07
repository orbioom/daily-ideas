import SwiftUI
import SwiftData

struct PiecesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Piece.updatedAt, order: .reverse) private var pieces: [Piece]
    @AppStorage("cone.confirmDeletes") private var confirmDeletes = true
    @State private var filter = "All"
    @State private var showingEditor = false
    @State private var pendingDelete: Piece?

    private let filters = ["All"] + Piece.stages

    private var filtered: [Piece] {
        filter == "All" ? pieces : pieces.filter { $0.stage == filter }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { f in
                            Button {
                                filter = f; Haptics.selection()
                            } label: {
                                Text(f).font(.caption.weight(.medium))
                                    .foregroundStyle(filter == f ? Brand.text : Brand.text2)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background((filter == f ? Brand.live.opacity(0.2) : Brand.hairline.opacity(0.5)), in: Capsule())
                            }
                        }
                    }
                    .padding(.horizontal).padding(.vertical, 8)
                }
                Group {
                    if pieces.isEmpty {
                        ScrollView {
                            EmptyStateView(icon: "square.stack.3d.up", title: "No pieces yet",
                                           message: "Add a piece and track it from greenware to finished.")
                            .glassCard().padding()
                        }
                    } else if filtered.isEmpty {
                        ScrollView {
                            EmptyStateView(icon: "tray", title: "Nothing in \(filter)",
                                           message: "No pieces are at this stage right now.")
                            .glassCard().padding()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filtered) { p in
                                    NavigationLink { PieceEditView(existing: p) } label: { PieceRow(piece: p) }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                if confirmDeletes { pendingDelete = p } else { delete(p) }
                                            } label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Pieces")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add piece")
                }
            }
            .background(Brand.pageBackground)
            .sheet(isPresented: $showingEditor) { PieceEditView(existing: nil) }
            .confirmationDialog("Delete this piece?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let p = pendingDelete { delete(p) }; pendingDelete = nil }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func delete(_ p: Piece) { context.delete(p); try? context.save(); Haptics.warning() }
}

private struct PieceRow: View {
    let piece: Piece
    private var stageColor: Color {
        switch piece.stage {
        case "Greenware": return Brand.text3
        case "Bisque": return Brand.warn
        case "Glazed": return Brand.info
        case "Fired": return Brand.live
        default: return Brand.magic
        }
    }
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(piece.title).font(.headline).foregroundStyle(Brand.text)
                Text("\(piece.clayBody.isEmpty ? piece.formingMethod : piece.clayBody) · \(piece.formingMethod)")
                    .font(.caption).foregroundStyle(Brand.text3)
                if !piece.glazeName.isEmpty {
                    Text("Glaze: \(piece.glazeName)").font(.caption2).foregroundStyle(Brand.text3)
                }
            }
            Spacer()
            Badge(text: piece.stage, color: stageColor)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(piece.title), \(piece.stage)")
    }
}
