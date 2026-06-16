import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false
    @State private var showLocations = false
    @State private var showRestoreToast = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    proSection
                    appearanceSection
                    chartSection
                    locationTimeSection
                    journalSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)

                if showRestoreToast {
                    VStack { Spacer(); SuccessToast(text: "Nothing to restore yet"); Spacer().frame(height: 40) }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showLocations) { LocationsView() }
        }
    }

    private var proSection: some View {
        Section {
            if isPro {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.gold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lodestar Pro is active").font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                        Text("Thank you for supporting an indie app.").font(.caption).foregroundStyle(Theme.inkSoft)
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles").foregroundStyle(Theme.gold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Lodestar Pro").font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                            Text("Full catalog, time travel, journal — \(Pro.priceLabel) once").font(.caption).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.inkFaint)
                    }
                }
                Button("Restore purchase") { showRestoreToast = true; hideToast() }
                    .font(.subheadline)
                    .tint(Theme.accent)
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
            }
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
                .tint(Theme.accent)
        }
        .listRowBackground(Theme.surface)
    }

    private var chartSection: some View {
        Section("Sky chart") {
            Toggle("Constellation lines", isOn: $settings.showConstellationLines)
                .tint(Theme.accent)
            Toggle("Star & planet labels", isOn: $settings.showLabels)
                .tint(Theme.accent)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Magnitude limit")
                    Spacer()
                    Text(String(format: "%.1f", settings.magnitudeLimit))
                        .foregroundStyle(Theme.inkSoft).monospacedDigit()
                }
                Slider(value: $settings.magnitudeLimit, in: 2.0...5.5, step: 0.5)
                    .tint(Theme.accent)
                Text("Higher shows fainter stars. Free shows to mag 3.5.")
                    .font(.caption2).foregroundStyle(Theme.inkFaint)
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var locationTimeSection: some View {
        Section("Location & time") {
            Button {
                showLocations = true
            } label: {
                HStack {
                    Label("Observing location", systemImage: "mappin.and.ellipse")
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(currentLocationName).foregroundStyle(Theme.inkSoft).font(.caption)
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.inkFaint)
                }
            }

            Picker("Time", selection: Binding(
                get: { settings.timeMode },
                set: { newValue in
                    if newValue == .custom && !isPro {
                        showPaywall = true
                    } else {
                        settings.timeMode = newValue
                    }
                }
            )) {
                ForEach(TimeMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
            }
            .pickerStyle(.segmented)

            if settings.timeMode == .custom && isPro {
                DatePicker("Custom moment", selection: Binding(
                    get: { settings.customDate },
                    set: { settings.customDate = $0 }
                ), displayedComponents: [.date, .hourAndMinute])
            } else if !isPro {
                Text("Time travel is a Pro feature — preview the sky on any date.")
                    .font(.caption2).foregroundStyle(Theme.inkFaint)
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var journalSection: some View {
        Section("Journal") {
            NavigationLink {
                JournalView()
            } label: {
                Label("Stargazing journal", systemImage: "book.closed")
                    .foregroundStyle(Theme.ink)
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0")
            LabeledContent("Engine", value: "On-device ephemeris")
            HStack {
                Image(systemName: "moon.stars.fill").foregroundStyle(Theme.accent)
                Text("Lodestar — the calm, offline planetarium. No account, no ads, ever.")
                    .font(.caption).foregroundStyle(Theme.inkSoft)
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var currentLocationName: String {
        if settings.selectedLocationID == "manual" { return settings.manualLocationName }
        return Gazetteer.byID[settings.selectedLocationID]?.name ?? "London"
    }

    private func hideToast() {
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation { showRestoreToast = false }
        }
    }
}
