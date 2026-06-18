import SwiftUI

struct DonenessGuideList: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @State private var showPaywall = false

    /// Free users see the core safe temps; the extended chef-preferred set is Pro.
    private var freeCount: Int { 6 }

    private var visibleGuides: [DonenessEngine.DonenessGuide] {
        pro.isPro ? DonenessEngine.guides : Array(DonenessEngine.guides.prefix(freeCount))
    }

    private var lockedCount: Int {
        max(0, DonenessEngine.guides.count - visibleGuides.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(Theme.good)
                    .accessibilityHidden(true)
                Text("USDA-safe internal temperatures. Measure the thickest part.")
                    .font(Theme.roundedStyle(.footnote))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .crispCard(radius: Theme.chipRadius)

            ForEach(visibleGuides) { guide in
                donenessRow(guide)
            }

            if lockedCount > 0 {
                Button { showPaywall = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(lockedCount) more chef-preferred targets")
                                .font(Theme.roundedStyle(.subheadline, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("Unlock the full doneness guide with Crisp Pro.")
                                .font(Theme.roundedStyle(.caption))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
                    }
                    .padding(16)
                    .crispCard()
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func donenessRow(_ g: DonenessEngine.DonenessGuide) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(g.food)
                    .font(Theme.roundedStyle(.headline, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(settings.tempUnit == .fahrenheit ? "\(g.safeF)°F" : "\(g.safeC)°C")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.accent)
                    .monospacedDigit()
            }
            if g.preferredF != g.safeF {
                Text("Preferred: \(settings.tempUnit == .fahrenheit ? "\(g.preferredF)°F" : "\(g.preferredC)°C")")
                    .font(Theme.roundedStyle(.caption, .semibold))
                    .foregroundStyle(Theme.warn)
            }
            Text(g.note)
                .font(Theme.roundedStyle(.footnote))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .crispCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(g.food), safe at \(settings.tempUnit == .fahrenheit ? "\(g.safeF) Fahrenheit" : "\(g.safeC) Celsius")")
    }
}
