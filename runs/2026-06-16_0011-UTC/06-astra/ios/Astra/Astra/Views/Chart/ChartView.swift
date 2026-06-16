import SwiftUI
import SwiftData

struct ChartView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Profile.createdDate) private var profiles: [Profile]

    @State private var selectedProfileID: UUID?
    @State private var detailPlanet: Planet?
    @State private var paywallReason: PaywallReason?
    @State private var showAddProfile = false

    private var activeProfile: Profile? {
        if let id = selectedProfileID, let match = profiles.first(where: { $0.id == id }) {
            return match
        }
        return ProfileResolver.primary(from: profiles, primaryID: settings.primaryProfileID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.skyGradient.ignoresSafeArea()
                Starfield(starCount: 40).ignoresSafeArea()
                content
            }
            .navigationTitle("Chart")
            .toolbar {
                if profiles.count > 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        profileMenu
                    }
                }
            }
            .sheet(item: $detailPlanet) { planet in
                if let profile = activeProfile {
                    PlanetDetailSheet(planet: planet, chart: ChartService.chart(for: profile))
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showAddProfile) {
                ProfileEditorView(profile: nil)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let profile = activeProfile {
            if isPro {
                wheelContent(for: profile)
            } else {
                lockedContent(for: profile)
            }
        } else {
            EmptyStateView(
                symbol: "circle.hexagongrid.fill",
                title: "No chart yet",
                message: "Create a chart to see your natal wheel drawn to the exact degree.",
                actionTitle: "Create your chart"
            ) {
                showAddProfile = true
            }
            .padding()
        }
    }

    private func wheelContent(for profile: Profile) -> some View {
        let chart = ChartService.chart(for: profile)
        let aspects = AspectEngine.aspects(in: chart.positions, baseOrb: settings.defaultOrb)

        return ScrollView {
            VStack(spacing: 16) {
                bigThreeHeader(profile: profile, chart: chart)

                ZodiacWheel(chart: chart, aspects: aspects) { planet in
                    Haptics.tap(enabled: settings.hapticsEnabled)
                    detailPlanet = planet
                }
                .frame(height: 340)
                .padding(.vertical, 8)

                Text("Tap any planet to read its placement. Glyphs in red are retrograde.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
                    .multilineTextAlignment(.center)

                legend
            }
            .padding(16)
        }
    }

    private func bigThreeHeader(profile: Profile, chart: Chart) -> some View {
        let sun = chart.position(.sun)?.sign ?? .aries
        let moon = chart.position(.moon)?.sign ?? .aries
        let rising = chart.ascendantSign

        return VStack(spacing: 10) {
            Text(profile.name)
                .font(Theme.serif(22, .bold))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 10) {
                bigThreeChip("Sun", sun.glyph, sun.name)
                bigThreeChip("Moon", moon.glyph, moon.name)
                if let rising {
                    bigThreeChip("Rising", rising.glyph, rising.name)
                } else {
                    bigThreeChip("Rising", "?", "No time")
                }
            }
        }
    }

    private func bigThreeChip(_ caption: String, _ glyph: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(caption.uppercased())
                .font(Theme.rounded(10, .bold))
                .foregroundStyle(Theme.inkFaint)
            Text(glyph)
                .font(.system(size: 22))
                .foregroundStyle(Theme.gold)
            Text(value)
                .font(Theme.rounded(12, .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption): \(value)")
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Aspect lines", systemImage: "line.diagonal")
            ForEach(AspectKind.allCases) { kind in
                HStack(spacing: 10) {
                    Capsule().fill(kind.color).frame(width: 22, height: 3)
                    Text(kind.rawValue).font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.ink)
                    Text(kind.glyph).foregroundStyle(kind.color)
                    Spacer()
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func lockedContent(for profile: Profile) -> some View {
        let chart = ChartService.chart(for: profile)
        return ScrollView {
            VStack(spacing: 16) {
                bigThreeHeader(profile: profile, chart: chart)

                ZStack {
                    ZodiacWheel(chart: chart, aspects: [])
                        .frame(height: 300)
                        .blur(radius: 7)
                        .opacity(0.6)
                        .accessibilityHidden(true)
                    VStack(spacing: 12) {
                        ProLockChip()
                        Text("The full natal wheel")
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Every planet at its exact degree, with all aspect lines, is part of Astra Pro.")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                }

                PrimaryButton(title: "Unlock the wheel (\(Pro.priceLabel))", systemImage: "lock.open.fill") {
                    paywallReason = .fullWheel
                }
            }
            .padding(16)
        }
    }

    private var profileMenu: some View {
        Menu {
            ForEach(profiles) { p in
                Button {
                    selectedProfileID = p.id
                } label: {
                    Label(p.name, systemImage: p.id == activeProfile?.id ? "checkmark" : "person")
                }
            }
        } label: {
            Image(systemName: "person.2.fill")
        }
        .accessibilityLabel("Switch chart")
    }
}

#Preview {
    ChartView()
        .modelContainer(PreviewContainer.shared)
        .environmentObject(AppSettings())
}
