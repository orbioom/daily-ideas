import SwiftUI

struct CompatibilityView: View {
    let profileA: Profile
    let profileB: Profile
    @EnvironmentObject private var settings: AppSettings

    private var report: CompatibilityResult {
        CompatibilityEngine.compatibility(
            profileA.scoredResult, nameA: shortName(profileA.name),
            profileB.scoredResult, nameB: shortName(profileB.name)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                scoreCard
                radarCard
                perTraitCard
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Compatibility")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func shortName(_ name: String) -> String {
        // Strip the "(sample)" suffix for cleaner copy.
        name.replacingOccurrences(of: " (sample)", with: "")
    }

    private var scoreCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Text(shortName(profileA.name)).bold()
                Image(systemName: "heart.fill").foregroundStyle(.white.opacity(0.9))
                    .accessibilityHidden(true)
                Text(shortName(profileB.name)).bold()
            }
            .font(Theme.rounded(17, .semibold))
            .foregroundStyle(.white)

            Text("\(Int(report.overall))%")
                .font(Theme.rounded(56, .bold))
                .foregroundStyle(.white)
                .accessibilityLabel("Overall compatibility \(Int(report.overall)) percent")

            Text(report.band)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 14).padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.2)))

            Text(report.headline)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(report.summary)
                .font(Theme.rounded(15))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.heroGradient))
    }

    private var radarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Side by side", systemImage: "chart.dots.scatter")
            TraitRadar(primary: profileA.scoredResult,
                       secondary: profileB.scoredResult,
                       primaryColor: Theme.accent,
                       secondaryColor: Theme.good)
                .frame(height: 240)
            HStack(spacing: 20) {
                legendDot(color: Theme.accent, label: shortName(profileA.name))
                legendDot(color: Theme.good, label: shortName(profileB.name))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .cardSurface()
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
    }

    private var perTraitCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Trait by trait", systemImage: "list.bullet")
            ForEach(report.perTrait) { tc in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: tc.trait.symbolName)
                            .foregroundStyle(Theme.accent).font(.system(size: 13))
                            .accessibilityHidden(true)
                        Text(tc.trait.rawValue)
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(tc.isComplementary ? "Complementary" : "\(Int(tc.similarity))% aligned")
                            .font(Theme.rounded(12, .semibold))
                            .foregroundStyle(tc.isComplementary ? Theme.warn : Theme.good)
                    }
                    Text(tc.note)
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                if tc.id != report.perTrait.last?.id {
                    Divider().overlay(Theme.hairline)
                }
            }
        }
        .padding(18)
        .cardSurface()
    }
}
