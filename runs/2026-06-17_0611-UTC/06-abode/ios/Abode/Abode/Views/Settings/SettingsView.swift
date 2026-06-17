import SwiftUI

/// Settings: persisted display & default preferences, plus Pro status and the paywall.
struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro
    @State private var showPaywall = false

    var body: some View {
        @Bindable var settings = settings
        @Bindable var pro = pro
        NavigationStack {
            ZStack {
                AbodeTheme.appBackground(scheme).ignoresSafeArea()
                Form {
                    proSection
                    displaySection($settings)
                    defaultsSection($settings)
                    feedbackSection($settings)
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if pro.isPro {
                HStack {
                    Label("Abode Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(AbodeTheme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(.subheadline)
                        .foregroundStyle(AbodeTheme.secondaryText(scheme))
                }
                Button("Lock again (demo)") { pro.lockForDemo() }
                    .foregroundStyle(AbodeTheme.danger)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Abode Pro", systemImage: "lock.open.fill")
                        Spacer()
                        Text(ProStore.priceDisplay)
                            .foregroundStyle(AbodeTheme.secondaryText(scheme))
                    }
                }
            }
        } header: {
            Text("Membership")
        }
    }

    // MARK: Display

    private func displaySection(_ settings: Bindable<AppSettings>) -> some View {
        Section {
            Picker("Currency", selection: settings.currencyCode) {
                ForEach(AppSettings.supportedCurrencies, id: \.code) { c in
                    Text(c.label).tag(c.code)
                }
            }
            Toggle("Show cents", isOn: settings.showCents)
        } header: {
            Text("Display")
        } footer: {
            Text("Monthly payments always show cents; other figures round to whole \(Format.currencySymbol) unless this is on.")
        }
    }

    // MARK: Defaults

    private func defaultsSection(_ settings: Bindable<AppSettings>) -> some View {
        Section {
            Stepper(value: settings.defaultRatePct, in: 0...20, step: 0.125) {
                HStack {
                    Text("Default rate")
                    Spacer()
                    Text(Format.percentValue(Decimal(settings.wrappedValue.defaultRatePct), fractionDigits: 3))
                        .foregroundStyle(AbodeTheme.secondaryText(scheme))
                }
            }
            Picker("Default term", selection: settings.defaultTermYears) {
                ForEach(CalculatorModel.termOptions, id: \.value) { o in
                    Text(o.label).tag(o.value)
                }
            }
            Stepper(value: settings.defaultPropertyTaxPct, in: 0...5, step: 0.05) {
                HStack {
                    Text("Default property tax")
                    Spacer()
                    Text(Format.percentValue(Decimal(settings.wrappedValue.defaultPropertyTaxPct), fractionDigits: 2))
                        .foregroundStyle(AbodeTheme.secondaryText(scheme))
                }
            }
        } header: {
            Text("Calculator defaults")
        } footer: {
            Text("New calculations start from these values.")
        }
    }

    // MARK: Feedback

    private func feedbackSection(_ settings: Bindable<AppSettings>) -> some View {
        Section {
            Toggle("Haptic feedback", isOn: settings.hapticsEnabled)
        } header: {
            Text("Feedback")
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(AbodeTheme.secondaryText(scheme))
            }
            Text("Abode runs entirely on your device. No accounts, no tracking, no ads. Estimates are for planning only and are not financial advice.")
                .font(.footnote)
                .foregroundStyle(AbodeTheme.secondaryText(scheme))
        } header: {
            Text("About")
        }
    }
}
