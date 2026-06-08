import SwiftUI

struct WeekDetailView: View {
    let week: Int
    let pregnancy: Pregnancy

    private var info: WeekInfo { WeekCatalog.info(for: week) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sizeHero
                developmentCard
                tipCard
                gainCard
            }
            .padding()
        }
        .background(Brand.pageBackground)
        .navigationTitle("Week \(week)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sizeHero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: 0x9A6FB0).opacity(0.16)).frame(width: 110, height: 110)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 44)).foregroundStyle(Color(hex: 0x9A6FB0))
            }
            .accessibilityHidden(true)
            Text("About a \(info.fruit.lowercased())")
                .font(.title2.weight(.bold)).foregroundStyle(Brand.text)
            HStack(spacing: 0) {
                metric(info.lengthString, "length")
                Rectangle().fill(Brand.hairline).frame(width: 1, height: 28)
                metric(info.weightString, "weight")
                Rectangle().fill(Brand.hairline).frame(width: 1, height: 28)
                metric(PregnancyEngine.trimesterName(PregnancyEngine.trimester(week: week))
                        .replacingOccurrences(of: " trimester", with: ""), "trimester")
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 20)
    }

    private func metric(_ v: String, _ l: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.subheadline.weight(.bold)).foregroundStyle(Brand.text)
            Text(l).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
    }

    private var developmentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "What's happening")
            Text(info.summary).font(.body).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles").foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: "This week's tip")
                Text(info.tip).font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    @ViewBuilder private var gainCard: some View {
        if let bmi = PregnancyEngine.bmi(weightKg: pregnancy.prePregnancyWeightKg, heightCm: pregnancy.heightCm) {
            let cat = PregnancyEngine.category(forBMI: bmi)
            let total = PregnancyEngine.recommendedTotalGainKg(category: cat, isMultiple: pregnancy.isMultiple)
            let soFar = PregnancyEngine.expectedGainSoFar(week: week, total: total)
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Healthy gain by now")
                Text(String(format: "%.1f – %.1f kg", soFar.lowerBound, soFar.upperBound))
                    .font(.title3.weight(.bold)).foregroundStyle(Brand.text)
                Text("Based on a \(cat.rawValue.lowercased()) starting BMI of \(String(format: "%.1f", bmi)). Total range for term: \(String(format: "%.0f–%.0f kg", total.lowerBound, total.upperBound)). Guidance only — your provider knows best.")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
    }
}
