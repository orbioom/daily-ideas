import SwiftUI

/// Interactive barbell plate calculator. Shows exactly what to load per side for a
/// target weight, in the user's unit, with a visual bar.
struct PlateCalculatorView: View {
    let initialWeightKg: Double
    let prefs: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var targetText: String = ""
    @State private var barText: String = ""

    private var target: Double { Double(targetText) ?? 0 }
    private var barWeight: Double { Double(barText) ?? 0 }

    private var loading: PlateCalculator.Loading {
        PlateCalculator.solve(target: target, barWeight: barWeight, unit: prefs.unit)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        inputs
                        barVisual
                        breakdown
                        if loading.leftoverPerSide > 0.001 {
                            mismatchNote
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private var inputs: some View {
        VStack(spacing: 14) {
            field(title: "Target weight (\(prefs.unit.display))", text: $targetText, hint: "100")
            field(title: "Bar weight (\(prefs.unit.display))", text: $barText, hint: "20")
        }
        .cardSurface()
    }

    private func field(title: String, text: Binding<String>, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            TextField(hint, text: text)
                .keyboardType(.decimalPad)
                .font(.title3.weight(.semibold))
                .padding(12)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                .onChange(of: text.wrappedValue) { _, v in
                    let f = v.filter { $0.isNumber || $0 == "." }
                    if f != v { text.wrappedValue = f }
                }
                .accessibilityLabel(title)
        }
    }

    private var barVisual: some View {
        VStack(spacing: 10) {
            HStack(spacing: 2) {
                Capsule().fill(Theme.textSecondary.opacity(0.5)).frame(width: 14, height: 8)
                ForEach(loading.perSide.reversed()) { plate in
                    ForEach(0..<plate.count, id: \.self) { _ in
                        plateView(plate.value)
                    }
                }
                Capsule().fill(Theme.textSecondary).frame(width: 30, height: 14)
                ForEach(loading.perSide) { plate in
                    ForEach(0..<plate.count, id: \.self) { _ in
                        plateView(plate.value)
                    }
                }
                Capsule().fill(Theme.textSecondary.opacity(0.5)).frame(width: 14, height: 8)
            }
            .frame(height: 90)
            .frame(maxWidth: .infinity)
            Text("Loaded: \(Units.trimmed(loading.achievable)) \(prefs.unit.display)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(loading.achievable >= target && target > 0 ? Theme.success : Theme.accent)
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bar loaded to \(Units.trimmed(loading.achievable)) \(prefs.unit.display)")
    }

    private func plateView(_ value: Double) -> some View {
        let height = min(86, max(34, CGFloat(value) * 1.6 + 30))
        return RoundedRectangle(cornerRadius: 4)
            .fill(plateColor(value))
            .frame(width: 13, height: height)
            .overlay(
                Text(Units.trimmed(value))
                    .font(.system(size: 7, weight: .bold))
                    .rotationEffect(.degrees(-90))
                    .foregroundStyle(.white)
                    .fixedSize()
            )
            .accessibilityHidden(true)
    }

    private func plateColor(_ value: Double) -> Color {
        switch value {
        case 25, 45: return Theme.coral
        case 20, 35: return Theme.rest
        case 15, 25: return Theme.pr
        case 10: return Theme.success
        default: return Theme.volume
        }
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Per side")
            if loading.perSide.isEmpty {
                Text(target > 0 ? "Just the bar — no plates needed." : "Enter a target weight to load the bar.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(loading.perSide) { plate in
                    HStack {
                        Circle().fill(plateColor(plate.value)).frame(width: 14, height: 14)
                        Text("\(Units.trimmed(plate.value)) \(prefs.unit.display)")
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("× \(plate.count)")
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .font(.subheadline)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(Units.trimmed(plate.value)) \(prefs.unit.display) plates, \(plate.count) per side")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var mismatchNote: some View {
        Label("\(Units.trimmed(loading.leftoverPerSide)) \(prefs.unit.display) per side can't be matched with standard plates.",
              systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(Theme.coral)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Theme.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private func prefill() {
        let bar = Units.display(fromKg: prefs.barWeightKg, unit: prefs.unit)
        barText = Units.trimmed(bar)
        if initialWeightKg > 0 {
            targetText = Units.trimmed(Units.display(fromKg: initialWeightKg, unit: prefs.unit))
        }
    }
}

#Preview {
    PlateCalculatorView(initialWeightKg: 100, prefs: AppSettings())
}
