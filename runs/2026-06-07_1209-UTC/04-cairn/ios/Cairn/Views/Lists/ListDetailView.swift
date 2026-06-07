import SwiftUI
import SwiftData
import Charts

struct ListDetailView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("cairn.unit") private var unit = "g"
    @AppStorage("cairn.includeWornInTotal") private var skinOutHeadline = false
    @Bindable var list: PackList
    @State private var showAdd = false

    private var w: PackWeights { PackMath.weights(for: list.entries) }
    private var byCat: [(category: GearCategory, grams: Double)] { PackMath.byCategory(list.entries) }

    private var grouped: [(GearCategory, [PackEntry])] {
        GearCategory.allCases.compactMap { c in
            let items = list.entries.filter { ($0.gear?.category ?? .other) == c }
                .sorted { ($0.gear?.name ?? "") < ($1.gear?.name ?? "") }
            return items.isEmpty ? nil : (c, items)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                if !byCat.isEmpty { breakdownCard }
                if list.entries.isEmpty {
                    EmptyStateView(icon: "plus.circle",
                                   title: "Empty list",
                                   message: "Add gear from your catalog to start building this pack.")
                } else {
                    ForEach(grouped, id: \.0) { cat, items in
                        categorySection(cat, items)
                    }
                }
                Button { showAdd = true } label: {
                    Label("Add gear", systemImage: "plus").frame(maxWidth: .infinity)
                }.buttonStyle(InkButtonStyle())
            }
            .padding()
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .sheet(isPresented: $showAdd) { AddGearSheet(list: list) }
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text((skinOutHeadline ? "SKIN-OUT WEIGHT" : "BASE WEIGHT"))
                    .font(Brand.mono(11, weight: .medium)).tracking(2).foregroundStyle(Brand.text3)
                Text(WeightFmt.string(skinOutHeadline ? w.skinOut : w.base, unit: unit))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.text).minimumScaleFactor(0.5).lineLimit(1)
                Text(PackMath.tier(baseGrams: w.base))
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.live)
            }
            HStack(spacing: 10) {
                miniStat("Base", w.base)
                miniStat("Consum.", w.consumable)
                miniStat("Worn", w.worn)
            }
            HStack(spacing: 10) {
                miniStat("On back", w.totalPack, accent: Brand.text)
                miniStat("Skin-out", w.skinOut, accent: Brand.text)
                miniStat("Big 3", w.bigThree, accent: Brand.warn)
            }
        }
        .frame(maxWidth: .infinity).glassCard(padding: 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Base weight \(WeightFmt.string(w.base, unit: unit)), total on back \(WeightFmt.string(w.totalPack, unit: unit))")
    }

    private func miniStat(_ label: String, _ grams: Double, accent: Color = Brand.text2) -> some View {
        VStack(spacing: 2) {
            Text(WeightFmt.compact(grams, unit: unit))
                .font(Brand.mono(13, weight: .semibold)).foregroundStyle(accent)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label.uppercased()).font(Brand.mono(8)).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Where the weight is")
            Chart(byCat, id: \.category) { row in
                SectorMark(angle: .value("Grams", row.grams),
                           innerRadius: .ratio(0.58), angularInset: 1.5)
                    .cornerRadius(4)
                    .foregroundStyle(row.category.tint)
            }
            .frame(height: 170)
            .accessibilityLabel("Weight breakdown by category")
            VStack(spacing: 6) {
                ForEach(byCat, id: \.category) { row in
                    HStack(spacing: 10) {
                        Circle().fill(row.category.tint).frame(width: 9, height: 9)
                        Text(row.category.rawValue).font(.subheadline).foregroundStyle(Brand.text2)
                        Spacer()
                        Text(WeightFmt.compact(row.grams, unit: unit))
                            .font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text)
                    }
                }
            }
        }.glassCard()
    }

    private func categorySection(_ cat: GearCategory, _ items: [PackEntry]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(cat.rawValue, systemImage: cat.symbol)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(cat.tint)
                Spacer()
                Text(WeightFmt.compact(items.map { $0.lineWeight }.reduce(0, +), unit: unit))
                    .font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text2)
            }.padding(.bottom, 8)
            ForEach(items) { entry in
                entryRow(entry)
                if entry.id != items.last?.id { Divider().overlay(Brand.hairline) }
            }
        }.glassCard()
    }

    private func entryRow(_ entry: PackEntry) -> some View {
        HStack(spacing: 12) {
            Button { entry.packed.toggle(); try? context.save(); Haptics.selection() } label: {
                Image(systemName: entry.packed ? "checkmark.circle.fill" : "circle")
                    .font(.title3).foregroundStyle(entry.packed ? Brand.live : Brand.text3)
            }
            .accessibilityLabel(entry.packed ? "Packed" : "Not packed")
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.gear?.name ?? "Removed item")
                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                HStack(spacing: 6) {
                    if entry.gear?.isWorn == true { Badge(text: "worn", color: Brand.live) }
                    if entry.gear?.isConsumable == true { Badge(text: "consum.", color: Brand.warn) }
                    Text(WeightFmt.string(entry.gear?.weightGrams ?? 0, unit: unit))
                        .font(.caption).foregroundStyle(Brand.text3)
                }
            }
            Spacer()
            Stepper(value: Binding(get: { entry.quantity },
                                   set: { entry.quantity = max(1, $0); try? context.save() }),
                    in: 1...50) {
                Text("×\(entry.quantity)").font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text)
            }
            .fixedSize()
        }
        .padding(.vertical, 7)
        .contextMenu {
            Button(role: .destructive) { remove(entry) } label: { Label("Remove from list", systemImage: "trash") }
        }
    }

    private func remove(_ entry: PackEntry) {
        context.delete(entry); try? context.save(); Haptics.warning()
    }
}
