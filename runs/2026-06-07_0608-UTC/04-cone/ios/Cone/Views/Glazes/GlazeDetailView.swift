import SwiftUI
import SwiftData

/// Recipe view with a live batch calculator: choose a batch size, see grams.
struct GlazeDetailView: View {
    @Bindable var glaze: Glaze
    @AppStorage("cone.batchGrams") private var batchGrams = 1000.0
    @State private var showingEdit = false

    private var lines: [ConeMath.BatchLine] {
        ConeMath.batch(materials: glaze.orderedMaterials.map { ($0.name, $0.percentage, $0.isAddition) },
                       batchGrams: batchGrams)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                batchCard
                recipeCard
                if !glaze.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionTitle(text: "Notes")
                        Text(glaze.notes).font(.subheadline).foregroundStyle(Brand.text2)
                    }.glassCard()
                }
            }
            .padding()
        }
        .navigationTitle(glaze.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showingEdit = true } } }
        .sheet(isPresented: $showingEdit) { GlazeEditView(existing: glaze) }
    }

    private var headerCard: some View {
        VStack(spacing: 6) {
            Text("Cone \(glaze.coneRange)").font(Brand.mono(26, weight: .bold)).foregroundStyle(Brand.text)
            HStack(spacing: 8) {
                Badge(text: glaze.surface); Badge(text: glaze.atmosphere)
            }
            if !glaze.colorNote.isEmpty {
                Text(glaze.colorNote).font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16).glassCard()
    }

    private var batchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Batch size")
            HStack {
                Text("\(Int(batchGrams)) g base").font(Brand.mono(20, weight: .bold)).foregroundStyle(Brand.text)
                Spacer()
                Stepper("", value: $batchGrams, in: 100...10000, step: 100).labelsHidden()
            }
            HStack(spacing: 8) {
                ForEach([500.0, 1000.0, 2000.0, 5000.0], id: \.self) { v in
                    Button("\(Int(v))") { batchGrams = v; Haptics.selection() }
                        .font(Brand.mono(13, weight: .medium))
                        .foregroundStyle(batchGrams == v ? Brand.text : Brand.text2)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background((batchGrams == v ? Brand.live.opacity(0.18) : Brand.hairline.opacity(0.5)),
                                    in: Capsule())
                }
            }
            if glaze.baseTotal > 0 && abs(glaze.baseTotal - 100) > 0.5 {
                Text("Base totals \(String(format: "%.1f", glaze.baseTotal))% — grams are scaled so the base equals your batch size.")
                    .font(.caption).foregroundStyle(Brand.warn)
            }
        }
        .glassCard()
    }

    private var recipeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Recipe")
            if lines.isEmpty {
                Text("Add materials to this glaze to see the batch.").font(.caption).foregroundStyle(Brand.text3)
            } else {
                ForEach(lines) { line in
                    HStack {
                        Text(line.name).foregroundStyle(line.isAddition ? Brand.live : Brand.text)
                        if line.isAddition { Badge(text: "add", color: Brand.live) }
                        Spacer()
                        Text("\(String(format: "%.1f", line.percentage))%")
                            .font(Brand.mono(12)).foregroundStyle(Brand.text3).frame(width: 56, alignment: .trailing)
                        Text(gramStr(line.grams))
                            .font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
                            .frame(width: 76, alignment: .trailing)
                    }
                    .font(.subheadline)
                    if line.id != lines.last?.id { Divider().overlay(Brand.hairline) }
                }
                Divider().overlay(Brand.hairline)
                HStack {
                    Text("Total batch").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text2)
                    Spacer()
                    Text(gramStr(lines.map { $0.grams }.reduce(0, +)))
                        .font(Brand.mono(15, weight: .bold)).foregroundStyle(Brand.text)
                }
            }
        }
        .glassCard()
    }

    private func gramStr(_ g: Double) -> String {
        g >= 100 ? "\(Int(g.rounded())) g" : String(format: "%.1f g", g)
    }
}
