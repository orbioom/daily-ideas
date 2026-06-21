import SwiftUI

struct CatalogView: View {
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var selectedStar: Star?
    @State private var selectedConstellation: ConstellationData?

    var filteredStars: [Star] {
        if searchText.isEmpty { return StarCatalog.stars }
        return StarCatalog.stars.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.constellation.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.skyBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Segment picker
                    Picker("Catalog", selection: $selectedTab) {
                        Text("Stars").tag(0)
                        Text("Planets").tag(1)
                        Text("Constellations").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .colorMultiply(NovaTheme.accent)

                    if selectedTab == 0 {
                        starList
                    } else if selectedTab == 1 {
                        planetList
                    } else {
                        constellationList
                    }
                }
            }
            .navigationTitle("Catalog")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(NovaTheme.cardBackground, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search stars, constellations…")
            .sheet(item: $selectedStar) { star in
                StarDetailView(star: star)
            }
        }
    }

    var starList: some View {
        List(filteredStars) { star in
            Button {
                selectedStar = star
            } label: {
                HStack(spacing: 14) {
                    Circle()
                        .fill(NovaTheme.starColor(bv: star.bv))
                        .frame(width: CGFloat(6 - min(5, star.magnitude)) + 4)
                        .frame(width: 24, alignment: .center)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(star.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(NovaTheme.textPrimary)
                        Text("\(star.constellation) · Type \(star.spectralType)")
                            .font(.system(size: 13))
                            .foregroundStyle(NovaTheme.textSecondary)
                    }
                    Spacer()
                    Text(String(format: "%.2f", star.magnitude))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(NovaTheme.textSecondary)
                        .accessibilityLabel("magnitude \(String(format: "%.2f", star.magnitude))")
                }
            }
            .listRowBackground(NovaTheme.cardBackground)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    var planetList: some View {
        List(PlanetName.allCases, id: \.rawValue) { planet in
            HStack(spacing: 14) {
                Text(planet.symbol)
                    .font(.system(size: 28))
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(planet.rawValue)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(NovaTheme.textPrimary)
                    Text(planetDescription(planet))
                        .font(.system(size: 13))
                        .foregroundStyle(NovaTheme.textSecondary)
                        .lineLimit(2)
                }
            }
            .listRowBackground(NovaTheme.cardBackground)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    var constellationList: some View {
        List(StarCatalog.constellations, id: \.name) { c in
            VStack(alignment: .leading, spacing: 4) {
                Text(c.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(NovaTheme.textPrimary)
                Text("\(c.abbreviation) · \(c.lines.count) line segments")
                    .font(.system(size: 13))
                    .foregroundStyle(NovaTheme.textSecondary)
            }
            .listRowBackground(NovaTheme.cardBackground)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    func planetDescription(_ planet: PlanetName) -> String {
        switch planet {
        case .venus: return "The Morning/Evening Star. Brightest planet. 108M km from Sun."
        case .mars: return "The Red Planet. Two moons. 228M km from Sun."
        case .jupiter: return "The Gas Giant. Largest planet. 778M km from Sun. 95 moons."
        case .saturn: return "The Ringed World. Second largest. 1.43B km from Sun."
        }
    }
}

struct StarDetailView: View {
    let star: Star
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.skyBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Star symbol
                        ZStack {
                            Circle()
                                .fill(NovaTheme.cardBackground)
                                .frame(width: 100, height: 100)
                            Image(systemName: "star.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(NovaTheme.starColor(bv: star.bv))
                        }

                        VStack(spacing: 6) {
                            Text(star.name)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(NovaTheme.textPrimary)
                            Text(star.constellation)
                                .font(.system(size: 16))
                                .foregroundStyle(NovaTheme.accent)
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            statCard("Magnitude", String(format: "%.2f", star.magnitude))
                            statCard("Spectral Type", star.spectralType)
                            statCard("RA", raString)
                            statCard("Dec", decString)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(NovaTheme.textSecondary)
                            Text(star.description)
                                .font(.system(size: 15))
                                .foregroundStyle(NovaTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(NovaTheme.cardBackground)
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(NovaTheme.accent)
                }
            }
        }
    }

    func statCard(_ label: String, _ value: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(NovaTheme.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(NovaTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(NovaTheme.cardBackground)
        .cornerRadius(10)
    }

    var raString: String {
        let h = Int(star.raDeg / 15)
        let m = Int((star.raDeg / 15 - Double(h)) * 60)
        return String(format: "%02dh %02dm", h, m)
    }

    var decString: String {
        let sign = star.decDeg >= 0 ? "+" : ""
        return String(format: "%@%.1f°", sign, star.decDeg)
    }
}
