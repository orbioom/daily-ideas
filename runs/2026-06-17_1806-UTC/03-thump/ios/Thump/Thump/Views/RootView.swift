import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var store: SequencerStore?
    @State private var didSeed = false

    var body: some View {
        Group {
            if let store {
                TabView {
                    SequencerView()
                        .tabItem { Label("Beats", systemImage: "square.grid.3x3.fill") }

                    PatternsView()
                        .tabItem { Label("Patterns", systemImage: "rectangle.stack.fill") }

                    KitsView()
                        .tabItem { Label("Kits", systemImage: "circle.hexagongrid.fill") }

                    SongView()
                        .tabItem { Label("Song", systemImage: "music.note.list") }

                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                }
                .environment(store)
                .tint(Theme.accent)
            } else {
                LoadingScreen(text: "Warming up the rack…")
            }
        }
        .task {
            // Build store + engine once, then seed + load initial kit.
            let s: SequencerStore
            if let existing = store {
                s = existing
            } else {
                s = SequencerStore(audio: AudioEngine())
                s.updatePro(isPro)
                store = s
            }
            if !didSeed {
                SeedData.seedIfNeeded(context: context)
                didSeed = true
            }
            s.audio.masterVolume = settings.masterVolume
            s.audio.metronomeEnabled = settings.metronomeEnabled
            s.audio.countInEnabled = settings.countInEnabled
            await s.ensureKitLoaded()
        }
        .onChange(of: isPro) { _, newValue in
            store?.updatePro(newValue)
        }
        .onChange(of: settings.masterVolume) { _, newValue in
            store?.audio.masterVolume = newValue
        }
        .onChange(of: settings.metronomeEnabled) { _, newValue in
            store?.audio.metronomeEnabled = newValue
        }
        .onChange(of: settings.countInEnabled) { _, newValue in
            store?.audio.countInEnabled = newValue
        }
    }
}

/// Full-screen calm loading state.
struct LoadingScreen: View {
    let text: String
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 18) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.accent)
                Text(text)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(text))
    }
}
