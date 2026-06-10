import SwiftUI
import SwiftData

/// The Chart tab: shows the primary profile's chart, or invites setup.
struct ChartTabView: View {
    @Query(sort: \ChartProfile.createdAt) private var profiles: [ChartProfile]
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if let primary = profiles.first(where: \.isPrimary) ?? profiles.first {
                    ChartScreen(profile: primary)
                } else {
                    VStack(spacing: 16) {
                        EmptyStateView(
                            icon: "circle.hexagongrid",
                            title: "No chart yet",
                            message: "Add your birth date, time, and place — the ephemeris does the rest, entirely on this device."
                        )
                        Button {
                            showEditor = true
                        } label: {
                            Label("Add your birth details", systemImage: "person.crop.circle.badge.plus")
                        }
                        .buttonStyle(GlassButtonStyle())
                        .padding(.horizontal, 48)
                    }
                }
            }
            .navigationTitle("Chart")
            .sheet(isPresented: $showEditor) {
                ProfileEditorView(profile: nil, makePrimary: true)
            }
        }
    }
}

/// A full chart for one profile: wheel, angles, placements, aspects.
struct ChartScreen: View {
    let profile: ChartProfile

    @AppStorage("houseSystem") private var houseSystemRaw = HouseSystem.wholeSign.rawValue
    @AppStorage("includeModern") private var includeModern = true
    @State private var chart: Chart?

    private var houseSystem: HouseSystem { HouseSystem(rawValue: houseSystemRaw) ?? .wholeSign }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let chart {
                    header(chart)
                    ChartWheelView(chart: chart)
                        .padding(.horizontal, 24)
                    placements(chart)
                    aspects(chart)
                } else {
                    ProgressView("Computing the sky…")
                        .tint(Brand.text2)
                        .foregroundStyle(Brand.text2)
                        .padding(.vertical, 80)
                }
            }
            .padding(16)
        }
        .task(id: "\(profile.birthDate.timeIntervalSince1970)-\(houseSystemRaw)-\(includeModern)-\(profile.latitude)-\(profile.longitude)-\(profile.timeKnown)") {
            chart = ChartEngine.chart(birthDate: profile.birthDate,
                                      latitude: profile.latitude,
                                      longitude: profile.longitude,
                                      timeKnown: profile.timeKnown,
                                      houseSystem: houseSystem,
                                      includeModern: includeModern)
        }
    }

    private func header(_ chart: Chart) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Brand.text)
                    Text(profile.birthDescription)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                    Text(profile.placeName)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
                Spacer()
                if profile.isPrimary {
                    HStack(spacing: 5) {
                        StatusDot()
                        Text("you")
                            .font(.caption)
                            .foregroundStyle(Brand.live)
                    }
                    .accessibilityLabel("Primary chart")
                }
            }
            HStack(spacing: 14) {
                bigThree("Sun", chart.positions.first { $0.planet == .sun })
                bigThree("Moon", chart.positions.first { $0.planet == .moon })
                if let asc = chart.ascendant {
                    VStack(spacing: 2) {
                        Text(Sign.at(longitude: asc).glyph)
                            .font(.title3)
                            .accessibilityHidden(true)
                        Text("\(Sign.at(longitude: asc).name)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Brand.text)
                        Text("Rising")
                            .font(.caption2)
                            .foregroundStyle(Brand.text3)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                } else {
                    VStack(spacing: 2) {
                        Text("—")
                            .font(.title3)
                            .foregroundStyle(Brand.text3)
                        Text("No time")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Brand.text2)
                        Text("Rising")
                            .font(.caption2)
                            .foregroundStyle(Brand.text3)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Rising sign unavailable without a birth time")
                }
            }
        }
        .glassCard()
    }

    private func bigThree(_ label: String, _ position: PlanetPosition?) -> some View {
        VStack(spacing: 2) {
            Text(position?.sign.glyph ?? "—")
                .font(.title3)
                .accessibilityHidden(true)
            Text(position?.sign.name ?? "—")
                .font(.caption.weight(.medium))
                .foregroundStyle(Brand.text)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) in \(position?.sign.name ?? "unknown")")
    }

    private func placements(_ chart: Chart) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Placements")
            ForEach(chart.positions) { position in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(position.planet.glyph)
                            .font(.title3)
                            .frame(width: 26)
                            .accessibilityHidden(true)
                        Text(position.summary)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                        Spacer()
                        if let house = chart.house(of: position.longitude) {
                            Text("H\(house)")
                                .font(Brand.mono(12, weight: .medium))
                                .foregroundStyle(Brand.text3)
                                .accessibilityLabel("House \(house)")
                        }
                    }
                    Text(position.meaning)
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                        .padding(.leading, 26)
                    if let house = chart.house(of: position.longitude),
                       house >= 1, house <= ChartEngine.houseMeanings.count {
                        Text("House \(house): \(ChartEngine.houseMeanings[house - 1])")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                            .padding(.leading, 26)
                    }
                }
                .padding(.vertical, 4)
                if position.id != chart.positions.last?.id { Divider() }
            }
            if chart.ascendant == nil {
                Text("Houses and the rising sign need a birth time.")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }

    private func aspects(_ chart: Chart) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Aspects")
            if chart.aspects.isEmpty {
                Text("No major aspects within orb — a rare, quiet chart.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
            } else {
                ForEach(chart.aspects) { aspect in
                    HStack {
                        Text(aspect.kind.glyph)
                            .font(.body)
                            .foregroundStyle(aspect.kind.isHarmonious ? Brand.live : Brand.text2)
                            .frame(width: 26)
                            .accessibilityHidden(true)
                        Text("\(aspect.a.name) \(aspect.kind.name.lowercased()) \(aspect.b.name)")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text)
                        Spacer()
                        Text(String(format: "%.1f°", aspect.orb))
                            .font(Brand.mono(12))
                            .foregroundStyle(Brand.text3)
                            .accessibilityLabel("orb \(String(format: "%.1f", aspect.orb)) degrees")
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .glassCard()
    }
}
