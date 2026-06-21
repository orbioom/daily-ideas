import SwiftUI
import SwiftData

struct TonightView: View {
    @State private var viewModel = SkyViewModel()
    @Query private var settingsList: [NovaSettings]

    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.skyBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        moonCard
                        planetsSection
                        brightStarsSection
                        observingTipsCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Tonight")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(NovaTheme.cardBackground, for: .navigationBar)
        }
        .onAppear {
            if let s = settingsList.first {
                viewModel.city = CityData.cities[safe: s.selectedCityIndex] ?? CityData.cities[0]
            }
            viewModel.recalculate()
        }
    }

    var moonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Text(moonPhaseEmoji)
                    .font(.system(size: 48))
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.moonPhaseName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(NovaTheme.textPrimary)
                    Text(String(format: "%.0f days old", viewModel.moonAge))
                        .font(.system(size: 14))
                        .foregroundStyle(NovaTheme.textSecondary)
                    if let moon = viewModel.moonObject {
                        Text(moon.isAboveHorizon ? String(format: "Up now · Alt %.0f°", moon.altDeg) : "Below horizon")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(moon.isAboveHorizon ? NovaTheme.accent : NovaTheme.textSecondary)
                    }
                }
                Spacer()
            }

            // Moon phase bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(NovaTheme.skyMid)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(NovaTheme.accentGold)
                        .frame(width: geo.size.width * CGFloat(viewModel.moonPhase), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(NovaTheme.cardBackground)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Moon: \(viewModel.moonPhaseName), \(String(format: "%.0f", viewModel.moonAge)) days old")
    }

    var moonPhaseEmoji: String {
        switch viewModel.moonAge {
        case 0..<1.85: return "🌑"
        case 1.85..<7.38: return "🌒"
        case 7.38..<9.22: return "🌓"
        case 9.22..<14.76: return "🌔"
        case 14.76..<16.61: return "🌕"
        case 16.61..<22.15: return "🌖"
        case 22.15..<23.99: return "🌗"
        default: return "🌘"
        }
    }

    var planetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Planets", icon: "circle.fill")
            ForEach(PlanetName.allCases, id: \.rawValue) { planet in
                if let obj = viewModel.skyObjects.first(where: {
                    if case .planet(let n) = $0.kind { return n == planet }
                    return false
                }) {
                    PlanetRow(planet: planet, object: obj)
                }
            }
        }
    }

    var brightStarsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Brightest Stars Up Now", icon: "star.fill")
            if viewModel.brightestStars.isEmpty {
                Text("No bright stars are currently visible. Try after sunset.")
                    .font(.system(size: 15))
                    .foregroundStyle(NovaTheme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(NovaTheme.cardBackground)
                    .cornerRadius(12)
            } else {
                ForEach(viewModel.brightestStars) { star in
                    BrightStarRow(star: star)
                }
            }
        }
    }

    var observingTipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Observing Tip", icon: "eye.fill")
            Text(observingTip)
                .font(.system(size: 15))
                .foregroundStyle(NovaTheme.textPrimary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(NovaTheme.cardBackground)
                .cornerRadius(12)
        }
    }

    var observingTip: String {
        let tips = [
            "Let your eyes dark-adapt for 20 minutes before observing. Avoid white light.",
            "Look for the Summer Triangle: Vega, Deneb, and Altair form a large triangle overhead in summer.",
            "The Milky Way is best seen from dark locations at least 1 hour from city lights.",
            "Use a red flashlight to preserve your night vision while reading star charts.",
            "On clear nights, sweep the sky slowly with binoculars to find star clusters.",
        ]
        let day = Calendar.current.component(.day, from: .now)
        return tips[day % tips.count]
    }
}

struct PlanetRow: View {
    let planet: PlanetName
    let object: SkyObject

    var body: some View {
        HStack(spacing: 14) {
            Text(planet.symbol)
                .font(.system(size: 24))
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(planet.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(NovaTheme.textPrimary)
                Text(object.isAboveHorizon
                     ? String(format: "Alt %.0f° · Az %.0f°", object.altDeg, object.azDeg)
                     : "Below horizon tonight")
                    .font(.system(size: 13))
                    .foregroundStyle(NovaTheme.textSecondary)
            }
            Spacer()
            Circle()
                .fill(object.isAboveHorizon ? NovaTheme.accent : NovaTheme.textSecondary.opacity(0.4))
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
        }
        .padding()
        .background(NovaTheme.cardBackground)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(planet.rawValue): \(object.isAboveHorizon ? "visible" : "not visible")")
    }
}

struct BrightStarRow: View {
    let star: SkyObject

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(NovaTheme.starGold)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
            Text(star.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(NovaTheme.textPrimary)
            Spacer()
            Text(String(format: "%.1f° up", star.altDeg))
                .font(.system(size: 13))
                .foregroundStyle(NovaTheme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(NovaTheme.cardBackground)
        .cornerRadius(10)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(NovaTheme.accent)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(NovaTheme.textSecondary)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
