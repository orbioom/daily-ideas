import SwiftUI

/// App preferences: appearance, haptics, default paper, input policy, default
/// pen color, plus the Pro status / paywall entry.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro: Bool = false

    @State private var showPaywall = false
    @State private var penColorHex: UInt = 0x1E1B2E

    var body: some View {
        Form {
            // Pro status
            Section {
                if isPro {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Theme.good)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quill Pro").font(Theme.rounded(16, .semibold))
                            Text("Thanks for your support!")
                                .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .accessibilityElement(children: .combine)
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Unlock Quill Pro")
                                    .font(Theme.rounded(16, .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text("One-time \(Pro.priceLabel) · no subscription")
                                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                        }
                    }
                }
            }

            // Appearance
            Section("Appearance") {
                Picker("Theme", selection: Binding(
                    get: { settings.appearance },
                    set: { settings.appearance = $0 }
                )) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Drawing
            Section("Drawing") {
                Picker("Default Paper", selection: Binding(
                    get: { settings.defaultTemplate },
                    set: { settings.defaultTemplate = $0 }
                )) {
                    ForEach(PaperTemplate.available(isPro: isPro)) { t in
                        Text(t.title).tag(t)
                    }
                }

                Picker("Input", selection: Binding(
                    get: { settings.inputPolicy },
                    set: { settings.inputPolicy = $0 }
                )) {
                    ForEach(InputPolicy.allCases) { policy in
                        Text(policy.title).tag(policy)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Pen Color")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                    ColorPaletteView(
                        selectedHex: $penColorHex,
                        isPro: isPro,
                        onLockedTap: { showPaywall = true }
                    )
                }
            }

            // Feedback
            Section("Feedback") {
                Toggle("Haptics", isOn: Binding(
                    get: { settings.hapticsEnabled },
                    set: { settings.hapticsEnabled = $0 }
                ))
            }

            // About
            Section {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Pencil & ink", value: "PencilKit")
            } header: {
                Text("About")
            } footer: {
                Text("Quill is a one-time purchase. No subscription, no account, no ads.")
            }
        }
        .navigationTitle("Settings")
        .background(Theme.bg.ignoresSafeArea())
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showPaywall) {
            PaywallView(reason: .general)
        }
        .onAppear {
            penColorHex = parseHex(settings.defaultPenColorHex)
        }
        .onChange(of: penColorHex) { _, newValue in
            settings.defaultPenColorHex = newValue.rgbHexString
        }
    }

    private func parseHex(_ s: String) -> UInt {
        let scrubbed = s.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        return UInt(scrubbed, radix: 16) ?? 0x1E1B2E
    }
}
