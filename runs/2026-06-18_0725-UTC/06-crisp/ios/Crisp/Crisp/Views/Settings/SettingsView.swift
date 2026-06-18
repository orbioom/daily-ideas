import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var toast: ToastMessage? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    proSection
                    appearanceSection
                    unitsSection
                    cookingSection
                    feedbackSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Theme.roundedStyle(.body, .bold))
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .toast($toast)
            .tint(Theme.accent)
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if pro.isPro {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Crisp Pro unlocked")
                            .font(Theme.roundedStyle(.headline, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Thanks for the support!")
                            .font(Theme.roundedStyle(.caption))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            } else {
                Button { showPaywall = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Crisp Pro")
                                .font(Theme.roundedStyle(.headline, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("Unlimited timers, custom foods & full doneness guide")
                                .font(Theme.roundedStyle(.caption))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
                    }
                }
                Button("Restore purchase") {
                    pro.restore()
                    toast = ToastMessage(symbol: "arrow.clockwise", text: "Nothing to restore")
                }
                .foregroundStyle(Theme.accent)
            }
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0; Haptics.selection(enabled: settings.hapticsEnabled) }
            )) {
                ForEach(AppearanceMode.allCases) { Text($0.rawValue).tag($0) }
            }
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Units

    private var unitsSection: some View {
        Section("Units") {
            Picker("Temperature", selection: Binding(
                get: { settings.tempUnit },
                set: { settings.tempUnit = $0 }
            )) {
                ForEach(TempUnit.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Weight", selection: Binding(
                get: { settings.weightUnit },
                set: { settings.weightUnit = $0 }
            )) {
                ForEach(WeightUnit.allCases) { Text($0.rawValue).tag($0) }
            }
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Cooking

    private var cookingSection: some View {
        Section("Cooking") {
            Toggle(isOn: $settings.includePreheat) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Include preheat")
                    Text("Adds \(CookEngine.preheatMinutes) min to cook times")
                        .font(Theme.roundedStyle(.caption))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .tint(Theme.accent)

            Stepper(value: $settings.defaultServings, in: 1...12) {
                HStack {
                    Text("Default servings")
                    Spacer()
                    Text("×\(settings.defaultServings)")
                        .foregroundStyle(Theme.inkSoft)
                        .monospacedDigit()
                }
            }

            Picker("Timer sound", selection: Binding(
                get: { settings.timerSound },
                set: { settings.timerSound = $0 }
            )) {
                ForEach(TimerSound.allCases) { Text($0.rawValue).tag($0) }
            }
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Feedback

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
                .tint(Theme.accent)
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0")
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Text("Foods in catalog")
                Spacer()
                Text("\(FoodCatalog.all.count)")
                    .foregroundStyle(Theme.inkSoft)
            }
            Text("Temps and times are tested starting points. Air fryers vary — check early and adjust to taste.")
                .font(Theme.roundedStyle(.caption))
                .foregroundStyle(Theme.inkSoft)
        }
        .listRowBackground(Theme.surface)
    }
}
