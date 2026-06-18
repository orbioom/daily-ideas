import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @State private var showPaywall = false
    @State private var restoreMessage: String?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: appearanceBinding) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .accessibilityHint("Choose light, dark, or follow the system")

                    Toggle("Color-blind safe palette", isOn: $settings.colorBlindSafe)
                        .accessibilityHint("Uses a high-contrast blue center tile")
                }

                Section("Gameplay") {
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                        .accessibilityHint("Vibration feedback for taps and results")
                    Toggle("Confirm on submit", isOn: $settings.confirmOnSubmit)
                        .accessibilityHint("Require pressing Enter to submit a word")
                    Toggle("Show rank toasts", isOn: $settings.showRankToasts)
                        .accessibilityHint("Celebrate each new rank with an overlay")
                }

                Section("Pro") {
                    if pro.isPro {
                        Label("Pangram Pro active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Theme.good)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Unlock Pangram Pro", systemImage: "crown.fill")
                        }
                    }
                    Button {
                        let ok = pro.restore()
                        restoreMessage = ok ? "Pro restored." : "No previous purchase found."
                    } label: {
                        Label("Restore purchase", systemImage: "arrow.clockwise")
                    }
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Words in dictionary", value: "\(WordData.words.count)")
                    LabeledContent("Curated seeds", value: "\(WordData.seeds.count)")
                    Text("Pangram is free, offline, and unlimited. Purchases are simulated for this build (StoreKit-ready).")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(
            get: { settings.appearance },
            set: { settings.appearance = $0 }
        )
    }
}
