import SwiftUI
import SwiftData
import Charts
import UIKit

struct ResultDetailView: View {
    @Bindable var profile: Profile
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext

    @State private var paywallReason: PaywallReason?
    @State private var shareImage: ShareableImage?

    private var result: ScoredResult { profile.scoredResult }
    private var archetype: Archetype { result.archetype }
    private var identity: Identity { TypeMapper.identity(for: result.traitScores) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                chartCard
                aboutTypeCard
                gatedSections
                methodologyNote
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(profile.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if isPro {
                        exportShareCard()
                    } else {
                        paywallReason = .shareCard
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share result card")
            }
        }
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        .sheet(item: $shareImage) { item in
            ShareSheet(items: [item.image])
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            TypeBadge(code: result.typeCode, identity: identity, size: 40)
            Text(archetype.name)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(.white)
            Text(archetype.tagline)
                .font(Theme.rounded(16))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
            Text(identity.blurb)
                .font(Theme.rounded(13))
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.heroGradient)
        )
    }

    // MARK: - Charts

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Your Big Five", systemImage: "chart.bar.fill")

            Chart(result.traitScores) { ts in
                BarMark(
                    x: .value("Score", ts.score),
                    y: .value("Trait", ts.trait.shortLabel)
                )
                .foregroundStyle(Theme.heroGradient)
                .cornerRadius(6)
                .annotation(position: .trailing) {
                    Text(settings.showTraitPercentages ? "\(Int(ts.score))%" : ts.band.rawValue)
                        .font(Theme.rounded(11, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .chartXScale(domain: 0...100)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let s = value.as(String.self),
                           let trait = Trait.allCases.first(where: { $0.shortLabel == s }) {
                            Text(trait.rawValue)
                                .font(Theme.rounded(12, .medium))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: [0, 50, 100])
            }
            .frame(height: 220)
            .accessibilityLabel("Big Five bar chart")
            .accessibilityValue(result.traitScores.map { "\($0.trait.rawValue) \(Int($0.score)) percent" }.joined(separator: ", "))

            Divider().overlay(Theme.hairline)

            TraitRadar(primary: result)
                .frame(height: 220)

            VStack(spacing: 12) {
                ForEach(result.traitScores) { ts in
                    TraitBar(traitScore: ts, showPercentage: settings.showTraitPercentages)
                }
            }
        }
        .padding(18)
        .cardSurface()
    }

    private var aboutTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "About \(archetype.name)", systemImage: "text.alignleft")
            Text(archetype.description)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(TypeMapper.dimensions) { dim in
                let r = TypeMapper.resolved(dim, in: result)
                HStack {
                    Text(dim.title)
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(width: 70, alignment: .leading)
                    Text("\(r.letter) · \(r.label)")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
            }
        }
        .padding(18)
        .cardSurface()
    }

    // MARK: - Pro-gated deep sections

    @ViewBuilder
    private var gatedSections: some View {
        if isPro {
            reportList(title: "Strengths", symbol: "bolt.fill", items: archetype.strengths, color: Theme.good)
            reportList(title: "Growth areas", symbol: "leaf.fill", items: archetype.growthAreas, color: Theme.warn)
            reportList(title: "Careers that fit", symbol: "briefcase.fill", items: archetype.careers, color: Theme.accent)
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "In relationships", systemImage: "heart.fill")
                Text(archetype.relationshipNotes)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .cardSurface()
        } else {
            lockedReportTeaser
        }
    }

    private func reportList(title: String, symbol: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, systemImage: symbol)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle().fill(color).frame(width: 7, height: 7).padding(.top, 7)
                        .accessibilityHidden(true)
                    Text(item)
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
        }
        .padding(18)
        .cardSurface()
    }

    private var lockedReportTeaser: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Your full report")
                ProLockChip()
            }
            Text("Unlock your strengths, growth areas, ideal careers, and how you show up in relationships — tailored to \(archetype.name).")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "Unlock full report", systemImage: "lock.open.fill") {
                paywallReason = .fullReport
            }
        }
        .padding(18)
        .cardSurface()
    }

    private var methodologyNote: some View {
        Text("Scores come from public-domain IPIP Big Five items. The four-letter type and archetype are a friendly summary of those traits — not a clinical diagnosis.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
    }

    // MARK: - Share card export

    @MainActor
    private func exportShareCard() {
        let card = ShareCardView(profile: profile)
            .frame(width: 340, height: 480)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            shareImage = ShareableImage(image: uiImage)
            Haptics.tap(enabled: settings.hapticsEnabled)
        }
    }
}

/// Wrapper so a UIImage can drive an `.sheet(item:)`.
struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// UIKit share sheet bridge (ShareLink can't take an in-memory UIImage as cleanly).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
