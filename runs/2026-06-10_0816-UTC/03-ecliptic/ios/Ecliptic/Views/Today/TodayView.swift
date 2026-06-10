import SwiftUI
import SwiftData

/// Today's sky and its transits to the primary chart.
struct TodayView: View {
    @Query(sort: \ChartProfile.createdAt) private var profiles: [ChartProfile]
    @AppStorage("includeModern") private var includeModern = true
    @AppStorage("transitOrb") private var transitOrb = 3.0
    @AppStorage("houseSystem") private var houseSystemRaw = HouseSystem.wholeSign.rawValue

    @State private var sky: [PlanetPosition]?
    @State private var transits: [TransitHit] = []
    @State private var computedAt = Date()

    private var primary: ChartProfile? {
        profiles.first(where: \.isPrimary) ?? profiles.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if let sky {
                    content(sky)
                } else {
                    ProgressView("Reading the sky…")
                        .tint(Brand.text2)
                        .foregroundStyle(Brand.text2)
                }
            }
            .navigationTitle("Today")
            .task(id: taskKey) { compute() }
            .refreshable { compute() }
        }
    }

    private var taskKey: String {
        "\(profiles.count)-\(includeModern)-\(transitOrb)-\(primary?.birthDate.timeIntervalSince1970 ?? 0)"
    }

    private func compute() {
        let now = Date()
        let jd = Astronomy.julianDay(now)
        let positions = ChartEngine.positions(jd: jd, includeModern: includeModern)
        var hits: [TransitHit] = []
        if let p = primary {
            let natal = ChartEngine.chart(birthDate: p.birthDate, latitude: p.latitude,
                                          longitude: p.longitude, timeKnown: p.timeKnown,
                                          houseSystem: HouseSystem(rawValue: houseSystemRaw) ?? .wholeSign,
                                          includeModern: includeModern)
            hits = ChartEngine.transits(natal: natal.positions, sky: positions, maxOrb: transitOrb)
        }
        sky = positions
        transits = hits
        computedAt = now
    }

    private func content(_ sky: [PlanetPosition]) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                skyCard(sky)
                transitsCard
                positionsCard(sky)
            }
            .padding(16)
        }
    }

    private func skyCard(_ sky: [PlanetPosition]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: "The sky now")
                Spacer()
                Text(computedAt, format: .dateTime.hour().minute())
                    .font(Brand.mono(12))
                    .foregroundStyle(Brand.text3)
            }
            if let sun = sky.first(where: { $0.planet == .sun }),
               let moon = sky.first(where: { $0.planet == .moon }) {
                HStack(spacing: 14) {
                    VStack(spacing: 4) {
                        Text(sun.sign.glyph)
                            .font(.system(size: 34))
                            .accessibilityHidden(true)
                        Text("Sun in \(sun.sign.name)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                        Text(sun.formattedDegree)
                            .font(Brand.mono(12))
                            .foregroundStyle(Brand.text3)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    VStack(spacing: 4) {
                        Text(moon.sign.glyph)
                            .font(.system(size: 34))
                            .accessibilityHidden(true)
                        Text("Moon in \(moon.sign.name)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                        Text(moon.formattedDegree)
                            .font(Brand.mono(12))
                            .foregroundStyle(Brand.text3)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
                Text("The Moon sets the day's emotional weather: \(moon.sign.style).")
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
            }
        }
        .glassCard()
    }

    @ViewBuilder
    private var transitsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Your transits")
            if primary == nil {
                Text("Add your birth chart in People to see how today's sky touches it.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            } else if transits.isEmpty {
                HStack(spacing: 10) {
                    StatusDot()
                    Text("A quiet sky — nothing within \(String(format: "%.0f", transitOrb))° of your chart today. Rest counts as progress.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
            } else {
                ForEach(transits) { hit in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(hit.kind.glyph)
                                .foregroundStyle(hit.kind.isHarmonious ? Brand.live : Brand.text2)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            Text(hit.headline)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Brand.text)
                        }
                        Text(hit.detail)
                            .font(.caption)
                            .foregroundStyle(Brand.text2)
                            .padding(.leading, 24)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    if hit.id != transits.last?.id { Divider() }
                }
            }
        }
        .glassCard()
    }

    private func positionsCard(_ sky: [PlanetPosition]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "All positions")
            ForEach(sky) { position in
                HStack {
                    Text(position.planet.glyph)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text(position.planet.name)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text)
                    Spacer()
                    Text("\(position.sign.glyph) \(position.sign.name) \(position.formattedDegree)")
                        .font(Brand.mono(13))
                        .foregroundStyle(Brand.text2)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(position.summary)
            }
            Text("Computed on this device from orbital elements — pull to refresh.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .glassCard()
    }
}
