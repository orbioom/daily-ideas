import SwiftUI

struct GuideView: View {
    @AppStorage("useMetric") private var useMetric = true
    @AppStorage("defaultLogReductions") private var defaultLogReductions = 6.5

    private let pasteurTemps: [Double] = [55, 57.5, 60, 62.5, 65, 68]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        howCard
                        pasteurizationCard
                        ForEach(DonenessGuide.categories, id: \.self) { cat in
                            categorySection(cat)
                        }
                    }
                    .padding(.horizontal, 18).padding(.vertical, 14)
                }
            }
            .navigationTitle("Guide")
        }
    }

    private var howCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "How Plateau times a cook")
            bullet("Come-up", "Solving the heat equation for your food's thickness and shape — how long the core takes to reach the bath temperature.")
            bullet("Hold", "A thermal-death-time model adds the minutes needed to pasteurize at that temperature, where it's achievable.")
            bullet("Total", "The minimum safe time. Sous vide is forgiving — holding longer rarely hurts.")
        }
        .glassCard()
    }

    private func bullet(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(Brand.warn).frame(width: 7, height: 7).padding(.top, 6)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                Text(body).font(.caption).foregroundStyle(Brand.text2)
            }
        }
    }

    private var pasteurizationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Pasteurization hold",
                          trailing: "\(formatted(defaultLogReductions))-log")
            VStack(spacing: 0) {
                ForEach(Array(pasteurTemps.enumerated()), id: \.offset) { i, t in
                    let mins = PlateauMath.pasteurizeMinutes(bathC: t, logReductions: defaultLogReductions)
                    HStack {
                        Text(TempFmt.temp(t, metric: useMetric))
                            .font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
                        Spacer()
                        Text(TempFmt.duration(mins)).font(Brand.mono(15)).foregroundStyle(Brand.live)
                    }
                    .padding(.vertical, 9)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(TempFmt.temp(t, metric: useMetric)): hold \(TempFmt.duration(mins))")
                    if i < pasteurTemps.count - 1 { Divider().overlay(Brand.hairline) }
                }
            }
            Text("Salmonella model (D₆₀ = 2 min, z = 5.6°C). Hold time begins once the core reaches temperature.")
                .font(.caption2).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private func categorySection(_ category: String) -> some View {
        let items = DonenessGuide.presets.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: category)
            ForEach(items) { preset in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: preset.symbol).foregroundStyle(Brand.warn)
                            .frame(width: 24).accessibilityHidden(true)
                        Text(preset.name).font(.headline).foregroundStyle(Brand.text)
                        Spacer()
                        Chip(text: "\(Int(preset.defaultThicknessMM))mm \(preset.shape.short.lowercased())")
                    }
                    ForEach(preset.levels) { lvl in
                        HStack {
                            Text(lvl.name).font(.subheadline).foregroundStyle(Brand.text)
                            Text(lvl.detail).font(.caption).foregroundStyle(Brand.text3)
                            Spacer()
                            Text(TempFmt.temp(lvl.celsius, metric: useMetric))
                                .font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text2)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(preset.name) \(lvl.name): \(TempFmt.temp(lvl.celsius, metric: useMetric))")
                    }
                    Text(preset.note).font(.caption).foregroundStyle(Brand.text3)
                }
                .glassCard()
            }
        }
    }

    private func formatted(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(v)
    }
}
