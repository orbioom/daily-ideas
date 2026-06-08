import SwiftUI

struct SettingsView: View {
    @AppStorage("anew.currency")      private var currencySymbol: String = "$"
    @AppStorage("anew.showInactive")  private var showInactive: Bool = false
    @AppStorage("anew.haptics")       private var hapticsEnabled: Bool = true
    @AppStorage("anew.appearance")    private var appearancePref: String = "system"
    @AppStorage("anew.reminderTime")  private var reminderTimeInterval: Double = 0
    @AppStorage("anew.onboarded")     private var onboarded: Bool = true

    @State private var showResetAlert = false
    @State private var reminderTime: Date = Date()

    private let currencyOptions = ["$", "£", "€", "¥", "₹", "A$", "C$", "CHF"]
    private let appearanceOptions: [(String, String)] = [
        ("system", "System"),
        ("light",  "Light"),
        ("dark",   "Dark"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                Form {
                    // MARK: Display
                    Section("Display") {
                        Picker("Currency symbol", selection: $currencySymbol) {
                            ForEach(currencyOptions, id: \.self) { sym in
                                Text(sym).tag(sym)
                            }
                        }
                        .accessibilityLabel("Currency symbol")

                        Picker("Appearance", selection: $appearancePref) {
                            ForEach(appearanceOptions, id: \.0) { item in
                                Text(item.1).tag(item.0)
                            }
                        }
                        .accessibilityLabel("App appearance")

                        Toggle("Show inactive quits", isOn: $showInactive)
                            .accessibilityHint("When on, archived quits appear in lists")
                    }

                    // MARK: Wellness
                    Section("Wellness") {
                        Toggle("Haptic feedback", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, new in
                                Haptics.enabled = new
                                if new { Haptics.tap() }
                            }
                            .accessibilityHint("Toggles vibration feedback throughout the app")

                        DatePicker(
                            "Preferred check-in time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: reminderTime) { _, new in
                            reminderTimeInterval = new.timeIntervalSince1970
                        }
                        .onAppear {
                            if reminderTimeInterval != 0 {
                                reminderTime = Date(timeIntervalSince1970: reminderTimeInterval)
                            }
                        }
                        .accessibilityLabel("Preferred check-in time")
                    }

                    // MARK: Account / data
                    Section("Data") {
                        Button("Restart onboarding") {
                            showResetAlert = true
                            Haptics.tap()
                        }
                        .foregroundStyle(Brand.warn)
                        .accessibilityHint("Shows the onboarding screens again on next launch")
                    }

                    // MARK: About
                    Section("About") {
                        aboutRow(label: "Version", value: "1.0")
                        aboutRow(label: "Studio",  value: "Orbioom")
                        aboutRow(label: "Data",    value: "100% on-device, no account needed")
                        aboutRow(label: "Reminders", value: "Set your preferred time above. Scheduling is local and private.")

                        if let orbioomURL = URL(string: "https://orbioom.com") {
                            Link(destination: orbioomURL) {
                                Label("orbioom.com", systemImage: "globe")
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.info)
                            }
                            .accessibilityLabel("Visit orbioom.com")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .alert("Restart Onboarding?", isPresented: $showResetAlert) {
                Button("Restart", role: .destructive) {
                    onboarded = false
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("The onboarding flow will be shown on next app launch. Your data is not affected.")
            }
            .preferredColorScheme(resolvedColorScheme)
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        switch appearancePref {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    @ViewBuilder
    private func aboutRow(label: String, value: String) -> some View {
        LabeledContent(label) {
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
