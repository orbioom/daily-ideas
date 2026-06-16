import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @State private var showPaywall = false
    @State private var showAbout = false
    @State private var toastMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection

                Section("Appearance") {
                    Picker(selection: Binding(
                        get: { settings.appearance },
                        set: { settings.appearance = $0 }
                    )) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.systemImage).tag(mode)
                        }
                    } label: {
                        Label("Theme", systemImage: "paintpalette.fill")
                    }
                }

                Section("Preferences") {
                    Toggle(isOn: $settings.hapticsEnabled) {
                        Label("Haptics", systemImage: "hand.tap.fill")
                    }
                    .tint(Theme.accent)

                    Toggle(isOn: $settings.rentRemindersEnabled) {
                        Label("Rent reminders", systemImage: "bell.badge.fill")
                    }
                    .tint(Theme.accent)

                    Picker(selection: $settings.currencyCode) {
                        ForEach(AppSettings.currencyOptions, id: \.self) { code in
                            Text("\(code) (\(Money.symbol(for: code)))").tag(code)
                        }
                    } label: {
                        Label("Currency", systemImage: "dollarsign.circle.fill")
                    }
                }

                Section {
                    Stepper(value: $settings.closingCostPct, in: 0...10, step: 0.5) {
                        HStack {
                            Label("Closing cost", systemImage: "percent")
                            Spacer()
                            Text(String(format: "%.1f%%", settings.closingCostPct))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                } header: {
                    Text("Cash-on-cash assumption")
                } footer: {
                    Text("Used as the closing-cost estimate in cash-on-cash returns when a property has no explicit closing costs entered.")
                }

                Section("About") {
                    Button {
                        showAbout = true
                    } label: {
                        Label("About Deed", systemImage: "info.circle.fill")
                            .foregroundStyle(Theme.ink)
                    }
                    HStack {
                        Label("Version", systemImage: "number")
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showAbout) { AboutView() }
            .toast($toastMessage)
        }
    }

    private var proSection: some View {
        Section {
            if pro.isPro {
                HStack {
                    Label("Deed Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Deed Pro")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("Unlimited properties, reports & export · \(ProStore.priceLabel)")
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
                Button("Restore Purchase") {
                    if pro.restore() {
                        toastMessage = "Pro restored"
                    } else {
                        toastMessage = "No purchase found"
                    }
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
                .foregroundStyle(Theme.accent)
            }
        }
    }
}
