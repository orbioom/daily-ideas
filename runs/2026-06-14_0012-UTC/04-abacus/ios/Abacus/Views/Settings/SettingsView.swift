import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false
    @State private var showAbout = false

    var body: some View {
        @Bindable var settings = settings
        return List {
            // MARK: Pro
            Section {
                if isPro {
                    HStack {
                        Label("Abacus Pro", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("Active")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.good)
                    }
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Label("Unlock Abacus Pro", systemImage: "seal")
                                .foregroundStyle(Theme.accent)
                            Spacer()
                            Text("$4.99")
                                .font(Theme.rounded(14, .medium))
                                .foregroundStyle(Theme.inkFaint)
                        }
                    }
                }
            } header: {
                Text("Pro")
            }

            // MARK: Display
            Section {
                Picker("Currency", selection: $settings.currencyCode) {
                    ForEach(CurrencyOption.allCases) { c in
                        Text(c.label).tag(c.rawValue)
                    }
                }
                Picker("Term unit", selection: $settings.termUnitRaw) {
                    ForEach(TermUnit.allCases) { u in
                        Text(u.label).tag(u.rawValue)
                    }
                }
            } header: {
                Text("Display")
            } footer: {
                Text("Currency symbol and how terms are shown across the app.")
            }

            // MARK: Defaults
            Section {
                Stepper(value: $settings.defaultTermMonths, in: 12...600, step: 12) {
                    HStack {
                        Text("Default term")
                        Spacer()
                        Text(Fmt.termDescription(months: settings.defaultTermMonths))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
                HStack {
                    Text("Default extra / month")
                    Spacer()
                    Text(Fmt.moneyWhole(settings.defaultExtraMonthly, symbol: settings.currency.symbol))
                        .foregroundStyle(Theme.inkFaint)
                }
                Stepper("Adjust extra", value: $settings.defaultExtraMonthly, in: 0...10_000, step: 50)
                    .labelsHidden()
                    .accessibilityLabel("Adjust default extra monthly payment")
            } header: {
                Text("New calculation defaults")
            } footer: {
                Text("Applied when you start a fresh calculation.")
            }

            // MARK: Feedback
            Section {
                Toggle(isOn: $settings.hapticsEnabled) {
                    Label("Haptic feedback", systemImage: "iphone.radiowaves.left.and.right")
                }
                .tint(Theme.accent)
            } header: {
                Text("Feedback")
            }

            // MARK: About
            Section {
                Button {
                    showAbout = true
                } label: {
                    Label("About Abacus", systemImage: "info.circle")
                        .foregroundStyle(Theme.ink)
                }
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showAbout) { AboutView() }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Theme.accentSoft)
                            .frame(width: 96, height: 96)
                        Image(systemName: "house.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityHidden(true)
                    Text("Abacus")
                        .font(Theme.rounded(26, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("A trustworthy mortgage & loan calculator. Ad-free, instant, and honest about what your money does — including how much your extra payments really save.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Engine", value: "Exact amortization")
                            InfoRow(label: "Privacy", value: "All on-device")
                            InfoRow(label: "Version", value: "1.0")
                        }
                    }
                    Text("Calculations are estimates for planning. Confirm exact figures with your lender.")
                        .font(Theme.rounded(11))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
            .background(Theme.bg)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
