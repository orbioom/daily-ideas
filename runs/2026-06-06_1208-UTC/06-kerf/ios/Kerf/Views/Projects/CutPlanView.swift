import SwiftUI

/// The optimized cut plan: boards to buy/use and what to cut from each.
struct CutPlanView: View {
    let project: Project
    @AppStorage("lengthUnit") private var unitRaw = LengthUnit.mm.rawValue

    @State private var plan: CutOptimizer.Plan?
    @State private var loading = true

    private var unit: LengthUnit { LengthUnit(rawValue: unitRaw) ?? .mm }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if loading {
                    loadingView
                } else if let plan {
                    if plan.boards.isEmpty && plan.unfittable.isEmpty {
                        EmptyStateView(icon: "wand.and.stars", title: "Nothing to plan",
                                       message: "Add parts and stock to generate a plan.").glassCard()
                    } else {
                        summaryCard(plan)
                        if !plan.unfittable.isEmpty { unfittableCard(plan) }
                        boardsSection(plan)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8).padding(.bottom, 32)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Cut Plan")
        .navigationBarTitleDisplayMode(.inline)
        .task { await compute() }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text("Optimizing layout…").font(.subheadline).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }

    private func compute() async {
        loading = true
        // Read the model on the main actor into Sendable value specs, then run
        // the pure optimizer off the main actor.
        let pieceSpecs = project.parts.map {
            CutOptimizer.PieceSpec(id: $0.id, label: $0.label, length: $0.lengthMm, quantity: $0.quantity)
        }
        let stockSpecs = project.stock.map {
            CutOptimizer.StockSpec(id: $0.id, label: $0.label, length: $0.lengthMm, quantity: $0.quantity)
        }
        let kerf = project.kerfMm
        let result = await Task.detached(priority: .userInitiated) {
            CutOptimizer.optimize(pieces: pieceSpecs, stock: stockSpecs, kerf: kerf)
        }.value
        plan = result
        loading = false
    }

    private func summaryCard(_ plan: CutOptimizer.Plan) -> some View {
        let cost = estimatedCost(plan)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                StatTile(value: "\(plan.boards.count)", label: "Boards needed", tint: Brand.text)
                StatTile(value: "\(Int((plan.efficiency * 100).rounded()))%", label: "Material used",
                         tint: plan.efficiency >= 0.8 ? Brand.live : Brand.warn)
            }
            HStack(spacing: 10) {
                StatTile(value: unit.string(plan.totalWaste), label: "Offcut / waste", tint: Brand.warn)
                if cost > 0 {
                    StatTile(value: String(format: "%.0f", cost), label: "Est. cost")
                }
            }
            ForEach(Array(plan.boardsByStock.enumerated()), id: \.offset) { _, item in
                Text("• \(item.count) × \(item.label.isEmpty ? "board" : item.label) (\(unit.string(item.length)))")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .glassCard()
    }

    private func unfittableCard(_ plan: CutOptimizer.Plan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(plan.shortStock ? "Not enough stock" : "Pieces too long", systemImage: "exclamationmark.triangle.fill")
                .font(.headline).foregroundStyle(Brand.danger)
            Text(plan.shortStock
                 ? "These pieces couldn't be placed — add more stock or mark a board as unlimited:"
                 : "These pieces are longer than any available board:")
                .font(.subheadline).foregroundStyle(Brand.text2)
            ForEach(plan.unfittable) { p in
                Text("• \(p.label.isEmpty ? "Part" : p.label) — \(unit.string(p.length))")
                    .font(.subheadline).foregroundStyle(Brand.text)
            }
        }
        .glassCard()
    }

    private func boardsSection(_ plan: CutOptimizer.Plan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Boards")
            ForEach(Array(plan.boards.enumerated()), id: \.element.id) { idx, board in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Board \(idx + 1)").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                        Spacer()
                        Text(unit.string(board.stockLength)).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                    }
                    BoardBar(layout: board, unit: unit)
                    let cuts = board.pieces.map { "\($0.label.isEmpty ? "cut" : $0.label) \(unit.string($0.length, withUnit: false))" }
                    Text(cuts.joined(separator: "  ·  "))
                        .font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    Text("Waste \(unit.string(board.waste))").font(.caption2).foregroundStyle(Brand.warn)
                }
                .glassCard()
            }
        }
    }

    private func estimatedCost(_ plan: CutOptimizer.Plan) -> Double {
        // map stock length -> price from the project's stock definitions
        var priceByLength: [Double: Double] = [:]
        for s in project.stock where s.pricePerBoard > 0 { priceByLength[s.lengthMm] = s.pricePerBoard }
        return plan.boards.reduce(0) { $0 + (priceByLength[$1.stockLength] ?? 0) }
    }
}
