import SwiftUI

struct DraftSettingsView: View {
    @AppStorage("draftDefaultGenre") private var defaultGenre = "Fantasy"
    @AppStorage("draftDefaultTarget") private var defaultTarget = 80000
    @AppStorage("draftShowWordCount") private var showWordCount = true
    @AppStorage("draftAutoDate") private var autoDate = true
    @AppStorage("draftHasSeenOnboarding") private var hasSeenOnboarding = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.06, blue: 0.02).ignoresSafeArea()

                List {
                    Section("Defaults") {
                        Picker("Default Genre", selection: $defaultGenre) {
                            ForEach(ProjectGenre.allCases, id: \.rawValue) { g in
                                Text(g.rawValue).tag(g.rawValue)
                            }
                        }
                        Stepper("Goal: \(defaultTarget.formatted()) words", value: $defaultTarget, in: 1000...500000, step: 5000)
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section("Display") {
                        Toggle("Show Word Count Progress", isOn: $showWordCount)
                        Toggle("Auto-update Timestamps", isOn: $autoDate)
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0").foregroundStyle(.secondary)
                        }
                        Button("Show Introduction") { hasSeenOnboarding = false }
                            .foregroundStyle(Color(red: 0.85, green: 0.58, blue: 0.15))
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
            }
            .navigationTitle("Settings")
        }
        .tint(Color(red: 0.85, green: 0.58, blue: 0.15))
    }
}
