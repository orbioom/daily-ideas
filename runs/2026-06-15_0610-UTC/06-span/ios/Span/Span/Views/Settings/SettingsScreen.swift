import SwiftUI
import SwiftData

/// Settings: persisted prefs that change behavior, palette & dot-style pickers, Pro,
/// data actions, and About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query private var profiles: [LifeProfile]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showAbout = false
    @State private var showProfileEditor = false
    @State private var statusMessage: String?

    private var profile: LifeProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Form {
                proSection
                profileSection
                displaySection
                paletteSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .sheet(isPresented: $showProfileEditor) { ProfileEditorView(profile: profile) }
            .confirmationDialog("Reset everything?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Reload sample life", role: .destructive) { reloadSample() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This replaces your profile, chapters, milestones, and goals.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Span Pro", systemImage: "crown.fill").foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.good)
                }
            } else {
                Button { paywallReason = .general } label: {
                    HStack {
                        Label("Unlock Span Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("Unlimited chapters & moments, premium palettes, dot styles, and the poster export. One-time, no ads.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Span Pro")
        }
    }

    // MARK: Profile

    private var profileSection: some View {
        Section {
            Button { showProfileEditor = true } label: {
                HStack {
                    Label("Edit life profile", systemImage: "person.crop.circle")
                    Spacer()
                    if let profile {
                        Text("\(profile.lifeExpectancyYears) yrs")
                            .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    }
                }
            }
        } header: {
            Text("Your Life")
        } footer: {
            Text("Birth date, life expectancy, and whether weeks start on Monday.")
        }
    }

    // MARK: Display prefs (persisted, functional)

    private var displaySection: some View {
        Section {
            Toggle(isOn: $settings.showWeekNumbers) {
                Label("Show week numbers", systemImage: "number")
            }
            Picker(selection: $settings.dotStyleRaw) {
                ForEach(DotStyle.allCases) { style in
                    Text(style.label).tag(style.rawValue)
                }
            } label: {
                Label("Dot style", systemImage: "circle.grid.3x3")
            }
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
        } header: {
            Text("Display")
        } footer: {
            Text("Week numbers show in the week detail. Dot style changes how the grid is drawn. Reduce Motion is read from your system settings and turns off the current-week glow automatically.")
        }
    }

    // MARK: Palette

    private var paletteSection: some View {
        Section {
            ForEach(Palettes.all) { palette in
                Button {
                    selectPalette(palette)
                } label: {
                    HStack(spacing: 12) {
                        swatch(palette)
                        Text(palette.name).foregroundStyle(Theme.ink)
                        if palette.isPro && !isPro {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11)).foregroundStyle(Theme.inkFaint)
                        }
                        Spacer()
                        if settings.paletteID == palette.id {
                            Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                        }
                    }
                }
            }
        } header: {
            Text("Color Palette")
        } footer: {
            Text(isPro ? "Suggested colors when you create chapters and moments."
                       : "Classic is free. Premium palettes are part of Span Pro.")
        }
    }

    private func swatch(_ palette: Palette) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<min(4, palette.count), id: \.self) { i in
                Circle()
                    .fill(palette.color(i))
                    .frame(width: 16, height: 16)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset data", systemImage: "trash")
            }
            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.good)
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("Everything lives on this device. Nothing is uploaded.")
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Span", systemImage: "info.circle")
            }
            HStack {
                Text("Version"); Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Actions

    private func selectPalette(_ palette: Palette) {
        if palette.isPro && !isPro {
            paywallReason = .palettes
        } else {
            settings.paletteID = palette.id
            Haptics.select(settings.hapticsEnabled)
        }
    }

    private func reloadSample() {
        SeedData.reloadSample(context: context)
        statusMessage = "Sample life reloaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        statusMessage = "All data erased."
        Haptics.light(settings.hapticsEnabled)
    }
}
