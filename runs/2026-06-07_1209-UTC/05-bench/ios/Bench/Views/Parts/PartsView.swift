import SwiftUI
import SwiftData

struct PartsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Component.name) private var parts: [Component]
    @AppStorage("bench.confirmDeletes") private var confirmDeletes = true
    @State private var showNew = false
    @State private var editing: Component?
    @State private var pendingDelete: Component?
    @State private var search = ""

    private var filtered: [Component] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return parts }
        return parts.filter { $0.name.lowercased().contains(q) || $0.value.lowercased().contains(q) }
    }
    private var grouped: [(ComponentKind, [Component])] {
        ComponentKind.allCases.compactMap { k in
            let items = filtered.filter { $0.kind == k }
            return items.isEmpty ? nil : (k, items)
        }
    }
    private var lowStock: Int { parts.filter { $0.lowStock }.count }

    var body: some View {
        NavigationStack {
            Group {
                if parts.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "cpu",
                                       title: "No parts yet",
                                       message: "Track what's in your drawers — values, packages and quantities — so you know what you can build.")
                            .padding(.top, 40)
                        Button { showNew = true } label: {
                            Label("Add a part", systemImage: "plus")
                        }.buttonStyle(InkButtonStyle()).padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(value: "\(parts.count)", label: "Part types")
                                StatTile(value: "\(parts.map { $0.quantity }.reduce(0,+))", label: "Total stock")
                                StatTile(value: "\(lowStock)", label: "Low stock",
                                         accent: lowStock > 0 ? Brand.warn : Brand.live)
                            }
                            ForEach(grouped, id: \.0) { kind, items in section(kind, items) }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Parts")
            .searchable(text: $search, prompt: "Search parts")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Image(systemName: "plus") }.tint(Brand.text)
                }
            }
            .sheet(isPresented: $showNew) { PartEditView(part: nil) }
            .sheet(item: $editing) { p in PartEditView(part: p) }
            .confirmationDialog("Delete this part?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let p = pendingDelete { delete(p) } }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func section(_ kind: ComponentKind, _ items: [Component]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(kind.rawValue, systemImage: kind.symbol)
                .font(.subheadline.weight(.semibold)).foregroundStyle(kind.tint)
                .padding(.bottom, 8)
            ForEach(items) { p in
                Button { editing = p } label: { row(p) }.buttonStyle(.plain)
                    .contextMenu {
                        Button { editing = p } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) {
                            if confirmDeletes { pendingDelete = p } else { delete(p) }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                if p.id != items.last?.id { Divider().overlay(Brand.hairline) }
            }
        }.glassCard()
    }

    private func row(_ p: Component) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(p.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                    if !p.value.isEmpty { Text(p.value).font(.caption).foregroundStyle(Brand.text2) }
                }
                HStack(spacing: 6) {
                    if !p.package.isEmpty { Text(p.package).font(.caption).foregroundStyle(Brand.text3) }
                    if p.lowStock { Badge(text: "low", color: Brand.warn) }
                }
            }
            Spacer()
            Text("×\(p.quantity)").font(Brand.mono(15, weight: .semibold))
                .foregroundStyle(p.quantity == 0 ? Brand.danger : Brand.text)
        }
        .padding(.vertical, 7)
    }

    private func delete(_ p: Component) {
        context.delete(p); try? context.save(); Haptics.warning(); pendingDelete = nil
    }
}
