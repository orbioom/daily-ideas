import SwiftUI
import SwiftData

struct BestiaryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \StatBlock.name) private var blocks: [StatBlock]
    @AppStorage("gambit.confirmDeletes") private var confirmDeletes = true
    @State private var showNew = false
    @State private var editing: StatBlock?
    @State private var pendingDelete: StatBlock?
    @State private var search = ""

    private var filtered: [StatBlock] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return blocks }
        return blocks.filter { $0.name.lowercased().contains(q) }
    }
    private var grouped: [(CombatantSide, [StatBlock])] {
        CombatantSide.allCases.compactMap { s in
            let items = filtered.filter { $0.side == s }
            return items.isEmpty ? nil : (s, items)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if blocks.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "pawprint",
                                       title: "Bestiary is empty",
                                       message: "Save the monsters, NPCs and PCs you use often. Drop them into any encounter in a tap.")
                            .padding(.top, 40)
                        Button { showNew = true } label: {
                            Label("New stat block", systemImage: "plus")
                        }.buttonStyle(InkButtonStyle()).padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(grouped.indices, id: \.self) { i in section(grouped[i].0, grouped[i].1) }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Bestiary")
            .searchable(text: $search, prompt: "Search stat blocks")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Image(systemName: "plus") }.tint(Brand.text)
                }
            }
            .sheet(isPresented: $showNew) { StatBlockEditView(block: nil) }
            .sheet(item: $editing) { b in StatBlockEditView(block: b) }
            .confirmationDialog("Delete this stat block?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let b = pendingDelete { delete(b) } }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func section(_ side: CombatantSide, _ items: [StatBlock]) -> some View {
        let color: Color = side == .enemy ? Brand.danger : (side == .ally ? Brand.info : Brand.live)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(side.rawValue + "s").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text2)
            }.padding(.bottom, 8)
            ForEach(items) { b in
                Button { editing = b } label: { row(b) }.buttonStyle(.plain)
                    .contextMenu {
                        Button { editing = b } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) {
                            if confirmDeletes { pendingDelete = b } else { delete(b) }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                if b.id != items.last?.id { Divider().overlay(Brand.hairline) }
            }
        }.glassCard()
    }

    private func row(_ b: StatBlock) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(b.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text("\(b.maxHP) HP · AC \(b.armorClass) · init \(b.initiativeMod >= 0 ? "+" : "")\(b.initiativeMod)")
                    .font(Brand.mono(11)).foregroundStyle(Brand.text3)
            }
            Spacer()
            Image(systemName: "pencil").font(.footnote).foregroundStyle(Brand.text3)
        }
        .padding(.vertical, 7)
    }

    private func delete(_ b: StatBlock) {
        context.delete(b); try? context.save(); Haptics.warning(); pendingDelete = nil
    }
}
