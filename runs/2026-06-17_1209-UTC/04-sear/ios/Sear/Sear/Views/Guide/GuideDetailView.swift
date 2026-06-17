import SwiftUI

/// Full doneness detail for a cut, including chef levels and the reverse-sear
/// calculator (both Pro-gated).
struct GuideDetailView: View {
    @Environment(AppSettings.self) private var settings
    @AppStorage("isPro") private var isPro = false
    let entry: GuideEntry

    @State private var paywallReason: PaywallReason?
    @State private var calcWeightLb: Double = 2

    /// Levels shown to everyone (chef levels are Pro-only).
    private var visibleLevels: [DonenessLevel] {
        isPro ? entry.levels : entry.levels.filter { !$0.chefLevel }
    }

    private var hiddenChefCount: Int {
        entry.levels.filter { $0.chefLevel }.count
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    donenessCard
                    if !isPro && hiddenChefCount > 0 {
                        chefTeaser
                    }
                    factsCard
                    if entry.protein == .beef || entry.protein == .lamb || entry.protein == .pork {
                        reverseSearCard
                    }
                    tipCard
                }
                .padding(16)
            }
        }
        .navigationTitle(entry.cut)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(entry.protein.label, systemImage: entry.protein.symbol)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(entry.protein.hue)
            Text(entry.cut)
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var donenessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pull temperatures")
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
            ForEach(visibleLevels) { level in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(level.name)
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                        if level.isUSDASafe {
                            Text("USDA-safe minimum")
                                .font(Theme.rounded(11, .semibold))
                                .foregroundStyle(Theme.good)
                        } else if level.chefLevel {
                            Text("Chef level")
                                .font(Theme.rounded(11, .semibold))
                                .foregroundStyle(Theme.ember)
                        }
                    }
                    Spacer()
                    Text(settings.temp(level.tempC))
                        .font(Theme.numeral(20, .bold))
                        .foregroundStyle(Theme.accent)
                        .monospacedDigit()
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }
        }
        .searCard()
    }

    private var chefTeaser: some View {
        Button { paywallReason = .advancedGuide } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(hiddenChefCount) more chef level\(hiddenChefCount == 1 ? "" : "s")")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Unlock rare/medium-well and other chef temps with Pro.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
            }
            .searCard()
        }
        .buttonStyle(.plain)
    }

    private var factsCard: some View {
        VStack(spacing: 10) {
            factRow("Smoker / grill temp", settings.temp(entry.smokerTempC), "flame")
            Divider().background(Theme.hairline)
            factRow("Time per pound", "~\(Int(entry.minutesPerLb)) min", "clock")
            Divider().background(Theme.hairline)
            factRow("Rest", "\(entry.restMinutes) min", "pause")
            Divider().background(Theme.hairline)
            factRow("Wood pairing", entry.woodPairing, "leaf")
        }
        .searCard()
    }

    private func factRow(_ title: String, _ value: String, _ symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var reverseSearCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Reverse-sear calculator", systemImage: "function")
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
            if isPro {
                Text("Estimate the low-and-slow roast time before the final hot sear.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                HStack {
                    Text("Weight")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text(String(format: "%.1f lb", calcWeightLb))
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                }
                Slider(value: $calcWeightLb, in: 0.5...12, step: 0.5)
                    .tint(Theme.accent)
                    .accessibilityValue(String(format: "%.1f pounds", calcWeightLb))
                let roastMin = Int((calcWeightLb * entry.minutesPerLb * 0.85).rounded())
                HStack(spacing: 12) {
                    calcStat("Low roast", "~\(roastMin) min")
                    calcStat("Sear", "2–4 min/side")
                    calcStat("Rest", "\(entry.restMinutes) min")
                }
            } else {
                Button { paywallReason = .reverseSearCalc } label: {
                    HStack {
                        Image(systemName: "lock.fill").foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text("Unlock the reverse-sear calculator with Pro")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .searCard()
    }

    private func calcStat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.accent)
                .monospacedDigit()
            Text(title)
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceAlt))
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Theme.ember)
                .accessibilityHidden(true)
            Text(entry.note)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .searCard()
    }
}
