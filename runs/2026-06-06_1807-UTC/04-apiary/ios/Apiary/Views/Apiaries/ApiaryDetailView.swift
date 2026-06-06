import SwiftUI
import SwiftData

struct ApiaryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var apiary: Apiary
    @State private var showEdit = false
    @State private var showAddHive = false
    @State private var confirmDelete = false

    private var hives: [Hive] { apiary.hives.sorted { $0.name < $1.name } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !apiary.notes.isEmpty {
                    Text(apiary.notes).font(.subheadline).foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                }
                HStack(spacing: 12) {
                    StatTile(value: "\(apiary.hives.count)", label: "Hives")
                    StatTile(value: "\(apiary.liveHives.count)", label: "Live", accent: Brand.live)
                    StatTile(value: MassUnit.kg.format(kg: apiary.hives.reduce(0) { $0 + $1.totalHoneyKg }),
                             label: "Honey", accent: Brand.warn)
                }

                HStack {
                    SectionHeader(title: "Hives")
                    Spacer()
                    Button { Haptics.tap(); showAddHive = true } label: {
                        Label("Add", systemImage: "plus.circle").font(.subheadline)
                    }
                }
                if hives.isEmpty {
                    Text("No hives here yet. Add one to start logging inspections.")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(hives) { h in
                            NavigationLink(value: h) { HiveRow(hive: h) }.buttonStyle(.plain)
                        }
                    }
                }

                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete apiary", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle()).tint(Brand.danger).padding(.top, 4)
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle(apiary.name).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showEdit = true } } }
        .sheet(isPresented: $showEdit) { ApiaryEditView(apiary: apiary) }
        .sheet(isPresented: $showAddHive) { HiveEditView(hive: nil, presetApiary: apiary) }
        .alert("Delete this apiary?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(apiary); try? context.save(); Haptics.warning(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This also deletes its \(apiary.hives.count) hive\(apiary.hives.count == 1 ? "" : "s") and all their records.") }
    }
}

/// Shared hive row used in apiary detail and tasks.
struct HiveRow: View {
    let hive: Hive
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                QueenDot(year: hive.queenYear)
                Text(hive.name).font(.headline).foregroundStyle(Brand.text)
                Spacer()
                HealthPill(health: BeeLogic.health(for: hive))
            }
            HStack(spacing: 6) {
                Chip(text: hive.kind.rawValue)
                if hive.status != .active { Chip(text: hive.status.rawValue, tint: Brand.warn) }
                if BeeLogic.swarmRisk(for: hive) { Chip(text: "Swarm risk", system: "bolt", tint: Brand.danger) }
                if BeeLogic.miteAlert(for: hive) { Chip(text: "Mites", system: "ant", tint: Brand.danger) }
            }
            if let days = BeeLogic.daysSinceInspection(hive) {
                Text(days == 0 ? "Inspected today" : "Inspected \(days)d ago")
                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
            } else {
                Text("Never inspected").font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }
}
