import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [NovaSettings]
    @State private var page = 0
    @State private var selectedCityIndex = 0
    @State private var searchText = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var settings: NovaSettings {
        if let s = settingsList.first { return s }
        let s = NovaSettings(); modelContext.insert(s); return s
    }

    var filteredCities: [CelestialCity] {
        if searchText.isEmpty { return CityData.cities }
        return CityData.cities.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.country.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            NovaTheme.skyBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                if page == 0 { page0 }
                else if page == 1 { page1 }
                else { page2 }
                Spacer()
                pageControls
                    .padding(.bottom, 32)
            }
            .padding(.horizontal)
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.35), value: page)
    }

    var page0: some View {
        VStack(spacing: 24) {
            Text("✦")
                .font(.system(size: 72))
                .foregroundStyle(NovaTheme.accentGold)
            Text("Nova")
                .font(.system(size: 42, weight: .thin, design: .serif))
                .foregroundStyle(NovaTheme.textPrimary)
            Text("Your personal star chart.\nThe entire night sky — offline, always on.")
                .font(.system(size: 17))
                .foregroundStyle(NovaTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    var page1: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(NovaTheme.accent)
                Text("Choose Your City")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(NovaTheme.textPrimary)
                Text("No GPS needed — pick your nearest city for accurate star positions.")
                    .font(.system(size: 15))
                    .foregroundStyle(NovaTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            TextField("Search cities…", text: $searchText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(NovaTheme.cardBackground)
                .cornerRadius(10)
                .foregroundStyle(NovaTheme.textPrimary)
                .accessibilityLabel("Search cities")

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredCities) { city in
                        Button {
                            selectedCityIndex = city.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(NovaTheme.textPrimary)
                                    Text("\(city.country) · \(String(format: "%.1f°", city.latitude))\(city.latitude >= 0 ? "N" : "S")")
                                        .font(.system(size: 13))
                                        .foregroundStyle(NovaTheme.textSecondary)
                                }
                                Spacer()
                                if city.id == selectedCityIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(NovaTheme.accent)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(city.id == selectedCityIndex ? NovaTheme.accent.opacity(0.15) : NovaTheme.cardBackground)
                            .cornerRadius(10)
                        }
                        .accessibilityLabel("\(city.name), \(city.country)")
                    }
                }
            }
            .frame(maxHeight: 260)
            .cornerRadius(12)
        }
    }

    var page2: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.fill")
                .font(.system(size: 56))
                .foregroundStyle(NovaTheme.accentGold)
            Text("Ready to Stargaze")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(NovaTheme.textPrimary)
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "map.circle.fill", text: "Live star chart with 60+ named stars")
                featureRow(icon: "moon.fill", text: "Moon phase and planet positions")
                featureRow(icon: "line.diagonal", text: "Constellation lines and names")
                featureRow(icon: "book.fill", text: "Star & constellation catalog with facts")
            }
            .padding(.horizontal, 8)
        }
    }

    func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(NovaTheme.accent)
                .frame(width: 32)
            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(NovaTheme.textPrimary)
            Spacer()
        }
    }

    var pageControls: some View {
        HStack {
            if page > 0 {
                Button("Back") { page -= 1 }
                    .font(.system(size: 17))
                    .foregroundStyle(NovaTheme.textSecondary)
            }
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == page ? NovaTheme.accent : NovaTheme.textSecondary.opacity(0.4))
                        .frame(width: 7, height: 7)
                }
            }
            Spacer()
            Button(page < 2 ? "Next" : "Let's Go") {
                if page < 2 { page += 1 }
                else { complete() }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(NovaTheme.accent)
        }
        .padding(.horizontal, 24)
    }

    private func complete() {
        settings.selectedCityIndex = selectedCityIndex
        settings.hasCompletedOnboarding = true
    }
}
