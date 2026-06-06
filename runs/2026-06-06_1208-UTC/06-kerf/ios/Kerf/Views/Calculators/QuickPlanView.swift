import SwiftUI

/// One-off cut optimizer: a single stock length and a quick list of cuts.
struct QuickPlanView: View {
    @AppStorage("lengthUnit") private var unitRaw = LengthUnit.mm.rawValue

    struct QuickPart: Identifiable { let id = UUID(); var length: Double; var qty: Int }

    @State private var stockText = ""
    @State private var kerfText = "3"
    @State private var newLength = ""
    @State private var newQty = 1
    @State private var parts: [QuickPart] = []

    private var unit: LengthUnit { LengthUnit(rawValue: unitRaw) ?? .mm }
    private var plan: CutOptimizer.Plan? {
        let stockMM = unit.toMM(parse(stockText))
        guard stockMM > 0, !parts.isEmpty else { return nil }
        let pieceSpecs = parts.map { CutOptimizer.PieceSpec(id: $0.id, label: "", length: $0.length, quantity: $0.qty) }
        let stockSpecs = [CutOptimizer.StockSpec(id: UUID(), label: "Board", length: stockMM, quantity: 0)]
        return CutOptimizer.optimize(pieces: pieceSpecs, stock: stockSpecs, kerf: unit.toMM(parse(kerfText)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                stockCard
                addCard
                if parts.isEmpty {
                    EmptyStateView(icon: "ruler", title: "No cuts yet",
                                   message: "Add the lengths you need and Kerf will lay them out.").glassCard()
                } else {
                    partsCard
                    if let plan { resultCard(plan) }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8).padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Quick Plan").navigationBarTitleDisplayMode(.inline)
        .onAppear { if stockText.isEmpty { stockText = unit == .mm ? "2400" : "96" } }
    }

    private var stockCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Stock length (\(unit.short))").font(.subheadline).foregroundStyle(Brand.text)
                Spacer()
                TextField("0", text: $stockText).keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing).frame(width: 100).font(Brand.mono(16))
            }
            HStack {
                Text("Kerf (\(unit.short))").font(.subheadline).foregroundStyle(Brand.text)
                Spacer()
                TextField("0", text: $kerfText).keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing).frame(width: 100).font(Brand.mono(16))
            }
        }
        .glassCard()
    }

    private var addCard: some View {
        HStack(spacing: 10) {
            TextField("Length", text: $newLength).keyboardType(.decimalPad)
                .frame(maxWidth: .infinity).font(Brand.mono(16))
                .padding(10).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            Stepper("×\(newQty)", value: $newQty, in: 1...99).fixedSize()
            Button { addPart() } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                .disabled(parse(newLength) <= 0)
                .accessibilityLabel("Add cut")
        }
        .glassCard()
    }

    private var partsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Cuts")
            ForEach(parts) { part in
                HStack {
                    Text("\(part.qty) × \(unit.string(part.length))").font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    Button { parts.removeAll { $0.id == part.id } } label: {
                        Image(systemName: "minus.circle").foregroundStyle(Brand.text3)
                    }.accessibilityLabel("Remove cut")
                }
                .padding(.vertical, 2)
            }
        }
        .glassCard()
    }

    private func resultCard(_ plan: CutOptimizer.Plan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                StatTile(value: "\(plan.boards.count)", label: "Boards", tint: Brand.text)
                StatTile(value: "\(Int((plan.efficiency * 100).rounded()))%", label: "Used",
                         tint: plan.efficiency >= 0.8 ? Brand.live : Brand.warn)
                StatTile(value: unit.string(plan.totalWaste), label: "Waste", tint: Brand.warn)
            }
            if !plan.unfittable.isEmpty {
                Label("\(plan.unfittable.count) piece(s) longer than the board.", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote).foregroundStyle(Brand.danger)
            }
            ForEach(Array(plan.boards.enumerated()), id: \.element.id) { idx, board in
                VStack(alignment: .leading, spacing: 6) {
                    Text("Board \(idx + 1)").font(.caption.weight(.semibold)).foregroundStyle(Brand.text2)
                    BoardBar(layout: board, unit: unit)
                }
            }
        }
        .glassCard()
    }

    private func addPart() {
        let mm = unit.toMM(parse(newLength))
        guard mm > 0 else { return }
        parts.append(QuickPart(length: mm, qty: newQty))
        newLength = ""; newQty = 1; Haptics.tap()
    }
    private func parse(_ s: String) -> Double { max(0, Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0) }
}
