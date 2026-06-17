import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var showRestored = false

    var body: some View {
        Form {
            playSection
            guideSection
            appearanceSection
            proSection
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .font(Theme.rounded(17, .bold))
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .alert("Restored", isPresented: $showRestored) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(isPro ? "Your Trace Pro purchase is active." : "No previous purchase was found on this device.")
        }
    }

    // MARK: - Sections

    private var playSection: some View {
        Section {
            Toggle(isOn: $settings.soundEnabled) {
                Label("Sound effects", systemImage: "speaker.wave.2.fill")
            }
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap.fill")
            }
            Toggle(isOn: $settings.leftHanded) {
                Label("Left-handed hints", systemImage: "hand.point.left.fill")
            }
            .accessibilityHint("Mirrors start hints for left-handed children")
            if isPro {
                Toggle(isOn: $settings.noFailMode) {
                    Label("No-fail practice", systemImage: "heart.circle.fill")
                }
                .accessibilityHint("Every completed trace earns a star")
            }
        } header: {
            Text("Play")
        }
        .tint(Theme.accent)
    }

    private var guideSection: some View {
        Section {
            Picker(selection: $settings.guideStyleRaw) {
                ForEach(GuideStyle.allCases) { style in
                    Label(style.rawValue, systemImage: style.iconName).tag(style.rawValue)
                }
            } label: {
                Label("Guide style", systemImage: "scribble.variable")
            }

            VStack(alignment: .leading, spacing: 10) {
                Label("Ink color", systemImage: "paintbrush.pointed.fill")
                HStack(spacing: 12) {
                    ForEach(InkColor.allCases) { ink in
                        Button {
                            settings.inkColorRaw = ink.rawValue
                            Haptics.selection(enabled: settings.hapticsEnabled)
                        } label: {
                            Circle()
                                .fill(ink.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().strokeBorder(
                                        settings.inkColor == ink ? Theme.ink : .clear,
                                        lineWidth: 3
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(ink.rawValue)
                        .accessibilityAddTraits(settings.inkColor == ink ? [.isSelected, .isButton] : .isButton)
                    }
                }
            }
        } header: {
            Text("Tracing guide")
        }
        .tint(Theme.accent)
    }

    private var appearanceSection: some View {
        Section {
            Picker(selection: $settings.appearanceRaw) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.iconName).tag(mode.rawValue)
                }
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }
        } header: {
            Text("Appearance")
        }
        .tint(Theme.accent)
    }

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Trace Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock Trace Pro", systemImage: "sparkles")
                        .foregroundStyle(Theme.accentDeep)
                }
            }
            Button {
                restore()
            } label: {
                Label("Restore purchase", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("Trace Pro")
        }
        .tint(Theme.accent)
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label("About Trace", systemImage: "info.circle.fill")
            }
            HStack {
                Label("Version", systemImage: "number")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
            .accessibilityElement(children: .combine)
        } header: {
            Text("About")
        }
        .tint(Theme.accent)
    }

    private func restore() {
        // Simulated restore (StoreKit-ready). Reveals existing entitlement state.
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
        showRestored = true
    }
}
