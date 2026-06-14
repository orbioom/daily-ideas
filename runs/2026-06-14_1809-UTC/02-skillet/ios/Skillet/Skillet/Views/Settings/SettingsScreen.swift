import SwiftUI
import SwiftData

/// Settings: persisted prefs, Pro, export, load/reset data, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var shopping: ShoppingState
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false
    @Query private var recipes: [Recipe]
    @Query private var pantry: [PantryItem]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showAbout = false
    @State private var statusMessage: String?

    private var customCount: Int { recipes.filter { $0.isCustom }.count }

    var body: some View {
        NavigationStack {
            Form {
                proSection
                matchingSection
                preferencesSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Reset all data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & reload samples", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your pantry, recipes, and shopping list.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Skillet Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
            } else {
                Button {
                    paywallReason = .recipeLimit
                } label: {
                    HStack {
                        Label("Unlock Skillet Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("\(customCount) of \(Pro.freeCustomRecipeLimit) free custom recipes used")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Skillet Pro")
        }
    }

    // MARK: Matching behavior

    private var matchingSection: some View {
        Section {
            Toggle(isOn: $settings.assumeStaples) {
                Label("Assume staples on hand", systemImage: "basket")
            }
        } header: {
            Text("Matching")
        } footer: {
            Text("When on, salt, oil, butter, flour, water and other basics are treated as always available, so recipes match more easily.")
        }
    }

    // MARK: Preferences (>=3 functional persisted prefs)

    private var preferencesSection: some View {
        Section {
            Stepper(value: Binding(
                get: { settings.defaultServings },
                set: { settings.defaultServings = settings.clampedServings($0) }
            ), in: 1...24) {
                Label("Default servings: \(settings.defaultServings)", systemImage: "person.2")
            }

            Toggle(isOn: $settings.hideOptional) {
                Label("Hide optional ingredients", systemImage: "eye.slash")
            }

            Picker(selection: $settings.measurementNote) {
                ForEach(AppSettings.measurementOptions, id: \.self) { opt in
                    Text(opt).tag(opt)
                }
            } label: {
                Label("Measurement style", systemImage: "ruler")
            }

            Picker(selection: $settings.defaultRecipeSortRaw) {
                ForEach(RecipeSort.allCases) { s in
                    Text(s.rawValue).tag(s.rawValue)
                }
            } label: {
                Label("Default recipe sort", systemImage: "arrow.up.arrow.down")
            }

            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
        } header: {
            Text("Preferences")
        } footer: {
            Text("These apply across the app immediately.")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                loadSamples()
            } label: {
                Label("Load sample data", systemImage: "tray.and.arrow.down")
            }

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset data", systemImage: "trash")
            }

            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.good)
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("Everything lives on this device. Nothing is uploaded. \(recipes.count) recipes · \(pantry.count) pantry items.")
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Skillet", systemImage: "info.circle")
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Actions

    private func loadSamples() {
        if recipes.isEmpty && pantry.isEmpty {
            var seeded = false
            SeedData.seedIfNeeded(context: context, didSeed: &seeded)
            didSeed = seeded
            statusMessage = "Sample data loaded."
            Haptics.success(settings.hapticsEnabled)
        } else {
            statusMessage = "You already have data — reset first to reload."
            Haptics.warning(settings.hapticsEnabled)
        }
    }

    private func resetAndReseed() {
        SeedData.clearAll(context: context)
        shopping.clearChecked()
        var seeded = false
        SeedData.seedIfNeeded(context: context, didSeed: &seeded)
        didSeed = seeded
        statusMessage = "Sample data restored."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        shopping.clearChecked()
        didSeed = true   // keep it empty; don't auto-reseed
        statusMessage = "All data erased."
        Haptics.success(settings.hapticsEnabled)
    }
}
