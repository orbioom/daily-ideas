import SwiftUI
import SwiftData

struct BrickSettingsView: View {
    @AppStorage("brickHaptics") private var hapticsEnabled = true
    @AppStorage("brickSoundEnabled") private var soundEnabled = true
    @AppStorage("brickShowFPS") private var showFPS = false
    @AppStorage("brickHasSeenOnboarding") private var hasSeenOnboarding = true
    @Environment(\.modelContext) private var modelContext
    @Query private var scores: [BrickHighScore]
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.12).ignoresSafeArea()

                List {
                    Section("Feedback") {
                        Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                        Toggle("Sound Effects", isOn: $soundEnabled)
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section("Display") {
                        Toggle("Show FPS", isOn: $showFPS)
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
                        .foregroundStyle(Color(red: 1, green: 0.6, blue: 0.1))
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section("Data") {
                        Button("Reset All Scores", role: .destructive) {
                            showResetConfirm = true
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
            }
            .navigationTitle("Settings")
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.12), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .confirmationDialog("Reset all high scores?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    scores.forEach { modelContext.delete($0) }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .tint(Color(red: 1, green: 0.6, blue: 0.1))
    }
}
