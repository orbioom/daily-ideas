import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                appearanceSection
                preferencesSection
                manageSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Furlong Pro", systemImage: "checkmark.seal.fill")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                }
            } else {
                Button {
                    showPaywall = true
                    Haptics.impact(settings.hapticsEnabled)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Furlong Pro")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("Export, unlimited trips, multi-vehicle • \(Pro.price)")
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0; Haptics.selection(settings.hapticsEnabled) })) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                .tint(Theme.accent)
        }
        .listRowBackground(Theme.surface)
    }

    private var preferencesSection: some View {
        Section("Tracking") {
            Picker("Distance unit", selection: Binding(
                get: { settings.distanceUnit },
                set: { settings.distanceUnit = $0; Haptics.selection(settings.hapticsEnabled) })) {
                ForEach(DistanceUnit.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Currency", selection: $settings.currencyCode) {
                ForEach(settings.currencyChoices, id: \.self) { Text($0).tag($0) }
            }
            Picker("Default trip purpose", selection: Binding(
                get: { settings.defaultPurpose },
                set: { settings.defaultPurpose = $0 })) {
                ForEach(TripPurpose.allCases) { Text($0.rawValue).tag($0) }
            }
            Toggle("Default to round trip", isOn: $settings.defaultRoundTrip)
                .tint(Theme.accent)
        }
        .listRowBackground(Theme.surface)
    }

    private var manageSection: some View {
        Section("Manage") {
            NavigationLink {
                VehiclesView()
            } label: {
                Label("Vehicles", systemImage: "car.2.fill")
            }
            NavigationLink {
                FavoritePlacesView()
            } label: {
                Label("Favorite places", systemImage: "star.fill")
            }
            NavigationLink {
                MileageRatesView()
            } label: {
                Label("IRS mileage rates", systemImage: "calendar.badge.clock")
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0")
                    .foregroundStyle(Theme.inkSoft)
            }
            Link(destination: URL(string: "https://www.irs.gov/tax-professionals/standard-mileage-rates") ?? URL(fileURLWithPath: "/")) {
                Label("IRS standard mileage rates", systemImage: "link")
            }
        } header: {
            Text("About")
        } footer: {
            Text("Furlong keeps everything on your device — no account, no cloud, no subscription. Estimates use IRS standard mileage rates; always confirm deductions with a tax professional.")
        }
        .listRowBackground(Theme.surface)
    }
}
