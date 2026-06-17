import SwiftUI

/// App settings: appearance, formatting, angle unit, haptics, themes (Pro),
/// high precision (Pro), plus Pro unlock / restore and About.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                formattingSection
                if pro.isPro { themeSection }
                proSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showAbout) { AboutView() }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .accessibilityHint("Switches between light, dark and system appearance")
        }
    }

    private var formattingSection: some View {
        Section("Numbers") {
            Picker("Decimal places", selection: Binding(
                get: { settings.decimalPlaces },
                set: { settings.decimalPlaces = $0 }
            )) {
                ForEach(DecimalPlaces.allCases) { place in
                    Text(place.rawValue).tag(place)
                }
            }
            Toggle("Thousands separator", isOn: $settings.groupingEnabled)
            Picker("Default angle", selection: Binding(
                get: { settings.defaultAngle },
                set: { settings.defaultAngle = $0 }
            )) {
                ForEach(AngleUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
        }
    }

    private var themeSection: some View {
        Section {
            Picker("Calculator theme", selection: $settings.selectedThemeRaw) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.rawValue).tag(theme.rawValue)
                }
            }
            Toggle("High precision", isOn: $settings.highPrecision)
        } header: {
            Text("Pro")
        } footer: {
            Text("High precision shows more decimal places in results.")
        }
    }

    private var proSection: some View {
        Section {
            if pro.isPro {
                HStack {
                    Label("Sigma Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                    Spacer()
                    Text("Unlocked")
                        .foregroundStyle(Theme.inkSoft)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock Sigma Pro", systemImage: "sparkles")
                        .foregroundStyle(Theme.accent)
                }
                Button("Restore Purchase") {
                    pro.restore()
                    Haptics.success(enabled: settings.hapticsEnabled)
                }
                .foregroundStyle(Theme.ink)
            }
        } header: {
            Text("Unlock")
        }
    }

    private var aboutSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                Label("About Sigma", systemImage: "info.circle")
                    .foregroundStyle(Theme.ink)
            }
            HStack {
                Text("Version")
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("1.0")
                    .foregroundStyle(Theme.inkSoft)
            }
        } header: {
            Text("About")
        }
    }
}
