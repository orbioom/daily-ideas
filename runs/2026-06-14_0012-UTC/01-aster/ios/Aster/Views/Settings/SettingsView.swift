import SwiftUI
import SwiftData

/// Settings: persisted, functional preferences + Pro/restore + About.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false

    // Persisted prefs.
    @AppStorage("defaultMapTheme") private var defaultMapTheme = MapTheme.mist.rawValue
    @AppStorage("defaultLayout") private var defaultLayout = LayoutStyle.tree.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("showNotePreview") private var showNotePreview = true
    @AppStorage("confirmDelete") private var confirmDelete = true

    @State private var showPaywall = false
    @State private var showRestoreNote = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Pro
                Section {
                    if isPro {
                        HStack {
                            Label("Aster Pro", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.good)
                            Spacer()
                            Text("Unlocked").foregroundStyle(Theme.inkSoft)
                        }
                    } else {
                        Button {
                            Haptics.tap(); showPaywall = true
                        } label: {
                            HStack {
                                Label("Unlock Aster Pro", systemImage: "sparkles")
                                Spacer()
                                Text("$6.99").foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                    Button("Restore Purchase") { restore() }
                } header: {
                    Text("Aster Pro")
                } footer: {
                    Text("One-time unlock for unlimited maps, all canvas themes, and outline export.")
                }

                // MARK: Defaults
                Section("New map defaults") {
                    Picker("Default theme", selection: $defaultMapTheme) {
                        ForEach(ProLimits.availableThemes(isPro: isPro)) { t in
                            Text(t.name).tag(t.rawValue)
                        }
                    }
                    Picker("Default layout", selection: $defaultLayout) {
                        ForEach(LayoutStyle.allCases) { Text($0.name).tag($0.rawValue) }
                    }
                }

                // MARK: Behaviour
                Section("Behaviour") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                    Toggle("Show note previews in outline", isOn: $showNotePreview)
                    Toggle("Confirm before deleting", isOn: $confirmDelete)
                }

                // MARK: About
                Section("About") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Aster", systemImage: "info.circle")
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: hapticsEnabled) { _, on in if on { Haptics.selection() } }
            .alert("Restore", isPresented: $showRestoreNote) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(isPro
                     ? "Your Aster Pro unlock has been restored."
                     : "No previous purchase was found on this device. In this demo build, purchases unlock locally.")
            }
            // Keep default theme valid if Pro is lost.
            .onChange(of: isPro) { _, nowPro in
                if !nowPro && !MapTheme.from(defaultMapTheme).isFree {
                    defaultMapTheme = MapTheme.mist.rawValue
                }
            }
        }
    }

    private func restore() {
        // Demo build: a real app would query StoreKit 2 here.
        showRestoreNote = true
        Haptics.tap()
    }
}

/// Static About screen.
private struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Theme.accentSoft)
                        .frame(width: 96, height: 96)
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityHidden(true)

                Text("Aster")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                Text("A calm, beautiful mind-mapping app. Capture a thought, then grow it outward as a radiating tree \u{2014} or a tidy outline. One-time unlock, no clutter.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                CardSection {
                    VStack(alignment: .leading, spacing: 10) {
                        aboutRow("circle.hexagongrid", "Radiating tree & radial layouts")
                        aboutRow("list.bullet.indent", "Map and outline, always in sync")
                        aboutRow("square.and.arrow.up", "Export to Markdown outline")
                        aboutRow("lock.open", "Honest one-time Pro unlock")
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 24)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutRow(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            Text(text)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}
