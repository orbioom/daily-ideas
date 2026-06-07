import SwiftUI
import SwiftData

struct GlazesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Glaze.name) private var glazes: [Glaze]
    @AppStorage("cone.confirmDeletes") private var confirmDeletes = true
    @State private var search = ""
    @State private var showingEditor = false
    @State private var pendingDelete: Glaze?

    private var filtered: [Glaze] {
        guard !search.isEmpty else { return glazes }
        let q = search.lowercased()
        return glazes.filter { $0.name.lowercased().contains(q) || $0.colorNote.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if glazes.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "drop", title: "No glazes yet",
                                       message: "Add your first recipe and Cone will scale it to any batch size.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filtered) { g in
                                NavigationLink { GlazeDetailView(glaze: g) } label: { GlazeRow(glaze: g) }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = g } else { delete(g) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                            if filtered.isEmpty { Text("No matches").foregroundStyle(Brand.text3).padding() }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Glazes")
            .searchable(text: $search, prompt: "Search glazes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add glaze")
                }
            }
            .background(Brand.pageBackground)
            .sheet(isPresented: $showingEditor) { GlazeEditView(existing: nil) }
            .confirmationDialog("Delete this glaze?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let g = pendingDelete { delete(g) }; pendingDelete = nil }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func delete(_ g: Glaze) { context.delete(g); try? context.save(); Haptics.warning() }
}

private struct GlazeRow: View {
    let glaze: Glaze
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(glaze.name).font(.headline).foregroundStyle(Brand.text)
                    if !glaze.colorNote.isEmpty {
                        Text(glaze.colorNote).font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                Spacer()
                Text("△\(glaze.coneRange)").font(Brand.mono(16, weight: .bold)).foregroundStyle(Brand.text)
            }
            HStack(spacing: 6) {
                Badge(text: glaze.surface)
                Badge(text: glaze.atmosphere)
                Badge(text: "\(glaze.materials.count) materials")
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(glaze.name), cone \(glaze.coneRange), \(glaze.surface)")
    }
}
