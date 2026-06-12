import SwiftUI

struct DialInView: View {
    @State private var method: BrewMethod = .espresso
    @State private var dose: Double = 18
    @State private var ratio: Double = 2.0
    @State private var taste: Taste = .sour

    private var output: Double { DialInEngine.output(dose: dose, ratio: ratio) }
    private var fixTip: DialInTip { DialInEngine.nextStep(taste: taste, method: method) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    methodCard
                    calculatorCard
                    fixerCard
                    referenceCard
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Theme.bgPrimary.ignoresSafeArea())
            .navigationTitle("Dial-in")
        }
    }

    private var methodCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Method").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            Picker("Method", selection: $method) {
                ForEach(BrewMethod.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.menu)
            .onChange(of: method) { _, m in
                ratio = min(max(ratio, m.ratioRange.lowerBound), m.ratioRange.upperBound)
                if !m.ratioRange.contains(ratio) { ratio = m.defaultRatio }
            }
        }
        .cremaCard()
    }

    private var calculatorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recipe calculator").font(.headline).foregroundStyle(Theme.textPrimary)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Dose").font(.subheadline).foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(Fmt.grams(dose)).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                }
                Slider(value: $dose, in: 5...40, step: 0.5).tint(Theme.accent)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Ratio").font(.subheadline).foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(String(format: "1:%.1f", ratio)).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
                }
                Slider(value: $ratio, in: method.ratioRange, step: 0.1).tint(Theme.accent)
            }
            Divider().overlay(Theme.track)
            HStack {
                Text(method.isEspresso ? "Target yield" : "Water needed")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(Fmt.grams(output))
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.numericText())
            }
            Text("Typical \(method.rawValue) ratio: 1:\(fmtRange(method.ratioRange))")
                .font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .cremaCard()
    }

    private var fixerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Fix my cup").font(.headline).foregroundStyle(Theme.textPrimary)
            Text("How did your last \(method.rawValue.lowercased()) taste?")
                .font(.subheadline).foregroundStyle(Theme.textSecondary)
            Picker("Taste", selection: $taste) {
                ForEach(Taste.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Divider().overlay(Theme.track)
            TipRow(tip: fixTip)
        }
        .cremaCard()
    }

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick reference").font(.headline).foregroundStyle(Theme.textPrimary)
            ForEach(BrewMethod.allCases) { m in
                HStack {
                    Label(m.rawValue, systemImage: m.symbol).font(.subheadline).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("1:\(fmtRange(m.ratioRange))").font(.subheadline.weight(.medium)).foregroundStyle(Theme.accent)
                }
                .padding(.vertical, 3)
                if m != BrewMethod.allCases.last { Divider().overlay(Theme.track) }
            }
        }
        .cremaCard()
    }

    private func fmtRange(_ r: ClosedRange<Double>) -> String {
        String(format: "%.1f–%.1f", r.lowerBound, r.upperBound)
    }
}
