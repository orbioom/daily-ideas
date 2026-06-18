import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @State private var showPaywall = false
    @State private var showRestoreToast = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                gameplaySection
                feedbackSection
                themeSection
                proSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .overlay(alignment: .bottom) {
                if showRestoreToast {
                    ToastView(icon: "checkmark.circle.fill", message: "Pro restored")
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
        } header: { Text("Appearance") }
        .listRowBackground(Theme.surface)
    }

    private var gameplaySection: some View {
        Section {
            Toggle(isOn: $settings.wrapAround) {
                settingLabel("Wrap-around K↔A", "King and Ace count as neighbours")
            }
            Toggle(isOn: $settings.leftHanded) {
                settingLabel("Left-handed layout", "Mirror the stock and waste piles")
            }
        } header: { Text("Gameplay") }
        .listRowBackground(Theme.surface)
    }

    private var feedbackSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                settingLabel("Haptics", "Vibrations on plays and wins")
            }
            Toggle(isOn: $settings.drawSound) {
                settingLabel("Draw sound", "Soft click when cards move")
            }
        } header: { Text("Feedback") }
        .listRowBackground(Theme.surface)
    }

    private var themeSection: some View {
        Section {
            ForEach(FeltTheme.allCases) { felt in
                feltRow(felt)
            }
        } header: { Text("Felt theme") } footer: {
            Text(pro.isPro ? "Choose any felt for the table." : "Classic is free. Unlock the rest with Pro.")
        }
        .listRowBackground(Theme.surface)
    }

    private func feltRow(_ felt: FeltTheme) -> some View {
        let locked = felt.isPro && !pro.isPro
        return Button {
            if locked { showPaywall = true } else { settings.feltTheme = felt }
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(felt.gradient(dark: false))
                    .frame(width: 40, height: 28)
                    .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Theme.hairline, lineWidth: 1))
                Text(felt.rawValue)
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.ink)
                if felt.isPro { ProBadge() }
                Spacer()
                if locked {
                    Image(systemName: "lock.fill").foregroundStyle(Theme.inkFaint)
                } else if settings.feltTheme == felt {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var proSection: some View {
        Section {
            if pro.isPro {
                HStack {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.accent)
                    Text("Crest Pro unlocked")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
            } else {
                Button { showPaywall = true } label: {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(Theme.gold)
                        Text("Unlock Crest Pro")
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(pro.priceLabel).foregroundStyle(Theme.inkSoft)
                        Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                    }
                }
                .buttonStyle(.plain)
                Button {
                    pro.restore()
                    withAnimation { showRestoreToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation { showRestoreToast = false }
                    }
                } label: {
                    Text("Restore purchase")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
        } header: { Text("Crest Pro") }
        .listRowBackground(Theme.surface)
    }

    private var aboutSection: some View {
        Section {
            aboutRow("Version", "1.0")
            aboutRow("Game", "TriPeaks solitaire")
            HStack {
                Text("Made with").font(Theme.rounded(16)).foregroundStyle(Theme.ink)
                Spacer()
                Text("calm focus 🌿").font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
            }
        } header: { Text("About") } footer: {
            Text("Crest is ad-free. One quiet table, forever.")
        }
        .listRowBackground(Theme.surface)
    }

    private func aboutRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.rounded(16)).foregroundStyle(Theme.ink)
            Spacer()
            Text(value).font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
        }
    }

    private func settingLabel(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(Theme.rounded(16)).foregroundStyle(Theme.ink)
            Text(subtitle).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
        }
    }
}
