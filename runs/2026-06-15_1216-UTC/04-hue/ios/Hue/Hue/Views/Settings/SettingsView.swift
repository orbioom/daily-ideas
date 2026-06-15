import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var customPalettes: [CustomPalette]

    @State private var showPaywall = false

    private var allPalettes: [Palette] {
        PaletteLibrary.all + customPalettes.map { $0.asPalette() }
    }

    var body: some View {
        NavigationStack {
            Form {
                proSection

                Section("Appearance") {
                    Picker("Theme", selection: appearanceBinding) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                }

                Section("Coloring") {
                    Toggle("Color by number by default", isOn: $settings.byNumberDefault)
                    Toggle("Show region outlines", isOn: $settings.showOutlines)
                    Picker("Default palette", selection: $settings.defaultPaletteId) {
                        ForEach(allPalettes) { p in
                            Text(p.name).tag(p.id)
                        }
                    }
                }

                Section("Feedback") {
                    Toggle("Haptics on fill", isOn: $settings.hapticsEnabled)
                }

                Section {
                    LabeledContent("Pages", value: "\(PageLibrary.all.count)")
                    LabeledContent("Palettes", value: "\(allPalettes.count)")
                    LabeledContent("Version", value: "1.0")
                } header: {
                    Text("About")
                } footer: {
                    Text("Hue keeps everything on your device. No ads, no accounts, no tracking.")
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .general)
            }
        }
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(get: { settings.appearance }, set: { settings.appearance = $0 })
    }

    @ViewBuilder
    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.good)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hue Pro active").font(Theme.rounded(16, .semibold))
                        Text("Thank you for supporting a calm, private app.")
                            .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Hue Pro").font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("All pages, custom palettes, watermark-free export")
                                .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Text(Pro.priceLabel).font(Theme.rounded(15, .bold)).foregroundStyle(Theme.accent)
                    }
                }
            }
        }
    }
}
