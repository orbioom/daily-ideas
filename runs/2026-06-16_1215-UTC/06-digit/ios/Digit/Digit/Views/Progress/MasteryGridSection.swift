import SwiftUI

/// A per-operation fact grid colored by mastery (the classic times-table style grid).
struct MasteryGridSection: View {
    let facts: [FactStat]
    let ops: [MathOp]

    @State private var selectedOp: MathOp = .add

    private var availableOps: [MathOp] {
        let present = ops.filter { op in facts.contains { $0.op == op } }
        return present.isEmpty ? (ops.isEmpty ? [.add] : ops) : present
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Operation", selection: $selectedOp) {
                    ForEach(availableOps) { op in
                        Text(op.shortTitle).tag(op)
                    }
                }
                .pickerStyle(.segmented)

                grid(for: selectedOp)

                legend
            }
        }
        .onAppear {
            if !availableOps.contains(selectedOp) {
                selectedOp = availableOps.first ?? .add
            }
        }
    }

    @ViewBuilder
    private func grid(for op: MathOp) -> some View {
        let dim = gridDimension(for: op)
        let lookup = factLookup(for: op)
        // header row + dim columns
        let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: dim + 1)

        LazyVGrid(columns: columns, spacing: 3) {
            // top-left corner cell
            cornerCell(op)
            // column headers
            ForEach(1...dim, id: \.self) { c in
                headerCell("\(c)")
            }
            // rows
            ForEach(1...dim, id: \.self) { r in
                headerCell("\(r)")
                ForEach(1...dim, id: \.self) { c in
                    let mastery = lookup["\(r)-\(c)"]
                    masteryCell(row: r, col: c, op: op, mastery: mastery)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(op.title) mastery grid")
    }

    private func cornerCell(_ op: MathOp) -> some View {
        Text(op.symbol)
            .font(Theme.rounded(14, .bold))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, minHeight: 26)
    }

    private func headerCell(_ s: String) -> some View {
        Text(s)
            .font(Theme.rounded(12, .semibold))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, minHeight: 26)
    }

    private func masteryCell(row r: Int, col c: Int, op: MathOp, mastery: Int?) -> some View {
        let level = mastery ?? -1
        let color = level < 0 ? Theme.surfaceAlt.opacity(0.4) : MasteryPalette.color(for: level)
        return RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(color)
            .frame(minHeight: 26)
            .accessibilityLabel("\(r) \(op.symbol) \(c): \(level < 0 ? "not practiced" : MasteryPalette.label(for: level))")
    }

    private var legend: some View {
        HStack(spacing: 12) {
            ForEach(0...3, id: \.self) { lvl in
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(MasteryPalette.color(for: lvl))
                        .frame(width: 14, height: 14)
                    Text(MasteryPalette.label(for: lvl))
                        .font(Theme.rounded(11))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Data

    /// Dimension of the grid for an op (mul/div use 12x12, add/sub use 10x10).
    private func gridDimension(for op: MathOp) -> Int {
        switch op {
        case .mul, .div: return 12
        case .add, .sub: return 10
        }
    }

    /// Map "a-b" → mastery for facts of this op, normalized to grid coordinates.
    private func factLookup(for op: MathOp) -> [String: Int] {
        var map: [String: Int] = [:]
        for f in facts where f.op == op {
            // For add/sub use a,b directly; for mul/div map dividend/divisor to factors.
            switch op {
            case .add, .sub:
                map["\(f.a)-\(f.b)"] = f.masteryLevel
            case .mul:
                map["\(f.a)-\(f.b)"] = f.masteryLevel
            case .div:
                // div fact a÷b = quotient; place at (quotient, divisor) coordinates.
                let divisor = f.b
                let quotient = divisor > 0 ? f.a / divisor : 0
                if quotient > 0 { map["\(quotient)-\(divisor)"] = f.masteryLevel }
            }
        }
        return map
    }
}
