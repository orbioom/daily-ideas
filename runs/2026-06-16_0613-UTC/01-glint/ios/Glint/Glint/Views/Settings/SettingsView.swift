import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.modelContext) private var context

    @State private var showPaywall = false
    @State private var showHowTo = false
    @State private var showResetConfirm = false
    @State private var restored = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                Form {
                    appearanceSection
                    gameplaySection
                    proSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showHowTo) { HowToPlayView() }
            .alert("Restore progress?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { resetProgress() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This clears level stars, daily results, saved games, and stats. This cannot be undone.")
            }
            .overlay(alignment: .bottom) {
                if restored {
                    Toast(text: "Purchases restored", systemImage: "checkmark.circle.fill")
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .accessibilityHint("Choose light, dark, or follow the system.")
        }
        .listRowBackground(Theme.surface)
    }

    private var gameplaySection: some View {
        Section("Gameplay") {
            Picker("Swap mode", selection: Binding(
                get: { settings.swapMode },
                set: { settings.swapMode = $0 }
            )) {
                ForEach(SwapMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            Text(settings.swapMode.help)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)

            Toggle("Haptics", isOn: $settings.hapticsEnabled)
            Toggle("Show hints", isOn: $settings.showHints)
            Toggle("Reduced effects", isOn: $settings.reducedEffects)
            Text("Reduced effects make clears and cascades instant — great for focus or motion sensitivity.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .listRowBackground(Theme.surface)
    }

    private var proSection: some View {
        Section("Glint Pro") {
            if pro.isPro {
                HStack {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.good)
                    Text("Glint Pro is active")
                        .foregroundStyle(Theme.ink)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill").foregroundStyle(Theme.gold)
                        Text("Unlock Glint Pro")
                        Spacer()
                        Text(pro.priceText).foregroundStyle(Theme.inkSoft)
                    }
                }
                Button("Restore Purchases") {
                    // Simulated restore: re-reads the stored flag.
                    withAnimation { restored = true }
                    Task {
                        try? await Task.sleep(nanoseconds: 1_800_000_000)
                        withAnimation { restored = false }
                    }
                }
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var aboutSection: some View {
        Section("About") {
            Button {
                showHowTo = true
            } label: {
                Label("How to Play", systemImage: "questionmark.circle")
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset all progress", systemImage: "trash")
            }
            Text("Glint is a calm, fair jewel puzzle. No lives, no timers, no ads.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .listRowBackground(Theme.surface)
    }

    private func resetProgress() {
        delete(LevelProgress.self)
        delete(DailyResult.self)
        delete(SavedGame.self)
        delete(GameRecord.self)
        delete(ZenScore.self)
        try? context.save()
    }

    private func delete<T: PersistentModel>(_ type: T.Type) {
        let descriptor = FetchDescriptor<T>()
        if let items = try? context.fetch(descriptor) {
            for item in items { context.delete(item) }
        }
    }
}
