import SwiftUI

/// Barbell plate calculator: enter a target weight, see what to load per side.
struct PlateCalcView: View {
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("barWeightKg") private var barWeightKg = 20.0

    @State private var targetText = ""
    @State private var plateToggles: [Double: Bool] = [:]

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }
    private var barInUnit: Double { unit.fromKg(barWeightKg) }
    private var available: [Double] {
        unit.standardPlates.filter { plateToggles[$0] ?? true }
    }
    private var target: Double { max(0, Double(targetText.replacingOccurrences(of: ",", with: ".")) ?? 0) }
    private var result: StrengthMath.PlateResult {
        StrengthMath.loadPlates(target: target, bar: barInUnit, plates: available)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                inputCard
                if target > barInUnit { resultCard } else { hintCard }
                platesCard
            }
            .padding(.horizontal, 16).padding(.vertical, 8).padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Plates")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Target weight (\(unit.short))").font(.subheadline).foregroundStyle(Brand.text)
                Spacer()
                TextField("0", text: $targetText).keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing).frame(width: 100).font(Brand.mono(18))
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Bar weight").font(.subheadline).foregroundStyle(Brand.text)
                Spacer()
                Text(Fmt.weight(barWeightKg, unit: unit)).font(Brand.mono(15)).foregroundStyle(Brand.text2)
            }
            Picker("Bar", selection: $barWeightKg) {
                Text("20 kg / 44 lb").tag(20.0)
                Text("15 kg / 33 lb").tag(15.0)
                Text("10 kg / 22 lb").tag(10.0)
                Text("45 lb (20.4 kg)").tag(20.4117)
            }.pickerStyle(.menu)
        }
        .glassCard()
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "Load per side")
            if result.perSide.isEmpty {
                Text("Just the bar — no plates needed.").font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                // visual stack of plates
                HStack(spacing: 6) {
                    Rectangle().fill(Brand.text3.opacity(0.5)).frame(width: 30, height: 10)
                    ForEach(Array(result.perSide.enumerated()), id: \.offset) { _, item in
                        ForEach(0..<item.count, id: \.self) { _ in
                            plateChip(item.plate)
                        }
                    }
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(result.perSide.enumerated()), id: \.offset) { _, item in
                        Text("\(item.count) × \(plateLabel(item.plate)) \(unit.short)")
                            .font(Brand.mono(15)).foregroundStyle(Brand.text)
                    }
                }
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Loaded total").foregroundStyle(Brand.text2).font(.subheadline)
                Spacer()
                Text("\(plateLabel(result.achievable)) \(unit.short)")
                    .font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
            }
            if result.leftover > 0.01 {
                Label("Closest match is \(plateLabel(result.achievable)) \(unit.short) — \(plateLabel(result.leftover)) \(unit.short) short with the selected plates.",
                      systemImage: "info.circle")
                    .font(.footnote).foregroundStyle(Brand.warn)
            }
        }
        .glassCard()
    }

    private var hintCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Load per side")
            Text("Enter a target heavier than the bar (\(Fmt.weight(barWeightKg, unit: unit))).")
                .font(.subheadline).foregroundStyle(Brand.text2)
        }
        .glassCard()
    }

    private var platesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Available plates (\(unit.short))")
            FlexWrap(unit.standardPlates) { plate in
                let on = plateToggles[plate] ?? true
                Button {
                    plateToggles[plate] = !on; Haptics.selection()
                } label: {
                    Text(plateLabel(plate))
                        .font(Brand.mono(14, weight: .medium))
                        .foregroundStyle(on ? .white : Brand.text2)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(on ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(.ultraThinMaterial)))
                        .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(plateLabel(plate)) \(unit.short) plate")
                .accessibilityValue(on ? "available" : "unavailable")
            }
        }
        .glassCard()
    }

    private func plateChip(_ w: Double) -> some View {
        let h = 30 + min(40, w) * 1.2
        return RoundedRectangle(cornerRadius: 3)
            .fill(Brand.inkGradient)
            .frame(width: 12, height: h)
            .accessibilityHidden(true)
    }
    private func plateLabel(_ w: Double) -> String { w == w.rounded() ? String(Int(w)) : String(format: "%.2f", w) }
}

/// Simple wrapping layout for a row of chips.
struct FlexWrap<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content
    init(_ items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items; self.content = content
    }
    var body: some View {
        FlowLayout(spacing: 8) { ForEach(items, id: \.self) { content($0) } }
    }
}

/// A minimal flow layout (iOS 16+ Layout protocol).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing; rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing; rowHeight = max(rowHeight, size.height)
        }
    }
}
