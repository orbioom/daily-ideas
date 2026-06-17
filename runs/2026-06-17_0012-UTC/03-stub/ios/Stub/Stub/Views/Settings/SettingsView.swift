import SwiftUI

/// Settings: persisted defaults & preferences, plus Pro, Learn, and About.
struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppPreferences.self) private var prefs
    @AppStorage("isPro") private var isPro = false

    @State private var showPaywall = false
    @State private var showStatePicker = false

    var body: some View {
        @Bindable var prefs = prefs
        return NavigationStack {
            Form {
                // MARK: Defaults
                Section("Calculator defaults") {
                    Picker("Default filing status", selection: $prefs.defaultFiling) {
                        ForEach(FilingStatus.allCases) { Text($0.label).tag($0) }
                    }
                    Button {
                        showStatePicker = true
                    } label: {
                        HStack {
                            Text("Default work state")
                                .foregroundStyle(StubTheme.primaryText(scheme))
                            Spacer()
                            Text(StateTaxTable.state(forCode: prefs.defaultStateCode).name)
                                .foregroundStyle(StubTheme.secondaryText(scheme))
                        }
                    }
                    Picker("Default pay frequency", selection: $prefs.defaultFrequency) {
                        ForEach(PayFrequency.allCases) { Text($0.shortLabel).tag($0) }
                    }
                }

                // MARK: Display
                Section("Display") {
                    Toggle("Show annual figures by default", isOn: $prefs.showAnnualByDefault)
                    Toggle("Round to whole dollars", isOn: $prefs.roundWhole)
                    Toggle("Haptic feedback", isOn: $prefs.hapticsEnabled)
                }

                // MARK: Pro
                Section("Stub Pro") {
                    if isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(StubTheme.green)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Unlock Stub Pro — $4.99", systemImage: "seal.fill")
                                .foregroundStyle(StubTheme.green)
                        }
                    }
                    Button("Restore purchase") { isPro = true }
                        .foregroundStyle(StubTheme.primaryText(scheme))
                }

                // MARK: Learn / Legal
                Section("Learn") {
                    NavigationLink {
                        DisclaimerView()
                    } label: {
                        Label("How estimates work", systemImage: "info.circle")
                    }
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Stub", systemImage: "questionmark.circle")
                    }
                }

                Section {
                    Text("Stub provides estimates only and is not tax advice. State rates are approximate. Federal & FICA parameters reflect 2025 figures.")
                        .font(.caption)
                        .foregroundStyle(StubTheme.secondaryText(scheme))
                }
            }
            .scrollContentBackground(.hidden)
            .background(StubTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showStatePicker) {
                StatePickerView(selectedCode: $prefs.defaultStateCode)
            }
        }
    }
}
