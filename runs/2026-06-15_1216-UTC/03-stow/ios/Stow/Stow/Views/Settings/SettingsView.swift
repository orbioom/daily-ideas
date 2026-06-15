import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.modelContext) private var context

    @Query private var allArticles: [Article]

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                appearanceSection
                readerSection
                readingSection
                behaviorSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .general)
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stow Pro is active")
                            .font(.headline)
                        Text("Thank you for supporting Stow.")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Theme.accent)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Stow Pro")
                                .font(.headline)
                                .foregroundStyle(Theme.ink)
                            Text("Unlimited articles, every theme, highlights & more")
                                .font(.caption)
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
        } footer: {
            if !isPro {
                Text("\(allArticles.filter { !$0.isArchived }.count) of \(Pro.freeArticleLimit) free article slots used.")
            }
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("App theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearanceRaw = $0.rawValue }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
        }
    }

    // MARK: Reader defaults

    private var readerSection: some View {
        Section {
            Picker("Default reader theme", selection: Binding(
                get: { settings.defaultReaderTheme },
                set: { newValue in
                    if Pro.isThemeLocked(newValue, isPro: isPro) {
                        showPaywall = true
                    } else {
                        settings.defaultReaderThemeRaw = newValue.rawValue
                    }
                }
            )) {
                ForEach(ReaderTheme.allCases) { t in
                    Text(t.title + (Pro.isThemeLocked(t, isPro: isPro) ? " (Pro)" : "")).tag(t)
                }
            }

            Picker("Default font", selection: Binding(
                get: { settings.defaultReaderFont },
                set: { newValue in
                    if Pro.isFontLocked(newValue, isPro: isPro) {
                        showPaywall = true
                    } else {
                        settings.defaultReaderFontRaw = newValue.rawValue
                    }
                }
            )) {
                ForEach(ReaderFont.allCases) { f in
                    Text(f.title + (Pro.isFontLocked(f, isPro: isPro) ? " (Pro)" : "")).tag(f)
                }
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Default text size")
                    Spacer()
                    Text("\(Int(settings.readerFontSize)) pt")
                        .foregroundStyle(Theme.inkSoft)
                }
                Slider(value: $settings.readerFontSize, in: 15...26, step: 1)
                    .tint(Theme.accent)
                    .accessibilityValue("\(Int(settings.readerFontSize)) points")
            }
        } header: {
            Text("Reader defaults")
        } footer: {
            Text("New articles open with these settings. You can adjust any article live while reading.")
        }
    }

    // MARK: Reading

    private var readingSection: some View {
        Section {
            VStack(alignment: .leading) {
                HStack {
                    Text("Reading speed")
                    Spacer()
                    Text("\(settings.wordsPerMinute) wpm")
                        .foregroundStyle(Theme.inkSoft)
                }
                Slider(
                    value: Binding(
                        get: { Double(settings.wordsPerMinute) },
                        set: { settings.wordsPerMinute = Int($0) }
                    ),
                    in: 120...400, step: 10
                )
                .tint(Theme.accent)
                .accessibilityLabel("Reading speed")
                .accessibilityValue("\(settings.wordsPerMinute) words per minute")
            }
        } header: {
            Text("Reading")
        } footer: {
            Text("Used to estimate how long each article will take.")
        }
    }

    // MARK: Behavior

    private var behaviorSection: some View {
        Section("Behavior") {
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                .tint(Theme.accent)
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Articles saved")
                Spacer()
                Text("\(allArticles.count)").foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        } header: {
            Text("About")
        } footer: {
            Text("Stow keeps everything on this device. No account, no cloud, no tracking.")
        }
    }
}
