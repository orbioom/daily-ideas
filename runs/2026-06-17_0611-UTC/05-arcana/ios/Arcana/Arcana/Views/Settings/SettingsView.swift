import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.modelContext) private var context
    @Query private var readings: [Reading]
    @Query private var dailies: [DailyDraw]

    @State private var paywall: PaywallReason?
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                drawSection
                appearanceSection
                deckSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywall) { PaywallView(reason: $0) }
            .alert("Erase all readings?", isPresented: $confirmReset) {
                Button("Erase", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes every saved reading and daily draw. This can't be undone.")
            }
        }
    }

    private var proSection: some View {
        Section {
            if isPro {
                Label {
                    VStack(alignment: .leading) {
                        Text("Arcana Pro is active").font(.headline)
                        Text("Thank you for supporting the app.").font(.caption).foregroundStyle(Theme.inkSoft)
                    }
                } icon: {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.gold)
                }
            } else {
                Button {
                    paywall = .general
                } label: {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(Theme.gold)
                        VStack(alignment: .leading) {
                            Text("Unlock Arcana Pro").font(.headline).foregroundStyle(Theme.ink)
                            Text("Advanced spreads, unlimited journal & more · \(Pro.priceLabel)")
                                .font(.caption).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                    }
                }
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var drawSection: some View {
        Section("Drawing") {
            Toggle("Allow reversed cards", isOn: $settings.allowReversals)
            if settings.allowReversals {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Reversal chance")
                        Spacer()
                        Text("\(Int(settings.reversalChance * 100))%").foregroundStyle(Theme.inkSoft)
                    }
                    Slider(value: $settings.reversalChance, in: 0...1, step: 0.05)
                        .accessibilityValue("\(Int(settings.reversalChance * 100)) percent")
                }
            }
            Toggle("Daily card reminder", isOn: $settings.dailyCardReminder)
        }
        .listRowBackground(Theme.surface)
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { Text($0.rawValue).tag($0) }
            }
            Toggle("Reduce starfield motion", isOn: $settings.reduceStarfield)
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
        }
        .listRowBackground(Theme.surface)
    }

    private var deckSection: some View {
        Section("Deck back") {
            ForEach(DeckTheme.allCases) { theme in
                let locked = theme.isPro && !isPro
                Button {
                    if locked { paywall = .deckThemes }
                    else { settings.deckTheme = theme }
                } label: {
                    HStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 28, height: 40)
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.gold.opacity(0.5), lineWidth: 1))
                        Text(theme.rawValue).foregroundStyle(Theme.ink)
                        if theme.isPro { ProBadge() }
                        Spacer()
                        if settings.deckTheme == theme {
                            Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                        } else if locked {
                            Image(systemName: "lock.fill").foregroundStyle(Theme.gold)
                        }
                    }
                }
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var dataSection: some View {
        Section("Your data") {
            HStack {
                Text("Saved readings")
                Spacer()
                Text("\(readings.count)").foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Text("Daily draws")
                Spacer()
                Text("\(dailies.count)").foregroundStyle(Theme.inkSoft)
            }
            Button("Erase all readings", role: .destructive) {
                confirmReset = true
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var aboutSection: some View {
        Section {
            ReflectionNote()
                .padding(.vertical, 4)
        } header: {
            Text("About")
        } footer: {
            Text("Arcana · Version 1.0 · Your readings stay private on this device.")
                .font(.caption)
        }
        .listRowBackground(Theme.surface)
    }

    private func eraseAll() {
        for r in readings { context.delete(r) }
        for d in dailies { context.delete(d) }
        try? context.save()
    }
}
