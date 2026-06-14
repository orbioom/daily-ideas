import SwiftUI
import SwiftData

/// Settings: persisted prefs that change behavior, theme picker, Pro, data actions, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showAbout = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                gameplaySection
                themeSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Reset stats?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & reload sample", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your game history and best scores.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Cobble Pro", systemImage: "crown.fill").foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.good)
                }
            } else {
                Button { paywallReason = .themes } label: {
                    HStack {
                        Label("Unlock Cobble Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("Premium themes, unlimited undo, and the Daily archive. No ads, ever.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Cobble Pro")
        }
    }

    // MARK: Gameplay prefs (functional, persisted)

    private var gameplaySection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
            Toggle(isOn: $settings.soundEnabled) {
                Label("Sound effects", systemImage: "speaker.wave.2")
            }
            Toggle(isOn: $settings.showGhost) {
                Label("Placement ghost", systemImage: "square.dashed")
            }
        } header: {
            Text("Gameplay")
        } footer: {
            Text("The ghost shows a green or red preview of where a piece will land. Reduce Motion is read from your system settings and disables clear animations automatically.")
        }
    }

    // MARK: Theme

    private var themeSection: some View {
        Section {
            ForEach(BlockPalettes.all) { palette in
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
            Text("Block Theme")
        } footer: {
            Text(isPro ? "Pick the palette used on the board and tray."
                       : "The Cobble palette is free. Premium palettes are part of Cobble Pro.")
        }
    }

    private func swatch(_ palette: BlockPalette) -> some View {
        HStack(spacing: 3) {
            ForEach(1...min(4, palette.count), id: \.self) { i in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(palette.color(i))
                    .frame(width: 14, height: 14)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                SeedData.insertSampleResults(context: context)
                statusMessage = "Sample games added."
                Haptics.clear(settings.hapticsEnabled)
            } label: {
                Label("Load sample data", systemImage: "tray.and.arrow.down")
            }
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset stats", systemImage: "trash")
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
                Label("About Cobble", systemImage: "info.circle")
            }
            HStack {
                Text("Version"); Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Actions

    private func selectPalette(_ palette: BlockPalette) {
        if palette.isPro && !isPro {
            paywallReason = .themes
        } else {
            settings.paletteID = palette.id
            Haptics.select(settings.hapticsEnabled)
        }
    }

    private func resetAndReseed() {
        SeedData.clearResults(context: context)
        SeedData.insertSampleResults(context: context)
        statusMessage = "Stats reset and sample reloaded."
        Haptics.clear(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearResults(context: context)
        statusMessage = "All stats erased."
        Haptics.clear(settings.hapticsEnabled)
    }
}
