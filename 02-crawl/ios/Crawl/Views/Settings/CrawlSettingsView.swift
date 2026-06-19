import SwiftUI

struct CrawlSettingsView: View {
    @AppStorage("crawlMode") private var savedMode = GameMode.classic.rawValue
    @AppStorage("crawlHaptics") private var hapticsEnabled = true
    @AppStorage("crawlGridVisible") private var gridVisible = false
    @AppStorage("crawlHasSeenOnboarding") private var hasSeenOnboarding = true

    private var selectedMode: Binding<GameMode> {
        Binding(
            get: { GameMode(rawValue: savedMode) ?? .classic },
            set: { savedMode = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.04).ignoresSafeArea()

                List {
                    Section("Gameplay") {
                        Picker("Default Mode", selection: selectedMode) {
                            ForEach(GameMode.allCases) { mode in
                                VStack(alignment: .leading) {
                                    Text(mode.rawValue)
                                    Text(mode.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .tag(mode)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section("Appearance") {
                        Toggle("Show Grid Lines", isOn: $gridVisible)
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section("Feel") {
                        Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0").foregroundStyle(.secondary)
                        }
                        Button("Show Introduction") {
                            hasSeenOnboarding = false
                        }
                        .foregroundStyle(.green)
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
            }
            .navigationTitle("Settings")
            .toolbarBackground(Color(red: 0.04, green: 0.06, blue: 0.04), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .tint(.green)
    }
}
