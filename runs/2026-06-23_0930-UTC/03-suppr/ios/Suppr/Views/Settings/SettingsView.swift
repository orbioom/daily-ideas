import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [AppSettings]
    @Query private var recipes: [Recipe]
    @Query private var meals: [PlannedMeal]
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @State private var showResetOnboarding = false

    private var settings: AppSettings {
        if let existing = settingsList.first { return existing }
        let fresh = AppSettings()
        context.insert(fresh)
        try? context.save()
        return fresh
    }

    var body: some View {
        NavigationStack {
            Form {
                planningSection
                listSection
                generalSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .alert("Show onboarding again?", isPresented: $showResetOnboarding) {
                Button("Show it") { hasOnboarded = false }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The welcome tour will appear next launch.")
            }
        }
    }

    private var planningSection: some View {
        Section {
            Stepper(value: bind(\.defaultServings), in: 1...20) {
                LabeledContent("Default servings", value: "\(settings.defaultServings)")
            }
            Toggle("Week starts on Monday", isOn: bindBool(\.weekStartsMonday))
                .tint(Theme.terracotta)
        } header: {
            Text("Planning")
        } footer: {
            Text("New meals you drop onto the plan start at your default servings.")
        }
    }

    private var listSection: some View {
        Section {
            Toggle("Pantry-aware list", isOn: bindBool(\.pantryAwareList))
                .tint(Theme.sage)
            Toggle("Hide pantry staples", isOn: bindBool(\.hideStaplesOnList))
                .tint(Theme.terracotta)
        } header: {
            Text("Grocery list")
        } footer: {
            Text("Pantry-aware list hides staples you marked as on hand. Hide staples removes common items (salt, oil) entirely.")
        }
    }

    private var generalSection: some View {
        Section("General") {
            Toggle("Haptics", isOn: bindBool(\.hapticsEnabled))
                .tint(Theme.terracotta)
            Button {
                showResetOnboarding = true
            } label: {
                Label("Replay welcome tour", systemImage: "sparkles")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Recipes", value: "\(recipes.count)")
            LabeledContent("Planned meals", value: "\(meals.count)")
            NavigationLink {
                AboutView()
            } label: {
                Label("About Suppr", systemImage: "info.circle")
            }
        }
    }

    // MARK: - Binding helpers

    private func bind(_ keyPath: ReferenceWritableKeyPath<AppSettings, Int>) -> Binding<Int> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { settings[keyPath: keyPath] = $0; try? context.save() }
        )
    }

    private func bindBool(_ keyPath: ReferenceWritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: {
                settings[keyPath: keyPath] = $0
                try? context.save()
                if keyPath == \AppSettings.hapticsEnabled { Haptics.enabled = $0 }
                Haptics.selection()
            }
        )
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient(colors: [Theme.terracotta, Theme.amber],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 96, height: 96)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)
                Text("Suppr")
                    .font(.title.bold())
                    .foregroundStyle(Theme.primaryText)
                Text("Weeknight meal planning, minus the chaos.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    aboutPoint("calendar", "Drag recipes onto a calm weekly grid.")
                    aboutPoint("cart", "Lists that build and aisle-sort themselves.")
                    aboutPoint("cabinet", "Pantry-aware so you never re-buy salt.")
                }
                .cardSurface()

                Text("Version 1.0")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutPoint(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.terracotta)
                .frame(width: 26)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.primaryText)
            Spacer()
        }
    }
}
