import SwiftUI
import SwiftData

struct PlacementsView: View {
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
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Placements")
            .toolbar {
                if profiles.count > 1 {
                    ToolbarItem(placement: .topBarTrailing) { profileMenu }
                }
            }
            .sheet(item: $detailPlanet) { planet in
                if let profile = activeProfile {
                    PlanetDetailSheet(planet: planet, chart: ChartService.chart(for: profile))
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showAddProfile) { ProfileEditorView(profile: nil) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let profile = activeProfile {
            loaded(profile)
        } else {
            EmptyStateView(
                symbol: "list.star",
                title: "No placements yet",
                message: "Create a chart to see every planet's sign, house, and meaning.",
                actionTitle: "Create your chart"
            ) { showAddProfile = true }
            .padding()
        }
    }

    private func loaded(_ profile: Profile) -> some View {
        let chart = ChartService.chart(for: profile)
        let aspects = AspectEngine.aspects(in: chart.positions, baseOrb: settings.defaultOrb)

        return ScrollView {
            LazyVStack(spacing: 16, pinnedViews: []) {
                bigThree(profile: profile, chart: chart)

                if !profile.hasExactTime {
                    noTimeBanner
                }

                placementsList(chart: chart)

                if isPro {
                    aspectsList(aspects)
                } else {
                    aspectsLocked
                }
            }
            .padding(16)
        }
    }

    private func bigThree(profile: Profile, chart: Chart) -> some View {
        let sun = chart.position(.sun)?.sign ?? .aries
        let moon = chart.position(.moon)?.sign ?? .aries
        let rising = chart.ascendantSign

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                ProfileAvatar(initial: profile.initial, seed: profile.colorSeed, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name).font(Theme.serif(20, .bold)).foregroundStyle(Theme.ink)
                    Text(profile.locationName).font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
                }
                Spacer()
            }
            HStack(spacing: 10) {
                headlineChip("Sun", sun)
                headlineChip("Moon", moon)
                if let rising { headlineChip("Rising", rising) }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func headlineChip(_ label: String, _ sign: ZodiacSign) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased()).font(Theme.rounded(10, .bold)).foregroundStyle(Theme.inkFaint)
            Text(sign.glyph).font(.system(size: 20)).foregroundStyle(sign.element.color)
            Text(sign.name).font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.ink)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).fill(Theme.surfaceAlt))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(sign.name)")
    }

    private var noTimeBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.questionmark")
                .foregroundStyle(Theme.warn)
                .accessibilityHidden(true)
            Text("Birth time unknown — houses and Rising are hidden. Planet signs remain accurate.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).fill(Theme.goldSoft))
    }

    private func placementsList(chart: Chart) -> some View {
        // Free tier: only Sun/Moon (+ Rising shown via big three). Pro: all planets.
        let visible: [Planet] = isPro ? Planet.allCases : [.sun, .moon]

        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Planets", systemImage: "circle.grid.cross.fill")
                .padding(.bottom, 8)
            ForEach(visible) { planet in
                placementRow(planet: planet, chart: chart)
                if planet != visible.last {
                    Divider().overlay(Theme.hairline)
                }
            }
            if !isPro {
                lockedPlanetsRow
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func placementRow(planet: Planet, chart: Chart) -> some View {
        let pos = chart.position(planet)
        let sign = pos?.sign ?? .aries
        let house = chart.house(for: planet)

        return Button {
            Haptics.tap(enabled: settings.hapticsEnabled)
            detailPlanet = planet
        } label: {
            HStack(spacing: 12) {
                Text(settings.glyphStyle == .symbol ? planet.glyph : "")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.gold)
                    .frame(width: settings.glyphStyle == .symbol ? 28 : 0)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(planet.name).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                        if pos?.retrograde == true {
                            Text("Rx").font(Theme.rounded(11, .bold))
                                .foregroundStyle(Theme.bad)
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(Capsule().fill(Theme.bad.opacity(0.15)))
                        }
                    }
                    Text(shortInterp(planet: planet, sign: sign))
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(sign.glyph).foregroundStyle(sign.element.color)
                        Text(sign.name).font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.ink)
                    }
                    if settings.showDegrees, let pos {
                        Text(ChartService.formatDegree(pos.degreesInSign))
                            .font(Theme.mono(11)).foregroundStyle(Theme.inkFaint)
                    }
                    if let house {
                        Text(house.ordinal).font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                    }
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(planet.name) in \(sign.name)\(pos?.retrograde == true ? ", retrograde" : "")\(house.map { ", \($0.ordinal) house" } ?? "")")
        .accessibilityHint("Opens placement detail")
    }

    private func shortInterp(planet: Planet, sign: ZodiacSign) -> String {
        switch planet {
        case .sun: return "Core self runs on \(sign.keywords.first ?? "this") energy"
        case .moon: return "Feels safest when things are \(sign.keywords.first ?? "steady")"
        default: return "\(planet.keywords.first?.capitalized ?? "Expression") in a \(sign.keywords.first ?? "distinct") key"
        }
    }

    private var lockedPlanetsRow: some View {
        Button {
            paywallReason = .allPlacements
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill").foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mercury through Pluto + aspects")
                        .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                    Text("See every placement with Astra Pro")
                        .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                ProLockChip()
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func aspectsList(_ aspects: [AspectHit]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Aspects", systemImage: "line.diagonal.arrow")
                .padding(.bottom, 8)
            if aspects.isEmpty {
                Text("No major aspects within your orb. Try a wider orb in Settings.")
                    .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    .padding(.vertical, 8)
            } else {
                ForEach(aspects) { hit in
                    aspectRow(hit)
                    if hit.id != aspects.last?.id {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func aspectRow(_ hit: AspectHit) -> some View {
        HStack(spacing: 12) {
            Text(hit.kind.glyph)
                .font(.system(size: 18))
                .foregroundStyle(hit.kind.color)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(hit.a.name) \(hit.kind.rawValue.lowercased()) \(hit.b.name)")
                    .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                Text(hit.kind.meaning)
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                    .lineLimit(2)
            }
            Spacer()
            Text(hit.exactness)
                .font(Theme.mono(11)).foregroundStyle(Theme.inkFaint)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private var aspectsLocked: some View {
        Button {
            paywallReason = .allPlacements
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "line.diagonal.arrow").foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your aspects").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                    Text("Every aspect with its meaning is part of Astra Pro")
                        .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                ProLockChip()
            }
            .padding(16)
            .contentShape(Rectangle())
            .cardSurface()
        }
        .buttonStyle(.plain)
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
    PlacementsView()
        .modelContainer(PreviewContainer.shared)
        .environmentObject(AppSettings())
}
