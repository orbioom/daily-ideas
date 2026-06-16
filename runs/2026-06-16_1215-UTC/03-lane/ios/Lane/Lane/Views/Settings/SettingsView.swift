import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @State private var showPaywall = false
    @State private var showAbout = false
    @State private var toast: ToastMessage?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                appearanceSection
                behaviorSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showAbout) { AboutView() }
            .toast($toast)
        }
    }

    // MARK: - Pro

    private var proSection: some View {
        Section {
            if proStore.isPro {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.good)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lane Pro unlocked")
                            .font(Theme.rounded(16, .semibold))
                        Text("Thank you for supporting Lane.")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Lane Pro")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("Unlimited boards, labels, WIP limits & insights")
                                .font(.caption)
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Button("Restore Purchase") { restore() }
                    .font(Theme.rounded(15, .medium))
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker(selection: appearanceBinding) {
                ForEach(AppearanceMode.allCases) { mode in
                    SwiftUI.Label(mode.rawValue, systemImage: mode.symbol).tag(mode)
                }
            } label: {
                SwiftUI.Label("Theme", systemImage: "paintbrush.fill")
            }
            .pickerStyle(.menu)
        }
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(get: { settings.appearance }, set: { settings.appearance = $0 })
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                SwiftUI.Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
            }
            Toggle(isOn: $settings.showCompletedCards) {
                SwiftUI.Label("Show completed cards", systemImage: "checkmark.circle")
            }
            Toggle(isOn: $settings.confirmBeforeDelete) {
                SwiftUI.Label("Confirm before delete", systemImage: "exclamationmark.shield")
            }
            Picker(selection: templateBinding) {
                ForEach(BoardTemplate.allCases) { t in
                    Text(t.title).tag(t)
                }
            } label: {
                SwiftUI.Label("Default new-board template", systemImage: "rectangle.split.3x1")
            }
            .pickerStyle(.menu)
        } header: {
            Text("Behavior")
        } footer: {
            Text("Defaults applied when you create a new board.")
        }
    }

    private var templateBinding: Binding<BoardTemplate> {
        Binding(get: { settings.defaultTemplate }, set: { settings.defaultTemplate = $0 })
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                HStack {
                    SwiftUI.Label("About Lane", systemImage: "info.circle")
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0")
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private func restore() {
        let restored = proStore.restore()
        Haptics.notify(restored ? .success : .warning, enabled: settings.hapticsEnabled)
        toast = ToastMessage(
            symbol: restored ? "checkmark.circle.fill" : "info.circle.fill",
            text: restored ? "Pro restored" : "No purchase found"
        )
    }
}
